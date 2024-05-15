if SERVER then

    TARDIS.artron_values = {
        cost_demat = -540 / 144,
        cost_mat = -360 / 144,
        cost_full = -1200 / 144,
        cost_controls = {
            ["cloak"] = -720 / 144,
            ["physlock"] = -540 / 144,
            ["float"] = -270 / 144,
        },

        --Cost of certain controls and stuff:
        cost_hads = -180 / 144,
        cost_chameleon = -560 / 144,
        cost_fast_return = -360 / 144,
        cost_failed_demat = -80 / 144,

        -- every 1 second:
        spend_vortex_teleport = -32 / 144,
        spend_flight_static = -5 / 144,
        spend_flight_moving = -24 / 144,
        spend_flight_boost = -45 / 144,
        spend_flight_broken = -8 / 144,
        spend_cloak = -18 / 144,
        spend_cloak_handbrake = -8 / 144,

        -- every 1 second:
        handbrake_multiplier = 0.01,
        handbrake_multiplier_float = 0.005,

        -- every 5 (by default) seconds:
        increase_normal = 15 * 5 / 144,
        increase_damaged = 10 * 5 / 144,
        increase_broken = 6 * 5 / 144,
        increase_poweroff = 24 * 5 / 144,
        increase_float = 8 * 5 / 144,

        increase_engine_release = 720 / 144,
    }

    function ENT:SetArtron(value)
        local maxArtron = TARDIS:GetSetting("artron_energy_max")
        value = math.max(0, math.min(value, maxArtron))
        self:SetData("artron-val", value, true)
        if value == 0 then
            self:CallHook("ArtronDepleted")
        end
    end

    function ENT:AddArtron(value)
        local currentArtron = self:GetArtron()
        self:SetArtron(currentArtron + value)
    end

    ENT:AddHook("Initialize", "artron", function(self)
        local max = TARDIS:GetSetting("artron_energy_max")
        local start = TARDIS:GetSetting("artron_energy_start") -- 0, 0.25, 0.5, 0.75 or 1
        self:SetArtron(max * start)
    end)


    --
    -- Bad artron consequences
    --

    ENT:AddHook("ArtronDepleted", "teleport_and_poweroff", function(self)
        if not TARDIS:GetSetting("artron_energy") then return end

        if self:GetData("teleport") or self:GetData("vortex") then
            self:InterruptTeleport()
            return
        end
        if self:GetPower() then
            self:InterruptFlight()
            self:SetPower(false)
            for k,_ in pairs(self.occupants) do
                TARDIS:ErrorMessage(k, "Artron.Depleted")
            end
        end
    end)

    local function ArtronDematCheck(self)
        local fast = self:GetFastRemat()
        local artron = self:GetArtron()

        if self:CallHook("ShouldUpdateArtron") == false then return end

        if fast and artron < -TARDIS.artron_values.cost_full then
            return true
        end
        if not fast and artron < -TARDIS.artron_values.cost_demat then
            return true
        end
    end

    ENT:AddHook("ShouldFailDemat", "artron", function(self, force)
        if not TARDIS:GetSetting("artron_energy") then return end
        if self:GetData("hads-attempt") then return end
        if self:GetData("fastreturn") then return end

        if ArtronDematCheck(self) then
            return true
        end
    end)

    ENT:AddHook("ShouldFailMat", "artron", function(self, dest_pos, dest_ang)
        if not TARDIS:GetSetting("artron_energy") then return end
        if self:CallHook("ShouldUpdateArtron") == false then return end

        local fast = self:GetFastRemat()
        local artron = self:GetArtron()
        if not fast and artron < -TARDIS.artron_values.cost_mat then
            return true
        end

    end)

    ENT:AddHook("CanTogglePower", "artron", function(self, on)
        if not TARDIS:GetSetting("artron_energy") then return end
        if self:GetData("redecorate") then return end

        if self:GetArtron() <= 0 and self:GetPower() == false then
            return false
        end
    end)

    --
    -- Decreasing artron energy
    --

    ENT:AddHook("Think", "artron", function(self)
        if not TARDIS:GetSetting("artron_energy") then return end

        if self:CallHook("ShouldUpdateArtron") == false then return end

        -- if artron energy should decrease, it happens every second
        if CurTime() < self:GetData("artron_next_update_time", 0) then return end
        self:SetData("artron_next_update_time", CurTime() + 1)

        local power = self:GetPower()
        local vortex = self:GetData("vortex")
        local teleport = self:GetData("teleport")
        local flight = self:GetData("flight")
        local handbrake = self:GetHandbrake()
        local cloak = self:GetCloak()
        local float = self:GetData("floatfirst")
        local damaged = self:IsDamaged()
        local broken = self:IsBroken()
        local broken_flight = self:GetData("broken_flight")

        local change = 0

        if teleport then
            return
        elseif vortex then
            change = change + TARDIS.artron_values.spend_vortex_teleport
        elseif broken_flight then
            change = change + TARDIS.artron_values.spend_flight_broken
        elseif flight then
            if TARDIS:IsBindDown(self.pilot,"flight-forward")
                or TARDIS:IsBindDown(self.pilot,"flight-backward")
                or TARDIS:IsBindDown(self.pilot,"flight-right")
                or TARDIS:IsBindDown(self.pilot,"flight-rotate")
                or TARDIS:IsBindDown(self.pilot,"flight-left")
                or TARDIS:IsBindDown(self.pilot,"flight-rotate")
                or TARDIS:IsBindDown(self.pilot,"flight-up")
                -- we don't have flight-down here to allow landing
            then
                if TARDIS:IsBindDown(self.pilot,"flight-boost") then
                    change = change + TARDIS.artron_values.spend_flight_boost
                else
                    change = change + TARDIS.artron_values.spend_flight_moving
                end
            end

            if self:GetTracking() then
                local vel = self:GetVelocity():Length()
                if vel > 1500 then
                    change = change + TARDIS.artron_values.spend_flight_boost
                elseif vel > 200 then
                    change = change + TARDIS.artron_values.spend_flight_moving
                end
            end

            change = change + TARDIS.artron_values.spend_flight_static
        end
        if cloak then
            if handbrake then
                change = change + TARDIS.artron_values.spend_cloak_handbrake
            else
                change = change + TARDIS.artron_values.spend_cloak
            end
        end

        if change < 0 then
            self:AddArtron(change)
            return
        end

        if self:CallHook("CanIncreaseArtron") == false then return end
        if CurTime() < self:GetData("artron_next_increase_time", 0) then return end

        local frequency = TARDIS:GetSetting("artron_energy_charge_frequency")
        local increase_interval = handbrake and 1 or frequency

        self:SetData("artron_next_increase_time", CurTime() + increase_interval)

        local max = TARDIS:GetSetting("artron_energy_max")
        if handbrake and float then
            local mult = TARDIS.artron_values.handbrake_multiplier_float
            self:AddArtron(max * mult * 5 / frequency)
            return
        end
        if handbrake then
            local mult = TARDIS.artron_values.handbrake_multiplier
            self:AddArtron(max * mult * 5 / frequency)
            return
        end
        if not power then
            self:AddArtron(TARDIS.artron_values.increase_poweroff)
            return
        end
        if float then
            self:AddArtron(TARDIS.artron_values.increase_float)
            return
        end
        if damaged then
            self:AddArtron(TARDIS.artron_values.increase_damaged)
            return
        end
        if broken then
            self:AddArtron(TARDIS.artron_values.increase_broken)
            return
        end
        self:AddArtron(TARDIS.artron_values.increase_normal) -- default state
    end)

    ENT:AddHook("TardisControlUsed", "artron", function(self, control)
        if not TARDIS:GetSetting("artron_energy") then return end

        if TARDIS.artron_values.cost_controls[control] then
            self:AddArtron(TARDIS.artron_values.cost_controls[control])
        end
    end)

    ENT:AddHook("DematFailed", "artron", function(self)
        if not TARDIS:GetSetting("artron_energy") then return end

        if not ArtronDematCheck(self) then return end
        self:AddArtron(TARDIS.artron_values.cost_failed_demat)
    end)

    ENT:AddHook("DematStart", "artron", function(self)
        if not TARDIS:GetSetting("artron_energy") then return end
        if self:CallHook("ShouldUpdateArtron") == false then return end

        if self:GetData("fastreturn") then
            if self:GetArtron() < -TARDIS.artron_values.cost_fast_return then
                self:SetArtron(1)
                return
            end
            self:AddArtron(TARDIS.artron_values.cost_fast_return)
        elseif self:GetFastRemat() then
            self:AddArtron(TARDIS.artron_values.cost_full)
        else
            self:AddArtron(TARDIS.artron_values.cost_demat)
        end
    end)

    ENT:AddHook("MatStart", "artron", function(self)
        if not TARDIS:GetSetting("artron_energy") then return end
        if self:CallHook("ShouldUpdateArtron") == false then return end

        if self:GetFastRemat() ~= true then
            self:AddArtron(TARDIS.artron_values.cost_mat)
        end
    end)

    ENT:AddHook("HADSTrigger", "artron", function(self)
        if not TARDIS:GetSetting("artron_energy") then return end

        if self:GetArtron() < -TARDIS.artron_values.cost_hads then
            self:SetArtron(1)
            return
        end
        self:AddArtron(TARDIS.artron_values.cost_hads)
    end)

    ENT:AddHook("ExteriorChanged", "artron", function(self)
        if not TARDIS:GetSetting("artron_energy") then return end
        if self:GetData("teleport") then return end

        self:AddArtron(TARDIS.artron_values.cost_chameleon)
    end)

    ENT:AddHook("CanChangeExterior", "artron", function(self)
        if not TARDIS:GetSetting("artron_energy") then return end

        if self:GetArtron() + TARDIS.artron_values.cost_chameleon < 1 then
            return false,true,"Chameleon.FailReasons.NotEnoughArtron",true
        end
    end)

    ENT:AddHook("HandbrakeToggled", "artron", function(self, on)
        if on then
            self:SetData("artron_next_increase_time", CurTime() + 1)
        end
    end)

    ENT:AddHook("OnHealthDepleted", "artron", function(self, on)
        self:SetArtron(0)
    end)

    ENT:AddHook("SettingChanged", "maxartron-changed", function(self, id, val)
        if id ~= "artron_energy_max" then return end

        if self:GetArtron() > val then
            self:SetArtron(val)
        end
    end)

    --
    -- Emergency artron behaviour
    --
    function ENT:ForceAddArtron()
        self:Explode(30)
        if IsValid(self.interior) then
            self.interior:Explode(30)
            self.interior:EmitSound(self.metadata.Interior.Sounds.Damage.Artron)
        end
        self:AddArtron(TARDIS.artron_values.increase_engine_release)

        local decrease = math.random(53, 432) * self:GetHealthMax() / 1000
        self:AddHealth(-decrease)
    end

    function ENT:EngineReleaseVortexArtron()
        if not TARDIS:GetSetting("artron_energy") then return end
        if not TARDIS:GetSetting("health-enabled") then return false end

        if self:GetData("vortex") then
            self:ForceAddArtron()
            return true
        end
        return false
    end

    ENT:AddHook("HandleE2", "artron", function(self, name, e2, ...)
        local args = {...}
        if name == "RemoveArtron" and TARDIS:CheckPP(e2.player, self) then
            local removeAmount = args[1]
            local currentAmount = self:GetArtron()

            if removeAmount <= 0 then return currentAmount end

            if currentAmount - removeAmount <= 0 then
                self:SetArtron(0)
                return 0
            elseif removeAmount < currentAmount then
                self:SetArtron(currentAmount - removeAmount)
                return currentAmount - removeAmount
            end
        elseif name == "GetArtron" then
            return self:GetArtron()
        elseif name == "GetMaxArtron" then
            return TARDIS:GetSetting("artron_energy_max")
        end
    end)
end

function ENT:GetArtron()
    return self:GetData("artron-val", 0)
end
