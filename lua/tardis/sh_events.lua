-- Events

TARDIS_EVENTS_DISABLED = 0
TARDIS_EVENTS_AUTO = 1
TARDIS_EVENTS_APRIL_FOOLS = 2
TARDIS_EVENTS_HALLOWEEN = 3
TARDIS_EVENTS_CHRISTMAS = 4

---@api
---@param ent (Player|gmod_tardis)?
---@param autoonly boolean?
---@return integer?
function TARDIS:GetCurrentEvent(ent, autoonly)
    local setting = TARDIS:GetSetting("events", ent)
    local year = tonumber(os.date("%Y"))
    local month = tonumber(os.date("%m"))
    local day = tonumber(os.date("%d"))

    if setting == TARDIS_EVENTS_DISABLED and not autoonly then
        return
    elseif setting ~= TARDIS_EVENTS_AUTO and not autoonly then
        return setting
    end

    local event
    if month == 4 and day == 1 then
        event = TARDIS_EVENTS_APRIL_FOOLS
    elseif month == 10 and day >= 24 and day <= 31 then
        event = TARDIS_EVENTS_HALLOWEEN
    elseif month == 12 and day >= 17 and day <= 31 then
        event = TARDIS_EVENTS_CHRISTMAS
    end

    local skipped = TARDIS:GetSetting("events_skipped", ent)
    if skipped and skipped.year == year and skipped.event == event and not autoonly then
        return
    end

    return event
end

---@api
---@param event integer?
---@param id boolean?
---@return string?
function TARDIS:GetEventName(event, id)
    if not event then event = TARDIS:GetCurrentEvent() end
    local name
    if not event then
        name = "Common.None"
    elseif event == TARDIS_EVENTS_APRIL_FOOLS then
        name = "Events.Types.AprilFools"
    elseif event == TARDIS_EVENTS_HALLOWEEN then
        name = "Events.Types.Halloween"
    elseif event == TARDIS_EVENTS_CHRISTMAS then
        name = "Events.Types.Christmas"
    end
    if id then
        return name
    else
        return TARDIS:GetPhrase(name)
    end
end

if CLIENT then
    ---@api
    function TARDIS:SkipEvent()
        local setting = TARDIS:GetSetting("events")
        if setting == TARDIS_EVENTS_DISABLED then
            self:Message(LocalPlayer(), "Events.SkipFailed", "Events.SkipFailed.Disabled")
            return
        elseif setting ~= TARDIS_EVENTS_AUTO then
            self:Message(LocalPlayer(), "Events.SkipFailed", "Events.SkipFailed.NotAutomatic")
            return
        end
        local event = TARDIS:GetCurrentEvent(nil, true)
        if not event then
            self:Message(LocalPlayer(), "Events.SkipFailed", "Events.SkipFailed.NoEvent")
            return
        end
        local year = tonumber(os.date("%Y"))
        local skipped = TARDIS:GetSetting("events_skipped")
        if skipped and skipped.year == year and skipped.event == event then
            self:Message(LocalPlayer(), "Events.SkipFailed", TARDIS:GetPhrase("Events.SkipFailed.AlreadySkipped", self:GetEventName(event)))
            return
        end
        TARDIS:SetSetting("events_skipped", {
            year = year,
            event = event
        })
        self:Message(LocalPlayer(), "Events.Skipped", self:GetEventName(event))
    end

    function TARDIS:NotifyEvent(event)
        if not event then event = self:GetCurrentEvent() end
        local eventname = self:GetEventName(event, true)
        self:Message(LocalPlayer(), "Events.NotifyEvent", eventname .. ".NotifyEvent", "Settings.Sections.Misc")
    end

    hook.Add("TARDIS_SettingChanged", "TARDIS_EventsSettingChanged", function(id, value, old_value, ply)
        if id == "events" and value == TARDIS_EVENTS_DISABLED and TARDIS:GetCurrentEvent(ply, true) then
            Derma_Query(
                TARDIS:GetPhrase("Events.ConfirmDisable"),
                TARDIS:GetPhrase("Common.Interface"),
                TARDIS:GetPhrase("Events.ConfirmDisable.All"), nil,
                TARDIS:GetPhrase("Events.ConfirmDisable.Current"), function()
                    TARDIS:SetSetting("events", old_value)
                    TARDIS:SkipEvent()
                    TARDIS:ReloadSpawnmenuOptionElements("Misc")
                end
            ):SetSkin("TARDIS")
        end
    end)
end
