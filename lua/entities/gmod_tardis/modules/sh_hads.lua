-- Hostile Action Displacement System

if SERVER then
    function ENT:GetHADS()
        return self:GetData("hads",false)
    end

    function ENT:SetHADS(on)
        self:CallCommonHook("HadsToggled", on)
        self:SetData("hads",on,true)
        return true
    end

    function ENT:ToggleHADS()
        local on = not self:GetHADS()
        return self:SetHADS(on)
    end

    function ENT:TriggerHADS()
        if self:CallHook("CanTriggerHads") == false then
            return false
        end
        if (self:GetHADS() == true
            and self:GetData("hads-triggered",false)==false)
            and (not self:GetData("teleport",false))
        then
            if self:GetData("doorstatereal") then
                self:ToggleDoor()
            end
            self:SetData("hads-attempt", true)
            if self:CallHook("CanDemat", true, true) == false then
                if not self:GetData("hads-failed-time") or CurTime() > self:GetData("hads-failed-time") + 10 then
                    self:SetData("hads-failed-time", CurTime())
                    TARDIS:ErrorMessage(self:GetCreator(), "HADS.DematError")
                    TARDIS:ErrorMessage(self:GetCreator(), "HADS.UnderAttack")
                end
                self:SetData("hads-attempt", nil)
                return false
            end
            self:SetData("hads-attempt", nil)
            TARDIS:Message(self:GetCreator(), "HADS.Triggered")
            TARDIS:Message(self:GetCreator(), "HADS.UnderAttack")
            self:SetData("hads-triggered", true, true)
            self:SetData("hads-demat", true, true)
            self:SetFastRemat(false)
            self:SetRandomDestination(true)
            self:AutoDemat()
            self:CallHook("HADSTrigger")
            self:SetData("hads-need-remat", true, true)
            self:Timer("HadsRematTime", math.random(10,25), function()
                if self:GetData("hads-need-remat", false) then
                    self:SetData("hads-auto-remat", true, true)
                    self:Mat(function(result)
                        if result then
                            TARDIS:Message(self:GetCreator(), "HADS.Mat")
                        end
                    end)
                end
            end)
            return true
        end
    end

    ENT:AddHook("OnTakeDamage", "hads", function(self)
        self:TriggerHADS()
    end)

    ENT:AddHook("HADSTrigger", "warning", function(self)
        self:UpdateWarning()
    end)

    ENT:AddHook("ShouldWarningBeEnabled","hads", function(self)
        if self:GetData("hads-triggered") then
            return true
        end
    end)

    ENT:AddHook("MatStart", "hads-cancel-remat", function(self)
        self:SetData("hads-need-remat", nil, true)
    end)

    ENT:AddHook("StopDemat","hads",function(self)
        if self:GetData("hads-triggered",false) then
            self:SetData("hads-triggered",false,true)
            self:UpdateWarning()
        end
    end)

    ENT:AddHook("StopMat", "hads", function(self)
        self:SetData("hads-auto-remat", nil, true)
    end)

    ENT:AddHook("ShouldStopSmoke", "hads", function(self)
        if self:GetData("hads-triggered") then return true end
    end)

    ENT:AddHook("InterruptTeleport", "hads-data", function(self)
        self:SetData("hads-triggered",false,true)
        self:SetData("hads-need-remat", nil, true)
        self:SetData("hads-auto-remat", nil, true)
    end)

    ENT:AddHook("ShouldUpdateArtron", "hads", function(self)
        if self:GetData("hads-triggered")
            or self:GetData("hads-need-remat")
            or self:GetData("hads-auto-remat")
        then
            return false
        end
    end)

    ENT:AddHook("HandleE2", "hads", function(self, name, e2, ...)
        local args = {...}
        if name == "GetHADS" then
            return self:GetHADS() and 1 or 0
        elseif name == "HADS" and TARDIS:CheckPP(e2.player, self) then
            return self:ToggleHADS() and 1 or 0
        elseif name == "SetHADS" and TARDIS:CheckPP(e2.player, self) then
            local on = args[1]
            local enabled = self:GetHADS()
            if on == 1 then
                if (not enabled) and self:SetHADS(true) then
                    return 1
                end
            else
                if enabled and self:SetHADS(false) then
                    return 1
                end
            end
            return 0
        end
    end)
end

ENT:AddHook("StopDemat","hads-demat",function(self)
    if self:GetData("hads-demat",false) then
        self:SetData("hads-demat", false, false) -- not networked
    end
end)