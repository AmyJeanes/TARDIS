-- MCP Functions

MCP:AddCapability({
    id = "tardis_control",
    description = "Allows MCP callers to spawn, control, and inspect TARDISes.",
    default = false,
})

---@param entindex number
---@return gmod_tardis? ent, string? err
local function resolveTardis(entindex)
    if type(entindex) ~= "number" then
        return nil, "`entindex` must be a number"
    end
    local ent = Entity(entindex)
    if not IsValid(ent) or not ent.TardisExterior then
        return nil, "no TARDIS at entindex " .. entindex
    end
    ---@cast ent gmod_tardis -- narrowed via the TardisExterior flag field, not a class-narrowing check the analyzer follows
    return ent
end

---@param steamid string?
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

---@param t any decoded JSON arg, validated at runtime
---@param label string
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

---@param v Vector
local function vec3(v) return { v.x, v.y, v.z } end
---@param a Angle
local function ang3(a) return { a.p, a.y, a.r } end

---@param ent Entity
local function ownerInfo(ent)
    local creator = ent:GetCreator()
    if not IsValid(creator) then return nil end
    return { name = creator:Nick(), steamid = creator:SteamID() }
end

---@param ent gmod_tardis
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
---@param ext gmod_tardis
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

---@param ext gmod_tardis
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
-- class -> count tally, plus an optional per-entity list (index/class/pos).
---@param ext gmod_tardis
---@param includeEntities boolean
local function cordonCensus(ext, includeEntities)
    local int = ext.interior
    if not IsValid(int) or not istable(int.props) then return nil end
    local count, classes = 0, {}
    local entities = includeEntities and {} or nil
    for e in pairs(int.props) do
        if IsValid(e) then
            count = count + 1
            local c = e:GetClass()
            classes[c] = (classes[c] or 0) + 1
            if entities then
                entities[#entities + 1] = { index = e:EntIndex(), class = c, pos = vec3(e:GetPos()) }
            end
        end
    end
    local census = { interior_index = int:EntIndex(), prop_count = count, classes = classes }
    if entities then census.entities = entities end
    return census
end

---@param ext gmod_tardis
local function interiorName(ext)
    local meta = ext.metadataID and TARDIS:GetInterior(ext.metadataID)
    if meta and meta.Name then return TARDIS:GetPhrase(meta.Name) end
    return nil
end

---@param ext gmod_tardis
local function chameleonInfo(ext)
    if not ext.IsChameleonActive then return nil end
    return {
        active = ext:IsChameleonActive(),
        current = ext:GetData("chameleon_current_exterior", false),
        selected = ext:GetData("chameleon_selected_exterior"),
        changing = ext:GetData("chameleon_changing", false),
    }
end

-- Scanners live on the interior entity, not the exterior.
---@param ext gmod_tardis
local function scannerInfo(ext)
    local int = ext.interior
    if not IsValid(int) or not int.GetScannersOn then return nil end
    return {
        on = int:GetScannersOn(),
        count = istable(int.scanners) and table.Count(int.scanners) or 0,
    }
end

---@param p linked_portal_door
local function portalTransform(p)
    if not IsValid(p) then return nil end
    local t = { pos = vec3(p:GetPos()), ang = ang3(p:GetAngles()) }
    if p.GetWidth then t.width = p:GetWidth() end
    if p.GetHeight then t.height = p:GetHeight() end
    return t
end

-- The interior's door portals (linked_portal_door): `exterior` sits at the exterior model's door in
-- the world, `interior` at the interior set. Their world transforms are how you aim a shot or trace at
-- the actual doorway.
---@param ext gmod_tardis
local function portalInfo(ext)
    local int = ext.interior
    if not IsValid(int) or not istable(int.portals) then return nil end
    return {
        exterior = portalTransform(int.portals.exterior),
        interior = portalTransform(int.portals.interior),
    }
end

-- Reverse lookup: the TARDIS a player is currently inside. Server-authoritative -- set on PlayerEnter,
-- cleared on exit (ply:GetTardisData("exterior")); read server-side only, so no sv/cl divergence. An
-- empty steamid means the first/only player (handy in singleplayer).
---@param steamid string
---@return gmod_tardis? ext, string? err
local function tardisFromPlayer(steamid)
    local ply, err = resolvePlayer(steamid ~= "" and steamid or nil)
    if not ply then return nil, err end
    local ext = ply.GetTardisData and ply:GetTardisData("exterior")
    if not IsValid(ext) or not ext.TardisExterior then
        return nil, "player " .. ply:Nick() .. " is not currently inside a TARDIS"
    end
    ---@cast ext gmod_tardis -- narrowed via the TardisExterior flag field, not a class-narrowing check the analyzer follows
    return ext
end

MCP:AddFunction({
    id = "tardis_list_interiors",
    description = "List interior IDs available to pass to tardis_spawn.",
    schema = { type = "object", properties = {}, required = {} },
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
    description = "Spawn a TARDIS for a player. Optional `pos`/`angles` place and orient it (SpawnTARDIS itself orients from the spawner's aim, so `angles` is applied after). `frozen` pins the exterior in place on spawn (default false -- it spawns mobile and settles under gravity like a normal spawn; set true to keep it exactly where placed for a static test). Returns the new entity's entindex, creation_id, spawn pos/angles, and the actual frozen state.",
    schema = {
        type = "object",
        properties = {
            interior = { type = "string", description = "Interior id from tardis_list_interiors." },
            steamid = { type = "string", description = "Owner SteamID/SteamID64; defaults to the first connected player." },
            pos = { type = "array", items = { type = "number" }, description = "Optional [x,y,z] spawn position; defaults to the spawner's aim trace." },
            angles = { type = "array", items = { type = "number" }, description = "Optional [p,y,r] spawn angles, applied after spawn." },
            frozen = { type = "boolean", description = "Freeze the exterior in place on spawn (raw physics EnableMotion(false)). Default false -- the TARDIS spawns mobile; set true to pin it where placed. This is a raw physics freeze, distinct from the TARDIS's own power-gated physlock, and the addon re-enables motion on materialisation." },
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

        local ang
        if args.angles then
            local a, angErr = parseTriple(args.angles, "angles")
            if not a then return { ok = false, error = angErr } end
            ang = Angle(a[1], a[2], a[3])
        end

        local ent = TARDIS:SpawnTARDIS(ply, { metadataID = args.interior, pos = pos })
        if not IsValid(ent) then
            return { ok = false, error = "TARDIS:SpawnTARDIS returned no entity (gamemode hook may have blocked spawn)" }
        end

        if ang then ent:SetAngles(ang) end

        local frozen = false
        if args.frozen == true then
            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableMotion(false)
                phys:Wake()
                frozen = true
            end
        end

        return {
            ok = true,
            entindex = ent:EntIndex(),
            creation_id = ent:GetCreationID(),
            pos = vec3(ent:GetPos()),
            angles = ang3(ent:GetAngles()),
            frozen = frozen,
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
    description = "Structured snapshot of a TARDIS exterior in one read. Identify the TARDIS by `entindex`, or pass `steamid` to look up the TARDIS a player is currently inside (server-authoritative occupancy). Returns identity (entindex, creation_id, interior_id + interior_name, pos, ang, owner), `state` (the addon's raw state value), power, physlock, handbrake, flight, a `chameleon` block {active, current exterior id (false = the TARDIS's own default), selected (pending selection), changing}, a `scanners` block {on, count} (from the interior), a `door` block {open, locked, locking}, a `portals` block with the interior's door portals' world transforms ({exterior, interior}, each {pos, ang, width, height}), a `materialization` block summarising the demat -> vortex -> mat lifecycle (`phase` is landed/dematerializing/in_vortex/materializing/teleporting, `landed` is true when no transition is in progress, plus the raw demat/mat/vortex/teleport/hads_demat flags), the `occupants` currently inside (name/steamid/userid) with occupant_count, and a `cordon` census of the interior's cordoned props (interior_index, prop_count, and a class -> count tally). Set `include_cordon_entities` to also get a per-entity `cordon.entities` list ({index, class, pos}).",
    schema = {
        type = "object",
        properties = {
            entindex = { type = "number", description = "TARDIS exterior entindex. Provide this or `steamid`." },
            steamid = { type = "string", description = "Instead of entindex, find the TARDIS the given player is currently inside (SteamID/SteamID64). Pass an empty string for the first/only player (singleplayer)." },
            include_cordon_entities = { type = "boolean", description = "Also include a per-entity `cordon.entities` list ({index, class, pos}), not just the count/class tally. Off by default to keep the read lean." },
        },
    },
    handler = function(args)
        local ext, err
        if args.entindex ~= nil then
            ext, err = resolveTardis(args.entindex)
        elseif args.steamid ~= nil then
            ext, err = tardisFromPlayer(args.steamid)
        else
            return { ok = false, error = "specify `entindex` (a TARDIS exterior) or `steamid` (find the TARDIS a player is inside)" }
        end
        if not IsValid(ext) then return { ok = false, error = err } end

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
            physlock = ext.GetPhyslock and ext:GetPhyslock() or false,
            handbrake = ext:GetHandbrake(),
            flight = ext:GetData("flight", false),
            chameleon = chameleonInfo(ext),
            scanners = scannerInfo(ext),
            door = {
                open = ext:DoorOpen(true),
                locked = ext:Locked(),
                locking = ext:Locking(),
            },
            portals = portalInfo(ext),
            materialization = materialization(ext),
            occupants = occupants,
            occupant_count = #occupants,
            cordon = cordonCensus(ext, args.include_cordon_entities == true),
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
    description = "Block until a TARDIS reaches a target phase of its demat/mat cycle, then report -- the readiness wait that replaces hand-rolled GetData polling loops. By default it waits until fully landed (neither `teleport`, which spans the whole cycle, nor `vortex` is set), held briefly so a phase handoff can't false-trigger. Pass `until_phase` to instead wait for a specific phase (landed/dematerializing/in_vortex/materializing/teleporting) -- e.g. wait for `in_vortex` after a tardis_demat. Returns `target` (what it waited for), `reached` (whether it got there before timing out), the honest `landed` state, timed_out, seconds_elapsed, the final `phase` + `materialization` block, and `pos`. Note a TARDIS parked in the vortex (e.g. after a bare tardis_demat with no follow-up) will NOT land on its own -- issue tardis_mat first, else a landed-wait times out reporting phase \"in_vortex\". `seconds` caps the wait (default 30, max 55).",
    schema = {
        type = "object",
        properties = {
            entindex = { type = "number", description = "TARDIS exterior entindex." },
            until_phase = { type = "string", description = "Wait until the TARDIS reaches this specific materialization phase instead of just landing: one of landed/dematerializing/in_vortex/materializing/teleporting. Omit to wait for landed (no teleport/vortex in progress)." },
            seconds = { type = "number", description = "Max seconds to wait (default 30, max 55). Returns reached=false if the target phase isn't reached in time." },
        },
        required = { "entindex" },
    },
    handler = function(args, ctx)
        local ext, err = resolveTardis(args.entindex)
        if not ext then return { ok = false, error = err } end

        local untilPhase = args.until_phase
        if untilPhase ~= nil then
            local valid = { landed = true, dematerializing = true, in_vortex = true, materializing = true, teleporting = true }
            if not valid[untilPhase] then
                return { ok = false, error = "`until_phase` must be one of landed/dematerializing/in_vortex/materializing/teleporting" }
            end
        end

        local seconds = math.Clamp(tonumber(args.seconds) or 30, 0.1, 55)

        MCP:Settle({
            seconds = seconds,
            stable_for = 0.1,
            check = function()
                if not IsValid(ext) then return false end
                if untilPhase then
                    return materialization(ext).phase == untilPhase
                end
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
                target = untilPhase or "landed",
                reached = s.settled,
                landed = m.landed,
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

            -- PlayerThirdPerson, not SetOutsideView: the latter only raises the `outside` flag, and the
            -- camera stays at the player because the hook that moves it out to the exterior answers only
            -- while `thirdperson` is set. Bare SetOutsideView leaves a half-state no real interaction
            -- produces. Applied after the settle because PlayerThirdPerson refuses a player the exterior
            -- does not yet list as an occupant, which PlayerEnter has not necessarily done when it returns.
            local outsideView
            if args.outside_view == true then
                ext:PlayerThirdPerson(ply, true)
                outsideView = ply:GetTardisData("thirdperson") == true
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

MCP:AddFunction({
    id = "tardis_set",
    description = "Mutate a TARDIS interior's state, then report. Operates on the exterior's interior entity. Supply at least one knob: `scanners` (turn the interior scanners on/off -- can be vetoed when unpowered, reported via scanners_took); `base_light_enabled`/`base_light_color`/`base_light_brightness` (the interior's custom base-light override -- color is [r,g,b] 0-255, brightness a multiplier; they only show while base_light_enabled is true and, when it's off, the interior uses its metadata default lighting); `light_state` (apply a named interior light preset like \"normal\"/\"moving\" -- states are interior-metadata-defined and applied client-side, so an unknown name is a harmless no-op). Returns the resulting scanners/base_light state and the applied knobs. The interior-write counterpart to tardis_state's reads.",
    schema = {
        type = "object",
        properties = {
            entindex = { type = "number", description = "TARDIS exterior entindex (mutations apply to its interior)." },
            scanners = { type = "boolean", description = "Turn the interior scanners on (true) or off (false). Vetoed when unpowered -- see scanners_took." },
            base_light_enabled = { type = "boolean", description = "Enable/disable the interior's custom base-light override. When off, the interior uses its metadata default lighting." },
            base_light_color = { type = "array", items = { type = "number" }, description = "Custom base-light color [r,g,b] (0-255). Only shows while base_light_enabled is true." },
            base_light_brightness = { type = "number", description = "Custom base-light brightness multiplier. Only shows while base_light_enabled is true." },
            light_state = { type = "string", description = "Apply a named interior light preset (ApplyLightState), e.g. \"normal\"/\"moving\". Interior-metadata-defined and applied client-side; an unknown name is a no-op." },
        },
        required = { "entindex" },
    },
    requires = { "tardis_control" },
    handler = function(args)
        local ext, err = resolveTardis(args.entindex)
        if not ext then return { ok = false, error = err } end
        local int = ext.interior
        if not IsValid(int) then return { ok = false, error = "TARDIS has no valid interior entity" } end

        local applied = {}
        local result = { ok = true, entindex = ext:EntIndex(), interior_index = int:EntIndex() }

        if args.scanners ~= nil then
            local want = args.scanners == true
            local took = int:SetScannersOn(want)
            result.scanners = int:GetScannersOn()
            result.scanners_took = took == true
            applied[#applied + 1] = "scanners"
        end

        if args.base_light_enabled ~= nil then
            int:SetCustomBaseLightEnabled(args.base_light_enabled == true)
            applied[#applied + 1] = "base_light_enabled"
        end
        if args.base_light_color ~= nil then
            local c, cErr = parseTriple(args.base_light_color, "base_light_color")
            if not c then return { ok = false, error = cErr } end
            int:SetCustomBaseLightColor(Color(math.Clamp(c[1], 0, 255), math.Clamp(c[2], 0, 255), math.Clamp(c[3], 0, 255)))
            applied[#applied + 1] = "base_light_color"
        end
        if args.base_light_brightness ~= nil then
            if not isnumber(args.base_light_brightness) then return { ok = false, error = "`base_light_brightness` must be a number" } end
            int:SetCustomBaseLightBrightness(math.max(0, args.base_light_brightness))
            applied[#applied + 1] = "base_light_brightness"
        end
        if args.light_state ~= nil then
            if not isstring(args.light_state) then return { ok = false, error = "`light_state` must be a string" } end
            int:ApplyLightState(args.light_state)
            result.light_state = args.light_state
            applied[#applied + 1] = "light_state"
        end

        if #applied == 0 then
            return { ok = false, error = "specify at least one knob: scanners / base_light_enabled / base_light_color / base_light_brightness / light_state" }
        end

        result.applied = applied
        result.base_light = {
            enabled = int:GetCustomBaseLightEnabled(),
            color = int:GetCustomBaseLightColor(),
            brightness = int:GetCustomBaseLightBrightness(),
        }
        return result
    end,
})

MCP:AddFunction({
    id = "tardis_chameleon",
    timeout = 18,
    description = "Change a TARDIS's exterior (chameleon shell) to a different appearance, wait for it to apply, then report. Pass `entindex` and either `exterior` (an id from tardis_list_exteriors) or `reset:true` (revert to the TARDIS's own default exterior). `animate` plays the change animation (adds the exterior's AnimTime delay); default is instant. Idempotent: if the TARDIS is already that exterior it reports took=true, changed=false without re-triggering. The change is vetoed (reported immediately via took=false + a `reason`, not a timeout) when the door is open, the TARDIS is unpowered, it's mid-teleport, or (with the artron_energy setting on) it lacks artron energy -- close the door / power up first. Returns the `chameleon` block {active, current, selected, changing}, took (the change reached the target), changed, and `reason` on a veto.",
    schema = {
        type = "object",
        properties = {
            entindex = { type = "number", description = "TARDIS exterior entindex." },
            exterior = { type = "string", description = "Exterior id (from tardis_list_exteriors) to change the shell to. Provide this or reset." },
            reset = { type = "boolean", description = "Revert to the TARDIS's own default exterior instead of setting `exterior`." },
            animate = { type = "boolean", description = "Play the chameleon change animation (adds the exterior's AnimTime delay). Default false = instant." },
        },
        required = { "entindex" },
    },
    requires = { "tardis_control" },
    handler = function(args, ctx)
        local ext, err = resolveTardis(args.entindex)
        if not ext then return { ok = false, error = err } end

        local target
        if args.reset == true then
            target = false
        elseif args.exterior ~= nil then
            if not isstring(args.exterior) or args.exterior == "" then
                return { ok = false, error = "`exterior` must be a non-empty exterior id (or use reset:true)" }
            end
            if not TARDIS:GetExteriors()[args.exterior] then
                return { ok = false, error = "unknown exterior id: " .. args.exterior .. " (see tardis_list_exteriors)" }
            end
            target = args.exterior
        else
            return { ok = false, error = "specify `exterior` (an id) or `reset` (revert to default)" }
        end

        local before = ext:GetData("chameleon_current_exterior", false)
        if before == target then
            -- Already that exterior; ChangeExterior would veto a same-set, so report without re-triggering.
            return { ok = true, entindex = ext:EntIndex(), took = true, changed = false, chameleon = chameleonInfo(ext) }
        end

        -- Report the veto reason immediately instead of timing out the settle (door open, no power,
        -- teleporting, not enough artron). CanChangeExterior returns (can_apply, select_failed, msg_key).
        local canApply, _, vetoMsg = ext:CallCommonHook("CanChangeExterior", target, false)
        if canApply == false then
            return {
                ok = true,
                entindex = ext:EntIndex(),
                took = false,
                changed = false,
                reason = vetoMsg and TARDIS:GetPhrase(vetoMsg) or "exterior change vetoed",
                chameleon = chameleonInfo(ext),
            }
        end

        ext:ChangeExterior(target, args.animate == true)

        MCP:Settle({
            seconds = 15,
            stable_for = 0,
            check = function()
                return IsValid(ext) and ext:GetData("chameleon_current_exterior", false) == target
            end,
        }, function(s)
            if not IsValid(ext) then
                ctx.respond({ ok = false, error = "TARDIS was removed during the exterior change" })
                return
            end
            ctx.respond({
                ok = true,
                entindex = ext:EntIndex(),
                took = s.settled,
                changed = s.settled,
                timed_out = not s.settled,
                seconds_elapsed = math.Round(s.elapsed, 3),
                chameleon = chameleonInfo(ext),
            })
        end)

        return ctx.deferred
    end,
})

MCP:AddFunction({
    id = "tardis_list_exteriors",
    description = "List exterior (chameleon shell) ids available to pass to tardis_chameleon, each with a display name and category.",
    schema = { type = "object", properties = {}, required = {} },
    handler = function()
        local exteriors = {}
        for id, meta in pairs(TARDIS:GetExteriors()) do
            if not (meta.Hidden or meta.Base == true) then
                exteriors[#exteriors + 1] = {
                    id = id,
                    name = meta.Name and TARDIS:GetPhrase(meta.Name) or id,
                    category = meta.Category and TARDIS:GetPhrase(meta.Category) or nil,
                }
            end
        end
        table.sort(exteriors, function(a, b) return a.id < b.id end)
        return { ok = true, exteriors = exteriors }
    end,
})
