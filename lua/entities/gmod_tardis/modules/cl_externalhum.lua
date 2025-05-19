-- Idle sound

ENT:AddHook("Initialize", "externalhum", function(self)
    -- Initialize the table for leaked interior hum sounds
    self.LeakedInteriorHums = {}
end)

ENT:AddHook("OnRemove", "externalhum", function(self)
    if self.ExternalHum then
        self.ExternalHum:Stop()
        self.ExternalHum = nil
    end
    if self.LeakedInteriorHums then
        for k, v in pairs(self.LeakedInteriorHums) do
            v:Stop()
            self.LeakedInteriorHums[k] = nil
        end
    end
end)

ENT:AddHook("ExteriorChanged", "externalhum", function(self)
    if self.ExternalHum then
        self.ExternalHum:Stop()
        self.ExternalHum = nil
    end
    if self.LeakedInteriorHums then
        for k, v in pairs(self.LeakedInteriorHums) do
            v:Stop()
            self.LeakedInteriorHums[k] = nil
        end
    end
end)

-- Function to update the interior hum leakage based on door state
local function UpdateInteriorHumLeakage(self)
    -- Only proceed if we have an interior
    if not IsValid(self.interior) then
        if self.LeakedInteriorHums then
            for k, v in pairs(self.LeakedInteriorHums) do
                v:Stop()
                self.LeakedInteriorHums[k] = nil
            end
        end
        return
    end
    
    local interior_hum_sounds = {}
    -- Get the interior hum sounds from metadata
    if self.metadata.Interior.Sounds and self.metadata.Interior.Sounds.Idle then
        interior_hum_sounds = self.metadata.Interior.Sounds.Idle
    elseif self.metadata.Interior.IdleSound then
        interior_hum_sounds = self.metadata.Interior.IdleSound
    end
    
    -- Calculate volume to match interior sound at doorway
    -- For a standard 5 meter (75 units) distance from door
    local door_sound_level = 75 -- Default sound level (about 5 meters)
    local volume_multiplier = TARDIS:GetSetting("interior_hum_leakage_volume") / 100
    
    -- Calculate a volume multiplier to match interior volume at door
    -- This makes the transition between inside/outside more seamless
    -- Typically sounds at a similar distance inside are slightly louder than outside because of enclosed space
    local interior_to_exterior_ratio = 0.85 -- Exterior sounds around 85% volume of interior sounds at similar distance
    
    if #interior_hum_sounds > 0 then
        -- Play all idle sounds simultaneously, just like interior does
        if TARDIS:GetSetting("interior_hum_leakage")
            and TARDIS:GetSetting("sound")
            and self:GetData("power-state")
            and not self:GetData("vortex")
            and self:DoorOpen(true) -- Only when doors are open
        then
            -- Loop through all idle sounds and play them
            for k, interior_hum_sound in pairs(interior_hum_sounds) do
                if interior_hum_sound and interior_hum_sound.path then
                    if not self.LeakedInteriorHums[k] then
                        self.LeakedInteriorHums[k] = CreateSound(self, interior_hum_sound.path)
                        self.LeakedInteriorHums[k]:Play()
                        
                        -- Limit sound range to about 5 meters
                        self.LeakedInteriorHums[k]:SetSoundLevel(door_sound_level)
                        
                        -- Apply volume settings with interior-to-exterior ratio for matching perceived volume
                        -- at doorway threshold, considering user's volume preference
                        local final_volume = (interior_hum_sound.volume or 1) * volume_multiplier * interior_to_exterior_ratio
                        self.LeakedInteriorHums[k]:ChangeVolume(final_volume, 0)
                    else
                        -- Update volume in case setting has changed
                        local final_volume = (interior_hum_sound.volume or 1) * volume_multiplier * interior_to_exterior_ratio
                        self.LeakedInteriorHums[k]:ChangeVolume(final_volume, 0)
                    end
                end
            end
            
            -- Cleanup any sounds that aren't in the current sounds list
            for k, v in pairs(self.LeakedInteriorHums) do
                local found = false
                for i, sound in pairs(interior_hum_sounds) do
                    if k == i then
                        found = true
                        break
                    end
                end
                
                if not found then
                    v:Stop()
                    self.LeakedInteriorHums[k] = nil
                end
            end
        else
            -- Stop all sounds if conditions aren't met
            for k, v in pairs(self.LeakedInteriorHums) do
                v:Stop()
                self.LeakedInteriorHums[k] = nil
            end
        end
    else
        -- No idle sounds configured, stop all playing sounds
        for k, v in pairs(self.LeakedInteriorHums) do
            v:Stop()
            self.LeakedInteriorHums[k] = nil
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