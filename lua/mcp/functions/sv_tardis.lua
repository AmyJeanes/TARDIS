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

---@return number[]? values, string? err
local function parseTriple(t, label)
    if type(t) ~= "table" or #t ~= 3 then
        return nil, "`" .. label .. "` must be a 3-element array"
    end
    for i = 1, 3 do
        if type(t[i]) ~= "number" then
            return nil, "`" .. label .. "[" .. i .. "]` must be a number"
        end
    end
    return { t[1], t[2], t[3] }
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

-- Summarise the demat -> vortex -> mat lifecycle. `landed` is the reliable idle gate: `teleport`
-- spans the whole cycle and `vortex` covers the between-phase, so neither set means fully landed.
local function materialization(ext)
    local demat = ext:GetData("demat", false)
    local mat = ext:GetData("mat", false)
    local vortex = ext:GetData("vortex", false)
    local teleport = ext:GetData("teleport", false)
    local phase
    if mat then phase = "materializing"
    elseif demat then phase = "dematerializing"
    elseif vortex then phase = "in_vortex"
    elseif teleport then phase = "teleporting"
    else phase = "landed" end
    return {
        phase = phase,
        landed = (not teleport) and (not vortex),
        demat = demat,
        mat = mat,
        vortex = vortex,
        teleport = teleport,
        hads_demat = ext:GetData("hads-demat", false),
    }
end

