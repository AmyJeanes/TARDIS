local T = {}
T.Interior = {}


T.Interior.Parts = {
	door = {
		model="models/vtalanov98/toyota_ext/doors_interior.mdl",
		posoffset=Vector(4.42,0,-52.33),
		angoffset=Angle(0,180,0),
	},
	default_doorframe = {},
	default_floor = {},
	default_entry = {},
	default_walls = {},
	default_roof = {},
	default_pillars = {},
	default_rings = {},
	default_side_panels = {},
	default_chairs = {},
	default_casing = {},
	default_console = { ang = Angle(0,90,0), pos = Vector(0,0,-0.1) },
	default_side_details1 = {},
	default_side_details2 = {},
	default_toplights = {},
	default_cables1 = {},
	default_cables2 = {},
	default_cables3 = {},
	default_roundels1 = {},
	default_roundels2 = {},
	default_bulbs = {},
	default_ticks = {},

	default_gears1 = {},
	default_gears2 = {},
	default_gears3 = {},

	default_handbrake = {},
	default_keyboard = {},
	default_telepathic = {},
	default_throttle = {},

	default_side_lever1 = { pos = Vector(100.487, 114.569, 126.76), },
	default_side_lever2 = { pos = Vector(-55.242, -142.028, 126.76), },
	default_side_dial = {},
	default_side_speakers = {},
	default_throttle_lights = {},

	default_bouncy_lever = { pos = Vector(37.6148, 12.5797, 134.562), },
	default_button_1 = {},
	default_button_2 = { pos = Vector(0,9.4,0), },
	default_buttons = {},
	default_crank = {},
	default_crank2 = {},
	default_crank3 = {},
	default_crank4 = {},
	default_crank5 = {},
	default_crank6 = {},
	default_ducks = {},
	default_fiddle1 = { pos = Vector(-47.83, 20.39, 128.36), },
	default_fiddle2 = { pos = Vector(-47.83, 17.33, 128.36), },

	default_flat_switch_1 = { pos = Vector(-10.1897, 28.1115, 137.23), },
	default_flat_switch_2 = { pos = Vector(-11.3625, 27.4343, 137.23), },
	default_flat_switch_3 = { pos = Vector(-12.5354, 26.7572, 137.23), },
	default_flat_switch_4 = { pos = Vector(-16.7892, 24.3012, 137.23), },
	default_flat_switch_5 = { pos = Vector(-17.9621, 23.6241, 137.23), },
	default_flat_switch_6 = { pos = Vector(-19.1350, 22.9469, 137.23), },

	default_flippers = {},
	default_handle1 = {pos = Vector(-32.0253, -11.1286, 136.032), ang = Angle(33.87, 94.5, -24.402)},
	default_handle2 = {pos = Vector(-32.0253, 11.1286, 136.032), },
	default_key = {},

	default_red_lever_1 = {},
	default_red_lever_2 = { pos = Vector(0,26.55,0), },

	default_thick_lever = {},

	default_colored_lever_1 = { pos = Vector(31.28, -6.48, 134.362), },
	default_colored_lever_2 = { pos = Vector(31.28, -3.23, 134.362), },
	default_colored_lever_3 = { pos = Vector(31.28,  0.00, 134.362), },
	default_colored_lever_4 = { pos = Vector(31.28,  3.24, 134.362), },
	default_colored_lever_5 = { pos = Vector(31.28,  6.47, 134.362), },

	default_phone = {},
	default_red_flick_cover = { pos = Vector(46.8003, 20.3683, 130.056), },
	default_red_flick_switch = { pos = Vector(48.3763, 20.3791, 129.36), },
	default_sliders = {},

	default_small_switch_1  = { pos = Vector(-43.5688,9.2562,129.997), },
	default_small_switch_2  = { pos = Vector(-43.5688,8.45203,129.997), },
	default_small_switch_3  = { pos = Vector(-43.5688,7.64787,129.997), },
	default_small_switch_4  = { pos = Vector(-43.5688,6.84371,129.997), },
	default_small_switch_5  = { pos = Vector(-43.5688,6.03954,129.997), },
	default_small_switch_6  = { pos = Vector(-43.5688,5.23538,129.997), },
	default_small_switch_7  = { pos = Vector(-43.5688,4.43121,129.997), },
	default_small_switch_8  = { pos = Vector(-43.5688,3.62705,129.997), },
	default_small_switch_9 = { pos = Vector(-43.5688,2.82289,129.997), },
	default_small_switch_10  = { pos = Vector(-43.5688,-2.63501,129.997), },
	default_small_switch_11 = { pos = Vector(-43.5688,-3.43917,129.997), },
	default_small_switch_12 = { pos = Vector(-43.5688,-4.24334,129.997), },
	default_small_switch_13 = { pos = Vector(-43.5688,-5.0475,129.997), },
	default_small_switch_14 = { pos = Vector(-43.5688,-5.85166,129.997), },
	default_small_switch_15 = { pos = Vector(-43.5688,-6.65583,129.997), },
	default_small_switch_16 = { pos = Vector(-43.5688,-7.45999,129.997), },
	default_small_switch_17 = { pos = Vector(-43.5688,-8.26416,129.997), },
	default_small_switch_18 = { pos = Vector(-43.5688,-9.06832,129.997), },

	default_spin_a_1 = { pos = Vector(-48.304,  9.401, 129.35), },
	default_spin_a_2 = { pos = Vector(-48.304,  4.707, 129.35), },
	default_spin_a_3 = { pos = Vector(-48.304, -0.009, 129.35), },
	default_spin_a_4 = { pos = Vector(-48.304, -4.644, 129.35), },
	default_spin_a_5 = { pos = Vector(-48.304, -9.453, 129.35), },

	default_spin_b_1 = { pos = Vector(-10.011, 45.859, 130.910), ang = Angle(0, -2.574, 0) },
	default_spin_b_2 = { pos = Vector(-14.892, 46.776, 129.530), ang = Angle(-2.88, -7.88, 4.089) },
	default_spin_b_3 = { pos = Vector(-33.016, 36.267, 129.530), ang = Angle(-4.68, -21.49, 4.023) },
	default_spin_b_4 = { pos = Vector(-34.663, 31.617, 130.910), ang = Angle( 1.56,  9.08, -1.378) },

	default_spin_big = { pos = Vector(33.5519, -30.4627, 130.518), ang = Angle(11.6955,-19.35,-2) },
	default_spin_crank = { pos = Vector(-39.865, -31.28, 129.931), ang = Angle(0, -4.62, 0) },
	default_spin_switch = { pos = Vector(32.9344, -25.9602, 132.217), ang = Angle(0, -4.62, 0) },

	default_switch = {},
	default_switch2 = {},
	default_toggles = {},
	default_toggles2 = {},
	default_tumblers = {},

	default_balls = {},
	default_console_scanner = {},

	default_side_cranks1 = {
		pos = Vector(-5.781, -7.625, 0.5),
		ang = Angle(0, -1.54, 0),
	},
	default_side_cranks2 = {
		pos = Vector(2.98, 9.09, 0.5),
		ang = Angle(0, 198.54, 0),
	},

	default_side_toggles_1 = {},
	default_side_toggles_2 = { ang = Angle(0,160,0), },

	default_top_doors_1 = { pos = Vector(-346.742, 125.858, 160.575), ang = Angle(0,70,0), },
	default_top_doors_2 = { pos = Vector(-346.742, -125.858, 160.575), ang = Angle(0,110,0), },

	default_monitor_1 = { ang = Angle(0,-120,0), },
	default_monitor_1_hitbox_handles = { pos = Vector(-20.06, -34.75, 154.08), ang = Angle(0, -30, 96.16) },
	default_monitor_1_hitbox_screen = { pos = Vector(-20.06, -34.75, 154.08), ang = Angle(0, -30, 96.16) },
	default_monitor_1_hitbox_static = { ang = Angle(0,-30,0) },

	default_monitor_2 = { ang = Angle(0,60,0), },
	default_monitor_2_hitbox_handles = { pos = Vector(20.06, 34.75, 154.08), ang = Angle(0, 150, 96.16) },
	default_monitor_2_hitbox_screen = { pos = Vector(20.06, 34.75, 154.08), ang = Angle(0, 150, 96.16) },
	default_monitor_2_hitbox_static = { ang = Angle(0,150,0) },

	default_rotor_ring = {},

	default_rotor = {},
	default_corridors = { ang = Angle(0,90,0), },
	default_intdoors = { pos = Vector(73.559, -417.853, 47.506), ang = Angle(0,10,0), },

	default_sonic_dispenser_hitbox = { ang = Angle(0,90,0), },
}


