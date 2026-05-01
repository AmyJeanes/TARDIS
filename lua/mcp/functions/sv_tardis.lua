-- MCP Functions

MCP:AddCapability({
    id = "tardis_control",
    description = "Allows MCP callers to spawn, control, and inspect TARDISes.",
    default = false,
})

local function resolveTardis(entindex)
    if type(entindex) ~= "number" then
        return nil, "`entindex` must be a number"
    end
    local ent = Entity(entindex)
    if not IsValid(ent) or not ent.TardisExterior then
        return nil, "no TARDIS at entindex " .. entindex
    end
    return ent
end

local function resolvePlayer(steamid)
    if steamid ~= nil then
        if type(steamid) ~= "string" then
            return nil, "`steamid` must be a string"
        end
        for _, p in ipairs(player.GetAll()) do
            if p:SteamID() == steamid or p:SteamID64() == steamid then
                return p
            end
        end
        return nil, "no connected player matches steamid " .. steamid
    end

    local players = player.GetAll()
    if #players == 0 then
        return nil, "no players connected; pass `steamid` once a player joins"
    end
    return players[1]
end

local function parseTriple(t, label)
    if type(t) ~= "table" or #t ~= 3 then
        return nil, "`" .. label .. "` must be a 3-element array"
    end
    for i = 1, 3 do
        if type(t[i]) ~= "number" then
            return nil, "`" .. label .. "[" .. i .. "]` must be a number"
        end
    end
    return t[1], t[2], t[3]
end

local function vec3(v) return { v.x, v.y, v.z } end
local function ang3(a) return { a.p, a.y, a.r } end

local function ownerInfo(ent)
    local creator = ent:GetCreator()
    if not IsValid(creator) then return nil end
    return { name = creator:Nick(), steamid = creator:SteamID() }
end

local function tardisSummary(ent)
    return {
        entindex = ent:EntIndex(),
        creation_id = ent:GetCreationID(),
        interior_id = ent.metadataID,
        pos = vec3(ent:GetPos()),
        ang = ang3(ent:GetAngles()),
        owner = ownerInfo(ent),
        state = ent:GetState(),
    }
end

MCP:AddFunction({
    id = "tardis_list_interiors",
    description = "List interior IDs available to pass to tardis_spawn.",
    schema = { type = "object", properties = {}, required = {} },
    requires = { "tardis_control" },
    handler = function()
        local interiors = {}
        for id, meta in pairs(TARDIS:GetInteriors()) do
            if not (meta.Base == true or meta.Hidden or meta.IsVersionOf) then
                interiors[#interiors + 1] = {
                    id = id,
                    name = TARDIS:GetPhrase(meta.Name),
                }
            end
        end
        table.sort(interiors, function(a, b) return a.id < b.id end)
        return { ok = true, interiors = interiors }
    end,
})

