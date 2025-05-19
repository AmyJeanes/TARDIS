-- Idle sound

ENT:AddHook("OnRemove", "externalhum", function(self)
    if self.ExternalHum then
        self.ExternalHum:Stop()
        self.ExternalHum = nil
    end
    if self.LeakedInteriorHum then
        self.LeakedInteriorHum:Stop()
        self.LeakedInteriorHum = nil
    end
end)

ENT:AddHook("ExteriorChanged", "externalhum", function(self)
    if self.ExternalHum then
        self.ExternalHum:Stop()
        self.ExternalHum = nil
    end
    if self.LeakedInteriorHum then
        self.LeakedInteriorHum:Stop()
        self.LeakedInteriorHum = nil
    end
end)

ENT:AddHook("Think", "externalhum", function(self)
    local hum_sound = self.metadata.Exterior.Sounds.Hum
    if hum_sound then
        if TARDIS:GetSetting("external_hum")
            and TARDIS:GetSetting("sound")
            and self:GetData("power-state")
            and not self:GetData("vortex")
        then
            if not self.ExternalHum then
                self.ExternalHum = CreateSound(self, hum_sound.path)
                self.ExternalHum:Play()
                self.ExternalHum:ChangeVolume(hum_sound.volume or 1,0)
            end
        elseif self.ExternalHum then
            self.ExternalHum:Stop()
            self.ExternalHum=nil
        end
    end
    
    -- Handle interior hum leakage when doors are open
    if IsValid(self.interior) then
        local interior_hum_sound
        -- Get the interior hum sound from metadata
        if self.metadata.Interior.Sounds and self.metadata.Interior.Sounds.Idle then
            interior_hum_sound = self.metadata.Interior.Sounds.Idle[1]
        elseif self.metadata.Interior.IdleSound then
            interior_hum_sound = self.metadata.Interior.IdleSound[1]
        end
        
        if interior_hum_sound then
            if TARDIS:GetSetting("interior_hum_leakage")
                and TARDIS:GetSetting("sound")
                and self:GetData("power-state")
                and not self:GetData("vortex")
                and self:DoorOpen(true) -- Only when doors are open
            then
                if not self.LeakedInteriorHum then
                    self.LeakedInteriorHum = CreateSound(self, interior_hum_sound.path)
                    self.LeakedInteriorHum:Play()
                    
                    -- Apply the volume setting (percentage of original volume)
                    local volume_multiplier = TARDIS:GetSetting("interior_hum_leakage_volume") / 100
                    self.LeakedInteriorHum:ChangeVolume((interior_hum_sound.volume or 1) * volume_multiplier, 0)
                end
            elseif self.LeakedInteriorHum then
                self.LeakedInteriorHum:Stop()
                self.LeakedInteriorHum = nil
            end
        end
    end
end)