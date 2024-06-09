TARDIS.IntModules["default_screens"] = {
	{
		pos = Vector(-33.658, -35.45, 159.97),
		ang = Angle(0, -30, 96),
		width = 378,
		height = 198,
		gui_rows = 4,
		power_off_black = false,
	},
	{
		pos = Vector(33.658, 35.45, 159.97),
		ang = Angle(0, 150, 96),
		width = 378,
		height = 198,
		gui_rows = 4,
		power_off_black = false,
	},
	{
		pos = Vector(-27.484, -23.735, 165.416),
		ang = Angle(0, -30, 102),
		width = 378,
		height = 198,
		gui_rows = 4,
		power_off_black = false,
	},
	{
		pos = Vector(27.484, 23.735, 165.416),
		ang = Angle(0, 150, 102),
		width = 378,
		height = 198,
		gui_rows = 4,
		power_off_black = false,
	},
}

TARDIS.IntModules["default_scanners"] = {
	{
		part = "default_console_scanner",
		mat = "models/cem/toyota_contr/screen",
		width = 1024,
		height = 1024,
		ang = Angle(0,0,0),
		fov = 90,
	},
}

TARDIS.IntModules["default_hook_screen_disable"] = {
	inthooks = {
		["ShouldNotDrawScreen"] = true,
	},
	func = function(ext,int,id)
		if SERVER then return end

		local m_id = (id % 2 ~= 0 and 1 or 2)

		if not ext:GetData("default_screen_enabled_" .. m_id) then return true end

		local m = int:GetPart("default_monitor_" .. m_id)
		if not IsValid(m) then return true end

		if id == 1 or id == 2 then
			if m:IsAnimationPlaying() then
				return true
			end

			if m:IsStatic() then
				return true
			end
		end

		if id == 3 or id == 4 then
			if not m:IsStatic() then
				return true
			end
		end
	end,
}

local function screen_toggle_func(self, ply, no)
    if self:GetScreensOn() then
        local data = "default_screen_enabled_" .. no
        local on = not self:GetData(data)
        self:SetData(data, on, true)

        TARDIS:StatusMessage(ply, "CustomControls.Default.ToggleScreen." .. no .. ".Status", on)
    else
        TARDIS:ErrorMessage(ply, "CustomControls.Default.ToggleScreen." .. no .. ".FailedToggle")
    end
end

TARDIS.IntModules["default_control_toggle_screen_1"] = {
	int_func=function(self,ply)
		screen_toggle_func(self, ply, 1)
	end,
	power_independent = false,
	screen_button = false,
	tip_text = "CustomControls.Default.ToggleScreen.1.Tip",
}

TARDIS.IntModules["default_control_toggle_screen_2"] = {
	int_func=function(self,ply)
		screen_toggle_func(self, ply, 2)
	end,
	power_independent = false,
	screen_button = false,
	tip_text = "CustomControls.Default.ToggleScreen.2.Tip",
}