local fallbackcol = Color(255, 255, 255)
fallbackcol = Color(fallbackcol.r, fallbackcol.g, fallbackcol.b):ToVector()

TARDIS.DynamicProxyVars = TARDIS.DynamicProxyVars or {}

---@class tardis_dynamic_proxy_vars
---@field LastValue Vector?
---@field value_cached Vector?
---@field var_cached string?
---@field light_col Vector?
---@field light_frame number?
---@field LastColor Vector?

-- Runs per material bind per frame, so no argument may allocate - callers
-- seed first-use defaults on the returned table instead of passing them in.
---@param ent gmod_tardis
---@param mat IMaterial
---@param name string
---@return tardis_dynamic_proxy_vars
local function getdynamicproxyvars(ent, mat, name)
    local byent = TARDIS.DynamicProxyVars[ent]
    if not byent then
        byent = {}
        TARDIS.DynamicProxyVars[ent] = byent
    end
    local bymat = byent[mat]
    if not bymat then
        bymat = {}
        byent[mat] = bymat
    end
    local vars = bymat[name]
    if not vars then
        vars = {}
        bymat[name] = vars
    end
    return vars
end

---@class tardis_state_texture_matproxy
---@field Texture string
---@field FrameNo string
---@field Textures table<any, string>
---@field FrameRates table<any, number>
---@field AnimateTextures table<any, boolean>
---@field FrameDurations table<any, number>
---@field FrameNumbers table
---@field next_update number
---@field last_update number
---@field current_frame number
---@field anim boolean?
---@field anim_num_frames number
---@field anim_frame_rate number
---@field anim_frame_dur number
---@field last_state any?

matproxy.Add({
    name = "TARDIS_State_Texture",

    ---@param self tardis_state_texture_matproxy
    ---@param mat IMaterial
    ---@param values { resulttexturevar: string, resultframevar: string, textures: table }
    init = function(self, mat, values)
        self.Texture = values.resulttexturevar
        self.FrameNo = values.resultframevar

        self.Textures = {}
        self.FrameRates = {}

        for k,v in pairs(values.textures) do
            if values.textures[v] then
                v = values.textures[v]
            end
            if istable(v) then
                local texture = table.GetKeys(v)[1]
                self.Textures[k] = texture
                self.FrameRates[k] = v[texture]
            else
                self.Textures[k] = v
                self.FrameRates[k] = 0
            end
        end

        self.AnimateTextures = {}
        self.FrameDurations = {}
        self.FrameNumbers = {}

        for k,_ in pairs(self.Textures) do
            local rate = self.FrameRates[k]
            local animate = rate ~= nil and rate > 0
            self.AnimateTextures[k] = animate
            if rate and animate then
                self.FrameDurations[k] = 1.0 / rate
            end
        end

        self.next_update = RealTime()
        self.last_update = RealTime()
        self.current_frame = 0
    end,

    ---@param self tardis_state_texture_matproxy
    ---@param mat IMaterial
    ---@param ent Entity?
    bind = function(self, mat, ent)
        if not IsValid(ent) or not ent.TardisPart then return end
        local ext = ent.exterior
        if not IsValid(ext) then return end

        local s = ext:GetState()

        if s ~= self.last_state then
            self.last_state = s

            if not self.Textures or not self.Textures[s] then return end

            if mat:GetTexture(self.Texture):GetName() ~= self.Textures[s] then
                -- SetTexture accepts a texture name string as well as an ITexture
                mat:SetTexture(self.Texture, self.Textures[s])
            end

            if self.AnimateTextures[s] then
                self.anim = true
                self.anim_num_frames = mat:GetTexture(self.Texture):GetNumAnimationFrames()
                self.anim_frame_rate = self.FrameRates[s]
                self.anim_frame_dur = self.FrameDurations[s]
            else
                self.anim = false
                self.current_frame = 0
                mat:SetInt(self.FrameNo, 0)
            end
        end

        if self.anim then
            local time = RealTime()

            if time > self.next_update then
                local frames_past = math.floor((time - self.last_update) * self.anim_frame_rate)
                self.current_frame = (self.current_frame + frames_past) % self.anim_num_frames

                self.last_update = time
                self.next_update = time + self.anim_frame_dur

                mat:SetInt(self.FrameNo, self.current_frame)
            end
        end
    end
})

---@class tardis_matproxy
---@field name string
---@field ResultTo string
---@field on_var string?
---@field off_var string?
---@field LastValue Vector
---@field TransitionSpeedOn number
---@field TransitionSpeedOff number
---@field last_var string?
---@field last_value Vector?

