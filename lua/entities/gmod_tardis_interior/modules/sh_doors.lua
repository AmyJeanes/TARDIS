-- Door

ENT:AddHook("PartBodygroupChanged", "doors", function(self, part, bodygroup, value)
    if not self.metadata.SyncDoorBodygroups then return end
    if self.exterior:IsChameleonActive() then return end

    if not IsValid(part) or part ~= self:GetPart("door") then return end
    if not IsValid(self.exterior) then return end
    local door_ext = self.exterior:GetPart("door")
    if not IsValid(door_ext) then return end

    if door_ext:GetBodygroup(bodygroup) ~= value then
        door_ext:SetBodygroup(bodygroup, value)
    end
end)

if SERVER then return end

function ENT:DoorOpen(...)
    return self.exterior:DoorOpen(...)
end


--
-- Classic doors support
--

ENT:AddHook("ShouldDrawPart", "classic_doors_intdoor", function(self, part)
    if self.metadata.EnableClassicDoors == true and part ~= nil
        and wp.drawing and wp.drawingent == self.portals.exterior
        and part == TARDIS:GetPart(self, "intdoor")
    then
        return false
    end
end)

ENT:AddHook("ShouldDrawPart", "classic_doors_door_mirror", function(self, part)
    if self.metadata.EnableClassicDoors == true and part ~= nil
        and part == TARDIS:GetPart(self, "door")
        and not (wp.drawing and wp.drawingent == self.portals.exterior)
    then
        return false
    end
end)

ENT:AddHook("ShouldDrawPart", "chameleon", function(self, part)
    if self:GetData("chameleon_active", false) and part ~= nil
        and wp.drawing and wp.drawingent == self.portals.exterior
        and part == TARDIS:GetPart(self, "door")
    then
        return false
    end
end)