local T = {}
T.Interior = {}

T.Interior.LightOverride = {
	basebrightness = 0.05,
	nopowerbrightness = 0.001,
}

T.Interior.Light = {
	color = Color(0,170,255),
	pos = Vector(0,0,-30),
	brightness = 8,

	NoLO = {
		brightness = 5,
		warn_brightness = 3,
	},
	NoExtra = {
		pos = Vector(0,0,187.4),
		brightness = 1,
	},

	tardis_states = {
		["idle_warning"] = {
			brightness = 6,
		},
	},
}



T.Interior.Lights = {}

T.Interior.Lights.console_white = {
		nopower = true,

		pos = Vector(0,0,187.4),
		brightness = 0.4,
		color = Color(255,255,200),

		tardis_states = {
			["idle_warning"] = {
				color = Color(255,143,143),
			},
			["off"] = {
				color = Color(0,120,200),
				brightness = 0.1,
			},
			["dead"] = {
				enabled = false,
			},
		},
}

T.Interior.Lights.console_bottom = {
	color = Color(0,170,255),
	pos = Vector(0,0,110),
	brightness = 0.5,

	nopower = true,

	tardis_states = {
		["idle_warning"] = {
			brightness = 0.2,
		},
		["off"] = {
			color = Color(0,65,215),
			brightness = 0.2,
		},
		["dead"] = {
			enabled = false,
		},
	},
}

TARDIS:AddInteriorTemplate("default_lighting", T)




local T = {}
T.Interior = {}


T.Interior.Size = {
	Max = Vector(892.477, 457.64, 800),
}


T.Interior.LightOverride = {
	basebrightness = 0.01,
	parts = {
		default_rings = 0.05,
		default_corridors = 0.05,
		default_intdoors = 0.05,
		default_intdoors_static = 0.05,
		default_corridor_doors_static = 0.05,
	},
	parts_nopower = {
		default_rings = 0.001,
	},
}


T.Interior.Lamps = {
	{
		color = Color(255, 255, 230),
		texture = "effects/flashlight/soft",
		fov = 170,
		distance = 751,
		brightness = 5,
		pos = Vector(0, 0, 790),
		ang = Angle(90, 90, 180),
		shadows = false,
		enabled = true,
		states = {
			["normal"] = { brightness = 4, },
			["moving"] = { brightness = 2, },
		},
	},
}


T.Interior.Light = {
	brightness = 5,
	warn_brightness = 4,
}


T.CustomHooks = {}

T.CustomHooks.lamps_toggle = {
	exthooks = {
		["DematStart"] = true,
		["StopMat"] = true,
		["FlightToggled"] = true,
	},
	func = function(ext,int)
		if SERVER then return end
		if not IsValid(int) then return end

		if ext:GetData("demat") or ext:GetData("flight") or ext:GetData("mat") then
			int:ApplyLightState("moving")
		else
			int:ApplyLightState("normal")
		end
	end,
}

T.CustomHooks.thirdperson_lamps_update = {
	exthooks = {
		["ThirdPerson"] = true,
	},
	func = function(ext,int,ply,enabled)
		if SERVER then return end
		if not IsValid(int) then return end
		if enabled then return end

		if ext:GetData("teleport") or ext:GetData("vortex") or ext:GetData("flight") then
			int:ApplyLightState("moving")
		else
			int:ApplyLightState("normal")
		end
	end,
}


TARDIS:AddInteriorTemplate("default_lamps", T)
