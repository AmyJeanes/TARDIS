-- glua_ls upstream: a literal assigned to a declared field is completeness-checked, so
-- these partial definitions report fields the merge supplies at runtime -- https://github.com/Pollux12/gmod-glua-ls/issues/71
---@diagnostic disable: missing-fields

local style = TARDIS:NewTipStyle()
style.style_id = "classic"
style.style_name = "Classic"
style.font = "GModWorldtip"
style.padding = 10
style.offset = 30
style.fr_width = 2
style.colors = {
    normal = {
        text = Color(0, 0, 0, 255),
        background = Color(255, 255, 200, 255),
        frame = Color(0, 0, 0, 255),
    },
    highlighted = {
        text = Color(0, 0, 0),
        background = Color(138, 228, 111),
        frame = Color(0, 0, 0, 255),
    }
}
TARDIS:AddTipStyle(style)
