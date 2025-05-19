-- Flight

ENT:AddHook("OnRemove", "flight", function(self)
    if self.flightsound then
        self.flightsound:Stop()
        self.flightsound=nil
    end
end)

function ENT:ChooseFlightSound()
    local sounds_int = self.metadata.Interior.Sounds
    local sounds_ext = self.metadata.Exterior.Sounds
    local ext = self.exterior
    local current_sound

    if self:GetData("broken_flight") then
        current_sound = sounds_int.FlightLoopBroken or sounds_int.FlightLoopDamaged
            or sounds_ext.FlightLoopBroken
        -- if the interior has its own damaged sound specified,
        -- we prefer it to exterior's broken sound for this case

        self.flightsounddamaged = false
        self.flightsoundbroken = true
    elseif self.exterior:IsLowHealth() then
        current_sound = sounds_int.FlightLoopDamaged or sounds_ext.FlightLoopDamaged
        self.flightsounddamaged = true
        self.flightsoundbroken = false
    else
        current_sound = sounds_int.FlightLoop or sounds_ext.FlightLoop
        self.flightsounddamaged = false
        self.flightsoundbroken = false
    end
    self.flightsound = CreateSound(self, current_sound)
end

local function IsFlightSoundWrong(self)
    if self.flightsoundbroken ~= self:GetData("broken_flight", false) then return true end
    if self.flightsounddamaged ~= (self.exterior:IsLowHealth() and not self:GetData("broken_flight")) then return true end
    return false
end

local function ShouldPlayFlightSounds(self)
    if not TARDIS:GetSetting("sound") then return false end
    if not TARDIS:GetSetting("flight-internalsound") then return false end
    if self:CallHook("ShouldTurnOffFlightSound") then return false end
    return true
end

ENT:AddHook("Think", "flight", function(self)
    if self:GetData("flight") and ShouldPlayFlightSounds(self) then
        if self.flightsound and self.flightsound:IsPlaying() then
            local p=math.Clamp(self.exterior:GetVelocity():Length()/250,0,15)
            self.flightsound:ChangePitch(95+p,0.1)
            self.flightsound:ChangeVolume(0.4)

            if IsFlightSoundWrong(self) then
                self.flightsound:Stop()
                self:ChooseFlightSound()
                self.flightsound:Play()
            end
        else
            self:ChooseFlightSound()
            self.flightsound:Play()
        end
    elseif self.flightsound then
        self.flightsound:Stop()
        self.flightsound=nil
    end
end)
