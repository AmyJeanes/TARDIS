TARDIS:AddControl({
    id = "flightlessflight",
    ext_func=function(self,ply)
        if self:ToggleFlightlessFlight() then
            TARDIS:StatusMessage(ply, "Controls.FlightlessFlight.Status", self:GetData("flightless"))
        else
            TARDIS:ErrorMessage(ply, "Controls.FlightlessFlight.FailedToggle")
        end
    end,
    serveronly=true,
    power_independent = false,
    screen_button = {
        virt_console = true,
        mmenu = false,
        toggle = true,
        frame_type = {2, 1},
        text = "Controls.FlightlessFlight",
        pressed_state_data = "flightless",
        order = 10,
    },
    tip_text = "Controls.FlightlessFlight.Tip"
})