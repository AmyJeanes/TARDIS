TARDIS:AddInteriorTemplate("default_lamps", {
    Interior = {
        Size = {
            Max = Vector(892.477, 457.64, 800)
        },
        LightOverride = {
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
        },
        Lamps = {
            {
                color = Color(255, 255, 230),
                texture = "effects/flashlight/soft",
                fov = 170,
                distance = 751,
                brightness = 5,
                pos = Vector(0, 0, 790),
                ang = Angle(90, 90, 180),
                shadows = false,
                states = {
                    ["normal"] = { enabled = true, },
                    ["moving"] = { enabled = false, },
                },
            },
        },
        Light={
            brightness = 5,
            warn_brightness = 4,
        },
    },
    CustomHooks = {
        lamps_toggle = {
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
        },
        thirdperson_lamps_update = {
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
        },
    },
})

TARDIS:AddInteriorTemplate("default_dynamic_color", {
    CustomHooks = {
        int_color = {
            inthooks = { ["Think"] = true },
            func = function(ext,int,frame_time)
                if not IsValid(int) then return end

                if SERVER then
                    local speed = 0.001

                    local k = ext:GetData("default_int_color_mult", math.Rand(0,1))
                    local target = ext:GetData("default_int_color_target")
                    if not target then
                        target = math.random(2) - 1
                        ext:SetData("default_int_color_target", target)
                    end

                    k = math.Approach(k, target, frame_time * speed)

                    ext:SetData("default_int_color_mult", k, true)
                    if k == target then
                        ext:SetData("default_int_color_target", 1 - target, true)
                    end
                end
            end,
        },
    },
})

local function get_color_setting_k(ply)
    local st = TARDIS:GetCustomSetting("default", "color", ply)

    if st == "blue" then
        return 0
    end
    if st == "green" then
        return 1
    end
    if st == "turquoise" then
        return 0.5
    end
    if st == "random" then
        return math.Rand(0,1)
    end
    return 0
end

TARDIS:AddInteriorTemplate("default_fixed_color", {
    CustomHooks = {
        int_color = {
            inthooks = {
                ["PostInitialize"] = true
            },
            func = function(ext,int,frame_time)
                if CLIENT then return end

                local k = get_color_setting_k(ext:GetCreator())
                int:SetData("default_int_color_mult", k, true)
            end,
        },
    },
})

local function change_light_color(lt, col)
    if lt and lt.brightness and col then
        lt.color = col
        lt.color_vec = Vector(col.r/255, col.g/255, col.b/255) * lt.brightness
        lt.render_table.color = lt.color_vec
    end
end

local function set_interior_color(int, k)
    if not int.light_data then return end

    local p = 1 - k

    -- Color(0,180,255) ... Color(0,235,200)
    local col = Color(0, 180 + 55 * k, 200 + 55 * p)

    int:SetData("default_int_env_color", col)

    change_light_color(int.light_data.main, col)
    change_light_color(int.light_data.extra.console_bottom, col)

    -- Color(80, 120, 255) ... Color (80, 255, 120)
    local rotor_col = Color(80, 120 + 125 * k, 120 + 125 * p)
    int:SetData("default_int_rotor_color", rotor_col)

    -- Color(240,240,255) ... Color(255,255,200)
    local console_col = Color(240 + 15 * k, 240 + 15 * k, 200 + 55 * p)
    change_light_color(int.light_data.extra.console_white, console_col)

    -- Color(255,255,255) ... Color(255,255,220)
    local floor_lights_col = Color(255, 255, 220 + 20 * p)
    int:SetData("default_int_floor_lights_color", floor_lights_col)

    int:SetData("default_int_color_set_mult", k)
end

TARDIS:AddInteriorTemplate("default_color_update", {
    CustomHooks = {
        int_color_update = {
            inthooks = { ["Think"] = true },
            func = function(ext,int,frame_time)
                if SERVER or not IsValid(int) then return end

                local k = int:GetData("default_int_color_mult")
                if not k then return end

                if k ~= int:GetData("default_int_color_set_mult") then
                    set_interior_color(int, k)
                end
            end,
        },
    },
})


TARDIS:AddInteriorTemplate("default_small_version", {
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
})

TARDIS:AddInteriorTemplate("default_small_version_lamp_fix", {
    Interior = {
        Size = {
            Max = Vector(484.983, 514.944, 800)
        },
    },
})

TARDIS:AddInteriorTemplate("default_screens_off", {
    CustomHooks = {
        screens_init = {
            inthooks = {
                ["Initialize"] = true,
            },
            func = function(ext,int,id)
                ext:SetData("default_screen_enabled_1", false, true)
                ext:SetData("default_screen_enabled_2", false, true)
            end,
        },
    },
    Interior = {
        Parts = {
            default_flat_switch_1 = { EnabledOnStart = false, },
        },
    },
})

TARDIS:AddInteriorTemplate("default_screens_on", {
    CustomHooks = {
        screens_init = {
            inthooks = {
                ["Initialize"] = true,
            },
            func = function(ext,int,id)
                ext:SetData("default_screen_enabled_1", true, true)
                ext:SetData("default_screen_enabled_2", false, true)
            end,
        },
    },
    Interior = {
        Parts = {
            default_flat_switch_1 = { EnabledOnStart = true, },
        },
    },
})
