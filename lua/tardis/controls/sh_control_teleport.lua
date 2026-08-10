TARDIS:AddControl({
    id = "teleport",
    ext_func=function(self,ply,part,complete)
        if (self:GetData("teleport") or self:GetData("vortex")) then
            self:Mat(function(result)
                if result then
                    TARDIS:Message(ply, "Controls.Teleport.Mat")
                else
                    TARDIS:ErrorMessage(ply, "Controls.Teleport.FailedMat")
                end
                complete(self)
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
                complete(self)
            end)
        end
        return true
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
    moves = {
        ["DematStart"] = true,
        ["MatStart"] = function(self)
            return self.metadata.Exterior.Teleport.ThrottleReset == "jump"
        end,
        ["StopMat"] = function(self)
            return self.metadata.Exterior.Teleport.ThrottleReset == "finish"
        end,
    }
})