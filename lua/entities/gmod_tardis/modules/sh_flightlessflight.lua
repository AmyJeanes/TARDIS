-- Roleplay

---@api
function ENT:GetFlightlessFlight()
    return self:GetData("flightless", false)
end

if SERVER then
    ---@api
    ---@param on boolean
    function ENT:SetFlightlessFlight(on)
        local flightfirst = self:GetData("flight")
        if on then
            if not self:SetFlight(true) then return false end
        elseif not self:GetData("flightlessfirst", false) then
            self:SetFlight(false)
        end
        if self:GetFlight() then
            local phys = self:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableGravity(on)
            end
        end
        self:SetData("flightless", on, true)
        self:SetData("flightlessfirst", flightfirst)
        return true
    end

    ---@api
    function ENT:ToggleFlightlessFlight()
        return self:SetFlightlessFlight(not self:GetFlightlessFlight())
    end

    ENT:AddHook("ShouldTurnOffRotorwash", "flightless", function(self)
        if self:GetData("flightless", false) then
            return true
        end
    end)

    ENT:AddHook("ShouldTurnOffFlightPhysics", "flightless", function(self)
        if self:GetData("flightless", false) then
            return true
        end
    end)

    ENT:AddHook("ShouldTurnOffFloatPhysics", "flightless", function(self)
        if self:GetData("flightless", false) then
            return true
        end
    end)

    ENT:AddHook("ShouldPlayLandingSound", "flightless", function(self)
        if self:GetData("flightless", false) then
            return true
        end
    end)

    ENT:AddHook("ShouldAllowFalling", "flightless", function(self)
        if self:GetData("flightless", false) then
            return true
        end
    end)
else
    ENT:AddHook("ShouldTurnOffFlightSound", "flightless", function(self)
        if self:GetData("flightless", false) then
            return true
        end
    end)

    ENT:AddHook("ShouldTurnOffLight", "flightless", function(self)
        if self:GetData("flightless", false) and not TARDIS:GetSetting("extlight-alwayson") then
            return true
        end
    end)

    ENT:AddHook("ShouldNotPulseLight", "flightless", function(self)
        if self:GetData("flightless", false) then
            return true
        end
    end)
end
