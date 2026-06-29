-- Handles players inside the tardis interior

if SERVER then
    hook.Add("PlayerSpawn", "tardis-handleplayers", function(ply)
        local int=ply:GetTardisInterior()
        if IsValid(int) and ply == int:GetCreator() then
            local fallback=int.metadata.Interior.Fallback
            if fallback then
                ply:SetPos(int:LocalToWorld(fallback.pos))
                ply:SetEyeAngles(int:LocalToWorldAngles(fallback.ang))
            end
        end
    end)
else
    ENT:AddHook("ShouldDraw", "players", function(self)
        -- Doors' base ShouldDraw already hides us when the player is outside us (at any
        -- depth). The case left to us: inside but in TARDIS' outside-door view - hide our
        -- interior so the doorway shows the world, unless our exterior is cordoned as a prop.
        if wp.drawing then return end
        if LocalPlayer():GetTardisInterior() == self and LocalPlayer():GetTardisData("outside") and self.props[self.exterior] == nil then
            return false
        end
    end)
    
    ENT:AddHook("ShouldDrawPlayer", "players", function(self, ply, localply)
        if localply:GetTardisData("outside") then
            return false
        end
    end)

    ENT:AddHook("ShouldDrawCordonProp", "outside", function(self, prop, localply)
        if localply:GetTardisData("outside") then
            return false
        end
    end)

    -- Predict tardis-data clear on exit (mirror of the entry-side hook on
    -- gmod_tardis). Gated on the main interior portal so customportals and
    -- false-world windows don't drop the player out; the server's
    -- TARDIS-PlayerDataClear broadcast re-clears shortly after.
    ENT:AddHook("PostTeleportPortal", "predict-tardisdata", function(self, portal, ent)
        if ent ~= LocalPlayer() then return end
        if not (self.portals and portal == self.portals.interior) then return end
        -- Self-nested (our exterior parked inside us): crossing the interior door keeps
        -- us inside, so keep our tardis-data. Clearing it desyncs from the server (which
        -- never exits us) and trips ShouldThink/"in the TARDIS" checks. Mirrors the Doors
        -- predict handler's ExteriorIsNested early-return.
        if self:ExteriorIsNested() then return end
        ent:ClearTardisData()
        -- If we emerged inside another TARDIS interior (a TARDIS parked in another's
        -- interior), predict entering it. The interior's ShouldDraw keys off
        -- GetTardisData("interior"), so without this it stays hidden until the server's
        -- TARDIS-PlayerData broadcast, which loses the race to the clear above.
        for k in pairs(Doors:GetInteriors()) do
            if k ~= self and IsValid(k) and k.TardisInterior and IsValid(k.exterior)
                and k:PositionInside(ent:GetPos()) then
                ent:SetTardisData("exterior", k.exterior)
                ent:SetTardisData("interior", k)
                break
            end
        end
    end)
end

-- Exclude the interior door part from Doors' stuck trace - a player landing in the
-- doorway shouldn't read as stuck against it. Shared so server and predicting client
-- build the same filter (the predicted unstick must land identically). A list, not a
-- veto, so it must be the only StuckFilter consumer returning non-nil (CallHook stops first).
ENT:AddHook("StuckFilter", "tardis-door", function(self)
    local door = self:GetPart("door")
    if IsValid(door) then return { door } end
end)
