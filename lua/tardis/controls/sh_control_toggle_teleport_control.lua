TARDIS:AddControl({
    id = "toggle_teleport_control",
    int_func=function(self,ply)
        TARDIS:StatusMessage(ply, "Controls.Teleport.Status", self:ToggleTeleportControl())
    end,
    serveronly = true,
    power_independent = true,
    tip_text = "Controls.ToggleTeleportControl.Tip",
})