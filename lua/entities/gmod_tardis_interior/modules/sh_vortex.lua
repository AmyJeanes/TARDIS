-- Vortex

ENT:AddHook("ShouldTracePortal", "vortex", function(self,portal)
    if self:GetData("vortex",false) and portal==self.portals.interior then
        return false
    end
end)

ENT:AddHook("ShouldTeleportPortal", "vortex", function(self,portal)
    if self:GetData("vortex",false) and portal==self.portals.interior then
        return false
    end
end)

if CLIENT then
    ENT:AddHook("ShouldTurnOffFlightSound", "vortex", function(self)
        if self:GetData("vortex",false) and self.exterior:GetFastRemat() then
            return true
        end
    end)
end