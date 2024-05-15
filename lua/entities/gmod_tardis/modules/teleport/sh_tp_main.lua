-- Main teleport-related functions

TARDIS:AddKeyBind("teleport-demat",{
    name="Demat",
    section="Teleport",
    func=function(self,down,ply)
        local pilot = self:GetData("pilot")
        if SERVER then
            if ply==pilot and down then
                ply:SetTardisData("teleport-demat-bind-down", true)
            end
            if ply==pilot and (not down) and ply:GetTardisData("teleport-demat-bind-down",false) then
                if not self:GetData("vortex") then
                    if self:GetDestinationPos() then
                        self:Demat()
                        return
                    end
                    local pos,ang=self:GetThirdPersonTrace(ply,ply:GetTardisData("viewang"))
                    self:Demat(pos,ang)
                end
            end
            if not down and ply:GetTardisData("teleport-demat-bind-down",false) then
                ply:SetTardisData("teleport-demat-bind-down", nil)
            end
        else
            if ply==pilot and down and (not (self:GetData("vortex") or self:GetData("teleport"))) then
                self:SetData("teleport-trace",true)
            else
                self:SetData("teleport-trace",false)
            end
        end
    end,
    key=MOUSE_LEFT,
    exterior=true
})

TARDIS:AddKeyBind("teleport-mat",{
    name="Mat",
    section="Teleport",
    func=function(self,down,ply)
        if ply==self.pilot and down then
            if self:GetData("vortex") then
                self:Mat()
            end
        end
    end,
    serveronly=true,
    key=MOUSE_LEFT,
    exterior=true
})

