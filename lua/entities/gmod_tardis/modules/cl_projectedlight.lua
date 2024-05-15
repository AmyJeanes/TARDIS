--Fake light bleeding

--Methods

function ENT:CalcLightBrightness(pos)
    local lightcolor = render.GetLightColor(pos):ToColor()
    local rm = 0.299*lightcolor.r
    local gm = 0.587*lightcolor.g
    local bm = 0.114*lightcolor.b
    local luminance = rm + gm + bm
    return luminance
end

function ENT:PickProjectedLightColor()
    local override = TARDIS:GetSetting("extprojlight-override-color")
    if override then return TARDIS:GetSetting("extprojlight-color") end

    local warning = self:GetData("warning",false)

    local pl = self.metadata.Exterior.ProjectedLight
    local ld = self.interior.light_data
    local int_color_data = ld and ld.main or self.metadata.Interior.Light
    local pickedcolor

    if warning then
        pickedcolor = pl.warncolor or int_color_data.warn_color
    end

    pickedcolor = pickedcolor or pl.color or int_color_data.color

    if pl.baselightmix > 0 and IsValid(self.interior) then
        local int_base_light_color = self.interior:GetBaseLightColor()

        local mix = pl.baselightmix
        pickedcolor = Color(
            pickedcolor.r * (1 - mix) + int_base_light_color.r * mix,
            pickedcolor.g * (1 - mix) + int_base_light_color.g * mix,
            pickedcolor.b * (1 - mix) + int_base_light_color.b * mix
        )
    end

    return pickedcolor
end

function ENT:PickProjectedLightBrightness()
    local override = TARDIS:GetSetting("extprojlight-override-brightness")
    return override and TARDIS:GetSetting("extprojlight-brightness") or self.metadata.Exterior.ProjectedLight.brightness
end

function ENT:PickProjectedLightDistance()
    local override = TARDIS:GetSetting("extprojlight-override-distance")
    return override and TARDIS:GetSetting("extprojlight-distance") or self.metadata.Exterior.ProjectedLight.farz
end

function ENT:CreateProjectedLight()
    if self.projectedlight then return end
    local pl = ProjectedTexture()
    pl:SetTexture(self.metadata.Exterior.ProjectedLight.texture)
    pl:SetVerticalFOV(self.metadata.Exterior.ProjectedLight.vertfov or self.metadata.Exterior.Portal.height)
    pl:SetHorizontalFOV(self.metadata.Exterior.ProjectedLight.horizfov or self.metadata.Exterior.Portal.width+10)
    pl:SetEnableShadows(true)
    self.projectedlight = pl
end

function ENT:RemoveProjectedLight()
    self:SetData("pl-color",nil)
    self:SetData("pl-brightness",nil)
    self:SetData("pl-distance",nil)
    if self.projectedlight then
        self.projectedlight:Remove()
        self.projectedlight = nil
    end
end

function ENT:UpdateProjectedLight()
    if not IsValid(self.projectedlight) or not self.projectedlight then return end
    local color = self:PickProjectedLightColor()
    if color~=self:GetData("pl-color",false) then
        self:SetData("pl-color",color)
        self.projectedlight:SetColor(color)
    end
    local brightness = self:PickProjectedLightBrightness()
    if brightness~=self:GetData("pl-brightness",false) then
        self:SetData("pl-brightness",brightness)
        self.projectedlight:SetBrightness(brightness)
    end
    local distance = self:PickProjectedLightDistance()
    if distance~=self:GetData("pl-distance",false) then
        self:SetData("pl-distance",distance)
        self.projectedlight:SetFarZ(distance)
    end
    self.projectedlight:SetPos(self:LocalToWorld(self.metadata.Exterior.ProjectedLight.offset))
    self.projectedlight:SetAngles(self:GetAngles())
    self.projectedlight:Update()
end

--Hooks

ENT:AddHook("OnRemove", "projectedlight", function(self)
    if IsValid(self.projectedlight) then
        self.projectedlight:Remove()
    end
end)

ENT:AddHook("ShouldDrawProjectedLight", "projectedlight", function(self)
    return self:DoorOpen(true)
end)

ENT:AddHook("ShouldNotDrawProjectedLight","projectedlight",function(self)
    if not TARDIS:GetSetting("extprojlight-enabled") then return true end
    if not IsValid(self.interior) then return true end
    if self:GetData("vortex",false) == true then return true end
    if not self.interior.light_data or not self.interior.light_data.main then return true end
end)

ENT:AddHook("Think", "projectedlight", function(self)
    if not self.interior then return end
    local shouldon = self:CallHook("ShouldDrawProjectedLight")
    local shouldoff = self:CallHook("ShouldNotDrawProjectedLight")

    if shouldon and (not shouldoff) then
        if (not self.projectedlight) or (not IsValid(self.projectedlight)) then
            self:CreateProjectedLight()
        end
        self:UpdateProjectedLight()
    elseif self.projectedlight then
        self:RemoveProjectedLight()
    end
end)