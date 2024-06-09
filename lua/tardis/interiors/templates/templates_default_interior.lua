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
                    ["normal"] = { brightness = 4, },
                    ["moving"] = { brightness = 2, },
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
