-- Handles players inside the tardis interior

if SERVER then
    hook.Add("PlayerSpawn", "tardis-handleplayers", function(ply)
        local int=ply:GetTardisData("interior")
        if IsValid(int) and int.TardisInterior and ply == int:GetCreator() then
            local fallback=int.metadata.Interior.Fallback
            if fallback then
                ply:SetPos(int:LocalToWorld(fallback.pos))
                ply:SetEyeAngles(int:LocalToWorldAngles(fallback.ang))
            end
        end
    end)
else
    ENT:AddHook("ShouldDraw", "players", function(self)
        if ((not (LocalPlayer():GetTardisData("interior")==self)) or (LocalPlayer():GetTardisData("outside") and (self.props[self.exterior]==nil))) and not wp.drawing and not self.contains[LocalPlayer().door] then
            return false
        end
    end)
    ENT:AddHook("ShouldThink", "players", function(self)
        if not (LocalPlayer():GetTardisData("interior")==self) then
            return false
        end
    end)
    ENT:AddHook("ShouldDrawPlayer", "players", function(self, ply, localply)
        if localply:GetTardisData("outside") then
            return false
        end
    end)

    -- Predict tardis data clear on exit (mirror of the entry-side hook on
    -- gmod_tardis). Gated on the main interior portal so customportals
    -- and false-world windows don't drop the player out of the TARDIS.
    -- Server's TARDIS-PlayerDataClear broadcast still arrives shortly
    -- after and re-clears.
    ENT:AddHook("PostTeleportPortal", "predict-tardisdata", function(self, portal, ent)
        if ent ~= LocalPlayer() then return end
        if not (self.portals and portal == self.portals.interior) then return end
        ent:ClearTardisData()
        if TARDIS_PredictDebug then
            TARDIS_PredictDebug:Log("predict-tardisdata int clear",
                string.format("portal=%s", tostring(portal)))
        end
    end)
end

-- Exclude the interior door part from the stuck test on both realms, so Doors'
-- GetStuckTrace builds identical filter membership client- and server-side and
-- the predicted unstick lands in the same place. Shared (registered on both
-- realms); the part is networked, IsValid guards the brief pre-spawn window.
-- Returns a list, not a veto, so it must be the only StuckFilter consumer that
-- returns non-nil (CallHook short-circuits on the first non-nil result). The
-- server still appends this part to stuckfilter in parts/door.lua; a duplicate
-- in a trace filter is a harmless no-op.
ENT:AddHook("StuckFilter", "tardis-door", function(self)
    local door = self:GetPart("door")
    if IsValid(door) then return { door } end
end)