---@param self tardis_matproxy
---@param mat IMaterial
---@param values table
local function matproxy_tardis_power_init(self, mat, values)
    self.ResultTo = values.resultvar
    self.on_var = values.onvar
    self.off_var = values.offvar
    self.LastValue = mat:GetVector(values.onvar)
    self.TransitionSpeedOn = values.transitionspeedon or 0
    self.TransitionSpeedOff = values.transitionspeedoff or 0
end

---@param self tardis_matproxy
---@param mat IMaterial
---@param ent any
local function matproxy_tardis_power_bind(self, mat, ent)
    if not IsValid(ent) then return end

    if ent.interior then
        ent = ent.interior
    end

    if ent.exterior then
        local ext = ent.exterior
        local on = ext:GetPower()
        local var = on and self.on_var or self.off_var
        if not var then return end

        local dynvars = getdynamicproxyvars(ext, mat, self.name)
        if dynvars.LastValue == nil then dynvars.LastValue = self.LastValue end
        -- The on/off source vars are material constants, so read once per var
        -- flip; an external write to them between flips won't be seen.
        local cached = dynvars.value_cached
        local value ---@type Vector
        if cached ~= nil and dynvars.var_cached == var then
            value = cached
        else
            value = mat:GetVector(var)
            dynvars.var_cached = var
            dynvars.value_cached = value
        end

        if var ~= self.last_var or value ~= self.last_value or value ~= dynvars.LastValue then
             -- Smoothly transition the color
            local transition_speed = on and self.TransitionSpeedOn or self.TransitionSpeedOff
            if transition_speed > 0 then
                local dir = value - dynvars.LastValue
                local dist = dir:Length()
                if dist > 1e-6 then -- Avoids floating point errors
                    local step = math.min(dist, transition_speed * FrameTime())
                    value = dynvars.LastValue + dir:GetNormalized() * step
                end
            end

            self.last_var = var
            self.last_value = value
            dynvars.LastValue = value
            mat:SetVector(self.ResultTo, value)
        end
    end
end

matproxy.Add({
    name = "TARDIS_Power",
    init = matproxy_tardis_power_init,
    bind = matproxy_tardis_power_bind,
})

matproxy.Add({
    name = "TARDIS_Power2",
    init = matproxy_tardis_power_init,
    bind = matproxy_tardis_power_bind,
})

matproxy.Add({
    name = "TARDIS_Power3",
    init = matproxy_tardis_power_init,
    bind = matproxy_tardis_power_bind,
})

matproxy.Add({
    name = "TARDIS_InteriorBaseLight",

    ---@param self table
    ---@param mat IMaterial
    ---@param values table
    init = function( self, mat, values )
        self.ResultTo = values.resultvar
    end,

    ---@param self table
    ---@param mat IMaterial
    ---@param ent Entity?
    bind = function( self, mat, ent )
        if not IsValid(ent) or not ent.TardisPart then return end

        local col = ent:GetData("interior_base_light_color_vec", TARDIS.color_white_vector)
        if col ~= self.last_col then
            self.last_col = col
            mat:SetVector(self.ResultTo, col)
        end
    end
})

matproxy.Add({
    name = "TARDIS_Interior_Color1",

    ---@param self table
    ---@param mat IMaterial
    ---@param values table
    init = function(self, mat, values)
        self.ResultTo = values.resultvar
    end,

    ---@param self table
    ---@param mat IMaterial
    ---@param ent Entity?
    bind = function(self, mat, ent)
        if not IsValid(ent) then return end
        if ent.interior then
            ent = ent.interior
        end
        if ent.exterior then
            if ent.metadata.Interior.MatProxy then
                local col = ent.metadata.Interior.MatProxy.Color1 --[[@as Color]]
                if col ~= self.last_col then
                    self.last_col = col
                    mat:SetVector(self.ResultTo, Color(col.r, col.g, col.b):ToVector())
                end
            end
        elseif self.last_col ~= false then
            self.last_col = false
            mat:SetVector(self.ResultTo, fallbackcol);
        end
    end
})

matproxy.Add({
    name = "TARDIS_Interior_Color2",

    ---@param self table
    ---@param mat IMaterial
    ---@param values table
    init = function(self, mat, values)
        self.ResultTo = values.resultvar
    end,

    ---@param self table
    ---@param mat IMaterial
    ---@param ent Entity?
    bind = function(self, mat, ent)
        if not IsValid(ent) then return end
        if ent.interior then
            ent = ent.interior
        end
        if ent.exterior then
            if ent.metadata.Interior.MatProxy then
                local col = ent.metadata.Interior.MatProxy.Color2 --[[@as Color]]
                if col ~= self.last_col then
                    self.last_col = col
                    mat:SetVector(self.ResultTo, Color(col.r, col.g, col.b):ToVector())
                end
            end
        elseif self.last_col ~= false then
            self.last_col = false
            mat:SetVector(self.ResultTo, fallbackcol);
        end
    end
})

