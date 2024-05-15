-- Power Exterior

TARDIS:AddKeyBind("power",{
    name="TogglePower",
    section="ThirdPerson",
    func=function(self,down,ply)
        if down and ply == self.pilot then
            TARDIS:Control("power", ply)
        end
    end,
    key=KEY_P,
    serveronly=true,
    exterior=true
})

ENT:AddHook("Initialize","power-init", function(self)
    if SERVER and self:GetData("power-state") == false then
        self:SetData("power_disabled_first", true)
    end
    self:SetData("power-state",true,true)
end)

function ENT:GetPower()
    return self:GetData("power-state", false)
end

ENT:AddHook("CanUseTardisControl", "power", function(self, control, ply)
    if not self:GetPower() and not control.power_independent then
        TARDIS:ErrorMessage(ply, "Common.PowerDisabledControl")
        return false
    end
end)

if SERVER then
    function ENT:TogglePower()
        return self:SetPower(not self:GetPower())
    end
    function ENT:SetPower(on)
        if (self:CallCommonHook("CanTogglePower", on) == false) then return false end
        self:SetData("power-state",on,true)
        self:CallCommonHook("PowerToggled", on)
        self:SendMessage("power_toggled", {on})
        return true
    end

    ENT:AddHook("PostInitialize","power-init", function(self)
        if self:GetData("power_disabled_first") then
            self:SetPower(false)
        end
    end)

    ENT:AddHook("CanTogglePower", "vortex", function(self, on)
        if self:GetData("teleport") or self:GetData("vortex") then
            return false
        end
    end)

    ENT:AddHook("CanTriggerHads","power",function(self)
        if not self:GetPower() then return false end
    end)

    ENT:AddHook("CanToggleShields", "power", function(self, on)
        if on and not self:GetPower() then return false end
    end)

    ENT:AddHook("CanChangeExterior","power",function(self)
        if not self:GetPower() then
            return false,true,"Chameleon.FailReasons.NoPower",true
        end
    end)

    ENT:AddHook("HandleE2", "power", function(self, name, e2, ...)
        local args = {...}
        if name == "Power" and TARDIS:CheckPP(e2.player, self) then
            return self:TogglePower() and 1 or 0
        elseif name == "GetPowered" then
            return self:GetPower() and 1 or 0
        elseif name == "SetPower" and TARDIS:CheckPP(e2.player, self) then
            local on = args[1]
            local power = self:GetPower()
            if on == 1 then
                if (not power) and self:SetPower(true) then
                    return 1
                end
            else
                if power and self:SetPower(false) then
                    return 1
                end
            end
            return 0
        end
    end)

    ENT:AddHook("ShouldRegenShields", "power", function(self)
        if not self:GetPower() then
            return false
        end
    end)

else
    ENT:AddHook("ShouldNotDrawProjectedLight", "power", function(self)
        if not self:GetPower() then return true end
    end)

    ENT:AddHook("ShouldTurnOffLight", "power", function(self)
        if not self:GetPower() then return true end
    end)

    ENT:OnMessage("power_toggled", function(self, data, ply)
        local on = data[1]
        self:CallCommonHook("PowerToggled", on)
    end)
end