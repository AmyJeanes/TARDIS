-- Spacebuild

ENT:AddHook("PostInitialize", "spacebuild", function(self)
    if not (CAF and CAF.GetAddon("Spacebuild")) then
        return
    end

    local center, radius = self:GetSphere()
    self.spacebuild_env = ents.Create("base_cube_environment")
    self.spacebuild_env:SetModel("models/props_lab/huladoll.mdl")
    self.spacebuild_env:SetPos(self:LocalToWorld(center))
    self.spacebuild_env:SetAngles(self:GetAngles())
    self.spacebuild_env:SetRenderMode(RENDERMODE_NONE)
    self.spacebuild_env:Spawn()
    self.spacebuild_env:Activate()

    self.spacebuild_env:CreateEnvironment(self, radius)

    -- override functions on the cube environment to the simpler base ones
    local baseEnt = scripted_ents.Get("base_sb_environment")
    self.spacebuild_env.OnEnvironment = baseEnt.OnEnvironment -- uses radius like the exit distance
    self.spacebuild_env.GetTemperature = baseEnt.GetTemperature -- ignores sunburn damage

    self:SetData("spacebuild", true)

    self:UpdateSpacebuildEnvironment()
end)

function ENT:UpdateSpacebuildEnvironment()
    if not IsValid(self.spacebuild_env) then
        return
    end

    local gravity, atmosphere, pressure, temperature, o2per, co2per, nper, hper, emptyper
    if self:GetPower() or (not self.exterior.environment) then
        -- earth-like atmosphere
        gravity = 1
        atmosphere = 1
        pressure = 1
        temperature = 295
        o2per = 21
        co2per = 0.45
        nper = 78
        hper = 0.55
        emptyper = 0
    elseif self.exterior.environment.sbenvironment then
        -- spacebuild bug: the GetX functions do not work on all environments so we have to get them directly
        local sbenv = self.exterior.environment.sbenvironment
        gravity = sbenv.gravity
        atmosphere = sbenv.atmosphere
        pressure = sbenv.pressure
        temperature = sbenv.temperature
        o2per = sbenv.air.o2per
        co2per = sbenv.air.co2per
        nper = sbenv.air.nper
        hper = sbenv.air.hper
        if sbenv.air.max == 0 then
            emptyper = 0
        else
            emptyper = (sbenv.air.empty / sbenv.air.max) * 100
        end
    else
        -- if there is no sbenvironment then we can use the GetX functions
        local env = self.exterior.environment
        gravity = env:GetGravity()
        atmosphere = env:GetAtmosphere()
        pressure = env:GetPressure()
        temperature = env:GetTemperature()
        o2per = env:GetO2Percentage()
        co2per = env:GetCO2Percentage()
        nper = env:GetNPercentage()
        hper = env:GetHPercentage()
        emptyper = env:GetEmptyAirPercentage()
    end

    self.spacebuild_env:UpdateEnvironment(nil, gravity, atmosphere, pressure, temperature, o2per, co2per, nper, hper)
    self.spacebuild_env.sbenvironment.atmosphere = atmosphere -- spacebuild bug: this value is not actually updated by UpdateEnvironment
end

function ENT:UpdateSpacebuildEnvironmentAir()
    if not IsValid(self.spacebuild_env) then
        return
    end

    local volume = self.spacebuild_env:GetVolume() / 1000
    local intenv = self.spacebuild_env.sbenvironment
    intenv.air.o2 = math.Round(intenv.air.o2per * 5 * volume * intenv.atmosphere)
    intenv.air.co2 = math.Round(intenv.air.co2per * 5 * volume * intenv.atmosphere)
    intenv.air.n = math.Round(intenv.air.nper * 5 * volume * intenv.atmosphere)
    intenv.air.h = math.Round(intenv.air.hper * 5 * volume * intenv.atmosphere)
    intenv.air.empty = math.Round(intenv.air.emptyper * 5 * volume * intenv.atmosphere)
    intenv.air.max = math.Round(100 * 5 * volume * intenv.atmosphere)
end

ENT:AddHook("PowerToggled", "spacebuild", function(self, on)
    self:UpdateSpacebuildEnvironment()
end)

ENT:AddHook("Think", "spacebuild", function(self)
    if not self:GetData("spacebuild", false) then
        return
    end

    if self.exterior.environment ~= self.exterior.environment_old then
        self:UpdateSpacebuildEnvironment()
        self.exterior.environment_old = self.exterior.environment
    end

    self:UpdateSpacebuildEnvironmentAir()
end)
