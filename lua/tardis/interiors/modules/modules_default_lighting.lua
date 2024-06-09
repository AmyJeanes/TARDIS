TARDIS.IntModules["default_lightoverride"] = {
	basebrightness = 0.05,
	nopowerbrightness = 0.001,
}

TARDIS.IntModules["default_light_main"] = {
	color = Color(0,170,255),
	pos = Vector(0,0,-30),
	brightness = 8,
	warn_brightness = 6,
	NoLO = {
		brightness = 5,
		warn_brightness = 3,
	},
	NoExtra = {
		pos = Vector(0,0,187.4),
		brightness = 1,
	},
}

TARDIS.IntModules["default_light_console_white"] = {
	pos = Vector(0,0,187.4),
	brightness = 0.4,
	color = Color(255,255,200),
	warn_color = Color(255,143,143),
	off_color = Color(0,120,200),
	off_brightness = 0.1,
	nopower = true,
}

TARDIS.IntModules["default_light_console_bottom"] = {
	color = Color(0,170,255),
	pos = Vector(0,0,110),
	brightness = 0.5,
	warn_brightness = 0.2,
	nopower = true,
	off_color = Color(0,65,215),
	off_brightness = 0.2,
}