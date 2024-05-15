-- Interior

ENT:AddHook("Use", "interior", function(self,a,c)
    if a:KeyDown(IN_WALK) or not IsValid(self.interior) or self:GetData("legacy_door_type") then
        if self:CallHook("CanPlayerEnterDoor")~=false then
            self:PlayerEnter(a)
        end
    else
        self:ToggleDoor()
    end
end)


ENT:AddHook("FindingPosition", "interior", function(self,e,ply)
    TARDIS:Message(ply, "Interior.FindingPosition")
    return true
end)

ENT:AddHook("FindingPositionFailed", "interior", function(self,e,ply,err)
    if err then
        TARDIS:ErrorMessage(ply, "Interior.FindingPositionFailed.Generic", err)
    else
        TARDIS:Message(ply, "Interior.FindingPositionFailed.NoSpace")
    end
    return true
end)

ENT:AddHook("FoundPosition", "interior", function(self,e,ply)
    TARDIS:Message(ply, "Interior.FoundPosition")
    return true
end)

ENT:AddHook("ShouldSpawnInterior", "interior", function(self)
    if TARDIS:GetSetting("nointerior", self) then
        return false
    end
end)

ENT:AddHook("OnRemove", "interior", function(self)
    if IsValid(self.interior) then
        self.interior.exterior_deleted = true
    end
end)