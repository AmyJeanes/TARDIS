-- Handles portals for rendering, thanks to bliptec (http://facepunch.com/member.php?u=238641) for being a babe

-- Shared so world-portals' predicted player teleport can also veto.
ENT:AddHook("ShouldTeleportPortal", "portals", function(self,portal,ent)
    if (not self.exterior:DoorOpen() and portal==self.portals.interior) or (ent.TardisPart and not ent.AllowThroughPortals) then
        return false
    end
    if portal:GetCustomLink() then
        local part = self:GetPart(portal:GetCustomLink())
        if IsValid(part) and part:GetOn()==false then
            return false
        end
    end
end)

if CLIENT then
    ---@param portal linked_portal_door
    ---@param exit linked_portal_door
    ---@param origin Vector
    ENT:AddHook("ShouldRenderPortal", "portals", function(self,portal,exit,origin)
        local dont,black = self:CallHook("ShouldNotRenderPortal",self,portal,exit,origin)
        if dont==nil then
            local other = self.exterior
            if IsValid(other) then
                dont,black = other:CallHook("ShouldNotRenderPortal",self,portal,exit,origin)
            end
        end
        if dont then
            return false, black
        elseif LocalPlayer():GetTardisData("outside") and wp.renderparent ~= self.portals.exterior then
            -- Don't show the interior portals if the player's view is outside e.g. piloting
            return false
        elseif (not (self.DoorOpen and self:DoorOpen(false))) and portal==self.portals.interior then
            -- Don't show the main interior portal (door) if the door is closed
            return false
        elseif (not TARDIS:GetSetting("portals-enabled")) then
            -- Don't show any portals if they are disabled, show black instead on the main interior
            -- portal or any portals opted in to be shown as black when disabled
            return false, self.portals.interior==portal or portal.black
        end
    end)

    ENT:AddHook("ShouldNotRenderPortal", "portals", function(self,parent,portal,exit)
        if portal:GetCustomLink() then
            local part = self:GetPart(portal:GetCustomLink())
            if IsValid(part) and ((part.Animate and part.animation and part.animation.pos==0) or ((not part.Animate) and part:GetOn()==false)) then
                -- Don't render part-linked custom portals if the part is not active. This is usually
                -- a physical door opening, so the portals save on performance when the door is closed.
                return true
            end
        end
    end)

    -- Smoothly closes door (if open) as player reaches render limit
    ENT:AddHook("Think", "portals", function(self)
        local ext=self.exterior
        if not IsValid(ext) then return end

        -- Skip the distance auto-close (keep the door open) when closing would be wrong: the
        -- door is already shut; the player is inside us at any depth; or our exterior is parked
        -- in another interior the player isn't in - out there the world distance to it is
        -- meaningless and it only renders nested through that interior's portal, so closing it
        -- here just blanks us when someone looks in. We still distance-close from its own space.
        local container = ext.insideof
        if not ext:GetData("doorstate",false)
            or self:LocalPlayerInside()
            or (IsValid(container) and not container:LocalPlayerInside()) then
            if ext.DoorOverride~=nil then ext.DoorOverride=nil end
            return
        end

        local dist=GetViewEntity():GetPos():Distance(ext:GetPos())
        local closedist=TARDIS:GetSetting("portals-closedist")
        local length=250
        local startdist=closedist-length
        if dist>=startdist and dist<=closedist then
            ext.DoorOverride=1-(dist-startdist)/length
        elseif dist>closedist and ext.DoorOverride~=0 then
            ext.DoorOverride=0
        elseif dist<startdist and ext.DoorOverride~=nil then
            ext.DoorOverride=nil
        end
    end)
end

ENT:AddHook("ShouldTracePortal", "portals", function(self,portal)
    if (not self.exterior:DoorOpen()) and portal==self.portals.interior then
        return false
    end
    if portal:GetCustomLink() then
        local part = self:GetPart(portal:GetCustomLink())
        if IsValid(part) and part:GetOn()==false then
            return false
        end
    end
end)

ENT:AddHook("TraceFilterPortal", "portals", function(self,portal)
    if portal==self.portals.interior then
        return self.exterior:GetPart("door")
    end
    if portal:GetCustomLink() then
        return self:GetPart(portal:GetCustomLink())
    end
end)

-- The solids a prop transiting our portal may phase through, fed to world-portals' pass-
-- through no-collide so a big prop doesn't jam crossing the doorway. It's opt-in: anything
-- left off stays solid (a missed one just jams the prop, never voids it), so we list only
-- what should give way - the interior model where metadata opts in (Interior.PortalNoCollide,
-- off by default so you can still stand on the floor), plus any parts flagged PortalNoCollide.
ENT:AddHook("NoCollidePortal", "parts", function(self)
    local list = {}
    if self.metadata.Interior.PortalNoCollide == true and IsValid(self:GetPhysicsObject()) then
        list[#list+1] = self
    end
    for _, part in pairs(self:GetParts() or {}) do
        if IsValid(part) and part.PortalNoCollide then list[#list+1] = part end
    end
    return list
end)