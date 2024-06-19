-- Lights && light states

local DEFAULT_MAIN_FALLOFF = 20
local DEFAULT_EXTRA_FALLOFF = 10


-- Light states

function ENT:ApplyLightState(state)
    self:SetData("light_state", state)
    self:CallHook("LightStateChanged", state)

    if SERVER then
        self:CallClientHook("ApplyLightState", state)
    else
        self:SetData("light_state", state)
        self:UpdateLights()
    end
end


if SERVER then return end


ENT:AddHook("ApplyLightState",  "client_func", function(self, state)
    self:ApplyLightState(state)
end)




local LIGHT_TARDIS_STATES = {
    -- { state_id, base_id, is_affected_by_power }
    -- order is important
    {"idle_warning", "idle", false, },

    {"off", "idle", true, },
    {"off_warning", "off", true, },
    {"dead", "off_warning", true, },

    {"travel", "idle", false, },
    {"takeoff", "travel", false, },
    {"travel_warning", "idle_warning", false, },
    {"takeoff_warning", "travel_warning", false, },

    {"handbrake", "idle", false, },
    {"demat_abort", "handbrake", false, },
    {"handbrake_warning", "idle_warning", false, },
    {"demat_abort_warning", "handbrake_warning", false, },
    {"parking", "idle", false, },
    {"parking_warning", "idle_warning", false, },

    {"demat_fail", "idle_warning", false, },
    {"mat_fail", "travel_warning", false, },
    {"demat_fail_warning", "travel_warning", false, },
    {"mat_fail_warning", "travel_warning", false, },
}
local LIGHT_PARAMS_LIST = { "color", "pos", "brightness", "falloff", "enabled", }

local function ConvertOldLightStates(lt)
    if lt.warncolor then
        lt.warn_color = lt.warncolor
        lt.warncolor = nil
    end

    if lt.warn_color or lt.warn_pos or lt.warn_brightness or lt.warn_falloff then
        lt.tardis_states["idle_warning"] = {
            color = lt.warn_color,
            pos = lt.warn_pos,
            brightness = lt.warn_brightness,
            falloff = lt.warn_falloff,
        }
    end

    if lt.off_color or lt.off_pos or lt.off_brightness or lt.off_falloff then
        lt.tardis_states["off"] = {
            color = lt.off_color,
            pos = lt.off_pos,
            brightness = lt.off_brightness,
            falloff = lt.off_falloff,
        }
    end

    if lt.off_warn_color or lt.off_warn_pos or lt.off_warn_brightness or lt.off_warn_falloff then
        lt.tardis_states["off_warning"] = {
            color = lt.off_warn_color,
            pos = lt.off_warn_pos,
            brightness = lt.off_warn_brightness,
            falloff = lt.off_warn_falloff,
        }
    end
end


function ENT:ParseLightTable(lt, default_falloff)
    if SERVER then return end
    if not lt then return end

    -- compatibility with old way of specifying lights
    if not lt.tardis_states then
        lt.tardis_states = {}
        ConvertOldLightStates(lt)
    end


    local ts = lt.tardis_states


    -- Generating the "idle" state (from light defaults)

    if not ts["idle"] then
        ts["idle"] = {}
        for i,param in ipairs(LIGHT_PARAMS_LIST) do
            if lt[param] then
                ts["idle"][param] = lt[param]
                lt[param] = nil
            end
        end
    end

    -- default falloff values were taken from cl_render.lua::predraw_o
    ts["idle"].falloff = ts["idle"].falloff or default_falloff


    -- Processing other states
    local function MergeInheritedLightState(state_id, base_id)
        local new_table = TARDIS:CopyTable(ts[base_id])
        if not ts[state_id] then
            ts[state_id] = new_table
            return
        end
        table.Merge(new_table, ts[state_id])
        ts[state_id] = new_table
    end

    for i,entry in pairs(LIGHT_TARDIS_STATES) do -- the order is important
        local state_id, base_id = entry[1], entry[2]
        local nopower_affected = entry[3]

        if not isstring(ts[state_id]) then
            MergeInheritedLightState(state_id, base_id)
            if nopower_affected and not lt.nopower then
                ts[state_id].enabled = false
            end
        end
    end


    -- processing inheritance

    local function CopyDefaultedLightState(state_id)
        if istable(ts[state_id]) then return end
        if not ts[state_id] then return end

        local defaulted_state_id = ts[state_id]

        if defaulted_state_id == state_id then
            error("Invalid light states: state " .. state_id .. " defauls to itself")
        end

        if not ts[defaulted_state_id] then
            error("Invalid light states: state " .. state_id ..
                  " defauls to a non-existant state " .. defaulted_state_id)
        end

        if isstring(ts[defaulted_state_id]) then
            CopyDefaultedLightState(defaulted_state_id)
            return
        end

        if istable(ts[defaulted_state_id]) then
            ts[state_id] = TARDIS:CopyTable(ts[defaulted_state_id])
            return
        end

        error("Invalid light states: state " .. state_id .. " has incorrect syntax")
    end

    for i,entry in pairs(LIGHT_TARDIS_STATES) do
        local state_id = entry[1]

        if isstring(ts[state_id]) then
            CopyDefaultedLightState(state_id)
        end
    end


    -- creating render tables
    lt.render_tables = {}
    for state_id,state in pairs(ts) do
        if state.enabled == false then
            lt.render_tables[state_id] = {}
        else
            lt.render_tables[state_id] = {
                type = MATERIAL_LIGHT_POINT,
                color = state.color:ToVector() * state.brightness,
                pos = self:LocalToWorld(state.pos),
                quadraticFalloff = state.falloff,
            }
        end
    end

