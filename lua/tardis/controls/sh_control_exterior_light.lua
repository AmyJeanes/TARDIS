TARDIS:AddControl({
    id = "exterior_light",
    ext_func=function(self,ply)
        local y, n
        if TARDIS:GetSetting("extlight-alwayson", self) then
            y = "Common.Disabled.Lower"
            n = "Common.Enabled.Lower"
        else
            y = "Common.Enabled.Lower"
            n = "Common.Disabled.Lower"
        end
        TARDIS:StatusMessage(ply, "Controls.ExteriorLight.Status", self:ToggleFlashLight(), y, n)
    end,
    serveronly=true,
    power_independent = false,
    screen_button = {
        virt_console = false,
        mmenu = false,
    },
    tip_text = "Controls.ExteriorLight.Tip",
})