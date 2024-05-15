function ENT:GetShieldsMax()
    local ratio = TARDIS:GetSetting("health_to_shields_ratio")
    return math.max(1, (1 - ratio) * TARDIS:GetSetting("health_max"))
end

function ENT:GetShieldsLevel()
    return self:GetData("shields_val")
end

function ENT:GetShieldsPercent()
    local val = self:GetShieldsLevel()
    local percent = (val * 100)/self:GetShieldsMax()
    return percent
end

function ENT:GetShieldsOn()
    return self:GetData("shields_on")
end

function ENT:GetShields()
    if not self:GetShieldsOn() or self:GetShieldsLevel() <= 0 then
        return false
    end
    return self:GetShieldsLevel()
end

if SERVER then
    function ENT:SetShieldsLevel(value, force)
        if not self:GetShieldsOn() and not force then return end

        local MaxShields = self:GetShieldsMax()
        value = math.Clamp(value, 0 , MaxShields)
        if self:GetData("shields_val") > value then
            self:SetData("shields_last_hit", CurTime())
            self:SetData("shields_charge_start", nil)
            self:SetData("shields_charge_aim", nil)
        end
        self:SetData("shields_val", value, true)
    end

    function ENT:AddShieldsLevel(value, force)
        if not self:GetShieldsOn() and not force then return end

        local CurrentShields = self:GetData("shields_val", 0)
        self:SetShieldsLevel(CurrentShields + value, force)
    end

    ENT:AddHook("Initialize", "shields", function(self)
        local max = self:GetShieldsMax()
        self:SetData("shields_val", max, true)
        self:SetData("shields_on", true, true)
    end)

    function ENT:SetShieldsOn(on)
        if self:CallCommonHook("CanToggleShields", on) == false then
            return false
        end
        self:SetData("shields_on", on, true)
        self:CallCommonHook("ShieldsToggled", on)
        return true
    end

    function ENT:ToggleShields()
        return self:SetShieldsOn(not self:GetShieldsOn())
    end

    ENT:AddHook("Think", "shields", function(self)
        if self:CallCommonHook("ShouldRegenShields") == false then return end
        if CurTime() < self:GetData("shields_regen_time", 0) then return end

        local charge_aim = self:GetData("shields_charge_aim")

        if charge_aim and self:GetShieldsLevel() < charge_aim then
            local charge_start = self:GetData("shields_charge_start", CurTime())
            local progress = math.Clamp(0.1 * (CurTime() - charge_start), 0, 1)
            local value = self:GetShieldsMax() * progress

            self:SetShieldsLevel(value)
            return
        end

        if charge_aim then
            self:SetData("shields_charge_aim", nil)
            self:SetData("shields_charge_start", nil)
            self:SetData("shields_last_hit", CurTime())
            return
        end

        if CurTime() < self:GetData("shields_last_hit", 0) + 10 then return end

        self:SetData("shields_regen_time", CurTime() + 0.75)
        self:AddShieldsLevel(self:GetShieldsMax() * 0.01)
    end)

    ENT:AddHook("ShouldRegenShields", "shields", function(self)
        if not self:GetShieldsOn() then
            return false
        end
    end)

    ENT:AddHook("OnHealthDepleted", "shields", function(self)
        self:SetShieldsLevel(0,true)
    end)

    ENT:AddHook("PowerToggled", "shields", function(self, on)
        if on and self:GetData("power_last_shields", false) == true then
            self:SetShieldsOn(true)
        else
            self:SetData("power_last_shields", self:GetShieldsOn())
            self:SetShieldsOn(false)
        end
    end)

    ENT:AddHook("ShieldsToggled", "charge", function(self, on)
        if not on then return end

        local saved_value = self:GetData("shields_charge_aim") or self:GetShieldsLevel()
        self:SetShieldsLevel(0, true)
        self:SetData("shields_charge_aim", saved_value)
        self:SetData("shields_charge_start", CurTime())
    end)

    ENT:AddHook("ShouldThinkFast","shields_charge",function(self)
        if self:GetData("shields_charge_aim") then
            return true
        end
    end)

    ENT:AddHook("SettingChanged", "shields", function(self, id, val)
        if id == "health_to_shields_ratio" then
            self:ChangeHealth(self:GetHealth())
            self:SetShieldsLevel(self:GetShieldsLevel())
            return
        end
        if id == "health_max" then
            self:SetShieldsLevel(self:GetShieldsLevel())
        end
    end)

    ENT:AddHook("HandleE2", "shields", function(self, name, e2, ...)
        local args = {...}
        if name == "ToggleShield" and TARDIS:CheckPP(e2.player, self) then
            if self:ToggleShields() then
                return 1
            else
                return 0
            end
        elseif name == "SetShield" and TARDIS:CheckPP(e2.player, self) then
            if args[1] == 1 then
                if (not self:GetShieldsOn()) and self:SetShieldsOn(true) then
                    return 1
                end
            else
                if self:GetShieldsOn() and self:SetShieldsOn(false) then
                    return 1
                end
            end
            return 0
        elseif name == "GetShieldsOn" then
            if self:GetShieldsOn() then
                return 1
            else
                return 0
            end
        elseif name == "GetShieldsLevel" then
            return self:GetShieldsLevel()
        elseif name == "GetShieldsPercent" then
            return self:GetShieldsPercent()
        elseif name == "GetShieldMax" then
            return self:GetShieldsMax()
        end
    end)
end