MCP:AddFunction({
    id = "tardis_list_spawned",
    description = "List currently-spawned TARDIS exteriors. Optional `steamid` filters to one owner.",
    schema = {
        type = "object",
        properties = {
            steamid = { type = "string", description = "Optional SteamID/SteamID64 to filter by owner." },
        },
        required = {},
    },
    requires = { "tardis_control" },
    handler = function(args)
        local ply
        if args.steamid then
            local p, err = resolvePlayer(args.steamid)
            if not p then return { ok = false, error = err } end
            ply = p
        end

        local list = {}
        for _, ent in ipairs(TARDIS:GetExteriorEnts(ply)) do
            list[#list + 1] = tardisSummary(ent)
        end
        return { ok = true, tardises = list }
    end,
})

MCP:AddFunction({
    id = "tardis_spawn",
    description = "Spawn a TARDIS for a player. Returns the new entity's entindex.",
    schema = {
        type = "object",
        properties = {
            interior = { type = "string", description = "Interior id from tardis_list_interiors." },
            steamid = { type = "string", description = "Owner SteamID/SteamID64; defaults to the first connected player." },
            pos = { type = "array", items = { type = "number" }, description = "Optional [x,y,z] spawn position; defaults to the spawner's aim trace." },
        },
        required = { "interior" },
    },
    requires = { "tardis_control" },
    handler = function(args)
        if type(args.interior) ~= "string" or args.interior == "" then
            return { ok = false, error = "missing or empty `interior`" }
        end
        if not TARDIS:GetInterior(args.interior) then
            return { ok = false, error = "unknown interior id: " .. args.interior }
        end

        local ply, plyErr = resolvePlayer(args.steamid)
        if not ply then return { ok = false, error = plyErr } end

        local pos
        if args.pos then
            local x, y, z = parseTriple(args.pos, "pos")
            if not x then return { ok = false, error = y } end
            pos = Vector(x, y, z)
        end

        local ent = TARDIS:SpawnTARDIS(ply, { metadataID = args.interior, pos = pos })
        if not IsValid(ent) then
            return { ok = false, error = "TARDIS:SpawnTARDIS returned no entity (gamemode hook may have blocked spawn)" }
        end

        return {
            ok = true,
            entindex = ent:EntIndex(),
            creation_id = ent:GetCreationID(),
            pos = vec3(ent:GetPos()),
            owner = { name = ply:Nick(), steamid = ply:SteamID() },
        }
    end,
})

MCP:AddFunction({
    id = "tardis_demat",
    description = "Trigger a TARDIS dematerialisation. Optional pos/ang override the destination.",
    schema = {
        type = "object",
        properties = {
            entindex = { type = "number", description = "TARDIS exterior entindex." },
            pos = { type = "array", items = { type = "number" }, description = "Optional [x,y,z] destination." },
            ang = { type = "array", items = { type = "number" }, description = "Optional [p,y,r] destination angles." },
        },
        required = { "entindex" },
    },
    requires = { "tardis_control" },
    handler = function(args)
        local ent, err = resolveTardis(args.entindex)
        if not ent then return { ok = false, error = err } end

        local pos, ang
        if args.pos then
            local x, y, z = parseTriple(args.pos, "pos")
            if not x then return { ok = false, error = y } end
            pos = Vector(x, y, z)
        end
        if args.ang then
            local p, yaw, r = parseTriple(args.ang, "ang")
            if not p then return { ok = false, error = yaw } end
            ang = Angle(p, yaw, r)
        end

        ent:Demat(pos, ang)
        return { ok = true }
    end,
})

MCP:AddFunction({
    id = "tardis_mat",
    description = "Trigger a TARDIS rematerialisation at its current destination.",
    schema = {
        type = "object",
        properties = {
            entindex = { type = "number", description = "TARDIS exterior entindex." },
        },
        required = { "entindex" },
    },
    requires = { "tardis_control" },
    handler = function(args)
        local ent, err = resolveTardis(args.entindex)
        if not ent then return { ok = false, error = err } end

        ent:Mat()
        return { ok = true }
    end,
})

MCP:AddFunction({
    id = "tardis_status",
    description = "Read state flags from a TARDIS exterior.",
    schema = {
        type = "object",
        properties = {
            entindex = { type = "number", description = "TARDIS exterior entindex." },
        },
        required = { "entindex" },
    },
    requires = { "tardis_control" },
    handler = function(args)
        local ent, err = resolveTardis(args.entindex)
        if not ent then return { ok = false, error = err } end

        return {
            ok = true,
            status = {
                state = ent:GetState(),
                power = ent:GetPower(),
                flight = ent:GetData("flight", false),
                handbrake = ent:GetHandbrake(),
                demat = ent:GetData("demat", false),
                mat = ent:GetData("mat", false),
                vortex = ent:GetData("vortex", false),
                teleport = ent:GetData("teleport", false),
                doors_open = ent:GetData("doorstatereal", false),
                hads_demat = ent:GetData("hads-demat", false),
                interior_id = ent.metadataID,
                pos = vec3(ent:GetPos()),
                ang = ang3(ent:GetAngles()),
                owner = ownerInfo(ent),
            },
        }
    end,
})

MCP:AddFunction({
    id = "tardis_remove",
    description = "Remove (despawn) a TARDIS exterior.",
    schema = {
        type = "object",
        properties = {
            entindex = { type = "number", description = "TARDIS exterior entindex." },
        },
        required = { "entindex" },
    },
    requires = { "tardis_control" },
    handler = function(args)
        local ent, err = resolveTardis(args.entindex)
        if not ent then return { ok = false, error = err } end

        ent:Remove()
        return { ok = true }
    end,
})
