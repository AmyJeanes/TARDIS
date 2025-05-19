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

-- Function to update the interior hum leakage based on door state
local function UpdateInteriorHumLeakage(self)
    -- Only proceed if we have an interior
    if not IsValid(self.interior) then
        if self.LeakedInteriorHum then
            self.LeakedInteriorHum:Stop()
            self.LeakedInteriorHum = nil
        end
        return
    end
    
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
                
                -- Limit sound range to about 5 meters (75 is approximately 5 meters in Source units)
                self.LeakedInteriorHum:SetSoundLevel(75)
                
                -- Apply the volume setting (percentage of original volume)
                local volume_multiplier = TARDIS:GetSetting("interior_hum_leakage_volume") / 100
                self.LeakedInteriorHum:ChangeVolume((interior_hum_sound.volume or 1) * volume_multiplier, 0)
            else
                -- Update volume in case setting has changed
                local volume_multiplier = TARDIS:GetSetting("interior_hum_leakage_volume") / 100
                self.LeakedInteriorHum:ChangeVolume((interior_hum_sound.volume or 1) * volume_multiplier, 0)
            end
        elseif self.LeakedInteriorHum then
            self.LeakedInteriorHum:Stop()
            self.LeakedInteriorHum = nil
        end
    end
end

-- Update the interior hum leak whenever doors are toggled
ENT:AddHook("ToggleDoorReal", "externalhum", function(self, open)
    UpdateInteriorHumLeakage(self)
end)

-- Update the interior hum leak when settings change
ENT:AddHook("SettingChanged", "externalhum", function(self, id, value)
    -- If relevant settings change, update the sound
    if id == "interior_hum_leakage" or id == "interior_hum_leakage_volume" or id == "sound" then
        UpdateInteriorHumLeakage(self)
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
    
    -- Regularly update the interior hum leakage status in Think for any other state changes
    UpdateInteriorHumLeakage(self)
end)