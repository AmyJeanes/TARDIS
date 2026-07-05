---@api
function ENT:GetConsoleEnabled()
    return self:GetData("console_on", true)
end

---@api
function ENT:GetHandbrakeControlEnabled()
    return self:GetData("handbrake_control_on", true)
end

---@api
function ENT:GetTeleportControlEnabled()
    return self:GetData("teleport_control_on", true)
end

if SERVER then
    ---@api
    ---@param on boolean
    ---@return boolean
    function ENT:SetConsoleEnabled(on)
        self:CallHook("ConsoleToggled", on)
        return self:SetData("console_on", on, true)
    end

    ---@api
    ---@param on boolean
    ---@return boolean
    function ENT:SetHandbrakeControlEnabled(on)
        self:CallHook("HandbrakeControlToggled", on)
        return self:SetData("handbrake_control_on", on, true)
    end

    ---@api
    ---@param on boolean
    ---@return boolean
    function ENT:SetTeleportControlEnabled(on)
        self:CallHook("TeleportControlToggled", on)
        return self:SetData("teleport_control_on", on, true)
    end

    ---@api
    ---@return boolean
    function ENT:ToggleConsole()
        return self:SetConsoleEnabled(not self:GetConsoleEnabled())
    end

    ---@api
    ---@return boolean
    function ENT:ToggleHandbrakeControl()
        return self:SetHandbrakeControlEnabled(not self:GetHandbrakeControlEnabled())
    end

    ---@api
    ---@return boolean
    function ENT:ToggleTeleportControl()
        return self:SetTeleportControlEnabled(not self:GetTeleportControlEnabled())
    end

    ENT:AddHook("Initialize", "console_on", function(self)
        self:SetData("console_on", true, true)
        self:SetData("handbrake_control_on", true, true)
        self:SetData("teleport_control_on", true, true)
    end)

end

ENT:AddHook("CanUseTardisControl", "console_on", function(self, control, ply, part)
    if not self:GetConsoleEnabled() and IsValid(part) and not control.bypass_console_toggle then
        return false
    end
end)

ENT:AddHook("CanUseTardisControl", "handbrake_control_on", function(self, control, ply, part)
    if not self:GetTeleportControlEnabled() and IsValid(part) and (control.id == "teleport" or control.id == "teleport_double") then
        return false
    end
end)

ENT:AddHook("CanUseTardisControl", "teleport_control_on", function(self, control, ply, part)
    if not self:GetHandbrakeControlEnabled() and IsValid(part) and control.id == "handbrake" then
        return false
    end
end)
