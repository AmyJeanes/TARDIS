-- Handbrake

function ENT:GetHandbrake()
    return self:GetData("handbrake", false)
end

if SERVER then
    ENT:AddHook("Initialize","handbrake-init", function(self)
        self:SetData("handbrake", false, true)
    end)

    function ENT:ToggleHandbrake()
        return self:SetHandbrake(not self:GetHandbrake())
    end

    function ENT:SetHandbrake(on)
        if self:CallCommonHook("CanToggleHandbrake") == false then
            return false
        end
        self:SetData("handbrake", on, true)
        self:CallCommonHook("HandbrakeToggled", on)
        self:SendMessage("handbrake_toggled", {on})
        return true
    end

    ENT:AddHook("ShouldFailDemat", "handbrake", function(self, force)
        if self:GetHandbrake() and force ~= true then
            return true
        end
    end)

    ENT:AddHook("HandbrakeToggled", "vortex", function(self, on)
        if not on then return end

        if self:GetData("teleport") or self:GetData("vortex") then
            self:InterruptTeleport()
        else
            self:InterruptFlight()
        end
    end)

    ENT:AddHook("CanTurnOnFlight", "handbrake", function(self)
        if self:GetHandbrake() then
            return false
        end
    end)

    ENT:AddHook("HandleE2", "handbrake", function(self, name, e2, ...)
        local args = {...}
        if name == "SetBrake" and TARDIS:CheckPP(e2.player, self) then
            local on = args[1]
            local handbrake = self:GetHandbrake()
            if on == 1 then
                if (not handbrake) and self:SetHandbrake(true) then
                    return 1
                end
            else
                if handbrake and self:SetHandbrake(false) then
                    return 1
                end
            end
            return 0
        elseif name == "ToggleBrake" and TARDIS:CheckPP(e2.player, self) then
            return self:ToggleHandbrake() and 1 or 0
        elseif name == "GetBrake" then
            return self:GetHandbrake() and 1 or 0
        end
    end)
else
    ENT:OnMessage("handbrake_toggled", function(self, data, ply)
        local on = data[1]
        self:CallCommonHook("HandbrakeToggled", on)
    end)
end