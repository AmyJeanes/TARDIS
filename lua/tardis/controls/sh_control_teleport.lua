TARDIS:AddControl({
    id = "teleport",
    ext_func=function(self,ply)
        if (self:GetData("teleport") or self:GetData("vortex")) then
            self:Mat(function(result)
                if result then
                    TARDIS:Message(ply, "Controls.Teleport.Mat")
                else
                    TARDIS:ErrorMessage(ply, "Controls.Teleport.FailedMat")
                end
            end)
        else
            self:Demat(nil, nil, function(result)
                if result then
                    TARDIS:Message(ply, "Controls.Teleport.Demat")
                else
                    if self:GetData("doorstatereal", false) and not TARDIS:GetSetting("teleport-door-autoclose", self) then
                        TARDIS:ErrorMessage(ply, "Controls.Teleport.FailedDematDoorsOpen")
                    elseif self:GetHandbrake() then
                        TARDIS:ErrorMessage(ply, "Controls.Teleport.FailedDematHandbrake")
                    else
                        TARDIS:ErrorMessage(ply, "Controls.Teleport.FailedDemat")
                    end
                end
            end)
        end
    end,
    serveronly=true,
    power_independent = false,
    screen_button = {
        virt_console = true,
        mmenu = false,
        toggle = true,
        frame_type = {0, 1},
        text = "Controls.Teleport",
        pressed_state_data = {"teleport", "vortex"},
        order = 6,
    },
    tip_text = "Controls.Teleport.Tip",
})