matproxy.Add({
    name = "TARDIS_Interior_Color3",

    ---@param self table
    ---@param mat IMaterial
    ---@param values table
    init = function(self, mat, values)
        self.ResultTo = values.resultvar
    end,

    ---@param self table
    ---@param mat IMaterial
    ---@param ent Entity?
    bind = function(self, mat, ent)
        if not IsValid(ent) then return end
        if ent.interior then
            ent = ent.interior
        end
        if ent.exterior then
            if ent.metadata.Interior.MatProxy then
                local col = ent.metadata.Interior.MatProxy.Color3 --[[@as Color]]
                if col ~= self.last_col then
                    self.last_col = col
                    mat:SetVector(self.ResultTo, Color(col.r, col.g, col.b):ToVector())
                end
            end
        elseif self.last_col ~= false then
            self.last_col = false
            mat:SetVector(self.ResultTo, fallbackcol);
        end
    end
})

---@param self tardis_matproxy
---@param mat IMaterial
---@param values table
local function matproxy_tardis_warning_init(self, mat, values)
    self.ResultTo = values.resultvar
    self.on_var = values.onvar
    self.off_var = values.offvar
end

---@param self tardis_matproxy
---@param mat IMaterial
---@param ent any
local function matproxy_tardis_warning_bind(self, mat, ent)
    if not IsValid(ent) then return end

    if ent.interior then
        ent = ent.interior
    end

    if ent.exterior then
        local ext = ent.exterior
        local var = ext:GetWarning() and self.on_var or self.off_var
        if not var then return end

        local value = mat:GetVector(var)

        if var ~= self.last_var or value ~= self.last_value then
            self.last_var = var
            self.last_value = value
            mat:SetVector(self.ResultTo, value)
        end
    end

end

matproxy.Add({
    name = "TARDIS_Warning",
    init = matproxy_tardis_warning_init,
    bind = matproxy_tardis_warning_bind,
})


---@param self tardis_matproxy
---@param mat IMaterial
---@param values table
local function matproxy_tardis_HDR_init(self, mat, values)
    self.ResultTo = values.resultvar
    self.on_var = values.onvar
    self.off_var = values.offvar
end

---@param self tardis_matproxy
---@param mat IMaterial
---@param ent any
local function matproxy_tardis_HDR_bind(self, mat, ent)
    if not IsValid(ent) or not IsValid(ent.exterior) or not ent.TardisPart then return end

    local var = render.GetHDREnabled() and self.on_var or self.off_var
    if not var then return end

    local value = mat:GetVector(var)

    if var ~= self.last_var or value ~= self.last_value then
        self.last_var = var
        self.last_value = value
        mat:SetVector(self.ResultTo, value)
    end

end

matproxy.Add({
    name = "TARDIS_HDR_State",
    init = matproxy_tardis_HDR_init,
    bind = matproxy_tardis_HDR_bind,
})

local vortexfallbackcol = Color(0, 0, 0) -- Uses black if no custom colour is set since that can fit for any tardis

---@class tardis_dynamic_light_matproxy
---@field name string
---@field ResultTo string
---@field DefaultColor Vector
---@field LastColor Vector
---@field TransitionSpeed number
---@field last_vortex_col Color?
---@field vortex_vec Vector