if SERVER then
    function ENT:ForceDematState()
        self:SetDestination(self:GetPos(), self:GetAngles())

        self:SetData("demat",true)
        self:SetData("vortexalpha", 1)
        self:SetData("teleport",true)
        self:SetData("alpha", 0)
        self:UpdateShadow()

        self:StopDemat()
    end

    function ENT:DematDoorCheck(pos, ang, callback, force)
        local autoclose = TARDIS:GetSetting("teleport-door-autoclose", self)
        if (force or autoclose) and self:GetData("doorstatereal") then
            self:CloseDoor(function()
                self:Demat(pos, ang, callback, force)
            end)
            return false
        end
        if self:GetData("doorstatereal") then
            if callback then callback(false) end
            return false
        end
        return true
    end

    function ENT:Demat(pos, ang, callback, force)

        force = force or self:CallCommonHook("ShouldForceDemat", pos, ang)

        if self:CallHook("CanDemat", force, false) == false then
            return callback and callback(false)
        end

        local redecorating = self:GetData("redecorate")

        if self:CallHook("ShouldFailDemat", force, pos, ang) == true and not redecorating then
            self:FailDemat()
            return callback and callback(false)
        end

        if not self:DematDoorCheck(pos, ang, callback, force) then return end

        if force then
            self:SetData("force-demat", true, true)
            self:SetData("force-demat-time", CurTime(), true)
            self:Explode(30)
            self.interior:Explode(20)
        end

        pos = pos or self:GetDestinationPos(true)
        ang = ang or self:GetDestinationAng(true)
        pos,ang = self:CallCommonHook("DestinationOverride", pos, ang) or pos,ang
        self:SetDestination(pos, ang)

        self:SendMessage("demat", { self:GetDestinationPos(true) } )
        self:SetData("demat",true)
        self:SetData("step",1)
        self:SetStepDelay()
        self:SetData("teleport",true)
        self:SetCollisionGroup( COLLISION_GROUP_WORLD )

        self:CallHook("DematStart")
        if force then self:CallHook("ForceDematStart") end
        self:UpdateShadow()

        if callback then callback(true) end
    end

    function ENT:FastDemat(pos, ang, callback)
        if self:GetData("vortex") and not self:GetData("fastdemat") then
            self:SetDestination(pos, ang)
            self:Mat(callback)
            return
        end
    
        if self:CallHook("CanDemat", true, true) == false then
            if callback then callback(false) end
            return
        end
    
        self:SetData("demat-fast-prev", self:GetFastRemat());
        self:SetFastRemat(true)
        self:SetData("fastdemat",true)
        self:CallHook("FastDemat")
        self:AutoDemat(pos, ang, callback)
    end

    function ENT:ChangePosition(pos, ang, phys_enable)
        if self:CallHook("PreTeleportPositionChange", pos, ang, phys_enable) == false then return end

        self:SetPos(pos)
        self:SetAngles(ang)

        self:CallHook("TeleportPositionChanged", pos, ang, phys_enable)
    end

    function ENT:Mat(callback)
        local pos = self:GetDestinationPos(true)
        local ang = self:GetDestinationAng(true)

        if self:CallHook("CanMat", pos, ang) == false then
            self:HandleNoMat(pos, ang, callback)
            return
        end

        local continue_mat = function(state)
            if state then
                if callback then callback(false) end
                return
            end

            self:SendMessage("premat", { self:GetDestinationPos(true) } )
            self:SetData("teleport",true)
            self:CallHook("PreMatStart")

            local tp_metadata = self.metadata.Exterior.Teleport
            local timerdelay = (self:GetFastRemat() and tp_metadata.PrematDelayFast or tp_metadata.PrematDelay)
            self:Timer("matdelay", timerdelay, function()
                if not IsValid(self) then return end
                self:SendMessage("mat")
                self:SetData("mat",true)
                self:SetData("step",1)
                self:SetStepDelay()
                self:SetData("vortex",false)
                local flight=self:GetData("prevortex-flight")
                if self:GetData("flight")~=flight then
                    self:SetFlight(flight)
                end
                self:SetData("prevortex-flight",nil)
                self:SetSolid(SOLID_VPHYSICS)
                self:CallHook("MatStart")
                self:ChangePosition(pos, ang, true)
                self:SetDestination(nil, nil)
            end)
            if callback then callback(true) end
        end
        if TARDIS:GetSetting("teleport-door-autoclose", self) then
            self:CloseDoor(continue_mat)
        else
            continue_mat(self:GetData("doorstatereal"))
        end
    end

    function ENT:StopDemat()
        self:SetData("demat",false)
        self:SetData("force-demat", false, true)
        self:SetData("step",1)
        self:SetData("step-delay",nil)
        self:SetData("vortex",true)
        self:SetData("teleport",false)
        self:SetSolid(SOLID_NONE)
        self:RemoveAllDecals()

        local flight = self:GetData("flight")
        self:SetData("prevortex-flight",flight)
        if not flight then
            self:SetFlight(true)
        end
        self:CallHook("StopDemat")
    end

    function ENT:StopMat()
        self:SetData("mat",false)
        self:SetData("step",1)
        self:SetData("step-delay",nil)
        self:SetData("teleport",false)
        self:SetCollisionGroup(COLLISION_GROUP_NONE)
        self:UpdateShadow()
        self:CallHook("StopMat")
    end

    ENT:AddHook("CanDemat", "teleport", function(self, force, check_failed)
        if self:GetData("teleport") or self:GetData("vortex") or (not self:GetPower()) then
            return false
        end
    end)

    ENT:AddHook("CanMat", "teleport", function(self, dest_pos, dest_ang, ignore_fail_mat)
        if self:GetData("teleport") or (not self:GetData("vortex")) then
            return false
        end
    end)

    ENT:AddHook("StopDemat", "vortex-random-pos", function(self)
        if not self:GetFastRemat()
            and not self:GetData("redecorate")
            and not self:GetData("redecorate_parent")
        then
            local randomLocation = self:GetRandomLocation(false)
            if randomLocation then
                self:ChangePosition(randomLocation, self:GetAngles(), false)
            end
        end
    end)

    ENT:AddHook("CanChangeDestination", "premat", function(self)
        if self:GetData("teleport") and self:GetData("vortex") then
            return false
        end
    end)

    ENT:AddHook("StopMat", "teleport", function(self)
        if self:GetData("fastdemat",false) then
            self:SetFastRemat(self:GetData("demat-fast-prev", false))
            self:SetData("fastdemat",false)
        end
    end)
