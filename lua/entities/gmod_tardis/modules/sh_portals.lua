-- Portals

-- Shared so world-portals' predicted player teleport can also veto.
-- DoorOpen() is networked; the TardisPart check is structural.
ENT:AddHook("ShouldTeleportPortal", "portals", function(self,portal,ent)
    if not self:DoorOpen() or (ent.TardisPart and not ent.AllowThroughPortals) then
        return false
    end
end)

if CLIENT then
    ENT:AddHook("ShouldRenderPortal", "portals", function(self,portal,exit,origin)
        local dont,black = self:CallHook("ShouldNotRenderPortal",self,portal,exit,origin)
        if dont==nil then
            local other = self.interior
            if IsValid(other) then
                dont,black = other:CallHook("ShouldNotRenderPortal",self,portal,exit,origin)
            end
        end
        local insidePortalView = wp.IsRenderingPortalView()
        if dont then
            return false, black
        elseif (not (self.DoorOpen and self:DoorOpen(true) and (insidePortalView or origin:Distance(self:GetPos())<TARDIS:GetSetting("portals-closedist") or self.DoorOverride~=nil))) then
            return false
        elseif (not TARDIS:GetSetting("portals-enabled")) then
            return false, true
        end
    end)
end

ENT:AddHook("ShouldTracePortal", "portals", function(self,portal)
    if not self:DoorOpen() then
        return false
    end
end)

ENT:AddHook("TraceFilterPortal", "portals", function(self,portal)
    if IsValid(self.interior) and portal == self.interior.portals.exterior then
        return self.interior:GetPart("door")
    end
end)

ENT:AddHook("ShouldVortexIgnoreZ", "portals", function(self)
    if IsValid(self.interior) and wp.drawingent==self.interior.portals.interior then
        return true
    end
end)

-- The solids a transiting prop may phase: the exterior shell itself unless metadata
-- opts it out (Exterior.PortalNoCollide=false), plus any parts flagged PortalNoCollide.
ENT:AddHook("NoCollidePortal", "parts", function(self)
    local list = {}
    if self.metadata.Exterior.PortalNoCollide ~= false and IsValid(self:GetPhysicsObject()) then
        list[#list+1] = self
    end
    for _, part in pairs(self:GetParts() or {}) do
        if IsValid(part) and part.PortalNoCollide then list[#list+1] = part end
    end
    return list
end)