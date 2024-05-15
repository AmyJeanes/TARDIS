TARDIS:AddControl({
    id = "float",
    ext_func=function(self,ply)
        if self:ToggleFloat() or self:GetData("flight") then
            TARDIS:StatusMessage(ply, "Controls.Float.Status", self:GetData("floatfirst"))
        else
            TARDIS:ErrorMessage(ply, "Controls.Float.FailedToggle")
        end
    end,
    serveronly=true,
    power_independent = true,
    screen_button = {
        virt_console = true,
        mmenu = false,
        toggle = true,
        frame_type = {2, 1},
        text = "Controls.Float",
        pressed_state_data = "float",
        order = 11,
    },
    tip_text = "Controls.Float.Tip",
})