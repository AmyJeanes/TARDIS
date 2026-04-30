local fallbackcol = Color(255, 255, 255)
fallbackcol = Color(fallbackcol.r, fallbackcol.g, fallbackcol.b):ToVector()

TARDIS.DynamicProxyVars = TARDIS.DynamicProxyVars or {}

local function getdynamicproxyvars(ent, mat, name, default)
    if not TARDIS.DynamicProxyVars[ent] then
        TARDIS.DynamicProxyVars[ent] = {}
    end
    if not TARDIS.DynamicProxyVars[ent][mat] then
        TARDIS.DynamicProxyVars[ent][mat] = {}
    end
    if not TARDIS.DynamicProxyVars[ent][mat][name] then
        TARDIS.DynamicProxyVars[ent][mat][name] = default
    end
    return TARDIS.DynamicProxyVars[ent][mat][name]
end

matproxy.Add({
    name = "TARDIS_State_Texture",

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
            local animate = (self.FrameRates[k] and self.FrameRates[k] > 0)
            self.AnimateTextures[k] = animate
            if animate then
                self.FrameDurations[k] = 1.0 / self.FrameRates[k]
            end
        end

        self.next_update = RealTime()
        self.last_update = RealTime()
        self.current_frame = 0
    end,

    bind = function(self, mat, ent)
        if not IsValid(ent) or not ent.TardisPart then return end
        local ext = ent.exterior
        if not IsValid(ext) then return end

        local s = ext:GetState()

        if s ~= self.last_state then
            self.last_state = s

            if not self.Textures or not self.Textures[s] then return end

            if mat:GetTexture(self.Texture):GetName() ~= self.Textures[s] then
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

local function matproxy_tardis_power_init(self, mat, values)
    self.ResultTo = values.resultvar
    self.on_var = values.onvar
    self.off_var = values.offvar
    self.LastValue = mat:GetVector(values.onvar)
    self.TransitionSpeedOn = values.transitionspeedon or 0
    self.TransitionSpeedOff = values.transitionspeedoff or 0
end

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

        local value = mat:GetVector(var)

        local dynvars = getdynamicproxyvars(ext, mat, self.name, { LastValue = self.LastValue })
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

    init = function( self, mat, values )
        self.ResultTo = values.resultvar
    end,

    bind = function( self, mat, ent )
        if not IsValid(ent) or not ent.TardisPart then return end

        local col = ent:GetData("interior_base_light_color_vec", TARDIS.color_white_vector)
        mat:SetVector(self.ResultTo, col)
    end
})

matproxy.Add({
    name = "TARDIS_Interior_Color1",

    init = function(self, mat, values)
        self.ResultTo = values.resultvar
    end,

    bind = function(self, mat, ent)
        if not IsValid(ent) then return end
        if ent.interior then
            ent = ent.interior
        end
        if ent.exterior then
            if ent.metadata.Interior.MatProxy then
                local col = ent.metadata.Interior.MatProxy.Color1 --[[@as Color]]
                col = Color(col.r, col.g, col.b):ToVector()
                mat:SetVector(self.ResultTo, col)
            end
        else
            mat:SetVector(self.ResultTo, fallbackcol);
        end
    end
})

matproxy.Add({
    name = "TARDIS_Interior_Color2",

    init = function(self, mat, values)
        self.ResultTo = values.resultvar
    end,

    bind = function(self, mat, ent)
        if not IsValid(ent) then return end
        if ent.interior then
            ent = ent.interior
        end
        if ent.exterior then
            if ent.metadata.Interior.MatProxy then
                local col = ent.metadata.Interior.MatProxy.Color2 --[[@as Color]]
                col = Color(col.r, col.g, col.b):ToVector()
                mat:SetVector(self.ResultTo, col)
            end
        else
            mat:SetVector(self.ResultTo, fallbackcol);
        end
    end
})

matproxy.Add({
    name = "TARDIS_Interior_Color3",

    init = function(self, mat, values)
        self.ResultTo = values.resultvar
    end,

    bind = function(self, mat, ent)
        if not IsValid(ent) then return end
        if ent.interior then
            ent = ent.interior
        end
        if ent.exterior then
            if ent.metadata.Interior.MatProxy then
                local col = ent.metadata.Interior.MatProxy.Color3 --[[@as Color]]
                col = Color(col.r, col.g, col.b):ToVector()
                mat:SetVector(self.ResultTo, col)
            end
        else
            mat:SetVector(self.ResultTo, fallbackcol);
        end
    end
})