T.Interior.Controls = {
	default_throttle  = "teleport_double",
	default_handbrake  = "handbrake",
	default_side_lever1 = "engine_release",
	default_side_speakers = "music",
	default_telepathic  = "destination",
	default_console_scanner = "thirdperson_careful",
	default_balls  = "thirdperson",
	default_keyboard  = "coordinates",
	default_crank4 = "repair",
	default_crank2  = "power",
	default_crank3  = "redecorate",
	default_side_lever2 = "physlock",
	default_crank = "random_coords",
	default_buttons = "isomorphic",
	default_fiddle1  = "door",
	default_fiddle2  = "doorlock",
	default_crank6 = "cloak",
	default_tumblers = "vortex_flight",
	default_button2 = "toggle_scanners",
	default_red_flick_switch = "engine_release",
	default_bouncy_lever = "fastreturn",
	default_key = "toggle_console",
	default_sonic_charger = "sonic_dispenser",
	default_spin_crank = "hads",
	default_small_switch_17 = "toggle_doorframe_light",
	default_small_switch_18 = "exterior_light",

	default_spin_b_1 = "flight",
	default_spin_b_2 = "float",
	default_spin_b_3 = "physlock",
	default_spin_b_4 = "spin_cycle",
	default_thick_lever = "shields",

	default_flat_switch_1 = "toggle_screen_1",
	default_flat_switch_2 = "toggle_screen_2",
	default_flat_switch_3 = "toggle_scanners",

	default_sonic_dispenser_hitbox = "sonic_dispenser",
}


