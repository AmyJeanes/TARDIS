-- Idle sound - the shell's own ambient sound, the exterior twin of the interior's. Neither is a
-- counterpart of the other, so both simply carry through the doorway: this one is heard outside and
-- leaks in, the interior's is heard inside and leaks out.

ENT:AddHook("Initialize", "idlesound", function(self)
    self.idlesounds = {}
end)

ENT:AddHook("OnRemove", "idlesound", function(self)
    if self.idlesounds then
        for _,v in pairs(self.idlesounds) do
            v:Stop()
        end
    end
end)

-- A new shell has its own sounds, so drop the old one's and let Think read them fresh.
ENT:AddHook("ExteriorChanged", "idlesound", function(self)
    if not self.idlesounds then return end
    for _,v in pairs(self.idlesounds) do
        v:Stop()
    end
    self.idlesounds = {}
end)

ENT:AddHook("Think", "idlesound", function(self)
    local sounds = self.metadata.Exterior.Sounds.Idle
    if not sounds or not self.idlesounds then return end

    -- a managed loop is destroyed when stopped, so power has to gate it here rather than
    -- pausing a channel this hook would then restart
    local play = self:GetPower() and not self:GetData("vortex")
        and TARDIS:GetSetting("idlesounds") and TARDIS:GetSetting("sound")
    for k,v in pairs(sounds) do
        ---@cast v tardis_sound_entry -- glua_ls reads a loop variable's fields as nilable
        local idlesnd = self.idlesounds[k]
        if play then
            local entry = TARDIS:SoundEntry(v)
            if (not idlesnd or not idlesnd:IsAlive()) and entry then
                self.idlesounds[k] = Doors:PlaySound({ path = entry.path, ent = self, loop = true,
                    volume = entry.volume or 1, owner = self, tag = "idle" })
            end
        elseif idlesnd then
            idlesnd:Stop()
            self.idlesounds[k] = nil
        end
    end
end)
