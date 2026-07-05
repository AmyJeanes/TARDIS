-- Notification messages

if SERVER then
    util.AddNetworkString("tardis_message")
else
    net.Receive("tardis_message", function()
        local error = net.ReadBool()
        local message = net.ReadString()
        local args = net.ReadTable()
        TARDIS:MessageInternal(LocalPlayer(), error, message, unpack(args))
    end)
end

function TARDIS:MessageInternal(ply, error, message, ...)
    if not IsValid(ply) then return end

    if SERVER then
        net.Start("tardis_message")
            net.WriteBool(error)
            net.WriteString(message)
            local args = {...}
            net.WriteTable(args)
        net.Send(ply)
        return
    end
    local style = self:GetSetting("notification_type", ply)

    local prefix = "[" .. TARDIS:GetPhrase("Common.TARDIS") .. "] "
    local err = error and TARDIS:GetPhrase("Common.Error") .. ": " or ""
    local translatedMessage = TARDIS:GetPhrase(message, ...)

    if style == 0 then
        return
    end
    if style == 1 then
        print(prefix .. err .. translatedMessage)
        return
    end
    if style == 2 then
        LocalPlayer():ChatPrint(prefix .. err .. translatedMessage)
        return
    end
    if style == 3 then
        local notifyType
        if error then
            notifyType = NOTIFY_ERROR
        else
            notifyType = NOTIFY_GENERIC
        end
        notification.AddLegacy(prefix .. translatedMessage, notifyType, 5)
        print(prefix .. err .. translatedMessage)
        return
    end
end

---@api
---@param ply Player
---@param message string
function TARDIS:Message(ply, message, ...)
    return TARDIS:MessageInternal(ply, false, message, ...)
end

---@api
---@param ply Player
---@param message string
function TARDIS:ErrorMessage(ply, message, ...)
    return TARDIS:MessageInternal(ply, true, message, ...)
end

---@api
---@param ply Player
---@param name string
---@param condition boolean
---@param enabled_msg? string
---@param disabled_msg? string
function TARDIS:StatusMessage(ply, name, condition, enabled_msg, disabled_msg)
    if not enabled_msg then enabled_msg = "Common.Enabled.Lower" end
    if not disabled_msg then disabled_msg = "Common.Disabled.Lower" end
    TARDIS:Message(ply, "%s %s", name, (condition and enabled_msg or disabled_msg))
end