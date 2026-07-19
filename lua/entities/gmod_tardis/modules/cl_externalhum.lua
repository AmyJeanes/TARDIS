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
        if not self.ExternalHum and hum_sound.path then
            self.ExternalHum = Doors:PlaySound({ path = hum_sound.path, ent = self, loop = true,
                volume = hum_sound.volume or 1, owner = self, tag = "hum" })
        end
    elseif self.ExternalHum then
        self.ExternalHum:Stop()
        self.ExternalHum = nil
    end
end)
