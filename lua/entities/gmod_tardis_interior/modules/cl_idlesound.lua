-- Idle sound

ENT:AddHook("Initialize", "idlesound", function(self)
    if self.metadata.Interior.Sounds.Idle or self.metadata.Interior.IdleSound then
        self.idlesounds={}
    end
end)

ENT:AddHook("OnRemove", "idlesound", function(self)
    if self.idlesounds then
        for _,v in pairs(self.idlesounds) do
            v:Stop()
        end
    end
end)

ENT:AddHook("Think", "idlesound", function(self)
    local sounds = self.metadata.Interior.Sounds.Idle or self.metadata.Interior.IdleSound
    if not sounds or not self.idlesounds then return end

    -- a managed loop is destroyed when stopped, so power has to gate it here rather than
    -- pausing a channel this hook would then restart
    local play = self:GetPower() and TARDIS:GetSetting("idlesounds") and TARDIS:GetSetting("sound")
    for k,v in pairs(sounds) do
        ---@cast v tardis_sound_entry -- glua_ls reads a loop variable's fields as nilable
        local idlesnd = self.idlesounds[k]
        if play then
            if not idlesnd then
                self.idlesounds[k] = Doors:PlaySound({ path = v.path, ent = self, loop = true,
                    volume = v.volume or 1, owner = self.exterior, tag = "idle" })
            end
        elseif idlesnd then
            idlesnd:Stop()
            self.idlesounds[k] = nil
        end
    end
end)