matproxy.Add({
    name = "TARDIS_ExteriorWindowLight",

    ---@param self tardis_dynamic_light_matproxy
    ---@param mat IMaterial
    ---@param values table
    init = function(self, mat, values)
        self.ResultTo = values.resultvar
        self.DefaultColor = mat:GetVector(values.defaultcolor)
        self.LastColor = self.DefaultColor
        self.TransitionSpeed = values.transitionspeed or 0
    end,

    ---@param self tardis_dynamic_light_matproxy
    ---@param mat IMaterial
    ---@param ent Entity?
    bind = function(self, mat, ent)
        if not IsValid(ent) then return end
        if ent.TardisPart and ent.InteriorPart then
            local ext = ent.exterior
            if not IsValid(ext) then return end
            local vortexcol = vortexfallbackcol
            if ext.metadata.Interior.MatProxy and ext.metadata.Interior.MatProxy.VortexColor then -- Making sure a vortex colour is set in the first place since people tend to re-use door on multiple tardises
                vortexcol = ext.metadata.Interior.MatProxy.VortexColor
            end
            if vortexcol ~= self.last_vortex_col then
                self.last_vortex_col = vortexcol
                self.vortex_vec = Color(vortexcol.r, vortexcol.g, vortexcol.b):ToVector()*2.5
            end
            local dynvars = getdynamicproxyvars(ext, mat, self.name)
            -- Sample the engine lighting query once per frame, not per bind.
            local fn = FrameNumber()
            local col = dynvars.light_col
            if dynvars.light_frame ~= fn or col == nil then
                col = render.ComputeLighting((ext:GetPos()+Vector(0, 0, 80)),ext:GetForward()) -- Gets the lighting from the perspective of the doors
                dynvars.light_frame = fn
                dynvars.light_col = col
            end
            if ext:GetData("teleport") or ext:GetData("vortex") then
                local exterioralpha = (ext:GetData("alpha",255)/255)
                local exterioralphainvert = ((exterioralpha - 1)*-1)
                col = ((col*exterioralpha) + (self.vortex_vec*exterioralphainvert)) -- Essentially calculates how dematerialised it is and fades the colour accordingly
            end

            -- Smoothly transition the color
            if self.TransitionSpeed > 0 then
                if dynvars.LastColor == nil then dynvars.LastColor = self.DefaultColor end
                if col ~= dynvars.LastColor then
                    local dir  = col - dynvars.LastColor
                    local dist = dir:Length()
                    if dist > 1e-6 then -- Avoids floating point errors
                        local step = math.min(dist, self.TransitionSpeed * FrameTime())
                        col = dynvars.LastColor + dir:GetNormalized() * step
                    end
                end
                dynvars.LastColor = col
            end
            mat:SetVector(self.ResultTo, col)
        else
            mat:SetVector(self.ResultTo, self.DefaultColor);
        end
    end
})

matproxy.Add({
    name = "TARDIS_ExteriorBaseLight",

    ---@param self tardis_dynamic_light_matproxy
    ---@param mat IMaterial
    ---@param values table
    init = function(self, mat, values)
        self.ResultTo = values.resultvar
        self.DefaultColor = mat:GetVector(values.defaultcolor)
        self.LastColor = self.DefaultColor
        self.TransitionSpeed = values.transitionspeed or 2
    end,

    ---@param self tardis_dynamic_light_matproxy
    ---@param mat IMaterial
    ---@param ent Entity?
    bind = function(self, mat, ent)
        if not IsValid(ent) then return end
        if ent.interior then
            ent = ent.interior
        end
        if ent.exterior then
            local ext = ent.exterior
            local vortexcol = vortexfallbackcol
            if ext.metadata.Interior.MatProxy and ext.metadata.Interior.MatProxy.VortexColor then -- Making sure a vortex colour is set in the first place since people tend to re-use door on multiple tardises
                vortexcol = ext.metadata.Interior.MatProxy.VortexColor
            end
            if vortexcol ~= self.last_vortex_col then
                self.last_vortex_col = vortexcol
                self.vortex_vec = Color(vortexcol.r, vortexcol.g, vortexcol.b):ToVector()*2.5
            end
            local dynvars = getdynamicproxyvars(ext, mat, self.name)
            -- Sample the engine lighting query once per frame, not per bind.
            local fn = FrameNumber()
            local col = dynvars.light_col
            if dynvars.light_frame ~= fn or col == nil then
                col = render.ComputeLighting((ext:GetPos()+Vector(0, 0, 10)),Vector(0, 0, 1)) -- Gets the lighting from near the origin of the tardis
                dynvars.light_frame = fn
                dynvars.light_col = col
            end
            if ext:GetData("teleport") or ext:GetData("vortex") then
                local exterioralpha = (ext:GetData("alpha",255)/255)
                local exterioralphainvert = ((exterioralpha - 1)*-1)
                col = ((col*exterioralpha) + (self.vortex_vec*exterioralphainvert)) -- Essentially calculates how dematerialised it is and fades the colour accordingly
            end

            -- Smoothly transition the color
            if self.TransitionSpeed > 0 then
                if dynvars.LastColor == nil then dynvars.LastColor = self.DefaultColor end
                if col ~= dynvars.LastColor then
                    local dir  = col - dynvars.LastColor
                    local dist = dir:Length()
                    if dist > 1e-6 then -- Avoids floating point errors
                        local step = math.min(dist, self.TransitionSpeed * FrameTime())
                        col = dynvars.LastColor + dir:GetNormalized() * step
                    end
                end
                dynvars.LastColor = col
            end
            mat:SetVector(self.ResultTo, col)
        else
            mat:SetVector(self.ResultTo, self.DefaultColor);
        end
    end
})