local function occupantList(ext)
    local list = {}
    if istable(ext.occupants) then
        for p in pairs(ext.occupants) do
            if IsValid(p) then
                list[#list + 1] = { name = p:Nick(), steamid = p:SteamID(), userid = p:UserID() }
            end
        end
    end
    return list
end

-- Census the interior's cordoned props (int.props) instead of the hand-rolled walk: a count and a
-- class -> count tally.
local function cordonCensus(ext)
    local int = ext.interior
    if not IsValid(int) or not istable(int.props) then return nil end
    local count, classes = 0, {}
    for e in pairs(int.props) do
        if IsValid(e) then
            count = count + 1
            local c = e:GetClass()
            classes[c] = (classes[c] or 0) + 1
        end
    end
    local census = { interior_index = int:EntIndex(), prop_count = count, classes = classes }
    return census
end

local function interiorName(ext)
    local meta = ext.metadataID and TARDIS:GetInterior(ext.metadataID)
    if meta and meta.Name then return TARDIS:GetPhrase(meta.Name) end
    return nil
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
            local coords, posErr = parseTriple(args.pos, "pos")
            if not coords then return { ok = false, error = posErr } end
            pos = Vector(coords[1], coords[2], coords[3])
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
            local coords, posErr = parseTriple(args.pos, "pos")
            if not coords then return { ok = false, error = posErr } end
            pos = Vector(coords[1], coords[2], coords[3])
        end
        if args.ang then
            local angles, angErr = parseTriple(args.ang, "ang")
            if not angles then return { ok = false, error = angErr } end
            ang = Angle(angles[1], angles[2], angles[3])
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
    id = "tardis_state",
    description = "Structured snapshot of a TARDIS exterior in one read. Returns identity (entindex, creation_id, interior_id + interior_name, pos, ang, owner), `state` (the addon's raw state value), power, handbrake, flight, a `door` block {open, locked, locking}, a `materialization` block summarising the demat -> vortex -> mat lifecycle (`phase` is landed/dematerializing/in_vortex/materializing/teleporting, `landed` is true when no transition is in progress, plus the raw demat/mat/vortex/teleport/hads_demat flags), the `occupants` currently inside (name/steamid/userid) with occupant_count, and a `cordon` census of the interior's cordoned props (interior_index, prop_count, and a class -> count tally). Pass `entindex` (a TARDIS exterior).",
    schema = {
        type = "object",
        properties = {
            entindex = { type = "number", description = "TARDIS exterior entindex." },
        },
        required = { "entindex" },
    },
    requires = { "tardis_control" },
    handler = function(args)
        local ext, err = resolveTardis(args.entindex)
        if not ext then return { ok = false, error = err } end

        local occupants = occupantList(ext)
        return {
            ok = true,
            entindex = ext:EntIndex(),
            creation_id = ext:GetCreationID(),
            interior_id = ext.metadataID,
            interior_name = interiorName(ext),
            pos = vec3(ext:GetPos()),
            ang = ang3(ext:GetAngles()),
            owner = ownerInfo(ext),
            state = ext:GetState(),
            power = ext:GetPower(),
            handbrake = ext:GetHandbrake(),
            flight = ext:GetData("flight", false),
            door = {
                open = ext:DoorOpen(true),
                locked = ext:Locked(),
                locking = ext:Locking(),
            },
            materialization = materialization(ext),
            occupants = occupants,
            occupant_count = #occupants,
            cordon = cordonCensus(ext),
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

MCP:AddFunction({
    id = "tardis_wait_landed",
    timeout = 58,
    description = "Block until a TARDIS finishes its current demat/mat cycle and is fully landed (materialised + idle), then report -- the readiness wait that replaces hand-rolled GetData polling loops. `landed` is true when neither `teleport` (which spans the whole cycle) nor `vortex` is set, held briefly so a phase handoff can't false-trigger. Returns landed (false on timeout), seconds_elapsed, the final `phase` + `materialization` block, and the landing `pos`. Note a TARDIS parked in the vortex (e.g. after a bare tardis_demat with no follow-up) will NOT land on its own -- issue tardis_mat first, else this times out reporting phase \"in_vortex\". `seconds` caps the wait (default 30, max 55).",
    schema = {
        type = "object",
        properties = {
            entindex = { type = "number", description = "TARDIS exterior entindex." },
            seconds = { type = "number", description = "Max seconds to wait for landing (default 30, max 55). Returns landed=false if it doesn't land in time." },
        },
        required = { "entindex" },
    },
    requires = { "tardis_control" },
    handler = function(args, ctx)
        local ext, err = resolveTardis(args.entindex)
        if not ext then return { ok = false, error = err } end

        local seconds = math.Clamp(tonumber(args.seconds) or 30, 0.1, 55)

        MCP:Settle({
            seconds = seconds,
            stable_for = 0.1,
            check = function()
                if not IsValid(ext) then return false end
                return (not ext:GetData("teleport", false)) and (not ext:GetData("vortex", false))
            end,
        }, function(s)
            if not IsValid(ext) then
                ctx.respond({ ok = false, error = "TARDIS was removed during the wait" })
                return
            end
            local m = materialization(ext)
            ctx.respond({
                ok = true,
                entindex = ext:EntIndex(),
                landed = s.settled,
                timed_out = not s.settled,
                seconds_elapsed = math.Round(s.elapsed, 3),
                phase = m.phase,
                materialization = m,
                pos = vec3(ext:GetPos()),
            })
        end)

        return ctx.deferred
    end,
})

MCP:AddFunction({
    id = "tardis_door",
    timeout = 12,
    description = "Set a TARDIS door to a specific open/closed and/or lock state, wait for the animation to finish, then report the actual result -- a set-state control (not a toggle), so it's idempotent. Pass `entindex` and at least one of `open` (true=open, false=close) and `locked` (true=lock, false=unlock). Locking also closes the door, so `open:true` with `locked:true` is contradictory: the lock wins, the door ends closed+locked, reported honestly via door_took=false. Unlocking is applied before opening so a lock can't block it. The open is instant; a close animates (~0.6s) and a lock animates -- this waits both out (up to 8s) before reporting the final door {open, locked, locking}, the before-state, and door_took / lock_took (whether each requested change took).",
    schema = {
        type = "object",
        properties = {
            entindex = { type = "number", description = "TARDIS exterior entindex." },
            open = { type = "boolean", description = "Set the door open (true) or closed (false)." },
            locked = { type = "boolean", description = "Set the door locked (true -- this also closes it) or unlocked (false)." },
        },
        required = { "entindex" },
    },
    requires = { "tardis_control" },
    handler = function(args, ctx)
        local ext, err = resolveTardis(args.entindex)
        if not ext then return { ok = false, error = err } end
        if args.open == nil and args.locked == nil then
            return { ok = false, error = "specify at least one of `open` or `locked`" }
        end

        local before = { open = ext:DoorOpen(true), locked = ext:Locked() }

        -- Unlock before opening so a lock can't block the open; lock last so it wins (it also closes).
        if args.locked == false then ext:SetLocked(false) end
        if args.open ~= nil then
            if args.open then ext:OpenDoor() else ext:CloseDoor() end
        end
        if args.locked == true then ext:SetLocked(true) end

        MCP:Settle({
            seconds = 8,
            stable_for = 0.1,
            check = function()
                if not IsValid(ext) then return false end
                -- doorchangewait is set during a close animation and cleared at its end (open is
                -- instant); Locking() covers the lock animation. Both clear == the door has settled.
                return (not ext:Locking()) and (not ext:GetData("doorchangewait", false))
            end,
        }, function(s)
            if not IsValid(ext) then
                ctx.respond({ ok = false, error = "TARDIS was removed during the wait" })
                return
            end
            local door = { open = ext:DoorOpen(true), locked = ext:Locked(), locking = ext:Locking() }
            local result = {
                ok = true,
                entindex = ext:EntIndex(),
                settled = s.settled,
                before = before,
                door = door,
            }
            if args.open ~= nil then result.door_took = (door.open == args.open) end
            if args.locked ~= nil then result.lock_took = (door.locked == args.locked) end
            ctx.respond(result)
        end)

        return ctx.deferred
    end,
})

MCP:AddFunction({
    id = "tardis_power",
    description = "Set a TARDIS's power on or off and report the result. SetPower is synchronous and can be vetoed (e.g. you can't power down while travelling/in the vortex); on a veto the power is left unchanged and `reason` carries why. Pass `entindex` and `on` (true/false). Returns requested/before/power/took (power == requested)/changed, plus `reason` on a failed toggle.",
    schema = {
        type = "object",
        properties = {
            entindex = { type = "number", description = "TARDIS exterior entindex." },
            on = { type = "boolean", description = "Power on (true) or off (false)." },
        },
        required = { "entindex", "on" },
    },
    requires = { "tardis_control" },
    handler = function(args)
        local ext, err = resolveTardis(args.entindex)
        if not ext then return { ok = false, error = err } end
        if type(args.on) ~= "boolean" then return { ok = false, error = "`on` must be a boolean (true=on, false=off)" } end

        local before = ext:GetPower()
        local toggled, reason = ext:SetPower(args.on)
        local after = ext:GetPower()
        local result = {
            ok = true,
            entindex = ext:EntIndex(),
            requested = args.on,
            before = before,
            power = after,
            took = (after == args.on),
            changed = (after ~= before),
        }
        if (not toggled) and reason then result.reason = tostring(reason) end
        return result
    end,
})

MCP:AddFunction({
    id = "tardis_enter",
    timeout = 8,
    description = "Move a player into a TARDIS interior, confirm they're inside, and report. Pass `entindex` (the TARDIS) and optionally `steamid` (the player to move; defaults to the first connected player) and `outside_view` (after entering, put them in the exterior third-person 'outside' camera). Waits briefly until the player registers as an occupant, then returns the player identity, inside (true once they're an occupant), outside_view (whether the outside camera took), and occupant_count.",
    schema = {
        type = "object",
        properties = {
            entindex = { type = "number", description = "TARDIS exterior entindex." },
            steamid = { type = "string", description = "Player SteamID/SteamID64 to move inside; defaults to the first connected player." },
            outside_view = { type = "boolean", description = "After entering, put the player in the exterior third-person 'outside' view." },
        },
        required = { "entindex" },
    },
    requires = { "tardis_control" },
    handler = function(args, ctx)
        local ext, err = resolveTardis(args.entindex)
        if not ext then return { ok = false, error = err } end
        local ply, plyErr = resolvePlayer(args.steamid)
        if not ply then return { ok = false, error = plyErr } end

        ext:PlayerEnter(ply)
        local outsideView
        if args.outside_view == true then outsideView = ext:SetOutsideView(ply, true) and true or false end

        MCP:Settle({
            seconds = 3,
            stable_for = 0,
            check = function()
                return IsValid(ext) and IsValid(ply) and istable(ext.occupants) and ext.occupants[ply] == true
            end,
        }, function(s)
            if not (IsValid(ext) and IsValid(ply)) then
                ctx.respond({ ok = false, error = "TARDIS or player became invalid during enter" })
                return
            end
            ctx.respond({
                ok = true,
                entindex = ext:EntIndex(),
                player = { name = ply:Nick(), steamid = ply:SteamID(), userid = ply:UserID() },
                inside = istable(ext.occupants) and ext.occupants[ply] == true or false,
                settled = s.settled,
                outside_view = outsideView,
                occupant_count = #occupantList(ext),
            })
        end)
        return ctx.deferred
    end,
})

MCP:AddFunction({
    id = "tardis_exit",
    timeout = 8,
    description = "Move a player out of a TARDIS interior to the exterior, confirm they've left, and report. Pass `entindex` (the TARDIS) and optionally `steamid` (defaults to the first connected player). Waits briefly until the player is no longer an occupant, then returns the player identity, was_inside (whether they were inside to begin with), inside (false once out), and occupant_count.",
    schema = {
        type = "object",
        properties = {
            entindex = { type = "number", description = "TARDIS exterior entindex." },
            steamid = { type = "string", description = "Player SteamID/SteamID64 to move out; defaults to the first connected player." },
        },
        required = { "entindex" },
    },
    requires = { "tardis_control" },
    handler = function(args, ctx)
        local ext, err = resolveTardis(args.entindex)
        if not ext then return { ok = false, error = err } end
        local ply, plyErr = resolvePlayer(args.steamid)
        if not ply then return { ok = false, error = plyErr } end

        local wasInside = istable(ext.occupants) and ext.occupants[ply] == true
        ext:PlayerExit(ply)

        MCP:Settle({
            seconds = 3,
            stable_for = 0,
            check = function()
                return (not IsValid(ply)) or not (IsValid(ext) and istable(ext.occupants) and ext.occupants[ply] == true)
            end,
        }, function(s)
            ctx.respond({
                ok = true,
                entindex = IsValid(ext) and ext:EntIndex() or args.entindex,
                player = IsValid(ply) and { name = ply:Nick(), steamid = ply:SteamID(), userid = ply:UserID() } or nil,
                was_inside = wasInside,
                inside = (IsValid(ext) and IsValid(ply) and istable(ext.occupants) and ext.occupants[ply] == true) or false,
                settled = s.settled,
                occupant_count = IsValid(ext) and #occupantList(ext) or 0,
            })
        end)
        return ctx.deferred
    end,
})
