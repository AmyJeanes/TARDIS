TARDIS:AddControl({
    id = "toggle_handbrake_control",
    int_func=function(self,ply)
        TARDIS:StatusMessage(ply, "Controls.Handbrake.Status", self:ToggleHandbrakeControl())
    end,
    serveronly = true,
    power_independent = true,
    tip_text = "Controls.ToggleHandbrakeControl.Tip",
})