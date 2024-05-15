-- Exterior light

function ENT:GetFlashLight()
    return self:GetData("flash-light-enabled", false)
end

if SERVER then
    function ENT:FlashLight(time)
        self:SendMessage("flash-light", { time })
    end

    function ENT:SetFlashLight(enabled)
        self:SetData("flash-light-enabled", enabled, true)
        return enabled
    end

    function ENT:ToggleFlashLight()
        return self:SetFlashLight(not self:GetFlashLight())
    end
else
    function ENT:FlashLight(time)
        self:SetData("flashuntil",CurTime()+time)
    end

    ENT:AddHook("ShouldTurnOnLight","light",function(self)
        if TARDIS:GetSetting("extlight-alwayson") ~= self:GetFlashLight() then
            return true
        end
        local flashuntil=self:GetData("flashuntil")
        if flashuntil then
            if CurTime()<flashuntil then
                return true
            else
                self:SetData("flashuntil",nil)
            end
        end
    end)

    ENT:OnMessage("flash-light", function(self, data, ply)
        self:FlashLight(data[1])
    end)

    ENT:AddHook("Initialize", "light", function(self)
        self.lightpixvis=util.GetPixelVisibleHandle()
    end)

    local mat=Material("models/drmatt/tardis/exterior/light")
    local size=64

    ENT:AddHook("Draw", "light", function(self)
        local light = self.metadata.Exterior.Light
        if not light or not light.enabled then return end

        local shouldon=self:CallHook("ShouldTurnOnLight")
        local shouldpulse=self:CallHook("ShouldPulseLight")
        local shouldoff=self:CallHook("ShouldTurnOffLight")

        if shouldon and (not shouldoff) then
            local col = light.color
            if self:GetData("warning") and light.warncolor ~= nil then
                col = light.warncolor
            end
            if TARDIS:GetSetting("extlight-override-color", self) then
                col = TARDIS:GetSetting("extlight-color", self)
            end
            if self.lightpixvis and (not wp.drawing) and (halo.RenderedEntity()~=self) then
                local pos=self:LocalToWorld(light.pos)
                local alpha = shouldpulse and (math.sin(CurTime() * 3.7) + 0.2) * (255 / 4) + (255 / 2) - 70 or 100
                render.SetMaterial(mat)
                local fallback=false

                if self:GetData("vortex",false) then
                    fallback=true
                end

                if fallback then
                    render.DrawSprite(pos, size, size, Color(col.r,col.g,col.b,alpha))
                else
                    local vis=util.PixelVisible(pos, 3, self.lightpixvis)*255
                    if vis>0 then
                        render.DrawSprite(pos, size, size, Color(col.r,col.g,col.b,math.min(vis,alpha)))
                    end
                end
            end
        end
    end)

    ENT:AddHook("Think", "light", function(self)
        local light = self.metadata.Exterior.Light
        if not (light and light.enabled and TARDIS:GetSetting("extlight-dynamic")) then return end

        local shouldon=self:CallHook("ShouldTurnOnLight")
        local shouldoff=self:CallHook("ShouldTurnOffLight")
        local shouldpulse=self:CallHook("ShouldPulseLight")

        local mult = shouldpulse and (1 + 0.1 * math.sin(CurTime() * 3.7)) or 1

        if shouldon and (not shouldoff) then
            local col = light.color
            if self:GetData("warning") and light.warncolor ~= nil then
                col = light.warncolor
            end
            if TARDIS:GetSetting("extlight-override-color", self) then
                col = TARDIS:GetSetting("extlight-color", self)
            end
            local size = TARDIS:GetSetting("extlight-size-dynamic", self)
            local dlight = DynamicLight( self:EntIndex() )
            if ( dlight ) then
                local c=Color(col.r,col.g,col.b)
                dlight.Pos = self:LocalToWorld(light.dynamicpos)
                dlight.r = c.r
                dlight.g = c.g
                dlight.b = c.b
                dlight.Brightness = light.dynamicbrightness
                dlight.Decay = 1500
                dlight.Size = light.dynamicsize * mult * size
                dlight.DieTime = CurTime() + 1
            end
        end
    end)
end