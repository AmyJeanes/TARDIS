include('shared.lua')

ENT:AddHook("PlayerInitialize", "interior", function(self)
    local id = net.ReadString()
    if net.ReadBool() then
        self.templates = TARDIS.von.deserialize(net.ReadString())
        if self.interior then
            self.interior.templates = self.templates
        end
    end

    self.metadata=TARDIS:CreateInteriorMetadata(id, self)

    -- The predicted unstick reads self.Fallback on the client (set server-side in init.lua).
    if self.metadata and self.metadata.Exterior then
        self.Fallback = self.metadata.Exterior.Fallback
    end
end)

---@return number
function ENT:GetDoorOpenness()
    local door = self:GetPart("door")
    if IsValid(door) and door.DoorPos then
        return math.Clamp(door.DoorPos, 0, 1)
    end
    return self:DoorOpen(true) and 1 or 0
end

-- Default for how much sound goes through the doors, will be configurable per interior in a later change
local CROSS_BOUNDARY_VOLUME = 0.5

---@return number
function ENT:GetCrossBoundaryVolume()
    if not TARDIS:GetSetting("sound_through_doors") then return 0 end
    return CROSS_BOUNDARY_VOLUME
end
