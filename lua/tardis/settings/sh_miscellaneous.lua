local SETTING_SECTION = "Misc"

TARDIS:AddSetting({
    id="notification_type",
    type="list",
    value=3,
    get_values_func = function()
        local prefix = "Settings.Sections.Misc.NotificationType.Types."
        return {
            { prefix.."Disabled", 0 },
            { prefix.."ConsoleLog", 1 },
            { prefix.."Chat", 2 },
            { prefix.."Inbuilt", 3 },
        }
    end,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    name="NotificationType",
})

TARDIS:AddSetting({
    id="spawnmenu_interior_icons",
    type="bool",
    value=false,

    class="local",

    option=true,
    section=SETTING_SECTION,
    name="SpawnmenuInteriorIcons",
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
    name="IsomorphicSecurityDefault",
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

TARDIS:AddSetting({
    id="show_release_notes",
    type="bool",
    value=true,

    class="local",

    option = true,
    section = SETTING_SECTION,
    name = "ShowReleaseNotes",
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
-- Tips

TARDIS:AddSetting({
    id="tips",
    type="bool",
    value=true,

    class="local",

    option=true,
    section=SETTING_SECTION,
    subsection="Tips",
    name="Enabled",
})

TARDIS:AddSetting({
    id="tips_show_all",
    type="bool",
    value=false,

    class="local",

    option=true,
    section=SETTING_SECTION,
    subsection="Tips",
    name="ShowAll",
})

TARDIS:AddSetting({
    id="tips_style",
    type="list",
    value="default",

    get_values_func = function()
        local values = {}
        for k,v in pairs(TARDIS:GetTipStyles()) do
            local style = "TipStyles."..v.style_name
            table.insert(values, {TARDIS:PhraseExists(style) and style or v.style_name, v.style_id})
        end
        return values
    end,

    class="local",

    option=true,
    section=SETTING_SECTION,
    subsection="Tips",
    name="Style",
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

--------------------------------------------------------------------------------
-- Language

TARDIS:AddSetting({
    id = "language",
    type = "list",
    value = "default",

    get_values_func = function()
        local values = {
            {TARDIS:GetPhrase("Settings.Sections.Misc.Language.Default"), "default"},
        }
        for k,v in pairs(TARDIS:GetLanguages()) do
            table.insert(values, {v.Name, k})
        end
        return values
    end,

    class="local",

    option = true,
    section = SETTING_SECTION,
    name = "Language",
})