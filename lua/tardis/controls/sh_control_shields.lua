TARDIS:AddControl({
    id = "shields",
    ext_func=function(self,ply)
        if self:ToggleShields() then
            TARDIS:StatusMessage(ply, "Controls.Shields.Status", self:GetData("shields_on"))
        else
            TARDIS:ErrorMessage(ply, "Controls.Shields.FailedToggle")
        end
    end,
    serveronly=true,
    power_independent = false,
    screen_button = {
        virt_console = true,
        mmenu = false,
        popup_only = false,
        toggle = true,
        frame_type = {2, 1},
        text = "Controls.Shields",
        pressed_state_data = "shields_on",
        order = 1,
    },
    tip_text = "Controls.Shields.Tip",
})