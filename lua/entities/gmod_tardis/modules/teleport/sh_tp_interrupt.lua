-- Teleport interrupting

function ENT:GetTeleportInterrupted()
    return self:GetData("teleport-interrupted", false)
end

function ENT:GetTeleportInterruptedTimeRemaining(round)
    local time = CurTime() - self:GetData("teleport-interrupt-time", 0)
    if round then
        time = math.ceil(time)
    end
    return 10 - time
end

if SERVER then
    function ENT:InterruptTeleport(callback)
        if not self:GetData("teleport", false) and not self:GetData("vortex", false) then return end

        local was_demating = self:GetData("demat", false)

        self:SetData("teleport-interrupt-fade", nil, true)

        local door_ok = true
        self:CloseDoor(function(state)
            if state then door_ok = false end
        end)
        if not door_ok then
            if callback then callback(false) end
            return
        end

        local pos = self:GetPos()
        local ang = self:GetAngles()

        if self:GetData("vortex", false) then
            pos = self:GetRandomLocation(false) or pos
        end

        self:ChangePosition(pos, ang, true)

        self:SetData("demat", false, true)
        self:SetData("fastreturn",false)
        self:SetDestination()
        self:SetData("vortex", false, true)
        self:SetSolid(SOLID_VPHYSICS)

        self:StopMat()
        self:SendMessage("stop_mat")

        self:SendMessage("interrupt-teleport")
        self:CallHook("InterruptTeleport")

        if not was_demating then
            self:Explode()
            if IsValid(self.interior) then
                self.interior:Explode(20)
            end

            self:Timer("interrupt_teleport", 1, function()
                self:Explode()
                if IsValid(self.interior) then
                    self.interior:Explode(20)
                end
            end)

            self:ChangeHealth(self:GetHealth() * math.random(85, 95) * 0.01)
            self:SetPower(false)
            self:SetData("power-lastflight", self:GetData("prevortex-flight", false), true)
            self:SetFloat(false)
            self:SetData("teleport-interrupted", true, true)
            self:SetData("teleport-interrupt-time", CurTime(), true)
            self:SetData("teleport-interrupt-effects", true, true)
        else
            self:SetData("teleport-interrupt-fade", true, true)
            self:CallCommonHook("DematInterrupted")
            self:CallClientCommonHook("DematInterrupted")
        end
    end

    ENT:AddHook("OnHealthDepleted", "tp_interrupt", function(self)
        if self:GetData("teleport", false) or self:GetData("vortex", false) then
            self:InterruptTeleport()
        end
    end)

    ENT:AddHook("CanIncreaseArtron", "tp_interrupt", function(self)
        if self:GetData("teleport-interrupted") then
            return false
        end
    end)

    ENT:AddHook("InterruptTeleport", "cancel_mat", function(self)
        self:CancelTimer("matdelay")
    end)

    ENT:AddHook("CanTogglePower", "tp_interrupt", function(self, on)
        if on and self:GetData("teleport-interrupted", false) then
            return false, "Controls.Power.FailedToggle.Interrupted", self:GetTeleportInterruptedTimeRemaining(true)
        end
    end)

    function ENT:EngineReleaseFreePower()
        if not self:GetData("teleport-interrupted", false) then return end

        self:Explode()
        self.interior:Explode(20)

        self:Timer("interrupt_teleport", 1, function()
            self:Explode()
            self.interior:Explode(20)
        end)

        self:SetData("teleport-interrupted", false, true)
    end
else
    function ENT:StopTeleportSounds()
        local ext = self.metadata.Exterior.Sounds.Teleport
        local int = self.metadata.Interior.Sounds.Teleport

        self:StopSound(ext.demat_damaged)
        self:StopSound(ext.demat)
        self:StopSound(ext.demat_fail)
        self:StopSound(ext.mat_damaged)
        self:StopSound(ext.mat)
        self:StopSound(ext.fullflight)
        self:StopSound(ext.fullflight_damaged)

        self.interior:StopSound(int.demat_damaged or ext.demat_damaged)
        self.interior:StopSound(int.demat or ext.demat)
        self.interior:StopSound(int.demat_fail or ext.demat_fail)
        self.interior:StopSound(int.mat_damaged or ext.mat_damaged)
        self.interior:StopSound(int.mat or ext.mat)
        self.interior:StopSound(int.fullflight or ext.fullflight)
        self.interior:StopSound(int.fullflight_damaged or ext.fullflight_damaged)

        if self.interior.dematfailsound then
            self.interior.dematfailsound:Stop()
            self.interior.dematfailsound = nil
        end
    end

    ENT:OnMessage("interrupt-teleport", function(self, data, ply)
        self:StopTeleportSounds()
        if TARDIS:GetSetting("teleport-sound") and TARDIS:GetSetting("sound") then
            local ext = self.metadata.Exterior.Sounds.Teleport
            local int = self.metadata.Interior.Sounds.Teleport
            self:EmitSound(ext.interrupt)
            self.interior:EmitSound(int.interrupt or ext.interrupt)
        end
    end)
end

ENT:AddHook("Think", "tp_interrupt", function(self)
    if not self:GetData("teleport-interrupted", false) then return end

    local timediff = CurTime() - self:GetData("teleport-interrupt-time", 0)

    if timediff > 6 and timediff < 6.2 and self:GetData("teleport-interrupt-effects", false) then
        self:SetData("teleport-interrupt-effects", false, true)
    end

    local showeffects = (CLIENT and self:GetData("teleport-interrupt-effects", false)
            and LocalPlayer():GetTardisData("exterior") == self
            and (not LocalPlayer():GetTardisData("thirdperson"))
            and TARDIS:GetSetting("breakdown-effects"))

    if showeffects then
        if math.Round(10 * CurTime()) % 2 == 0 then
            self:InteriorSparks(1)
        end
        if timediff < 0.1 or (timediff > 2 and timediff < 2.1)
            or (timediff > 2.6 and timediff < 2.7)
        then
            self:InteriorExplosion()
        end
    end

    if timediff > 10 then
        self:SetData("teleport-interrupted", false, true)
    end
end)