T.Interior.PartTips = {
	default_throttle = {pos = Vector(44.891, 14.683, 132.679), right = false, down = true, },
	default_handbrake = {pos = Vector(46.248, -16.804, 131.436), right = true, down = true, },
	default_side_lever1 = {pos = Vector(103.41, 121.655, 130.044), right = true, down = false, },
	default_side_lever2 = {pos = Vector(-59.115, -151.548, 126.17), right = true, down = false, },
	default_telepathic = {pos = Vector(19.919, 35.908, 130.754), right = true, down = false, },
	default_keyboard = {pos = Vector(20.64, -39.63, 129.29), right = true, down = true, },
	default_crank4 = {pos = Vector(-34.917, -29.135, 132.425), right = true, down = true, },
	default_toggles = {pos = Vector(39.523, 0.016, 133.705), right = true, down = false, },
	default_buttons = {pos = Vector(10.193, -49.502, 128.582), right = true, down = true,  },
	default_switch2 = {pos = Vector(-35.645, 12.629, 135.094), right = true, down = true,  },
	default_switch = {pos = Vector(-45.646, -17.836, 130.267), right = true, down = true,  },
	default_thick_lever = {pos = Vector(-36.787, -13.688, 134.195), right = true, down = false, },
	default_crank = {pos = Vector(30.237, -28.123, 132.312), right = true, down = false,  },
	default_crank2 = {pos = Vector(-9.156, -47.859, 130.481), right = true, down = true, },
	default_crank3 = {pos = Vector(-6.948, -30.268, 137.647), right = false, down = false, },
	default_crank5 = {pos = Vector(-24.084, 21.564, 136.681), right = true, down = false, },
	default_crank6 = {pos = Vector(-6.901, 31.399, 136.842), right = false, down = true, },
	default_spin_switch = {pos = Vector(33.531, -25.783, 132.247), right = true, down = false,  },
	default_tumblers = {pos = Vector(35.573, -11.599, 134.216), right = false, down = false, },
	default_button_1 = {pos = Vector(39.263, -4.64, 132.233), right = false, down = false, },
	default_button_2 = {pos = Vector(39.263, 4.64, 132.233), right = true, down = false, },
	default_handle2 = {pos = Vector(-33.066, 10.939, 137.381), right = true, down = false, },
	default_handle1 = {pos = Vector(-32.921, -10.81, 137.31), right = false, down = false, },
	default_red_flick_switch = {pos = Vector(47.918, 20.722, 129.642), right = true, down = true, },
	default_bouncy_lever = { pos = Vector(36.789, 14.121, 134.479), right = true, down = false, },
	default_red_lever_1 = {pos = Vector(-44.239, -12.951, 131.572), right = true, down = false, },
	default_red_lever_2 = {pos = Vector(-44.051, 14.102, 131.376), right = false, down = false, },
	default_spin_a_2 = {pos = Vector(-49.221, 4.594, 129.101), right = true, down = true, },
	default_spin_b_3 = {pos = Vector(-32.958, 36.406, 129.314), right = true, down = true, },
	default_spin_b_2 = {pos = Vector(-15.003, 46.519, 128.838), right = true, down = true, },
	default_spin_crank = {pos = Vector(-40.013, -31.619, 130.98), right = false, down = true, },
	default_key = {pos = Vector(-23.59, -20.837, 137.406), right = false, down = false, },

	default_fiddle1 = { right = false, down = true, },
	default_fiddle2 = { right = true, down = true, },

	default_small_switch_1 = {right = false, down = true,},
	default_small_switch_2 = {right = false, down = false,},
	default_small_switch_3 = {right = true, down = false,},
	default_small_switch_4 = {right = true, down = true,},
	default_small_switch_5 = {right = false, down = true,},
	default_small_switch_6 = {right = false, down = false,},
	default_small_switch_7 = {right = true, down = false,},
	default_small_switch_8 = {right = true, down = true,},
	default_small_switch_9 = {right = false, down = true,},
	default_small_switch_10 = {right = true, down = false},
	default_small_switch_11 = {right = false, down = true,},
	default_small_switch_12 = {right = false, down = false,},
	default_small_switch_13 = {right = true, down = false,},
	default_small_switch_14 = {right = true, down = true,},
	default_small_switch_15 = {right = false, down = true,},
	default_small_switch_16 = {right = false, down = false,},
	default_small_switch_17 = {right = true, down = false,},
	default_small_switch_18 = {right = true, down = true,},

	default_spin_a_1 = {},
	default_spin_a_2 = {},
	default_spin_a_3 = {},
	default_spin_a_4 = {},
	default_spin_a_5 = {},

	default_spin_b_1 = { right = false, down = true, },
	default_spin_b_2 = { right = true, down = true, },
	default_spin_b_3 = { right = false, down = false, },
	default_spin_b_4 = { right = true, down = true, },

	default_flat_switch_1 = {right = false, down = false, },
	default_flat_switch_2 = {right = true, down = false, },
	default_flat_switch_3 = {right = true, down = true, },
	default_flat_switch_4 = {right = false, down = false, },
	default_flat_switch_5 = {right = true, down = true, },
	default_flat_switch_6 = {right = true, down = false,},

	default_side_cranks1 = { pos = Vector(75.28, 139.87, 129.97), right = true, down = true, },
	default_side_cranks2 = { pos = Vector(-23.13, -157.55, 130.01), right = true, down = true, },

	default_flippers = { pos = Vector(-36.1, 0.49, 131.31), right = true, down = true, },
	default_spin_big = { pos = Vector(34.71, -30.58, 130.3), right = true, down = true, },
	default_gears1 = { pos = Vector(-25.47, -28.1, 133.62), right = true, down = true, },
	default_gears2 = { pos = Vector(-17.79, -39.58, 131.39), right = true, down = true, },
	default_gears3 = { pos = Vector(-13.37, -28.16, 135.71), right = true, down = true, },
	default_sonic_dispenser_hitbox = { pos = Vector(8.4, -37.31, 135.07), right = false, down = false, },
	default_sliders = { pos = Vector(14.79, -31.19, 134.22), right = true, down = true, },
	default_toggles2 = { pos = Vector(15.55, -24.79, 136.77), right = true, down = true, },
	default_phone = { pos = Vector(27.75, -35.17, 130.68), right = true, down = true, },
	default_ducks = { pos = Vector(31.21, -32.59, 130.36), right = true, down = true, },
	default_colored_lever_1 = { pos = Vector(31.04, -6.4, 135.01), right = true, down = true, },
	default_colored_lever_2 = { pos = Vector(31.27, -3.28, 134.69), right = true, down = true, },
	default_colored_lever_3 = { pos = Vector(31.37, -0.02, 134.47), right = true, down = true, },
	default_colored_lever_4 = { pos = Vector(31.12, 3.29, 135.1), right = true, down = true, },
	default_colored_lever_5 = { pos = Vector(31.09, 6.44, 135.21), right = true, down = true, },
}


