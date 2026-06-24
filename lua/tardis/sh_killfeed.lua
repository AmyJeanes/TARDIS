if SERVER then
    -- Routes a TARDIS kill to a interior/exterior specific kill feed icon and interior name:
    --   materials/killfeed/tardis/interiors/<interior_id>.vmt  (native skin)
    --   materials/killfeed/tardis/exteriors/<exterior_id>.vmt  (chameleon-applied exterior)
    local function resolve(inflictor)
        if not IsValid(inflictor) then return end
        ---@cast inflictor gmod_tardis
        if not inflictor.TardisExterior then return end

        local ext = inflictor:GetData("chameleon_current_exterior")
        local id = ext or inflictor.metadataID
        local mat = "killfeed/tardis/" .. (ext and "exteriors/" or "interiors/") .. string.lower(id)
        local icon = file.Exists("materials/" .. mat .. ".vmt", "GAME") and mat or nil

        return icon, TARDIS:GetTARDISName(inflictor.metadata)
    end

    local pendingicon, pendingname

    hook.Add("PlayerDeath", "TARDIS_killfeed", function(_, inflictor)
        pendingicon, pendingname = resolve(inflictor)
    end)

    hook.Add("OnNPCKilled", "TARDIS_killfeed", function(_, _, inflictor)
        pendingicon, pendingname = resolve(inflictor)
    end)

    local patched = false
    local function installdetour()
        if patched then return end
        if not GAMEMODE or not isfunction(GAMEMODE.SendDeathNotice) then return end
        patched = true

        local base = GAMEMODE.SendDeathNotice
        function GAMEMODE:SendDeathNotice(attacker, inflictor, victim, flags)
            if inflictor == "gmod_tardis" then
                if pendingicon then inflictor = pendingicon end
                if pendingname and attacker == "#gmod_tardis" then attacker = pendingname end
            end
            pendingicon, pendingname = nil, nil
            return base(self, attacker, inflictor, victim, flags)
        end
    end

    hook.Add("Initialize", "TARDIS_killfeed", installdetour)
    installdetour()
else
    killicon.Add("gmod_tardis", "killfeed/gmod_tardis", Color(255,255,255,255))
    language.Add("gmod_tardis", "TARDIS")

    for _, sub in ipairs({ "interiors", "exteriors" }) do
        for _, f in ipairs(file.Find("materials/killfeed/tardis/" .. sub .. "/*.vmt", "GAME")) do
            local mat = "killfeed/tardis/" .. sub .. "/" .. string.StripExtension(f)
            killicon.Add(string.lower(mat), mat, Color(255,255,255,255))
        end
    end
end