local function matproxy_tardis_warning_init(self, mat, values)
    self.ResultTo = values.resultvar
    self.on_var = values.onvar
    self.off_var = values.offvar
end

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


local function matproxy_tardis_HDR_init(self, mat, values)
    self.ResultTo = values.resultvar
    self.on_var = values.onvar
    self.off_var = values.offvar
end

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

matproxy.Add({
    name = "TARDIS_ExteriorWindowLight",

    init = function(self, mat, values)
        self.ResultTo = values.resultvar
        self.DefaultColor = mat:GetVector(values.defaultcolor)
        self.LastColor = self.DefaultColor
        self.TransitionSpeed = values.transitionspeed or 0
    end,

    bind = function(self, mat, ent)
        if not IsValid(ent) then return end
        if ent.TardisPart and ent.InteriorPart then
            local ext = ent.exterior
            if not IsValid(ext) then return end
            local vortexcol = vortexfallbackcol
            if ext.metadata.Interior.MatProxy and ext.metadata.Interior.MatProxy.VortexColor then -- Making sure a vortex colour is set in the first place since people tend to re-use door on multiple tardises
                vortexcol = ext.metadata.Interior.MatProxy.VortexColor
            end
            vortexcol = (Color(vortexcol.r, vortexcol.g, vortexcol.b):ToVector()*2.5)
            local col = render.ComputeLighting((ext:GetPos()+Vector(0, 0, 80)),ext:GetForward()) -- Gets the lighting from the perspective of the doors
            if ext:GetData("teleport") or ext:GetData("vortex") then
                local exterioralpha = (ext:GetData("alpha",255)/255)
                local exterioralphainvert = ((exterioralpha - 1)*-1)
                col = ((col*exterioralpha) + (vortexcol*exterioralphainvert)) -- Essentially calculates how dematerialised it is and fades the colour accordingly
            end

            -- Smoothly transition the color
            if self.TransitionSpeed > 0 then
                local dynvars = getdynamicproxyvars(ext, mat, self.name, { LastColor = self.DefaultColor })
                local dir  = col - dynvars.LastColor
                local dist = dir:Length()
                if dist > 1e-6 then -- Avoids floating point errors
                    local step = math.min(dist, self.TransitionSpeed * FrameTime())
                    col = dynvars.LastColor + dir:GetNormalized() * step
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

    init = function(self, mat, values)
        self.ResultTo = values.resultvar
        self.DefaultColor = mat:GetVector(values.defaultcolor)
        self.LastColor = self.DefaultColor
        self.TransitionSpeed = values.transitionspeed or 2
    end,

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
            vortexcol = (Color(vortexcol.r, vortexcol.g, vortexcol.b):ToVector()*2.5)
            local col = render.ComputeLighting((ext:GetPos()+Vector(0, 0, 10)),Vector(0, 0, 1)) -- Gets the lighting from near the origin of the tardis
            if ext:GetData("teleport") or ext:GetData("vortex") then
                local exterioralpha = (ext:GetData("alpha",255)/255)
                local exterioralphainvert = ((exterioralpha - 1)*-1)
                col = ((col*exterioralpha) + (vortexcol*exterioralphainvert)) -- Essentially calculates how dematerialised it is and fades the colour accordingly
            end

            -- Smoothly transition the color
            if self.TransitionSpeed > 0 then
                local dynvars = getdynamicproxyvars(ext, mat, self.name, { LastColor = self.DefaultColor })
                local dir  = col - dynvars.LastColor
                local dist = dir:Length()
                if dist > 1e-6 then -- Avoids floating point errors
                    local step = math.min(dist, self.TransitionSpeed * FrameTime())
                    col = dynvars.LastColor + dir:GetNormalized() * step
                end
                dynvars.LastColor = col
            end
            mat:SetVector(self.ResultTo, col)
        else
            mat:SetVector(self.ResultTo, self.DefaultColor);
        end
    end
})
