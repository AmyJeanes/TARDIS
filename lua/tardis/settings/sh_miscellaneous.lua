local SETTING_SECTION = "Misc"

TARDIS:AddSetting({
    id="events",
    type="list",
    value=1,
    sort=false,
    get_values_func = function()
        local event = TARDIS:GetPhrase("Events.Event.Lower")
        return {
            { "Common.Disabled", TARDIS_EVENTS_DISABLED },
            { "Common.Automatic", TARDIS_EVENTS_AUTO },
            { TARDIS:GetEventName(TARDIS_EVENTS_APRIL_FOOLS) .. " " .. event, TARDIS_EVENTS_APRIL_FOOLS },
            { TARDIS:GetEventName(TARDIS_EVENTS_HALLOWEEN) .. " " .. event, TARDIS_EVENTS_HALLOWEEN },
            { TARDIS:GetEventName(TARDIS_EVENTS_CHRISTMAS) .. " " .. event, TARDIS_EVENTS_CHRISTMAS },
        }
    end,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    name="Events",
})

TARDIS:AddButtonOption({
    id="events_skip",

    func=function(self)
        self:SkipEvent()
    end,

    section=SETTING_SECTION,
    name="Events.SkipCurrent",
})

TARDIS:AddSetting({
    id="csequences-enabled",
    type="bool",
    value=false,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    name="EnableControlSequences",
})

TARDIS:AddSetting({
    id="security",
    type="bool",
    value=false,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    name="EnableIsomorphicSecurityDefault",
})

TARDIS:AddSetting({
    id="lock_autoclose",
    type="bool",
    value=false,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    name="DoorCloseOnLock",
})

--------------------------------------------------------------------------------
-- Teleport

TARDIS:AddSetting({
    id="teleport-door-autoclose",
    type="bool",
    value=false,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Teleport",
    name="AutoCloseDoors",
})

TARDIS:AddSetting({
    id="dest-onsetdemat",
    type="bool",
    value=false,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Teleport",
    name="DestinationDematOnSet",
})

TARDIS:AddSetting({
    id="vortex-enabled",
    type="bool",
    value=true,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Teleport",
    name="ShowVortex",
})

TARDIS:AddSetting({
    id="teleport_warning_infinite",
    type="bool",
    value=true,
    class="networked",
    option=true,
    section=SETTING_SECTION,
    subsection="Teleport",
    name="InfiniteWarning",
})

--------------------------------------------------------------------------------
-- Flight

TARDIS:AddSetting({
    id="opened-door-no-spin",
    type="bool",
    value=true,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Flight",
    name="StopSpinningOpenDoor",
})

TARDIS:AddSetting({
    id="opened-door-no-boost",
    type="bool",
    value=false,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Flight",
    name="DisableBoostOpenDoor",
})

TARDIS:AddSetting({
    id="thirdperson_careful_enabled",
    type="bool",
    value=true,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Flight",
    name="UseWalkKeyThirdPerson",
})

TARDIS:AddSetting({
    id="flight_interrupt_to_float",
    type="bool",
    value=true,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Flight",
    name="FlightInterruptToFloat",
})

--------------------------------------------------------------------------------
-- Spawning the TARDIS

TARDIS:AddSetting({
    id="use_classic_door_interiors",
    type="bool",
    value=true,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Spawning",
    name="PreferClassicDoor",
})

TARDIS:AddSetting({
    id="randomize_skins",
    type="bool",
    value=true,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Spawning",
    name="RandomizeSkins",
})

TARDIS:AddSetting({
    id="winter_skins",
    type="bool",
    value=false,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Spawning",
    name="UseWinterSkins",
})

TARDIS:AddSetting({
    id="nointerior",
    type="bool",
    value=false,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Spawning",
    name="NoInterior",
})

TARDIS:AddSetting({
    id="legacy_door_type",
    type="bool",
    value=false,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Spawning",
    name="LegacyDoorType",
})

TARDIS:AddSetting({
    id="use_enhanced_door_collision",
    type="bool",
    value=false,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Spawning",
    name="UseEnhancedDoorCollision",
})

