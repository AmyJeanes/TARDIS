local SETTING_SECTION = "Performance"

TARDIS:AddSetting({
    id="lightoverride-enabled",
    type="bool",
    value=true,

    class="local",

    option=true,
    section=SETTING_SECTION,
    name="LightingOverride",
})

TARDIS:AddSetting({
    id="extra-lights",
    type="bool",
    value=true,

    class="local",

    option=true,
    section=SETTING_SECTION,
    name="ExtraLights",
})

TARDIS:AddSetting({
    id="lamps-enabled",
    type="bool",
    value=true,

    class="local",

    option=true,
    section=SETTING_SECTION,
    name="Lamps",
})

TARDIS:AddSetting({
    id="portals-enabled",
    type="bool",
    value=true,

    class="local",

    option=true,
    section=SETTING_SECTION,
    name="Portals",
})

TARDIS:AddSetting({
    id="portals-closedist",
    type="number",
    value=1000,
    min=350,
    max=5000,

    class="local",

    option=true,
    section=SETTING_SECTION,
    name="DoorCloseDistance",
})

TARDIS:AddSetting({
    id="extlight-dynamic",
    type="bool",
    value=true,

    class="local",

    option=true,
    section=SETTING_SECTION,
    name="DynamicExteriorLight",
})

TARDIS:AddSetting({
    id="extprojlight-enabled",
    type="bool",
    value=true,

    class="local",

    option=true,
    section=SETTING_SECTION,
    name="ProjectedDoorExteriorLight",
})

TARDIS:AddSetting({
    id="smooth-light-transitions",
    type="bool",
    value=true,

    class="local",

    option=true,
    section=SETTING_SECTION,
    name="SmoothLightTransitions",
})

TARDIS:AddSetting({
    id="breakdown-effects",
    type="bool",
    value=true,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    name="BreakdownEffects",
})

TARDIS:AddSetting({
    id="gui_animations",
    type="bool",
    value=true,

    class="local",

    option=true,
    section=SETTING_SECTION,
    name="GUIAnimations",
})