else
    ENT:OnMessage("demat", function(self, data, ply)
        self:SetData("demat",true)
        self:SetData("step",1)
        self:SetStepDelay()
        self:SetData("teleport",true)
        if TARDIS:GetSetting("teleport-sound") and TARDIS:GetSetting("sound") then
            local shouldPlayExterior = self:CallHook("ShouldPlayDematSound", false)~=false
            local shouldPlayInterior = self:CallHook("ShouldPlayDematSound", true)~=false
            if not (shouldPlayExterior or shouldPlayInterior) then return end
            local ext = self.metadata.Exterior.Sounds.Teleport
            local int = self.metadata.Interior.Sounds.Teleport

            local sound_demat_ext = ext.demat
            local sound_demat_fast_ext = ext.demat_fast
            local sound_demat_int = int.demat or ext.demat
            local sound_fullflight_ext = ext.fullflight
            local sound_fullflight_int = int.fullflight or ext.fullflight

            if (self:IsLowHealth() or self:GetData("force-demat", false))
                and not self:GetData("redecorate")
            then
                sound_demat_ext = ext.demat_damaged
                sound_demat_fast_ext = ext.demat_damaged
                sound_demat_int = int.demat_damaged or ext.demat_damaged
                sound_fullflight_ext = ext.fullflight_damaged
                sound_fullflight_int = int.fullflight_damaged or ext.fullflight_damaged
            end

            local sound_demat_hads_ext = ext.demat_hads
            local sound_demat_hads_int = int.demat_hads or ext.demat_hads

            local pos = data[1]

            if LocalPlayer():GetTardisData("exterior")==self then
                if self:GetFastRemat() then
                    if shouldPlayInterior then
                        self.interior:EmitSound(sound_fullflight_int)
                    end
                    if shouldPlayExterior then
                        self:EmitSound(sound_fullflight_ext)
                    end
                else
                    if shouldPlayInterior then
                        if self:GetData("hads-demat") then
                            self.interior:EmitSound(sound_demat_hads_int)
                        else
                            self.interior:EmitSound(sound_demat_int)
                        end
                    end
                    if shouldPlayExterior then
                        if self:GetData("hads-demat") then
                            self:EmitSound(sound_demat_hads_ext)
                        else
                            self:EmitSound(sound_demat_ext)
                        end
                    end
                end
            elseif shouldPlayExterior then
                if self:GetFastRemat() then
                    sound.Play(sound_demat_fast_ext,self:GetPos())
                else
                    if self:GetData("hads-demat") then
                        sound.Play(sound_demat_hads_ext,self:GetPos())
                    else
                        sound.Play(sound_demat_ext,self:GetPos())
                    end
                end
                if pos and self:GetFastRemat() then
                    if not IsValid(self) then return end
                    if self:IsLowHealth() and self:GetFastRemat() then
                        sound.Play(ext.mat_damaged_fast, pos)
                    else
                        sound.Play(ext.mat_fast, pos)
                    end
                end
            end
        end
        self:CallHook("DematStart")
    end)

    ENT:OnMessage("premat", function(self, data, ply)
        self:SetData("teleport",true)
        self:SetData("premat_start_time", CurTime())
        if TARDIS:GetSetting("teleport-sound") and TARDIS:GetSetting("sound") then
            local shouldPlayExterior = self:CallHook("ShouldPlayMatSound", false)~=false
            local shouldPlayInterior = self:CallHook("ShouldPlayMatSound", true)~=false
            if not (shouldPlayExterior or shouldPlayInterior) then return end
            local ext = self.metadata.Exterior.Sounds.Teleport
            local int = self.metadata.Interior.Sounds.Teleport
            local pos=data[1]
            if LocalPlayer():GetTardisData("exterior")==self and (not self:GetFastRemat()) then
                if self:IsLowHealth() then
                    if shouldPlayExterior then
                        self:EmitSound(ext.mat_damaged)
                    end
                    if shouldPlayInterior then
                        self.interior:EmitSound(int.mat_damaged or ext.mat_damaged)
                    end
                else
                    if shouldPlayExterior then
                        self:EmitSound(ext.mat)
                    end
                    if shouldPlayInterior then
                        self.interior:EmitSound(int.mat or ext.mat)
                    end
                end
            elseif not self:GetFastRemat() and shouldPlayExterior then
                if self:IsLowHealth() then
                    sound.Play(ext.mat_damaged,pos)
                else
                    sound.Play(ext.mat,pos)
                end
            end
        end
        self:CallHook("PreMatStart")
    end)

    ENT:OnMessage("mat", function(self, data, ply)
        self:SetData("mat",true)
        self:SetData("step",1)
        self:SetStepDelay()
        self:SetData("vortex",false)
        self:CallHook("MatStart")
    end)

    function ENT:StopDemat()
        self:SetData("demat",false)
        self:SetData("step",1)
        self:SetData("step-delay",nil)
        self:SetData("vortex",true)
        self:SetData("vortex_enter_time",CurTime())
        self:SetData("teleport",false)
        self:CallHook("StopDemat")
    end

    function ENT:StopMat()
        self:SetData("mat",false)
        self:SetData("step",1)
        self:SetData("step-delay",nil)
        self:SetData("teleport",false)
        self:CallHook("StopMat")
    end

    ENT:OnMessage("stop_mat", function(self, data, ply)
        self:StopMat()
    end)

    ENT:AddHook("ShouldTurnOffLight", "teleport", function(self)
        if self:GetData("teleport", false) and self:GetData("alpha",255) == 0 then return true end
    end)
