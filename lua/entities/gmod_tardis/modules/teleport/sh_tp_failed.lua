-- Failed and forced teleport functions

if SERVER then
    function ENT:FailDemat()
        self:SetData("failing-demat", true, true)
        self:CallCommonHook("DematFailed")
        self:SendMessage("failed-demat")
        local infinite = TARDIS:GetSetting("teleport_warning_infinite", self)
        if not infinite then
            local time = self.metadata.Timings.DematFail
            self:Timer("failed-demat-stop", time, function()
                self:FailDematStop()
            end)
        end
    end

    function ENT:FailDematStop()
        self:SetData("failing-demat", false, true)
        self:CallCommonHook("DematFailStopped")
        self:CallClientCommonHook("DematFailStopped")
    end

    ---@param pos Vector?
    ---@param ang Angle?
    ---@param callback fun(success: boolean)?
    function ENT:HandleNoMat(pos, ang, callback)
        local fail = self:CallHook("ShouldFailMat", pos, ang)
        local possible = self:CallHook("CanMat", pos, ang, true)

        self:CallHook("HandleNoMat", pos, ang, callback)

        if fail ~= true or possible == false then
            if callback then callback(false) end
            return
        end

        if self:GetFastRemat() then
            if pos == self:GetPos() or pos == nil then
                if callback then callback(false) end
                return
            end

            self:SetData("failed-mat-destination-pos", pos)
            self:SetData("failed-mat-destination-ang", ang)

            self:SetDestination(self:GetPos(), self:GetAngles())

            self:SendMessage("failed-mat")

            self:Mat(callback)
            return
        end

        self:SetData("failing-mat", true, true)
        self:CallCommonHook("MatFailed")
        self:SendMessage("failed-mat")
        local infinite = TARDIS:GetSetting("teleport_warning_infinite", self)
        if not infinite then
            local time = self.metadata.Timings.MatFail
            self:Timer("failed-mat-stop", time, function()
                self:FailMatStop()
            end)
        end
        if callback then callback(false) end
    end

    function ENT:FailMatStop()
        self:SetData("failing-mat", false, true)
        self:CallCommonHook("MatFailStopped")
        self:CallClientCommonHook("MatFailStopped")
    end

    ENT:AddHook("StopMat", "failed-mat-destination-restore", function(self)
        local pos = self:GetData("failed-mat-destination-pos")
        local ang = self:GetData("failed-mat-destination-ang", Angle(0,0,0))

        if pos then
            self:SetDestination(pos, ang)
        end

        self:SetData("failed-mat-destination-pos", nil)
        self:SetData("failed-mat-destination-ang", nil)
    end)

    ENT:AddHook("ShouldFailDemat", "doors", function(self, force)
        if self:GetData("doorstatereal") and force ~= true
            and not TARDIS:GetSetting("teleport-door-autoclose", self)
        then
            return true
        end
    end)

    ---@param pos Vector?
    ---@param ang Angle?
    ---@param callback fun(success: boolean)?
    function ENT:ForceDemat(pos, ang, callback)
        self:Demat(pos, ang, callback, true)
    end

    ---@api
    ---@param pos Vector?
    ---@param ang Angle?
    ---@param callback fun(success: boolean)?
    function ENT:AutoDemat(pos, ang, callback)
        if self:CallHook("CanDemat", false, true) ~= false then
            self:Demat(pos, ang, callback)
        elseif self:CallHook("CanDemat", true, true) ~= false then
            self:ForceDemat(pos, ang, callback)
        else
            if callback then callback(false) end
        end
    end

    ENT:AddHook("CanDemat", "failed", function(self, force, check_failed)
        if not check_failed then return end

        if self:CallHook("ShouldFailDemat", force) == true then
            return false
        end
    end)

    ENT:AddHook("CanMat", "failed", function(self, dest_pos, dest_ang, ignore_fail_mat)
        if ignore_fail_mat ~= true and self:CallHook("ShouldFailMat", dest_pos, dest_ang) == true then
            return false
        end
    end)

    ENT:AddHook("ShouldFailMat", "doors", function(self, dest_pos, dest_ang)
        if self:GetData("doorstatereal")
            and not TARDIS:GetSetting("teleport-door-autoclose", self)
        then
            return true
        end
    end)

    ---@param pos Vector?
    ---@param ang Angle?
    ---@param callback fun(success: boolean)?
    function ENT:EngineReleaseDemat(pos, ang, callback)
        if not self:GetData("failing-demat", false) then return end

        if self:CallHook("ShouldFailDemat", false) == true then
            if not self:IsLowHealth() then
                self:ForceDemat(pos, ang, callback)
            else
                self:SendMessage("engine-release-explode")
                self:TogglePower()
            end
        else
            self:Demat(pos, ang, callback, false)
        end
    end

    ENT:AddHook("ToggleDoor", "failing-demat", function(self,open)
        if self:GetData("failing-demat", false) then
            if not open then
                self:Demat(nil, nil, nil, false)
            end
        end
    end)

    ENT:AddHook("ToggleDoor", "failing-mat", function(self,open)
        if self:GetData("failing-mat", false) then
            if not open then
                self:SetData("failing-mat", false, true)
                self:Mat(nil)
            end
        end
    end)

    ENT:AddHook("DematStart", "failing-demat", function(self, pos, ang, callback, force)
        self:FailDematStop()
    end)

    ENT:AddHook("PreMatStart", "failing-mat", function(self, pos, ang, callback, ignore_fail_mat)
        self:SetData("failing-mat", false, true)
    end)

    ENT:AddHook("PowerToggled", "failing-demat", function(self, on)
        if not on then
            self:FailDematStop()
        end
    end)

    ENT:AddHook("HandbrakeToggled", "failing-demat", function(self, on)
        if not on then
            self:FailDematStop()
        end
    end)

