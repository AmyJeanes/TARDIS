-- Teleport hooks

ENT:AddHook("CanTrack","teleport",function(self,state)
    if self:GetData("teleport") then
        return false
    end
end)

ENT:AddHook("IsTravelling", "teleport", function(self)
    if self:GetData("teleport") or self:GetData("vortex") then
        return true
    end
end)

if SERVER then
    ENT:AddHook("CanToggleDoor","teleport",function(self,state)
        if self:GetData("teleport") then
            return false
        end
    end)

    ENT:AddHook("ShouldThinkFast","teleport",function(self)
        if self:GetData("teleport") then
            return true
        end
    end)

    ENT:AddHook("CanPlayerEnter","teleport",function(self)
        if self:GetData("teleport") or self:GetData("vortex") then
            return false, true
        end
    end)

    ENT:AddHook("CanPlayerEnterDoor","teleport",function(self)
        if (self:GetData("teleport") or self:GetData("vortex")) then
            return false
        end
    end)

    ENT:AddHook("CanPlayerExit","teleport",function(self)
        if self:GetData("teleport") or self:GetData("vortex") then
            return false
        end
    end)

    ENT:AddHook("ShouldTurnOnRotorwash", "teleport", function(self)
        if self:GetData("teleport") then
            return true
        end
    end)

    ENT:AddHook("ShouldNotPlayLandingSound", "teleport", function(self)
        if self:GetData("teleport") then
            return true
        end
    end)

    ENT:AddHook("ShouldExteriorDoorCollide", "teleport", function(self,open)
        if self:GetData("teleport") or self:GetData("vortex") then
            return false
        end
    end)

    ENT:AddHook("CanRepair", "teleport", function(self, ignore_health)
        if self:GetData("teleport") or self:GetData("vortex") then
            return false
        end
    end)

    ENT:AddHook("CanChangeExterior","teleport",function(self)
        if self:GetData("demat") or self:GetData("vortex")
            or (self:GetData("mat") and self:GetData("step") > 1)
        then
            return false,false,"Chameleon.FailReasons.Teleporting",false
        end
    end)

    ENT:AddHook("ShouldDrawShadow", "teleport", function(self)
        if self:GetData("teleport") or self:GetData("vortex") then
            return false
        end
    end)

    ENT:AddHook("ShouldStopFire", "teleport", function(self)
        if self:GetData("teleport") or self:GetData("vortex") then
            return true
        end
    end)
else
    ENT:AddHook("ShouldTurnOnLight","teleport",function(self)
        if self:GetData("teleport") then
            return true
        end
    end)

    ENT:AddHook("ShouldPulseLight","teleport",function(self)
        if self:GetData("teleport") then
            return true
        end
    end)

    ENT:AddHook("ShouldTurnOffFlightSound", "teleport", function(self)
        if self:GetData("teleport") or (self:GetData("vortex") and (TARDIS:GetExteriorEnt() ~= self or self:GetFastRemat())) then
            return true
        end
    end)

    ENT:AddHook("PilotChanged","teleport",function(self,old,new)
        if self:GetData("teleport-trace") then
            self:SetData("teleport-trace",false)
        end
    end)
end

