-- Lights

local function ParseLightTable(lt, interior, default_falloff)
    if SERVER then return end

    if not lt then return end

    lt.falloff = lt.falloff or default_falloff
    -- default falloff values were taken from cl_render.lua::predraw_o

    if lt.warncolor then
        lt.warn_color = lt.warncolor
        lt.warncolor = nil
    end

    lt.warn_color = lt.warn_color or lt.color
    lt.warn_pos = lt.warn_pos or lt.pos
    lt.warn_brightness = lt.warn_brightness or lt.brightness
    lt.warn_falloff = lt.warn_falloff or lt.falloff

    if lt.nopower then
        lt.off_color = lt.off_color or lt.color
        lt.off_pos = lt.off_pos or lt.pos
        lt.off_brightness = lt.off_brightness or lt.brightness
        lt.off_falloff = lt.off_falloff or lt.falloff

        -- defaulting `off + warn` to `off` unless specified otherwise
        lt.off_warn_color = lt.off_warn_color or lt.off_color
        lt.off_warn_pos = lt.off_warn_pos or lt.off_pos
        lt.off_warn_brightness = lt.off_warn_brightness or lt.off_brightness
        lt.off_warn_falloff = lt.off_warn_falloff or lt.off_falloff
    end

    -- optimize calculations in `cl_render.lua::predraw_o`
    lt.color_vec = lt.color:ToVector() * lt.brightness
    lt.pos_global = interior:LocalToWorld(lt.pos)

    lt.warn_color_vec = lt.warn_color:ToVector() * lt.warn_brightness
    lt.warn_pos_global = interior:LocalToWorld(lt.warn_pos)

    if lt.nopower then
        lt.off_pos_global = interior:LocalToWorld(lt.off_pos)
        lt.off_color_vec = lt.off_color:ToVector() * lt.off_brightness

        lt.off_warn_pos_global = interior:LocalToWorld(lt.off_warn_pos)
        lt.off_warn_color_vec = lt.off_warn_color:ToVector() * lt.off_warn_brightness
    end

    lt.render_table = {
        type = MATERIAL_LIGHT_POINT,
        color = lt.color_vec,
        pos = lt.pos_global,
        quadraticFalloff = lt.falloff,
    }
    lt.warn_render_table = {
        type = MATERIAL_LIGHT_POINT,
        color = lt.warn_color_vec,
        pos = lt.warn_pos_global,
        quadraticFalloff = lt.warn_falloff,
    }

    if lt.nopower then
        lt.off_render_table = {
            type = MATERIAL_LIGHT_POINT,
            color = lt.off_color_vec,
            pos = lt.off_pos_global,
            quadraticFalloff = lt.off_falloff,
        }
        lt.off_warn_render_table = {
            type = MATERIAL_LIGHT_POINT,
            color = lt.off_warn_color_vec,
            pos = lt.off_warn_pos_global,
            quadraticFalloff = lt.off_warn_falloff,
        }
    else
        lt.off_render_table = {}
        lt.off_warn_render_table = {}
    end
end