else -- CLIENT
    ENT:OnMessage("failed-demat", function(self, data, ply)
        self:CallCommonHook("DematFailed")
        if TARDIS:GetSetting("teleport-sound") and TARDIS:GetSetting("sound") then
            local infinite = TARDIS:GetSetting("teleport_warning_infinite", self)
            local ext = self.metadata.Exterior.Sounds.Teleport
            local int = self.metadata.Interior.Sounds.Teleport
            self:EmitSound(ext.demat_fail)
            if ((not infinite) or (not int.demat_fail_loop)) and IsValid(self.interior) then
                self.interior:EmitSound(int.demat_fail or ext.demat_fail)
            end
        end
        if LocalPlayer():GetTardisExterior() == self and IsValid(self.interior) then
            util.ScreenShake(self.interior:GetPos(), 2.5, 100, 3, 300)
        end
    end)

    ENT:OnMessage("failed-mat", function(self, data, ply)
        self:CallCommonHook("MatFailed")
        if TARDIS:GetSetting("teleport-sound") and TARDIS:GetSetting("sound") then
            local ext = self.metadata.Exterior.Sounds.Teleport
            local int = self.metadata.Interior.Sounds.Teleport
            self:EmitSound(ext.mat_fail)
            if IsValid(self.interior) then
                self.interior:EmitSound(int.mat_fail or ext.mat_fail)
            end
        end
        if LocalPlayer():GetTardisExterior() == self and IsValid(self.interior) then
            util.ScreenShake(self.interior:GetPos(), 2.5, 100, 3, 300)
        end
    end)

    ENT:OnMessage("engine-release-explode", function(self, data, ply)
        self:InteriorExplosion()
    end)

    ENT:AddHook("Think", "failing-demat", function(self)
        local interior = self.interior
        if not IsValid(interior) then return end
        if self:GetData("failing-demat", false) and TARDIS:GetSetting("teleport-sound") and TARDIS:GetSetting("sound") then
            local setting = TARDIS:GetSetting("teleport_warning_infinite", self)
            local sound = self.metadata.Interior.Sounds.Teleport.demat_fail_loop
            if setting and sound then
                local snd = interior.dematfailsound
                if not snd then
                    snd = CreateSound(interior, sound)
                    interior.dematfailsound = snd
                    snd:SetSoundLevel(90)
                end
                if not snd:IsPlaying() then
                    snd:Play()
                end
            end
        else
            local snd = interior.dematfailsound
            if snd then
                snd:Stop()
                interior.dematfailsound = nil
            end
        end
    end)

    ENT:AddHook("DematFailStopped", "failing-demat", function(self)
        local interior = self.interior
        if not IsValid(interior) then return end
        local snd = interior.dematfailsound
        if snd then
            snd:Stop()
            interior.dematfailsound = nil
            local power = self:GetPower()
            local teleport = self:GetData("teleport", false)
            local sound = self.metadata.Interior.Sounds.Teleport.demat_fail_loop_stop
            if power and (not teleport) and sound then
                interior:EmitSound(sound)
            end
        end
    end)

    ENT:AddHook("OnRemove", "failing-demat", function(self)
        local interior = self.interior
        if not IsValid(interior) then return end
        local snd = interior.dematfailsound
        if snd then
            snd:Stop()
            interior.dematfailsound = nil
        end
    end)
end


ENT:AddHook("Think","breakdown-effects", function(self)
    if self:GetData("force-demat", false) then
        local timediff = CurTime() - self:GetData("force-demat-time")

        local showeffects = (CLIENT and LocalPlayer():GetTardisExterior() == self
            and (not LocalPlayer():GetTardisData("thirdperson"))
            and TARDIS:GetSetting("breakdown-effects"))

        if showeffects then
            if timediff > 0.5 and timediff < 0.6 then
                self:InteriorExplosion()
                util.ScreenShake(self.effect_pos, 10, 100, 10, 300)
            end

            if timediff > 1.2 and timediff < 1.3 then
                self:InteriorExplosion()
                self:SetData("interior-lights-blinking", true, true)
                self:SetData("force-demat-sparkling", true, false)
            end

            if self:GetData("force-demat-sparkling", false) then
                if math.Round(1.5 * CurTime()) % 2 == 0 then
                    local power = 1.2 + math.random(1, 5) * 0.1
                    power = power - math.max(0, timediff) * 0.1
                    power = math.max(0, power)
                    self:InteriorSparks(power)
                end
            end

            if self:GetData("force-demat-sparkling", false) and timediff > 6 then
                self:InteriorExplosion()
                self:SetData("force-demat-sparkling", false, false)
            end
        end

        if self:GetData("interior-lights-blinking", false) and timediff > 4 then
            if SERVER then
                local newhealth = self:GetHealth() * math.random(75, 95) * 0.01
                self:ChangeHealth(newhealth)
            end
            if showeffects then self:InteriorExplosion() end
            self:SetData("interior-lights-blinking", false, true)
        end
    end
end)





