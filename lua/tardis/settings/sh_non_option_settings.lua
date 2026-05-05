-- These are not configured by user directly, but used to store data

-- Interior-specific settings
TARDIS:AddSetting({
    id = "interior_custom_settings",
    type="table",
    value = {},

    class="networked",

    option = false,
})

-- Used by "Select for redecoration"
TARDIS:AddSetting({
    id="redecorate-interior",
    type="text",
    value=false,

    class="networked",

    option = false,
})

-- Helps to keep the folded/unfolded subsections in the settings
TARDIS:AddSetting({
    id = "options-unfolded-subsections",
    type="table",
    value = {},

    class="local",

    option = false,
})

-- "Don't Show Again" button (cl_prompts.lua)
TARDIS:AddSetting({
    id="light_override_prompt_noshow",
    type="bool",
    value=false,

    class="local",

    option = false,
})

-- Skip event
TARDIS:AddSetting({
    id="events_skipped",
    type="table",
    value={},

    class="networked",

    option = false,
})

-- Icon pack config
TARDIS:AddSetting({
    id = "icon_pack_config",
    type = "table",
    value = { packs = {} },

    class = "local",

    option = false,
})