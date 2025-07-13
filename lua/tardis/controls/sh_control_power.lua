TARDIS:AddControl({
    id = "power",
    ext_func=function(self,ply)
        local interrupted = self:GetTeleportInterrupted()
        local success, reason, arg1, arg2 = self:TogglePower()
        if success then
            TARDIS:StatusMessage(ply, "Controls.Power.Status", self:GetData("power-state"))
        elseif reason then
            TARDIS:ErrorMessage(ply, reason, arg1, arg2)
        else
            TARDIS:ErrorMessage(ply, "Controls.Power.FailedToggle")
        end
    end,
    serveronly=true,
    power_independent = true,
    screen_button = {
        virt_console = true,
        mmenu = false,
        toggle = true,
        frame_type = {2, 1},
        text = "Controls.Power",
        pressed_state_data = "power-state",
        order = 2,
    },
    tip_text = "Controls.Power.Tip",
})