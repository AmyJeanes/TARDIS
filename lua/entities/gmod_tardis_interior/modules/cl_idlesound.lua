-- Idle sound

---@class gmod_tardis_interior
---@field idlesounds table<any, doors_managed_sound>

ENT:AddHook("Initialize", "idlesound", function(self)
    if self.metadata.Interior.Sounds.Idle or self.metadata.Interior.IdleSound then
        -- glua_ls upstream: empty {} rejected against the declared container field type -- https://github.com/Pollux12/gmod-glua-ls/issues/80
        self.idlesounds={} --[[@as table<any, doors_managed_sound>]]
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

    local play = self:GetPower() and TARDIS:GetSetting("idlesounds") and TARDIS:GetSetting("sound")
    for k,v in pairs(sounds) do
        local idlesnd = self.idlesounds[k]
        if play then
            local entry = TARDIS:SoundEntry(v)
            if (not idlesnd or not idlesnd:IsAlive()) and entry then
                self.idlesounds[k] = self:PlaySound({ path = entry.path, loop = true, volume = entry.volume or 1, tag = "idle" })
            end
        elseif idlesnd then
            idlesnd:Stop()
            self.idlesounds[k] = nil
        end
    end
end)