end





-- Light setups

function ENT:GetCurrentLightData()
    local NoExtra = not TARDIS:GetSetting("extra-lights")
    local NoLamps = not TARDIS:GetSetting("lamps-enabled")

    local setup = "Default"

    if NoExtra and NoLamps then
        setup = "NoLampsNoExtra"
    elseif NoExtra then
        setup = "NoExtra"
    elseif NoLamps then
        setup = "NoLamps"
    end

    local ld = self.light_data_setups[setup]

    local state = self:GetData("light_state")
    if state and ld.states and ld.states[state] then
        ld = ld.states[state]
    end

    return ld
end

function ENT:UpdateLights()
    if not self.lights_loaded then
        return self:LoadLights()
    end
    self.light_data = self:GetCurrentLightData()
end

local function MergeLightTable(tbl, base)
    local new_table = TARDIS:CopyTable(base)
    if not tbl then return new_table end

    new_table.NoExtra = nil
    new_table.NoLamps = nil
    new_table.NoLampsNoExtra = nil

    table.Merge(new_table, tbl)
    return new_table
end

function ENT:CreateLightSetup(setup_name, light, extra_lights, default_setup_name)
    local current_light = light[setup_name] or light[default_setup_name]
    local setup = {
        main = MergeLightTable(current_light, light),
        extra = {},
    }

    if extra_lights and istable(extra_lights) then
        for id,li in pairs(extra_lights) do
            if li and istable(li) then
                local current_light = li[setup_name] or li[default_setup_name]
                setup.extra[id] = MergeLightTable(current_light, li)
            end
        end
    end

    self.light_data_setups[setup_name] = setup
end

function ENT:PrepareLightStates(setup, lt, lt_id)
    if not lt or not lt.states then return end

    for state_id,state in pairs(lt.states) do
        setup.states = setup.states or {}
        setup.states[state_id] = setup.states[state_id] or {}

        local this_state = setup.states[state_id]

        if lt_id then
            this_state.extra = this_state.extra or {}
            this_state.extra[lt_id] = MergeLightTable(state, lt)
            this_state.extra[lt_id].states = nil
        else
            this_state.main = this_state.main or {}
            this_state.main = MergeLightTable(state, lt)
            this_state.main.states = nil
        end
    end
end

function ENT:ParseLightStatesForLight(setup, lt_id)
    local all_states = setup.states
    if not all_states or table.IsEmpty(all_states) then return end

    if lt_id then
        for state_id, state in pairs(all_states) do
            if state.extra and state.extra[lt_id] then
                self:ParseLightTable(state.extra[lt_id], DEFAULT_EXTRA_FALLOFF)
            end
        end
    else
        for state_id, state in pairs(all_states) do
            if state.main then
                self:ParseLightTable(state.main, DEFAULT_MAIN_FALLOFF)
            end
        end
    end
end



function ENT:LoadLights(reload)
    if self.lights_loaded and not reload then
        return self:UpdateLights()
    end

    local int_metadata = self.metadata.Interior
    local light = int_metadata.Light
    local lights = int_metadata.Lights
    self.light_data_setups = {}

    self:CreateLightSetup("Default",        int_metadata.Light, int_metadata.Lights)
    self:CreateLightSetup("NoLamps",        int_metadata.Light, int_metadata.Lights)
    self:CreateLightSetup("NoExtra",        int_metadata.Light)
    self:CreateLightSetup("NoLampsNoExtra", int_metadata.Light, nil, "NoExtra")

    for setup_id,setup in pairs(self.light_data_setups) do
        self:PrepareLightStates(setup, setup.main)
        self:ParseLightTable(setup.main, DEFAULT_MAIN_FALLOFF)
        self:ParseLightStatesForLight(setup)

        if not table.IsEmpty(setup.extra) then
            for el_id,el in pairs(setup.extra) do
                self:PrepareLightStates(setup, el, el_id)
                self:ParseLightTable(el, DEFAULT_EXTRA_FALLOFF)
                self:ParseLightStatesForLight(setup, el_id)
            end
        end

    end

    self.lights_loaded = true
    self:UpdateLights()
end




-- Hooks to make it work

ENT:AddHook("Initialize", "lights", function(self)
    self:LoadLights()
end)

ENT:AddHook("SettingChanged", "lights", function(self, id, val)
    if id == "extra-lights" or id == "lamps-enabled" then
        self:UpdateLights()
    end
end)

ENT:AddHook("SlowThink", "lights", function(self)
    local pos = self:GetPos()
    if self.lights_lastpos == pos then return end
    if self.lights_lastpos ~= nil then
        self:LoadLights(true)
        self:LoadLamps()
        self:CreateLamps()
    end
    self.lights_lastpos = pos
end)


ENT:AddHook("ShouldDrawLight", "interior_light_enabled", function(self,id,light)
    if light and light.enabled == false then return false end
    -- allow disabling lights with light states
end)
