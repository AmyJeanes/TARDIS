-- This module handles two separate audio features:
-- 1. ExternalHum: The humming sound from the exterior shell when powered (using external_hum setting)
-- 2. LeakedInteriorHums: Interior hum sounds leaking through when doors are open (using interior_hum_leakage setting)

ENT:AddHook("Initialize", "externalhum", function(self)
    self.LeakedInteriorHums    = {}
    self.InteriorToExteriorRatio = 1.0
end)

ENT:AddHook("PostInitialize", "externalhum", function(self)
    if not IsValid(self.interior) then return end 

    local portal = self.metadata.Interior and self.metadata.Interior.Portal
    if not portal or not portal.pos then
        return 1
    end

    local dist = portal.pos:Length()
    if dist < 1 then
        return 1
    end

    -- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/sp/src/public/soundflags.h#L76
    local attenuation = 0.8 -- default attenuation for sound level 75
    local maxDistance = attenuation * 1000

    local gain = math.Clamp(1 - (dist / maxDistance), 0, 1)

    self.InteriorToExteriorRatio = gain
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
end)

-- Fade out the interior hums to the configured volume when the player exits
ENT:AddHook("PlayerExit", "externalhum", function(self, ply)
    if ply ~= LocalPlayer() then return end
    if not TARDIS:GetSetting("interior_hum_leakage") then return end
    local sounds = self.metadata.Interior.Sounds.Idle or self.metadata.Interior.IdleSound
    if not sounds then return end
    local ratio = self.InteriorToExteriorRatio or 1.0
    local vol_setting = TARDIS:GetSetting("interior_hum_leakage_volume") / 100
    for k, snd in pairs(sounds) do
        local vol = snd.volume or 1
        local vol_with_ratio = vol * ratio
        local final_vol = vol_with_ratio * vol_setting
        local hum = self.LeakedInteriorHums[k]
        if hum then
            hum:SetVolume(vol_with_ratio)
            hum:SetVolume(final_vol, 0.3)
        end
    end
end)

 ENT:AddHook("SettingChanged", "externalhum", function(self, id, val)
    if id ~= "interior_hum_leakage_volume" then return end

    local sounds = self.metadata.Interior.Sounds.Idle or self.metadata.Interior.IdleSound
    if not sounds then return end

    local vol_setting = val / 100
    local ratio = self.InteriorToExteriorRatio or 1.0

    for k, snd in pairs(sounds) do
        local hum = self.LeakedInteriorHums[k]
        if hum then
            hum:SetVolume((snd.volume or 1) * vol_setting * ratio)
        end
    end
end)

-- This Think hook handles two separate audio features:
-- 1. ExternalHum: The humming sound from the exterior shell when powered (using external_hum setting)
-- 2. LeakedInteriorHums: Interior hum sounds leaking through when doors are open (using interior_hum_leakage setting)
ENT:AddHook("Think", "externalhum", function(self)
    -- Part 1: Handle exterior hum sound
    local hum_sound = self.metadata.Exterior.Sounds.Hum
    local hum_sound_path
    if hum_sound then
        hum_sound_path = hum_sound.path
        if TARDIS:GetSetting("external_hum")
            and TARDIS:GetSetting("sound")
            and self:GetData("power-state")
            and not self:GetData("vortex")
        then
            if not self.ExternalHum and hum_sound_path then
                self.ExternalHum = Doors:PlaySound({ path = hum_sound_path, ent = self, loop = true,
                    volume = hum_sound.volume or 1, owner = self, tag = "hum" })
            end
        elseif self.ExternalHum then
            self.ExternalHum:Stop()
            self.ExternalHum=nil
        end
    end

    -- Part 2: Regularly update the interior hum leakage status for when doors open/close
    local sounds = self.metadata.Interior.Sounds.Idle or self.metadata.Interior.IdleSound
    if not sounds then return end

    if #sounds > 0
       and TARDIS:GetSetting("interior_hum_leakage")
       and TARDIS:GetSetting("sound")
       and self:GetData("power-state")
       and not self:GetData("vortex")
       and self:DoorOpen(true)
    then
        local vol_setting = TARDIS:GetSetting("interior_hum_leakage_volume") / 100
        local ratio = self.InteriorToExteriorRatio or 1.0

        local ext_portal = self.portals and self.portals.exterior
        local emitter = (IsValid(ext_portal) and ext_portal) or self

        for k, snd in pairs(sounds) do
            ---@cast snd tardis_sound_entry -- glua_ls reads a loop variable's fields as nilable
            if snd.path ~= hum_sound_path and not self.LeakedInteriorHums[k] then
                self.LeakedInteriorHums[k] = Doors:PlaySound({ path = snd.path, ent = emitter,
                    loop = true, volume = (snd.volume or 1) * vol_setting * ratio,
                    owner = self, tag = "hum_leak" })
            end
        end

        for k, v in pairs(self.LeakedInteriorHums) do
            if not sounds[k] then
                v:Stop()
                self.LeakedInteriorHums[k] = nil
            end
        end
    else
        for _, v in pairs(self.LeakedInteriorHums) do v:Stop() end
        self.LeakedInteriorHums = {}
    end
end)
