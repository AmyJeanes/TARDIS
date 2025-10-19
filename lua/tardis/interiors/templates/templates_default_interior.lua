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
                default_corridor_doors_1 = 0.05,
                default_corridor_doors_2 = 0.05,
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
                warn = {
                    brightness = 0,
                }
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

local function set_interior_color_smith(int, k)
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

    -- Color(255,255,200) ... Color(255,255,220)
    local floor_lights_col = Color(255, 255, 200 + 20 * p)
    int:SetData("default_int_floor_lights_color", floor_lights_col)

    int:SetData("default_int_color_set_mult", k)
end

TARDIS:AddInteriorTemplate("default_color_update_smith", {
    CustomHooks = {
        int_color_update = {
            inthooks = { ["Think"] = true },
            func = function(ext,int,frame_time)
                if SERVER or not IsValid(int) then return end

                local k = int:GetData("default_int_color_mult")
                if not k then return end

                if k ~= int:GetData("default_int_color_set_mult") then
                    set_interior_color_smith(int, k)
                end
            end,
        },
    },
})

local function set_interior_color_capaldi(int, k)
    if not int.light_data then return end

    local p = 1 - k

    -- Color(255,153,0) ... Color(255,75,0)
    local env_col = Color(255, 50 + 15 * k, 0)

    int:SetData("default_int_env_color", env_col)

    -- Color(255,50,0) ... Color(255,75,0)
    local main_col = Color(255, 50 + 15 * k, 0)

    change_light_color(int.light_data.main, main_col)
    change_light_color(int.light_data.extra.console_bottom, main_col)

    -- Color(150,50,0) ... Color(150,65,0)
    local rotor_col = Color(150, 50 + 15 * k, 0)
    int:SetData("default_int_rotor_color", rotor_col)

    -- Color(255,50,0) ... Color(255,75,0)
    local console_col = Color(255, 50 + 15 * k, 0)
    change_light_color(int.light_data.extra.console_white, console_col)

    -- Color(255,255,200) ... Color(255,255,220)
    local floor_lights_col = Color(255, 255, 200 + 20 * p)
    int:SetData("default_int_floor_lights_color", floor_lights_col)

    int:SetData("default_int_color_set_mult", k)
end

TARDIS:AddInteriorTemplate("default_color_update_capaldi", {
    CustomHooks = {
        int_color_update = {
            inthooks = { ["Think"] = true },
            func = function(ext,int,frame_time)
                if SERVER or not IsValid(int) then return end

                local k = int:GetData("default_int_color_mult")
                if not k then return end

                if k ~= int:GetData("default_int_color_set_mult") then
                    set_interior_color_capaldi(int, k)
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
            default_intdoors = false,
            default_intdoors_static = { pos = Vector(73.559, -417.853, 47.506), ang = Angle(0,10,0), },
            default_corridor_doors_static = { pos = Vector(-475.5, 213, 160.8) },
            default_corridors = false,
            default_corridor_doors_1 = false,
            default_corridor_doors_2 = false,
            default_corridors_small = { ang = Angle(0,90,0) },
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

TARDIS:AddInteriorTemplate("default_studio_set_ceiling", {
     CustomHooks = {
        studio_set_ceiling = {
            inthooks = {
                ["Initialize"] = true,
            },
            func = function(ext,int,id)
                if IsValid(int) then
                    local rotor=int:GetPart("default_rotor")
                    if IsValid(rotor) then
                        rotor:SetBodygroup(2, 1) -- Ceiling
                    end
                end
            end,
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

TARDIS:AddInteriorTemplate("default_smith", {
    CustomHooks = {
        init = {
            inthooks = {
                ["Initialize"] = true,
            },
            func = function(ext,int,id)
                if CLIENT then return end
                local monitor_1 = int:GetPart("default_monitor_1")
                local monitor_2 = int:GetPart("default_monitor_2")
                if IsValid(monitor_1) and IsValid(monitor_2) then
                    monitor_2:SetBodygroup(0, 1)
                    monitor_1:SetBodygroup(0, 1)
                end
            end,
        },
    },
})

TARDIS:AddInteriorTemplate("default_capaldi", {
    CustomHooks = {
        init = {
            inthooks = {
                ["Initialize"] = true,
            },
            func = function(ext,int,id)
                if CLIENT or not IsValid(int) then return end
                local console = int:GetPart("default_console")
                if IsValid(console) then
                    console:SetBodygroup(2, 1) -- Phone port
                    console:SetBodygroup(5, 1) -- DVD slot
                    console:SetBodygroup(6, 1) -- Siege panel
                end
                local doorframe = int:GetPart("default_doorframe")
                if IsValid(doorframe) then
                    doorframe:SetBodygroup(1, 1) -- Doorframe light
                end
                local monitor_1 = int:GetPart("default_monitor_1")
                local monitor_2 = int:GetPart("default_monitor_2")
                if IsValid(monitor_1) and IsValid(monitor_2) then
                    monitor_2:SetBodygroup(0, 2) -- Screen
                    monitor_1:SetBodygroup(0, 2) -- Screen
                end
                local rotor = int:GetPart("default_rotor")
                if IsValid(rotor) then
                    rotor:SetBodygroup(0, 2) -- Base
                end
                local phone = int:GetPart("default_phone")
                if IsValid(phone) then
                    phone:SetBodygroup(0, 1) -- Phone
                end
                local walls = int:GetPart("default_walls")
                if IsValid(walls) then
                    walls:SetBodygroup(1, 1) -- Walls
                end
            end,
        },
    },
})