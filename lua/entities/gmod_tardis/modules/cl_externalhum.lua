-- The shell's own humming sound, played from the exterior while it has power.
--
-- Interior hums used to be leaked out here as a second, independent copy of each one, which drifted
-- against the original - measured over a second apart on the same file, so crossing the threshold handed
-- you a different copy at a different point in the loop. Leaking is now a property of the doorway rather
-- than a feature maintained here, so the interior's own hum is simply heard through it, and the volume
-- setting reaches it via GetCrossBoundaryVolume.

ENT:AddHook("OnRemove", "externalhum", function(self)
    if self.ExternalHum then
        self.ExternalHum:Stop()
        self.ExternalHum = nil
    end
end)

ENT:AddHook("ExteriorChanged", "externalhum", function(self)
    if self.ExternalHum then
        self.ExternalHum:Stop()
        self.ExternalHum = nil
    end
end)

ENT:AddHook("Think", "externalhum", function(self)
    local hum_sound = self.metadata.Exterior.Sounds.Hum
    if not hum_sound then return end
    if TARDIS:GetSetting("external_hum")
        and TARDIS:GetSetting("sound")
        and self:GetData("power-state")
        and not self:GetData("vortex")
    then
        local entry = TARDIS:SoundEntry(hum_sound)
        if not self.ExternalHum and entry then
            self.ExternalHum = Doors:PlaySound({ path = entry.path, ent = self, loop = true,
                volume = entry.volume or 1, owner = self, tag = "hum",
                pair = "hum", through_doors = entry.through_doors })
        end
    elseif self.ExternalHum then
        self.ExternalHum:Stop()
        self.ExternalHum = nil
    end
end)
