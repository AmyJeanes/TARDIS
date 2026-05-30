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
        -- DoorPos now eases shut rather than snapping (see parts/door.lua), so a
        -- fast walk-away can cross portals-closedist before the close animation
        -- finishes. The old distance cutoff was only ever in sync with the door
        -- because the override hard-set DoorPos to 0 at the same instant; with
        -- easing it would kill the portal mid-animation, leaving a visibly-open
        -- door over dead space. While the walk-away override is managing the door
        -- (DoorOverride ~= nil) keep rendering regardless of distance; the
        -- DoorOpen(true) guard still cuts it the frame DoorPos reaches 0. Purely
        -- additive -- the occupant case keeps DoorOverride nil and is unchanged.
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