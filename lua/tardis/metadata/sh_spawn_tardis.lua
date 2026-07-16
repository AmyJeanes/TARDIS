if SERVER then
    util.AddNetworkString("TARDIS-Spawn-Delete-Sound")

    ---@param entity gmod_tardis
    function TARDIS:SetupRandomSkin(entity)
        if not TARDIS:GetSetting("randomize_skins", entity) then return end

        local total_skins = entity:SkinCount()
        if total_skins <= 0 then return end

        local chosen_skin = math.random(total_skins)
        local excluded = entity.metadata.Exterior.ExcludedSkins
        local winter = entity.metadata.Exterior.WinterSkins
        local winter_ok = TARDIS:GetSetting("winter_skins", entity)

        ---@param skin integer
        local function cannot_use_skin(skin)
            local is_excluded = table.HasValue(excluded, skin)
            return is_excluded or (not winter_ok and winter and table.HasValue(winter, skin) )
        end

        if excluded then
            local attempts = 1
            while cannot_use_skin(chosen_skin) and attempts < 30 do
                chosen_skin = math.random(total_skins)
                attempts = attempts + 1
            end
        end
        if not excluded or not table.HasValue(excluded, chosen_skin) then
            entity:SetSkin(chosen_skin)
            entity:SetData("intdoor_skin_needs_update", true, true)
        end
    end

    ---@api
    ---@param ply Player
    ---@param customData table
    ---@param force boolean?
    ---@return gmod_tardis?
    function TARDIS:SpawnTARDIS(ply, customData, force)
        local entityName = "gmod_tardis"

        local metadataID = customData.metadataID
        local interior = TARDIS:GetInterior(metadataID)

        if not (interior and IsValid(ply) and (force or gamemode.Call("PlayerSpawnSENT", ply, entityName))) then return end

        local vStart = ply:EyePos()
        local vForward = ply:GetAimVector()

        local tr
        if not customData.pos then
            local trace = {}
            trace.start = vStart
            trace.endpos = vStart + (vForward * 4096)
            trace.filter = ply

            -- Realm-mismatch heuristic false positive: util.TraceLine is shared and we are inside if SERVER then.
            ---@diagnostic disable-next-line: gmod-realm-mismatch-heuristic
            tr = util.TraceLine(trace)
        end

        local sent = scripted_ents.GetStored(entityName).t
        ClassName = entityName
        local SpawnFunction = scripted_ents.GetMember(entityName, "SpawnFunction")
        if not SpawnFunction then
            return
        end
        local entity = SpawnFunction(sent, ply, tr, entityName, customData)

        if IsValid(entity) and IsValid(ply) then
            entity:SetCreator(ply)
        end

        ClassName = nil

        if not IsValid(entity) then return end

        local printName = TARDIS:GetTARDISName(entity.metadata)

        if IsValid(ply) then
            gamemode.Call("PlayerSpawnedSENT", ply, entity)
        end

        undo.Create("SENT")
        undo.SetPlayer(ply)
        undo.AddEntity(entity)
        if customData.redecorate_parent then
            undo.AddEntity(customData.redecorate_parent)
        end
        undo.SetCustomUndoText("Undone " .. printName)
        undo.AddFunction(function()
            if not IsValid(entity) then return false end
            net.Start("TARDIS-Spawn-Delete-Sound")
                net.WriteBool(false)
                net.WriteVector(entity:GetPos())
                net.WriteString(entity.metadata.Exterior.Sounds.Delete or "")
            net.Broadcast()
        end)
        undo.Finish(printName)

        if not customData.redecorate_parent then
            net.Start("TARDIS-Spawn-Delete-Sound")
                net.WriteBool(true)
                net.WriteEntity(entity)
                net.WriteVector(entity:GetPos())
                net.WriteString(entity.metadata.Exterior.Sounds.Spawn or "")
            net.Broadcast()
        end

        ply:AddCleanup("sents", entity)
        entity:SetVar("Player", ply)

        TARDIS:SetupRandomSkin(entity)

        return entity
    end
    concommand.Add("tardis2_spawn", function(ply, cmd, args)
        TARDIS:SpawnTARDIS(ply, {metadataID = args[1]})
    end)
else -- CLIENT

    -- Dynamic read/write counts not handled by analyzer.
    ---@diagnostic disable-next-line: gmod-net-read-write-order-mismatch
    net.Receive("TARDIS-Spawn-Delete-Sound", function()
        local ent
        local pos
        local spawn = net.ReadBool()
        if spawn then
            ent = net.ReadEntity()
            pos = net.ReadVector()
        else
            pos = net.ReadVector()
        end

        local snd = net.ReadString()
        if snd == "" then return end
        if not (TARDIS:GetSetting("spawn_delete_sound") and TARDIS:GetSetting("sound")) then return end

        if spawn and IsValid(ent) then
            TARDIS:PlayManagedSound({ path = snd, owner = ent, tag = "spawn", ent = ent })
        else
            sound.Play(snd, pos)
        end
    end)
end
