local SETTING_SECTION = "Exterior"

--------------------------------------------------------------------------------
-- Exterior light

TARDIS:AddSetting({
    id="extlight-override-color",
    type="bool",
    value=false,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Light",
    name="EnableColorOverride",
})

TARDIS:AddSetting({
    id="extlight-color",
    type="color",
    value=Color(255,255,255),

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Light",
    name="ColorOverride",
})

TARDIS:AddSetting({
    id="extlight-size-dynamic",
    type="number",
    value=1,
    min=0.1,
    max=5,

    class="local",

    option=true,
    section=SETTING_SECTION,
    subsection="Light",
    name="DynamicLightSize",
})

TARDIS:AddSetting({
    id="extlight-alwayson",
    type="bool",
    value=false,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Light",
    name="AlwaysOn",
})

--------------------------------------------------------------------------------
-- Projected light

TARDIS:AddSetting({
    id="extprojlight-override-brightness",
    type="bool",
    value=false,

    class="local",

    option=true,
    section=SETTING_SECTION,
    subsection="ProjectedLight",
    name="EnableBrightnessOverride",
})

TARDIS:AddSetting({
    id="extprojlight-override-color",
    type="bool",
    value=false,

    class="local",

    option=true,
    section=SETTING_SECTION,
    subsection="ProjectedLight",
    name="EnableColorOverride",
})

TARDIS:AddSetting({
    id="extprojlight-override-distance",
    type="bool",
    value=false,

    class="local",

    option=true,
    section=SETTING_SECTION,
    subsection="ProjectedLight",
    name="EnableDistanceOverride",
})

TARDIS:AddSetting({
    id="extprojlight-brightness",
    type="number",
    value=0.1,
    min=0,
    max=10,

    class="local",

    option=true,
    section=SETTING_SECTION,
    subsection="ProjectedLight",
    name="BrightnessOverride",
})

TARDIS:AddSetting({
    id="extprojlight-distance",
    type="number",
    value=750,
    min=0,
    max=5000,

    class="local",

    option=true,
    section=SETTING_SECTION,
    subsection="ProjectedLight",
    name="DistanceOverride",
})

TARDIS:AddSetting({
    id="extprojlight-color",
    type="color",
    value=Color(255,255,255),

    class="local",

    option=true,
    section=SETTING_SECTION,
    subsection="ProjectedLight",
    name="ColorOverride",
})

--------------------------------------------------------------------------------
-- Effects

TARDIS:AddSetting({
    id="extrotorwash-enabled",
    type="bool",
    value=true,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Effects",
    name="RotorwashEnabled",
})

TARDIS:AddSetting({
    id="extwarningsmoke-enabled",
    type="bool",
    value=true,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Effects",
    name="WarningSmokeEnabled",
})

--------------------------------------------------------------------------------
-- Rendering

TARDIS:AddSetting({
    id="enhanced-fading-enabled",
    type="bool",
    value=false,

    class="local",

    option=true,
    section=SETTING_SECTION,
    subsection="Rendering",
    name="EnhancedFadingEnabled",
})