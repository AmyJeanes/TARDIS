local SETTING_SECTION = "GUI"

TARDIS:AddSetting({
    id="gui_old",
    type="bool",
    value=false,

    class="local",

    option=true,
    section=SETTING_SECTION,
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
    name="ScreenRows",
})

TARDIS:AddSetting({
    id="gui_override_numrows",
    type="bool",
    value=false,

    class="local",

    option=true,
    section=SETTING_SECTION,
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
        for k,v in pairs(TARDIS:GetGUIThemes()) do
            local name = "Themes."..v.name
            table.insert(values, {TARDIS:PhraseExists(name) and name or v.name, v.id})
        end
        return values
    end,

    class="local",

    option = true,
    section = SETTING_SECTION,
    name = "Theme",
})

TARDIS:AddSetting({
    id = "gui_chameleon_3d_preview",
    type = "bool",
    value = false,

    class="local",

    option = true,
    section = SETTING_SECTION,
    name = "Chameleon3DPreview",
})
