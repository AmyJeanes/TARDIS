matproxy.Add({
    name = "TARDIS_DefaultInt_EnvColor",

    init = function(self, mat, values)
        self.ResultTo = values.resultvar
    end,

    bind = function(self, mat, ent)
        if not IsValid(ent) or not ent.TardisPart then return end

        local col = ent:GetData("default_int_env_color", Color(0,200,255))
        local power = ent.exterior and ent.exterior:GetPower()

        if self.lastcol ~= col or self.lastpower ~= power then
            self.lastcol = col
            self.lastpower = power

            col = Color(col.r, col.g, col.b):ToVector()
            if not power then
                col = col * 0.1
            end

            mat:SetVector(self.ResultTo, col);
        end
    end
})

matproxy.Add({
    name = "TARDIS_DefaultInt_FloorLightsColor",

    init = function(self, mat, values)
        self.ResultTo = values.resultvar
    end,

    bind = function(self, mat, ent)
        if not IsValid(ent) or not ent.TardisPart then return end

        local col = ent:GetData("default_int_floor_lights_color", Color(230,230,210))

        if self.lastcol ~= col then
            self.lastcol = col

            col = Color(col.r, col.g, col.b):ToVector()
            mat:SetVector(self.ResultTo, col);
        end
    end
})

matproxy.Add({
    name = "TARDIS_DefaultInt_RotorInColor",

    init = function(self, mat, values)
        self.ResultTo = values.resultvar
    end,

    bind = function(self, mat, ent)
        if not IsValid(ent) or not ent.TardisPart then return end

        local col = ent:GetData("default_int_rotor_color", Color(255,255,255))

        if self.lastcol ~= col then
            self.lastcol = col

            col = Color(col.r, col.g, col.b):ToVector()
            mat:SetVector(self.ResultTo, col)
        end
    end
})

matproxy.Add({
    name = "TARDIS_DefaultInt_TelepathicsAddColor",

    init = function(self, mat, values)
        self.ResultTo = values.resultvar
    end,

    bind = function(self, mat, ent)
        if not IsValid(ent) or not IsValid(ent.interior) or not ent.TardisPart then return end

        local time = ent.interior:GetData("default_telepathic_activation")
        local timediff = time and (RealTime() - time)

        if time == nil then
            time = LocalPlayer():GetTardisData("destination_last_exit")
            timediff = time and (CurTime() - time)
        end

        if time then
            timediff = math.Clamp(math.abs(timediff), 0, 1)
            mat:SetFloat(self.ResultTo, 0.7 * (1 - timediff))
            return
        end

        if mat:GetFloat(self.ResultTo) ~= 0 then
            mat:SetFloat(self.ResultTo, 0)
        end
    end
})


matproxy.Add({
    name = "TARDIS_DefaultInt_SonicCharger",
    init = function (self, mat, values)
        self.ResultTo = values.resultvar
        self.on_var = values.onvar
        self.off_var = values.offvar
    end,
    bind = function(self, mat, ent)
        if not IsValid(ent) or not IsValid(ent.exterior) or not ent.TardisPart then return end

        local active = ent:GetData("default_sonic_charger_active")

        if active ~= self.last_active then
            self.last_active = active
            local var = active and self.on_var or self.off_var
            if not var then return end

            mat:SetVector(self.ResultTo, mat:GetVector(var))
        end
    end,
})

matproxy.Add({
    name = "TARDIS_DefaultInt_ThrottleLights",
    init = function (self, mat, values)
        self.ResultTo = values.resultvar
        self.on_var = values.onvar
        self.off_var = values.offvar

        self.ResultTo2 = values.resultvar2
        self.on_var2 = values.onvar2
        self.off_var2 = values.offvar2

        self.ResultTo3 = values.resultvar3
        self.on_var3 = values.onvar3
        self.off_var3 = values.offvar3
    end,
    bind = function(self, mat, ent)
        if not IsValid(ent) or not ent.TardisPart or not IsValid(ent.interior) or ent.ID ~= "default_throttle_lights" then
            if not self.last_on then
                self.last_on = true
                mat:SetVector(self.ResultTo, mat:GetVector(self.on_var))
                mat:SetVector(self.ResultTo2, mat:GetVector(self.on_var2))
                mat:SetVector(self.ResultTo3, mat:GetVector(self.on_var3))
            end
            return
        end

        local throttle = ent.interior:GetPart("default_throttle")
        if not IsValid(throttle) then return end

        local on = throttle:GetOn()

        if on ~= self.last_on then
            self.last_on = on
            local var = on and self.on_var or self.off_var
            local var2 = on and self.on_var2 or self.off_var2
            local var3 = on and self.on_var3 or self.off_var3
            if not var or not var2 or not var3 then return end

            mat:SetVector(self.ResultTo, mat:GetVector(var))
            mat:SetVector(self.ResultTo2, mat:GetVector(var2))
            mat:SetVector(self.ResultTo3, mat:GetVector(var3))
        end
    end,
})

