-- This module handles two separate audio features:
-- 1. ExternalHum: The humming sound from the exterior shell when powered (using external_hum setting)
-- 2. LeakedInteriorHums: Interior hum sounds leaking through when doors are open (using interior_hum_leakage setting)

-- Calculate the ratio of interior to exterior sound volume for a seamless transition
local function CalculateInteriorToExteriorRatio(self)
    -- Only proceed if we have an interior with fallback data
    if not self.interior or not self.metadata.Interior.Fallback or not self.metadata.Interior.Fallback.pos then
        return 0.85 -- Default fallback value if we can't calculate
    end
    
    -- Get the distance from interior origin (where the sound is played) to the interior fallback position (door)
    local fallback_pos = self.metadata.Interior.Fallback.pos
    local distance_to_fallback = fallback_pos:Length() -- Distance from origin (0,0,0) to fallback
    
    -- Sound in Source engine attenuates based on distance
    -- We need to calculate a ratio that makes the exterior sound match what would be heard at the fallback position
    -- Standard sound level of 75 is approximately 5 meters (265 units)
    local sound_reference_distance = 265
    
    -- Calculate how much the interior sound attenuates at the fallback position
    -- Sound attenuates inversely with distance, so farther = quieter
    local ratio
    
    if distance_to_fallback <= 1 then
        -- If almost at origin, maintain 85% for safety
        ratio = 0.85
    else
        -- Calculate ratio based on distance and an adjustment factor
        -- The closer the fallback is to origin (smaller distance_to_fallback), the higher the ratio should be
        -- since the interior sound would be louder at fallback position
        ratio = sound_reference_distance / (distance_to_fallback * 3)
        
        -- Clamp to reasonable values (0.3 to 1.0)
        ratio = math.Clamp(ratio, 0.3, 1.0)
    end
    
    return ratio
end

ENT:AddHook("Initialize", "externalhum", function(self)
    -- Initialize the table for leaked interior hum sounds
    self.LeakedInteriorHums = {}
    
    -- Initialize with a default ratio
    self.InteriorToExteriorRatio = 0.85
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

ENT:AddHook("PostInitialize", "externalhum", function(self)
    -- Calculate the interior-to-exterior ratio if interior is available
    -- This only needs to be done once since the interior doesn't change during use
    if self.interior and IsValid(self.interior) then
        self.InteriorToExteriorRatio = CalculateInteriorToExteriorRatio(self)
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
-- This is separate from the ExternalHum feature and controlled by the interior_hum_leakage setting
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
    -- For a standard 5 meter distance but with stronger falloff
    local door_sound_level = 100 -- Higher value for faster falloff, still centered ~5 meters
    local volume_multiplier = TARDIS:GetSetting("interior_hum_leakage_volume") / 100
    
    -- Use the dynamically calculated ratio to match the interior sound volume
    -- This makes transitions between inside/outside seamless when walking through the door
    local interior_to_exterior_ratio = self.InteriorToExteriorRatio or 0.85
    
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

-- This Think hook handles two separate audio features:
-- 1. ExternalHum: The humming sound from the exterior shell when powered (using external_hum setting)
-- 2. LeakedInteriorHums: Interior hum sounds leaking through when doors are open (using interior_hum_leakage setting)
ENT:AddHook("Think", "externalhum", function(self)
    -- Part 1: Handle exterior hum sound
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
    
    -- Part 2: Regularly update the interior hum leakage status for when doors open/close
    UpdateInteriorHumLeakage(self)
end)