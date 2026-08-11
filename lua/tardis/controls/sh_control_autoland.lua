TARDIS:AddControl({
    id = "autoland",
    aliases = { "vortex_flight" },
    ext_func = function(self,ply)
        if self:ToggleAutoland() then
            TARDIS:StatusMessage(ply, "Controls.Autoland.Status", self:GetAutoland(), "Common.Enabled.Lower", "Common.Disabled.Lower")
        else
            TARDIS:ErrorMessage(ply, "Controls.Autoland.FailedToggle")
        end
    end,
    serveronly = true,
    power_independent = false,
    screen_button = {
        virt_console = true,
        mmenu = false,
        toggle = true,
        frame_type = {2, 1},
        text = "Controls.Autoland",
        pressed_state_data = "autoland",
        order = 8,
    },
    tip_text = "Controls.Autoland.Tip",
})