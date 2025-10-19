-- Idle sound

ENT:AddHook("Initialize", "idlesound", function(self)
    if self.metadata.Interior.Sounds.Idle or self.metadata.Interior.IdleSound then
        self.idlesounds={}
    end
end)

ENT:AddHook("OnRemove", "idlesound", function(self)
    if self.idlesounds then
        for k,v in pairs(self.idlesounds) do
            v:Stop()
            v=nil
        end
    end
end)

ENT:AddHook("PlayerEnter", "idlesound", function(self)
    local sounds = self.metadata.Interior.Sounds.Idle or self.metadata.Interior.IdleSound
    local vol_setting = TARDIS:GetSetting("interior_hum_leakage") and (TARDIS:GetSetting("interior_hum_leakage_volume") / 100) or 0
    for k, snd in pairs(sounds) do
        local vol = snd.volume or 1
        local final_vol = vol * vol_setting
        if self.idlesounds[k] then
            self.idlesounds[k]:ChangeVolume(final_vol, 0)
            self.idlesounds[k]:ChangeVolume(vol, 0.3)
        end
    end
end)

ENT:AddHook("Think", "idlesound", function(self)
    local sounds = self.metadata.Interior.Sounds.Idle or self.metadata.Interior.IdleSound
    if sounds and self.idlesounds then
        for k,v in pairs(sounds) do
            if TARDIS:GetSetting("idlesounds") and TARDIS:GetSetting("sound") then
                if not self.idlesounds[k] then
                    self.idlesounds[k]=CreateSound(self, v.path)
                    self.idlesounds[k]:PlayEx(v.volume or 1, 100)
                end
            else
                if self.idlesounds[k] then
                    self.idlesounds[k]:Stop()
                    self.idlesounds[k]=nil
                end
            end
        end
    end
end)