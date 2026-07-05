-- Lamps (projected lights)

if CLIENT then
    local function MergeLampTable(tbl, base, keep_warn_off_options)
        if not tbl then return nil end

        local new_table = TARDIS:CopyTable(base)
        new_table.states = nil
        if not keep_warn_off_options then
            new_table.warn = nil
            new_table.off = nil
            new_table.off_warn = nil
        end
        table.Merge(new_table, tbl)
        return new_table
    end

    local function ParseLampTable(lmp)
        if not lmp then return end
        if lmp.parsed == true then return end

        lmp.texture = lmp.texture or "effects/flashlight/soft"
        lmp.pos = lmp.pos or Vector(0,0,0)
        lmp.ang = lmp.ang or Angle(0,0,0)
        lmp.fov = lmp.fov or 90
        lmp.color = lmp.color or Color(255,255,255)
        lmp.brightness = lmp.brightness or 3.0
        lmp.distance = lmp.distance or 1024
        lmp.shadows = lmp.shadows or false
        lmp.shadowfilter = lmp.shadowfilter or 1

        lmp.warn = MergeLampTable(lmp.warn, lmp, false)
        lmp.off = MergeLampTable(lmp.off, lmp, false)
        lmp.off_warn = MergeLampTable(lmp.off_warn, lmp.off or lmp, false)

        if lmp.states then
            for k,v in pairs(lmp.states) do
                lmp.states[k] = MergeLampTable(v, lmp, true)
            end
        end

        lmp.parsed = true
    end

    ---@param lamp table?
    function ENT:InitLampData(lamp)
        if not lamp or not lamp.pos then return end
        lamp.pos_global = self:LocalToWorld(lamp.pos)
        if lamp.sprite then
            lamp.spritepixvis = util.GetPixelVisibleHandle()
            lamp.sprite_brightness = lamp.sprite_brightness or 1
        end
        self:InitLampData(lamp.warn)
        self:InitLampData(lamp.off)
        self:InitLampData(lamp.off_warn)

        if not lamp.states then return end
        for _,v in pairs(lamp.states) do
            self:InitLampData(v)
        end
    end

    function ENT:LoadLamps()
        local lamps = self.metadata.Interior.Lamps
        if not lamps then return end

        self.lamps_data = {}

        for k,v in pairs(lamps) do
            ParseLampTable(v) -- only once per metadata
            local this_lamp = TARDIS:CopyTable(v)
            self:InitLampData(this_lamp)
            self.lamps_data[k] = this_lamp
        end
    end

    ENT:AddHook("Initialize", "lamps", function(self)
        self:LoadLamps()
        self:CreateLamps()
    end)

    ---@param lamp table?
    function ENT:CreateLamp(lamp)
        if not lamp then return end
        if lamp.enabled == false then return end
        local pl = ProjectedTexture()
        pl:SetTexture(lamp.texture)
        pl:SetPos(lamp.pos_global)
        pl:SetAngles(lamp.ang)
        pl:SetFOV(lamp.fov)
        pl:SetColor(lamp.color)
        pl:SetBrightness(lamp.brightness)
        pl:SetFarZ(lamp.distance)
        pl:SetEnableShadows(lamp.shadows)
        pl:SetShadowFilter(lamp.shadowfilter)
        pl:SetNoCull(true)
        pl:Update()
        return pl
    end

    local function SelectLampTable(self, lmp)
        local state = self:GetData("light_state")
        local warning = self:GetData("warning", false)
        local power = self:GetPower()
        local l = lmp

        if lmp and lmp.states then
            l = lmp.states[state] or l
        end

        if not power and lmp.nopower ~= true then
            return nil
        end

        if not power and warning then
            l = l.off_warn or l
        elseif not power then
            l = l.off or l
        elseif warning then
            l = l.warn or l
        end

        return l
    end

    function ENT:CreateLamps()
        if not TARDIS:GetSetting("lamps-enabled") then return end
        if TARDIS.debug_lamps_enabled then return end
        if not self.lamps_data then return end

        self:RemoveLamps() -- drop existing projected textures first, else they leak until GC (double-bright flash)
        local lamps = {}
        self.lamps = lamps
        for k,v in pairs(self.lamps_data) do
            lamps[k] = self:CreateLamp(SelectLampTable(self, v))
        end
        self:RunLampUpdate()
    end

    function ENT:RemoveLamps()
        if not self.lamps then return end
        for _,v in pairs(self.lamps) do
            if IsValid(v) then
                v:Remove()
            end
        end
        self.lamps = nil
    end

    ENT:AddHook("LightStateChanged", "lamps", function(self) self:CreateLamps() end)

    ENT:AddHook("PowerToggled", "lamps", function(self) self:CreateLamps() end)

    ENT:AddHook("WarningToggled", "lamps", function(self) self:CreateLamps() end)


    function ENT:RunLampUpdate()
        if not TARDIS:GetSetting("lamps-enabled") then return end
        if not self.lamps then return end

        self.lamps_need_updating = true

        self:Timer("lamps_update_stop", 0.3, function()
            self.lamps_need_updating = false
        end)
    end

    ENT:AddHook("Think", "lamps_updates", function(self)
        if not self.lamps_need_updating then return end

        if not TARDIS:GetSetting("lamps-enabled") then return end
        if not self.lamps then return end

        for _,v in pairs(self.lamps) do
            if IsValid(v) then
                v:Update()
            end
        end
    end)

    local matLight = Material("sprites/light_ignorez")
    ENT:AddHook("Draw", "lamps", function(self)
        if not TARDIS:GetSetting("lamps-enabled") then return end
        if not self.lamps_data then return end

        for _,v in pairs(self.lamps_data) do
            local data = SelectLampTable(self, v)
            if not data then return end
            if data.sprite then
                -- adapted from https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/entities/entities/gmod_lamp.lua

                local lightPos = data.pos_global
                local viewNormal = lightPos - EyePos()
                local distance = viewNormal:Length()

                render.SetMaterial( matLight )
                local visible = util.PixelVisible(lightPos, 16, data.spritepixvis)
                if not visible then return end

                local size = math.Clamp(distance * visible * 2, 64, 512)

                distance = math.Clamp(distance, 32, 800)
                local alpha = math.Clamp((1000 - distance) * visible * data.sprite_brightness, 0, 100)

                render.DrawSprite(lightPos, size, size, ColorAlpha(data.color, alpha))
                render.DrawSprite(lightPos, size * 0.4, size * 0.4, Color( 255, 255, 255, alpha ))
            end
        end
    end)


    ENT:AddHook("SettingChanged", "lamps", function(self, id, val)
        if id ~= "lamps-enabled" then return end

        if val and self.lamps == nil then
            self:CreateLamps()
        elseif not val and self.lamps then
            self:RemoveLamps()
        end
    end)

    ENT:AddHook("PostInitialize", "lamps", function(self)
        self:RunLampUpdate()
    end)

    ENT:AddHook("ToggleDoor", "lamps", function(self)
        self:RunLampUpdate()
    end)

    ENT:AddHook("PlayerEnter", "lamps", function(self)
        self:RunLampUpdate()
    end)

    ENT:AddHook("OnRemove", "lamps", function(self)
        self:RemoveLamps()
    end)
end

