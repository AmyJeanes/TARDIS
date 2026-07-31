-- glua_ls upstream: a literal assigned to a declared field is completeness-checked, so
-- these partial definitions report fields the merge supplies at runtime -- https://github.com/Pollux12/gmod-glua-ls/issues/71
---@diagnostic disable: missing-fields

local style = TARDIS:NewTipStyle()
style.style_id = "white_on_blue"
style.style_name = "WhiteOnBlue"
style.font = "Trebuchet24"
style.padding = 10
style.offset = 30
style.fr_width = 0
style.colors = {
    normal = {
        text = Color(255, 255, 255, 255),
        background = Color(10, 10, 255, 140),
        frame = Color(10, 10, 50, 100),
    },
    highlighted = {
        text = Color(255, 255, 255, 255),
        background = Color(36, 173, 18, 140),
        frame = Color(10, 10, 50, 100),
    }
}
TARDIS:AddTipStyle(style)