T.Interior.CustomTips = {
	{pos = Vector(83.96, 122.99, 125.78), right = true, down = true, part = "default_side_speakers", },
	{pos = Vector(130.65, 71.77, 125.87), right = true, down = true, part = "default_side_speakers", },
	{pos = Vector(-38.64, -144.1, 125.97), right = true, down = true, part = "default_side_speakers", },
	{pos = Vector(-101.11, -110.17, 126.19), right = true, down = true, part = "default_side_speakers", },
	{pos = Vector(-35.68, 28.74, 131.96), right = true, down = false, part = "default_balls", },
	{pos = Vector(-6.69, 45.46, 131.72), right = false, down = false, part = "default_balls", },

	{pos = Vector(334.946, -34.611, 40.627), text = "Never Gonna Give You Up!\nNever Gonna Let You Down!"}
}


T.Interior.TipSettings = {
	view_range_min = 40,
	view_range_max = 75,
},


TARDIS:AddInteriorTemplate("default_parts", T)




local T = {
    Interior = {
        Size = {
            Min = Vector(-555.742, -461.072, 0),
            Max = Vector(388.574, 371.054, 381.653),
        },
        ExitBox = {
            Min = Vector(-659.914, -564.271, -50),
            Max = Vector(484.983, 514.944, 385.095),
        },

        Parts = {
            default_rotor = {
                model = "models/molda/toyota_int/rotor_small.mdl",
            },
            default_intdoors = false,
            default_intdoors_static = { pos = Vector(73.559, -417.853, 47.506), ang = Angle(0,10,0), },
            default_corridor_doors_static = { pos = Vector(-475.5, 213, 160.8) },
            default_corridors = {
                model = "models/molda/toyota_int/corridor_version3.mdl"
            },
        },
    },
}

TARDIS:AddInteriorTemplate("default_small_version", T)




TARDIS:AddInteriorTemplate("default_small_version_lamp_fix", {
    Interior = {
        Size = {
            Max = Vector(484.983, 514.944, 800)
        },
    },
})

