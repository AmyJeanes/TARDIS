local SETTING_SECTION = "UI"

TARDIS:AddSetting({
    id = "language",
    type = "list",
    value = "default",

    get_values_func = function()
        local values = {
            {TARDIS:GetPhrase("Settings.Sections.UI.Language.Default"), "default"},
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

TARDIS:AddSetting({
    id="notification_type",
    type="list",
    value=3,
    sort=false,
    get_values_func = function()
        local prefix = "Settings.Sections.UI.NotificationType.Types."
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
    id="show_release_notes",
    type="bool",
    value=true,

    class="local",

    option = true,
    section = SETTING_SECTION,
    name = "ShowReleaseNotes",
})

--------------------------------------------------------------------------------
-- Icons

TARDIS:AddButtonOption({
    id="icon_pack_customize",

    func=function(self)
        self:CustomizeIconPack()
    end,

    section=SETTING_SECTION,
    subsection="Icons",
    name="IconPack.Customize",
})

TARDIS:AddSetting({
    id = "spawnmenu_icon_mode",
    type = "list",
    value = "interior_on_hover",
    sort = false,

    get_values_func = function()
        return {
            {"IconPacks.Customize.IconMode.InteriorOnHover",  TARDIS.SpawnmenuIconMode.InteriorOnHover},
            {"IconPacks.Customize.IconMode.SpawniconOnHover", TARDIS.SpawnmenuIconMode.SpawniconOnHover},
            {"IconPacks.Customize.IconMode.InteriorOnly",     TARDIS.SpawnmenuIconMode.InteriorOnly},
            {"IconPacks.Customize.IconMode.SpawniconOnly",    TARDIS.SpawnmenuIconMode.SpawniconOnly},
        }
    end,

    class = "local",

    option = true,
    section = SETTING_SECTION,
    subsection = "Icons",
    name = "SpawnmenuIconMode",
})

--------------------------------------------------------------------------------
-- Screen

TARDIS:AddSetting({
    id="gui_old",
    type="bool",
    value=false,

    class="local",

    option=true,
    section=SETTING_SECTION,
    subsection="Screen",
    name="OldGUI",
})

TARDIS:AddSetting({
    id="gui_popup_scale",
    type="number",
    value=1.0,
    min=0.25,
    max=1.75,
    round_func = function(x)
        return (x - x % 0.05)
    end,

    class="local",

    option=true,
    section=SETTING_SECTION,
    subsection="Screen",
    name="PopupScale",
})

TARDIS:AddSetting({
    id="gui_screen_numrows",
    type="integer",
    value=3,
    min=2,
    max=7,

    class="local",

    option=true,
    section=SETTING_SECTION,
    subsection="Screen",
    name="ScreenRows",
})

TARDIS:AddSetting({
    id="gui_override_numrows",
    type="bool",
    value=false,

    class="local",

    option=true,
    section=SETTING_SECTION,
    subsection="Screen",
    name="ScreenOverrideRows",
})

TARDIS:AddSetting({
    id="gui_popup_numrows",
    type="integer",
    value=4,
    min=2,
    max=7,

    class="local",

    option=true,
    section=SETTING_SECTION,
    subsection="Screen",
    name="PopupRows",
})

TARDIS:AddSetting({
    id = "gui_interface_theme",
    type = "list",
    value = "default_interior",

    get_values_func = function()
        local values = {
            {"Themes.InteriorDefault", "default_interior"},
        }
        for _,v in pairs(TARDIS:GetGUIThemes()) do
            local name = "Themes."..v.name
            table.insert(values, {TARDIS:PhraseExists(name) and name or v.name, v.id})
        end
        return values
    end,

    class="local",

    option = true,
    section = SETTING_SECTION,
    subsection = "Screen",
    name = "Theme",
})

TARDIS:AddSetting({
    id = "gui_chameleon_3d_preview",
    type = "bool",
    value = false,

    class="local",

    option = true,
    section = SETTING_SECTION,
    subsection = "Screen",
    name = "Chameleon3DPreview",
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
        for _,v in pairs(TARDIS:GetTipStyles()) do
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
