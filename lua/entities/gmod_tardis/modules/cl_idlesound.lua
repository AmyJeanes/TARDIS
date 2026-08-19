-- Idle sound

---@class gmod_tardis
---@field idlesounds table<any, doors_managed_sound>

ENT:AddHook("Initialize", "idlesound", function(self)
    -- glua_ls upstream: empty {} rejected against the declared container field type -- https://github.com/Pollux12/gmod-glua-ls/issues/80
    self.idlesounds = {} --[[@as table<any, doors_managed_sound>]]
end)

ENT:AddHook("OnRemove", "idlesound", function(self)
    if self.idlesounds then
        for _,v in pairs(self.idlesounds) do
            v:Stop()
        end
    end
end)

ENT:AddHook("ExteriorChanged", "idlesound", function(self)
    if not self.idlesounds then return end
    for _,v in pairs(self.idlesounds) do
        v:Stop()
    end
    -- glua_ls upstream: empty {} rejected against the declared container field type -- https://github.com/Pollux12/gmod-glua-ls/issues/80
    self.idlesounds = {} --[[@as table<any, doors_managed_sound>]]
end)

ENT:AddHook("Think", "idlesound", function(self)
    local sounds = self.metadata.Exterior.Sounds.Idle
    if not sounds or not self.idlesounds then return end

    local play = self:GetPower() and not self:GetData("vortex")
        and TARDIS:GetSetting("idlesounds") and TARDIS:GetSetting("sound")
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
