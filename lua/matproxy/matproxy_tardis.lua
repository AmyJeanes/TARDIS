local fallbackcol = Color(255, 255, 255)
fallbackcol = Color(fallbackcol.r, fallbackcol.g, fallbackcol.b):ToVector()

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

        for k,v in pairs(self.Textures) do
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
end

local function matproxy_tardis_power_bind(self, mat, ent)
    if not IsValid(ent) then return end

    if ent.interior then
        ent = ent.interior
    end

    if ent.exterior then
        local var = ent.exterior:GetPower() and self.on_var or self.off_var
        if not var then return end

        local value = mat:GetVector(var)

        if var ~= self.last_var or value ~= self.last_value then
            self.last_var = var
            self.last_value = value
            mat:SetVector(self.ResultTo, value)
        end
    else
        mat:SetVector(self.ResultTo, fallbackcol)
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
                local col = ent.metadata.Interior.MatProxy.Color1
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
                local col = ent.metadata.Interior.MatProxy.Color2
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
                local col = ent.metadata.Interior.MatProxy.Color3
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
        local var = ent.exterior:GetWarning() and self.on_var or self.off_var
        if not var then return end

        local value = mat:GetVector(var)

        if var ~= self.last_var or value ~= self.last_value then
            self.last_var = var
            self.last_value = value
            mat:SetVector(self.ResultTo, value)
        end
    else
        mat:SetVector(self.ResultTo, fallbackcol)
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