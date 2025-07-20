TARDIS:AddControl({
    id = "teleport_double",
    ext_func=function(self,ply,part)
        if not IsValid(part) then
            return TARDIS:Control("teleport", ply, nil)
        end

        local on = part:GetOn()
        local tp = self:GetData("teleport")
        local vx = self:GetData("vortex")

        if (vx and on) or (not on and not tp and not vx) then
            TARDIS:Control("teleport", ply, part)
        elseif tp and (not vx) and on then
            self:InterruptTeleport()
        end

        if on then
            self:CancelTimer("teleport_double_fail_mat_stop")
            local infinite = TARDIS:GetSetting("teleport_warning_infinite", self)
            if not infinite then
                local time = self.metadata.Timings.DematFail
                self:Timer("teleport_double_fail_demat_stop", time, function()
                    self:FailDematStop()
                end)
            else
                self:FailDematStop()
            end
        else
            self:CancelTimer("teleport_double_fail_demat_stop")
            self:Timer("teleport_double_fail_mat_stop", 2, function()
                self:FailMatStop()
            end)
        end
    end,
    serveronly=true,
    power_independent = false,
    screen_button = false,
    tip_text = "Controls.Teleport.Tip",
    moves = {
        ["DematStart"] = function(self, part)
            if not part:GetOn() then
                return true
            end
        end,
        ["PreMatStart"] = function(self, part)
            if part:GetOn() then
                return true
            end
        end,
    }
})
