function ENT:GetWarning()
    return self:GetData("warning", false)
end

if SERVER then
    ENT:AddHook("Initialize","warning-init", function(self)
        self:SetData("warning", false, true)
    end)

    function ENT:ToggleWarning()
        return self:SetWarning(not self:GetWarning())
    end

    function ENT:SetWarning(on)
        self:SetData("warning", on, true)
        self:CallCommonHook("WarningToggled", on)
    end

    function ENT:UpdateWarning()
        if (self:CallCommonHook("ShouldWarningBeEnabled") == true) ~= self:GetWarning() then
            self:ToggleWarning()
        end
    end

    ENT:AddHook("OnHealthChange", "warning", function(self)
        self:UpdateWarning()
    end)

    ENT:AddHook("WarningToggled", "client", function(self, on)
        self:SendMessage("warning_toggled", {on})
    end)
else
    ENT:OnMessage("warning_toggled", function(self, data, ply)
        self:CallCommonHook("WarningToggled", data[1])
    end)
end

-- Support for old naming

ENT:AddHook("DataChanged", "warning", function(self, id, val)
    if id ~= "warning" then return end

    self:SetData("health-warning", val, true)
end)

ENT:AddHook("WarningToggled", "warning", function(self, on)
    self:CallCommonHook("HealthWarningToggled", on)
end)