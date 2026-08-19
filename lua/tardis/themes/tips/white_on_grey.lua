-- Partial definitions completed at runtime
---@diagnostic disable: missing-fields

local style = TARDIS:NewTipStyle()
style.style_id = "white_on_grey"
style.style_name = "WhiteOnGrey"
style.font = "Trebuchet24"
style.padding = 10
style.offset = 30
style.fr_width = 0
style.colors = {
    normal = {
        text = Color(255, 255, 255, 255),
        background = Color(50, 50, 50, 100),
        frame = Color(70, 70, 70, 100),
    },
    highlighted = {
        text = Color(255, 255, 255, 255),
        background = Color(48, 131, 37, 154),
        frame = Color(70, 70, 70, 100),
    }
}
TARDIS:AddTipStyle(style)