if CLIENT then
    local function MergeLightTable(tbl, base)
        local new_table = TARDIS:CopyTable(base)
        if not tbl then return new_table end

        new_table.NoLO = nil
        new_table.NoExtra = nil
        new_table.NoExtraNoLO = nil

        table.Merge(new_table, tbl)
        return new_table
    end

    function ENT:LoadLights()
        local noLO = not TARDIS:GetSetting("lightoverride-enabled")
        local noExtra = not TARDIS:GetSetting("extra-lights")

        local int_metadata = self.metadata.Interior
        local light = int_metadata.Light
        local lights = int_metadata.Lights

        local light_alt

        if noLO and noExtra then
            light_alt = light.NoExtraNoLO or light.NoLO
        elseif noLO then
            light_alt = light.NoLO
        elseif noExtra then
            light_alt = light.NoExtra
        end

        self.light_data = {
            main = MergeLightTable(light_alt, light),
            extra = {},
        }
        ParseLightTable(self.light_data.main, self, 20)

        if not lights then return end
        for k,v in pairs(lights) do
            if v and istable(v) then
                local v_alt
                if noLO then
                    v_alt = v.NoLO
                end
                self.light_data.extra[k] = MergeLightTable(v_alt, v)
                ParseLightTable(self.light_data.extra[k], self, 10)
            end
        end
    end

    ENT:AddHook("Initialize", "lights", function(self)
        self:LoadLights()
    end)

    ENT:AddHook("SettingChanged", "lights", function(self, id, val)
        if id ~= "lightoverride-enabled" and id ~= "extra-lights" then return end
        self:LoadLights()
    end)

    function ENT:DrawLight(id,light)
        if self:CallHook("ShouldDrawLight",id,light)==false then return end

        local dlight = DynamicLight(id, true)
        if not dlight then return end

        local warning = self:GetData("warning", false)
        local power = self:GetPower()

        if not power and warning then
            dlight.Pos = light.off_warn_pos_global
            dlight.r = light.off_warn_color.r
            dlight.g = light.off_warn_color.g
            dlight.b = light.off_warn_color.b
            dlight.Brightness = light.off_warn_brightness
        elseif not power then
            dlight.Pos = light.off_pos_global
            dlight.r = light.off_color.r
            dlight.g = light.off_color.g
            dlight.b = light.off_color.b
            dlight.Brightness = light.off_brightness
        elseif warning then
            dlight.Pos = light.warn_pos_global
            dlight.r = light.warn_color.r
            dlight.g = light.warn_color.g
            dlight.b = light.warn_color.b
            dlight.Brightness = light.warn_brightness
        else -- power & no warning
            dlight.Pos = light.pos_global
            dlight.r = light.color.r
            dlight.g = light.color.g
            dlight.b = light.color.b
            dlight.Brightness = light.brightness
        end

        dlight.Decay = 5120
        dlight.Size = 1024
        dlight.DieTime = CurTime() + 1
    end

    ENT:AddHook("Think", "lights", function(self)
        if TARDIS:GetSetting("lightoverride-enabled") then return end
        local light = self.light_data.main
        local lights = self.light_data.extra
        local index=self:EntIndex()
        if light then
            self:DrawLight(index,light)
        end
        if lights and TARDIS:GetSetting("extra-lights") then
            local i=0
            for _,light in pairs(lights) do
                i=i+1
                self:DrawLight((index*1000)+i,light)
            end
        end
    end)

    ENT:AddHook("ShouldDrawLight", "interior_light_enabled", function(self,id,light)
        if light and light.enabled == false then return false end
        -- allow disabling lights with light states
    end)
end




-- Light states

local function ChangeSingleLightState(light_table, state)
    local new_state = light_table.states and light_table.states[state]
    if not new_state then return end
    table.Merge(light_table, new_state)
end

function ENT:ApplyLightState(state)
    self:SetData("light_state", state)
    self:CallHook("LightStateChanged", state)

    if SERVER then
        self:SendMessage("light_state", {state} )
    else
        local ldata = self.light_data
        if not ldata then return end
        ChangeSingleLightState(ldata.main, state)
        ParseLightTable(ldata.main, self, 20)

        for k,v in pairs(ldata.extra) do
            ChangeSingleLightState(v, state)
            ParseLightTable(v, self, 10)
        end
    end
end

if CLIENT then
    ENT:OnMessage("light_state", function(self, data, ply)
        self:ApplyLightState(data[1])
    end)
end


if CLIENT then
    ENT:AddHook("SlowThink", "lights", function(self)
        local pos = self:GetPos()
        if self.lights_lastpos == pos then return end
        if self.lights_lastpos ~= nil then
            self:LoadLights()
            self:LoadLamps()
            self:CreateLamps()
        end
        self.lights_lastpos = pos
    end)
end