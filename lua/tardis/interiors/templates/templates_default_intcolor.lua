local function get_color_setting_k(ply)
    local st = TARDIS:GetCustomSetting("default", "color", ply)

    if st == "blue" then
        return 0
    end
    if st == "green" then
        return 1
    end
    if st == "turquoise" then
        return 0.6
    end
    if st == "random" then
        return math.Rand(0,1)
    end
    return 0
end

local function change_light_color(lt, rt, col)
    if lt and lt.brightness and col then
        lt.color = col

        local color_vec = Vector(col.r/255, col.g/255, col.b/255)
        rt.color = color_vec * lt.brightness
    end
end

local function set_interior_color(int, k)
    if not int.light_data then return end

    local state = int.exterior:GetState()

    local lmn = int.light_data.main.tardis_states[state]
    local lcb = int.light_data.extra.console_bottom.tardis_states[state]
    local lcw = int.light_data.extra.console_white.tardis_states[state]
    local lmn_rt = int.light_data.main.render_tables[state]
    local lcb_rt = int.light_data.extra.console_bottom.render_tables[state]
    local lcw_rt = int.light_data.extra.console_white.render_tables[state]

    local p = 1 - k

    -- Color(0,180,255) ... Color(0,235,200)
    local col = Color(0, 180 + 55 * k, 200 + 55 * p)

    int:SetData("default_int_env_color", col)

    change_light_color(lmn, lmn_rt, col)
    change_light_color(lcb, lcb_rt, col)

    -- Color(80, 120, 255) ... Color (80, 255, 120)
    local rotor_col = Color(80, 120 + 125 * k, 120 + 125 * p)
    int:SetData("default_int_rotor_color", rotor_col)

    -- Color(240,240,255) ... Color(255,255,200)
    local console_col = Color(240 + 15 * k, 240 + 15 * k, 200 + 55 * p)
    change_light_color(lcw, lcw_rt, console_col)

    -- Color(255,255,255) ... Color(255,255,220)
    local floor_lights_col = Color(255, 255, 220 + 20 * p)
    int:SetData("default_int_floor_lights_color", floor_lights_col)

    int:SetData("default_int_color_set_mult", k)
end

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
                else
                    local k = int:GetData("default_int_color_mult")
                    if not k then return end

                    if k ~= int:GetData("default_int_color_set_mult") then
                        set_interior_color(int, k)
                    end
                end
            end,
        },
    },
})


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
        int_color_update = {
            inthooks = { ["Think"] = true },
            func = function(ext,int,frame_time)
                if SERVER or not IsValid(int) then return end
                if int:GetData("default_int_color_updated") then return end

                local k = int:GetData("default_int_color_mult")
                if not k then return end

                if k ~= int:GetData("default_int_color_set_mult") then
                    set_interior_color(int, k)
                    int:SetData("default_int_color_updated", true)
                end
            end,
        },
    },
})