end

function ENT:SetStepDelay()
    local demat=self:GetData("demat")
    local fast=self:GetFastRemat()
    local mat=self:GetData("mat")
    local hads=self:GetData("hads-triggered")
    if not (demat or mat) then return end

    local teleport_md = self.metadata.Exterior.Teleport
    local sequence_delays
    if hads then
        sequence_delays = teleport_md.DematHadsSequenceDelays
    elseif demat then
        if fast then
            sequence_delays = teleport_md.DematFastSequenceDelays
        else
            sequence_delays = teleport_md.DematSequenceDelays
        end
    else
        if fast then
            sequence_delays = teleport_md.MatFastSequenceDelays
        else
            sequence_delays = teleport_md.MatSequenceDelays
        end
    end
    local step = self:GetData("step",1)
    if sequence_delays and sequence_delays[step] then
        self:SetData("step-delay",CurTime() + sequence_delays[step])
    else
        self:SetData("step-delay",nil)
    end
end

function ENT:GetTargetAlpha()
    local demat = self:GetData("demat")
    local mat = self:GetData("mat")
    local hads = self:GetData("hads-triggered")
    local step = self:GetData("step",1)

    if demat and hads then
        return self.metadata.Exterior.Teleport.HadsDematSequence[step]
    elseif demat and (not mat) then
        return self.metadata.Exterior.Teleport.DematSequence[step]
    elseif mat and (not demat) then
        return self.metadata.Exterior.Teleport.MatSequence[step]
    else
        return 255
    end
end

ENT:AddHook("Think","teleport",function(self,delta)
    local demat = self:GetData("demat")
    local hads = self:GetData("hads-demat")
    local mat = self:GetData("mat")
    if not (demat or mat) then return end
    local alpha=self:GetData("alpha",255)
    local target=self:GetTargetAlpha()
    local step=self:GetData("step",1)

    local teleport_md = self.metadata.Exterior.Teleport
    local fast = self:GetFastRemat()

    local demat_steps = hads and #teleport_md.HadsDematSequence or #teleport_md.DematSequence

    if alpha==target then
        if demat then
            if step >= demat_steps then
                self:StopDemat()
                return
            else
                self:SetData("step",step+1)
                self:SetStepDelay()
            end
        elseif mat then
            if step >= #teleport_md.MatSequence then
                self:StopMat()
                return
            else
                self:SetData("step",step+1)
                self:SetStepDelay()
            end
        end
        target=self:GetTargetAlpha()
    end

    if self:GetData("step-delay") and self:GetData("step-delay")>CurTime() then return end
    local sequencespeed = (fast and teleport_md.SequenceSpeedFast or teleport_md.SequenceSpeed)
    if self:IsLowHealth() then
        sequencespeed = (fast and teleport_md.SequenceSpeedWarnFast or teleport_md.SequenceSpeedWarning)
    end
    if self:GetData("hads-demat") then
        sequencespeed = teleport_md.SequenceSpeedHads
    end
    if istable(sequencespeed) then
        sequencespeed = demat and sequencespeed.Demat or sequencespeed.Mat
    end
    alpha=math.Approach(alpha,target,delta*66*sequencespeed)
    self:SetData("alpha",alpha)
    self:SetAttachedTransparency(alpha)
end)

-- returns the progress of the current sequence on a scale from 0 to 1
function ENT:GetSequenceProgress()
    if not self:GetData("teleport") then return 1 end

    local tp_metadata = self.metadata.Exterior.Teleport
    local demat = self:GetData("demat")
    local sequence = demat and tp_metadata.DematSequence or tp_metadata.MatSequence

    if self:GetData("hads-demat") then
        sequence = tp_metadata.HadsDematSequence
    end

    local start_alpha = demat and 255 or 0

    local steps = #sequence - 1
    local step = self:GetData("step") - 1
    if step >= steps then return 1 end

    local a_target = sequence[step + 1]
    local a_prev = sequence[step] or start_alpha
    if a_prev == a_target then return 1 end

    local a = self:GetData("alpha",255)

    local progress = step / steps
    progress = progress + (1 - math.abs((a - a_target) / (a_prev - a_target))) / steps
    return progress
end
