-- Portals

if SERVER then
    ENT:AddHook("ShouldTeleportPortal", "portals", function(self,portal,ent)
        if not self:DoorOpen() or (ent.TardisPart and not ent.AllowThroughPortals) then
            return false
        end
    end)
else
    ENT:AddHook("ShouldRenderPortal", "portals", function(self,portal,exit,origin)
        local dont,black = self:CallHook("ShouldNotRenderPortal",self,portal,exit,origin)
        if dont==nil then
            local other = self.interior
            if IsValid(other) then
                dont,black = other:CallHook("ShouldNotRenderPortal",self,portal,exit,origin)
            end
        end
        if dont then
            return false, black
        elseif (not (self.DoorOpen and self:DoorOpen(true) and origin:Distance(self:GetPos())<TARDIS:GetSetting("portals-closedist"))) then
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