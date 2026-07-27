TARDIS:AddControl({
    id = "toggle_screens",
    int_func=function(self,ply)
        if self:ToggleScreens() then
            TARDIS:StatusMessage(ply, "Controls.ToggleScreens.Status", self:GetData("screens_on"))
        else
            TARDIS:ErrorMessage(ply, "Controls.ToggleScreens.FailedToggle")
        end
    end,
    serveronly=true,
    power_independent = false,
    screen_button = {
        virt_console = true,
        mmenu = false,
        popup_only = true,
        toggle = true,
        frame_type = {2, 1},
        text = "Controls.ToggleScreens",
        pressed_state_data = "screens_on",
        order = 1,
    },
    tip_text = "Controls.ToggleScreens.Tip",
})