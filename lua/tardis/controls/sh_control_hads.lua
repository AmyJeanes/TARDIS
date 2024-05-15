TARDIS:AddControl({
    id = "hads",
    ext_func=function(self,ply)
        self:ToggleHADS()
        TARDIS:StatusMessage(ply, "Controls.HADS.Status", self:GetHADS())
    end,
    serveronly=true,
    power_independent = false,
    screen_button = {
        virt_console = true,
        mmenu = false,
        toggle = true,
        frame_type = {2, 1},
        text = "Controls.HADS",
        pressed_state_data = "hads",
        order = 14,
    },
    tip_text = "Controls.HADS.Tip",
})