-- Handles portals for rendering, thanks to bliptec (http://facepunch.com/member.php?u=238641) for being a babe

-- Shared so world-portals' predicted player teleport can also veto.
-- DoorOpen, GetCustomLink, GetPart, GetOn all read networked state.
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
        elseif (not (self.DoorOpen and self:DoorOpen(false))) and portal==self.portals.interior then
            return false
        elseif (not TARDIS:GetSetting("portals-enabled")) then
            return false, self.portals.interior==portal or portal.black
        end
    end)

    ENT:AddHook("ShouldNotRenderPortal", "portals", function(self,parent,portal,exit)
        if portal:GetCustomLink() then
            local part = self:GetPart(portal:GetCustomLink())
            if IsValid(part) and ((part.Animate and part.animation and part.animation.pos==0) or ((not part.Animate) and part:GetOn()==false)) then
                return true
            end
        end
    end)

    -- Smoothly closes door (if open) as player reaches render limit
    ENT:AddHook("Think", "portals", function(self)
        local ext=self.exterior
        if IsValid(ext) then
            if ext:GetData("doorstate",false) then
                local dist=GetViewEntity():GetPos():Distance(ext:GetPos())
                local closedist=TARDIS:GetSetting("portals-closedist")
                local length=250
                local startdist=closedist-length
                if dist>=startdist and dist<=closedist then
                    ext.DoorOverride=1-(dist-startdist)/length
                elseif dist>closedist and ext.DoorOverride~=0 and (not IsValid(LocalPlayer():GetTardisData("exterior"))) then
                    ext.DoorOverride=0
                elseif dist<startdist and ext.DoorOverride~=nil then
                    ext.DoorOverride=nil
                end
            elseif ext.DoorOverride then
                ext.DoorOverride = nil
            end
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