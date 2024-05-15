-- Power Interior

function ENT:GetPower()
    return self.exterior:GetPower()
end

ENT:AddHook("CanUseTardisControl", "power", function(self, control, ply)
    if not self:GetPower() and not control.power_independent then
        TARDIS:ErrorMessage(ply, "Common.PowerDisabledControl")
        return false
    end
end)

if SERVER then
    function ENT:TogglePower()
        self.exterior:TogglePower()
    end

    function ENT:SetPower(on)
        self.exterior:SetPower(on)
    end

    ENT:AddHook("PostInitialize","power-init", function(self)
        if self:GetData("power_disabled_first") then
            self:SetPower(false)
        end
    end)

    ENT:AddHook("PowerToggled", "interior-power", function(self, state)
        self:SendMessage("power-toggled", {state} )
    end)
else
    ENT:OnMessage("power-toggled", function(self, data, ply)
        local state = data[1]
        if TARDIS:GetSetting("sound") then
            local sound_on = self.metadata.Interior.Sounds.Power.On
            local sound_off = self.metadata.Interior.Sounds.Power.Off
            if TARDIS:GetExteriorEnt() == self.exterior then
                if not TARDIS:GetSetting("sound") then return end
                self:EmitSound(state and sound_on or sound_off)
            end
            local idle_sounds = self.metadata.Interior.Sounds.Idle or self.metadata.Interior.IdleSound
            if idle_sounds and self.idlesounds then
                for k,v in pairs(idle_sounds) do
                    if self.idlesounds[k] then
                        if state then
                            self.idlesounds[k]:Play()
                            self.idlesounds[k]:ChangeVolume(v.volume or 1,0)
                        else
                            self.idlesounds[k]:Stop()
                        end
                    end
                end
            end
        end
    end)

    ENT:AddHook("ShouldNotDrawScreen", "power", function(self)
        if not self:GetPower() then
            return true
        end
    end)

    ENT:AddHook("ShouldDrawBlackScreen", "power", function(self)
        if not self:GetPower() then
            return true
        end
    end)

    ENT:AddHook("ShouldDrawLight", "power", function(self,id,light)
        if (not self:GetPower()) and ((not light) or (not light.nopower)) then
            return false
        end
    end)

    ENT:AddHook("ShouldDrawLight", "interior-lights-blinking", function(self)
        if self:GetData("interior-lights-blinking") then
            return (math.Round(3 * CurTime()) % 2 ~= 0)
        end
    end)

end