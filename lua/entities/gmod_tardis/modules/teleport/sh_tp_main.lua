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

---@param sequence number[]
---@param from number starting alpha
---@param speed number
---@param delays number[]?
---@return number
local function sequenceDuration(sequence, from, speed, delays)
    local total, prev = 0, from
    for i, target in ipairs(sequence) do
        total = total + math.abs(target - prev) / (66 * speed)
        if delays and delays[i] then total = total + delays[i] end
        prev = target
    end
    return total
end

---@param speed tardis_sequence_speed
---@param mat boolean
---@return number
local function dirSpeed(speed, mat)
    if istable(speed) then return mat and speed.Mat or speed.Demat end
    return speed
end

---@api
---@return number
function ENT:GetDematDuration()
    local tp = self.metadata.Exterior.Teleport
    return sequenceDuration(tp.DematSequence, 255, dirSpeed(tp.SequenceSpeed, false), tp.DematSequenceDelays)
end

---@api
---@return number
function ENT:GetMatDuration()
    local tp = self.metadata.Exterior.Teleport
    return sequenceDuration(tp.MatSequence, 0, dirSpeed(tp.SequenceSpeed, true), tp.MatSequenceDelays)
end

---@return number
function ENT:GetPrematLead()
    local premat = self.metadata.Exterior.Teleport.PrematDelay
    if self:GetFastRemat() then
        return math.min(premat, self:GetDematDuration())
    end
    return premat
end

if SERVER then
    ---@api
    function ENT:ForceDematState()
        self:SetDestination(self:GetPos(), self:GetAngles())

        self:StopDemat()

        -- Network what StopDemat only set serverside, so clients don't stay visibly landed
        self:SetData("vortex", true, true)
        self:SetData("teleport", false, true)
        self:SetData("demat", false, true)
        self:SetData("alpha", 0, true)

        self:UpdateShadow()
        self:UpdateDoorCollision()
    end

    ---@param pos Vector?
    ---@param ang Angle?
    ---@param callback fun(success: boolean)?
    ---@param force boolean?
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

    -- Makes sure the TARDIS doesn't fall through interiors when demat/matting.
    -- DEBRIS is the one group that rests on a prop/shell floor yet still passes through players.
    ---@param pos Vector
    ---@return COLLISION_GROUP
    function ENT:TeleportCollisionGroup(pos)
        for interior in pairs(Doors:GetInteriors()) do
            if IsValid(interior) and interior:PositionInside(pos) then
                return COLLISION_GROUP_DEBRIS
            end
        end
        return COLLISION_GROUP_WORLD
    end

    ---@api
    ---@param pos Vector?
    ---@param ang Angle?
    ---@param callback fun(success: boolean)?
    ---@param force boolean?
    function ENT:Demat(pos, ang, callback, force)

        if pos and ang then
            self:SetDestination(pos, ang)
        end

        force = force or self:CallCommonHook("ShouldForceDemat", pos, ang)

        if self:CallHook("CanDemat", force, false) == false then
            return callback and callback(false)
        end

        local redecorating = self:GetData("redecorate")

        if self:CallHook("ShouldFailDemat", force, pos, ang) == true and not redecorating then
            self:FailDemat()
            return callback and callback(false)
        end

        local doorcheck = self:DematDoorCheck(pos, ang, callback, force)
        if not doorcheck then return doorcheck end

        if force then
            self:SetData("force-demat", true, true)
            self:SetData("force-demat-time", CurTime(), true)
            self:Explode(30)
            if IsValid(self.interior) then
                self.interior:Explode(20)
            end
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
        self:SetData("teleport-interrupt-fade", nil, true)
        self:SetCollisionGroup( self:TeleportCollisionGroup(self:GetPos()) )
        self:SetData("demat-startpos",self:GetPos(),true)
        self:SetData("demat-startang",self:GetAngles(),true)

        self:CallCommonHook("DematStart")
        if force then self:CallHook("ForceDematStart") end
        self:UpdateShadow()

        if callback then callback(true) end
    end

    ---@param pos Vector
    ---@param ang Angle
    ---@param phys_enable boolean
    function ENT:ChangePosition(pos, ang, phys_enable)
        if self:CallHook("PreTeleportPositionChange", pos, ang, phys_enable) == false then return end

        self:SetPos(pos)
        self:SetAngles(ang)

        self:CallHook("TeleportPositionChanged", pos, ang, phys_enable)
    end

    ---@param pos Vector
    ---@param ang Angle
    function ENT:PerformMatVisual(pos, ang)
        if not IsValid(self) then return end
        self:SendMessage("mat")
        self:SetData("mat",true)
        self:SetData("teleport",true)
        self:SetData("premat-start", nil, true)
        self:SetData("step",1)
        self:SetStepDelay()
        self:SetData("vortex",false)
        local flight=self:GetData("prevortex-flight")
        if self:GetData("flight")~=flight then
            self:SetFlight(flight)
        end
        self:SetData("prevortex-flight",nil)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(self:TeleportCollisionGroup(pos))
        self:CallCommonHook("MatStart")
        self:ChangePosition(pos, ang, true)
        self:SetData("demat-startpos",nil,true)
        self:SetData("demat-startang",nil,true)
        self:SetDestination(nil, nil)
    end

    ---@api
    ---@param callback fun(success: boolean)?
    function ENT:Mat(callback)
        local pos = self:GetDestinationPos(true)
        local ang = self:GetDestinationAng(true)

        if self:CallHook("CanMat", pos, ang) == false then
            self:HandleNoMat(pos, ang, callback)
            return
        end

        ---@param state boolean
        local continue_mat = function(state)
            if state then
                if callback then callback(false) end
                return
            end

            self:SendMessage("premat", { self:GetDestinationPos(true) } )
            self:SetData("teleport",true)
            self:SetData("premat-start", CurTime(), true)
            self:CallCommonHook("PreMatStart")

            self:Timer("matdelay", self.metadata.Exterior.Teleport.PrematDelay, function()
                self:PerformMatVisual(pos, ang)
            end)
            if callback then callback(true) end
        end
        if TARDIS:GetSetting("teleport-door-autoclose", self) then
            self:CloseDoor(continue_mat)
        else
            continue_mat(self:GetData("doorstatereal"))
        end
    end

    -- Starts the premat sequence for a no-vortex demat
    function ENT:NoVortexMat()
        local pos = self:GetDestinationPos(true)
        local ang = self:GetDestinationAng(true)
        if self:CallHook("CanMat", pos, ang) == false then
            -- Reverse the premat if CanMat fails after the premat has started
            self:SetData("premat-start", nil, true)
            self:CallClientHook("NoVortexMatCancelled")
            self:HandleNoMat(pos, ang, nil)
            return
        end
        self:PerformMatVisual(pos, ang)
    end

    function ENT:StopDemat()
        self:SetData("demat",false)
        self:SetData("force-demat", false, true)
        self:SetData("step",1)
        self:SetData("step-delay",nil)
        self:SetData("hads-demat",false)
        self:SetData("vortex",true)
        self:SetData("teleport",false)
        self:SetData("teleport-interrupt-fade", nil)
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
        self:CallCommonHook("StopMat")
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

    ENT:AddHook("StopDemat", "npcbehaviour", function(self)
        self:ClearNPCTargeting()
    end)

    ENT:AddHook("CanChangeDestination", "premat", function(self)
        if self:GetData("teleport") and self:GetData("vortex") then
            return false
        end
    end)

    ENT:AddHook("StopMat", "teleport", function(self)
        if self:GetData("fastreturn-restore",false) then
            self:SetFastRemat(self:GetData("demat-fast-prev", false))
            self:SetData("fastreturn-restore",false)
        end
    end)
else
    ---@param extpath string?
    ---@param intpath string?
    ---@param shouldext boolean
    ---@param shouldint boolean
    ---@param seek number? seconds to start into the sound (no-vortex mat trims its lead-in)
    ---@return doors_managed_sound? interior_handle
    ---@return doors_managed_sound? exterior_handle
    function ENT:PlayTeleportSound(extpath, intpath, shouldext, shouldint, seek)
        local int_handle, ext_handle
        if shouldint and intpath and IsValid(self.interior) then
            int_handle = self.interior:PlaySound({ path = intpath, tag = "teleport", pair = "teleport", resumable = true, seek = seek })
        end
        if shouldext and extpath then
            ext_handle = self:PlaySound({ path = extpath, tag = "teleport", pair = "teleport", resumable = true, seek = seek })
        end
        return int_handle, ext_handle
    end

    -- Speed that the exterior must go for the sound to detach during a teleport
    -- Real movement speed tops at around 2-3k, teleport reads as >10k
    local BYSTANDER_PIN_JUMP = 6000

    ---@class tardis_teleport_crossfade_override
    ---@field active boolean
    ---@field dirty boolean
    ---@field MatStart number
    ---@field MatFade number
    ---@field DematStart number
    ---@field DematFade number

    -- Used by `tardis2_debug_crossfade`
    ---@type tardis_teleport_crossfade_override
    TARDIS.TeleportCrossfadeOverride = { active = false, dirty = false, MatStart = 0, MatFade = 0, DematStart = 0, DematFade = 0 }

    ---@return number mat_start_pct
    ---@return number mat_fade_pct
    ---@return number demat_start_pct
    ---@return number demat_fade_pct
    function ENT:GetTeleportCrossfadeSettings()
        local o = TARDIS.TeleportCrossfadeOverride
        if o.active then
            return o.MatStart, o.MatFade, o.DematStart, o.DematFade
        end
        local cf = self.metadata.Exterior.Teleport.Crossfade
        return cf.MatStart, cf.MatFade, cf.DematStart, cf.DematFade
    end

    -- Get the actual seconds for the crossfade timings from the set percentages
    ---@return number mat_lead   seconds before the teleport the mat ramp starts
    ---@return number mat_fade   mat ramp length in seconds
    ---@return number demat_lead seconds before the teleport the demat fade starts
    ---@return number demat_fade demat fade length in seconds
    function ENT:GetTeleportCrossfadeTimings()
        local ms, mft, ds, dft = self:GetTeleportCrossfadeSettings()
        local premat = math.min(self.metadata.Exterior.Teleport.PrematDelay, self:GetDematDuration())
        local mat_end = self:GetMatDuration()
        local mat_lead = (100 - ms) / 100 * premat
        local demat_lead = (100 - ds) / 100 * premat
        local mat_fade = mft / 100 * (mat_lead + mat_end)
        local demat_fade = dft / 100 * (demat_lead + mat_end)
        return mat_lead, mat_fade, demat_lead, demat_fade
    end

    ---@return number
    function ENT:GetTeleportDuration()
        return self:GetDematDuration() + self:GetMatDuration()
    end

    ---@class gmod_tardis
    ---@field tp_crossfade_demat_sounds table?
    ---@field tp_crossfade_mat_sounds table?
    ---@field tp_crossfade_jump number?
    ---@field tp_crossfade_mat_started boolean?
    ---@field tp_crossfade_demat_started boolean?

    function ENT:ClearTeleportCrossfade()
        self.tp_crossfade_demat_sounds = nil
        self.tp_crossfade_mat_sounds = nil
        self.tp_crossfade_jump = nil
        self.tp_crossfade_mat_started = nil
        self.tp_crossfade_demat_started = nil
    end

    ---@param mat_int doors_managed_sound?
    ---@param mat_ext doors_managed_sound?
    ---@param jump_time number CurTime the materialisation lands
    function ENT:StartTeleportCrossfade(mat_int, mat_ext, jump_time)
        if not self.tp_crossfade_demat_sounds then return end
        local mat = {}
        if mat_int then mat_int:SetVolume(0, 0) mat[#mat + 1] = mat_int end
        if mat_ext then mat_ext:SetVolume(0, 0) mat[#mat + 1] = mat_ext end
        self.tp_crossfade_mat_sounds = mat
        self.tp_crossfade_jump = jump_time
        self.tp_crossfade_mat_started = nil
        self.tp_crossfade_demat_started = nil
    end

    ENT:AddHook("Think", "teleport_crossfade", function(self)
        local mat = self.tp_crossfade_mat_sounds
        local jump = self.tp_crossfade_jump
        if not (mat and jump) then return end
        local ttj = jump - CurTime()
        local mat_lead, mat_fade, demat_lead, demat_fade = self:GetTeleportCrossfadeTimings()

        if not self.tp_crossfade_mat_started and ttj <= mat_lead then
            self.tp_crossfade_mat_started = true
            for _, h in ipairs(mat) do if h:IsAlive() then h:SetVolume(1, mat_fade) end end
        end

        local demat = self.tp_crossfade_demat_sounds
        if not self.tp_crossfade_demat_started and ttj <= demat_lead then
            self.tp_crossfade_demat_started = true
            if demat then for _, h in ipairs(demat) do if h:IsAlive() then h:FadeOut(demat_fade) end end end
        end

        -- Past the jump: release only once the mat sound has finished (the dev readout watches this until then).
        if ttj <= 0 then
            local playing = false
            for _, h in ipairs(mat) do if h:IsAlive() then playing = true break end end
            if not playing then self:ClearTeleportCrossfade() end
        end
    end)

    ENT:AddHook("NoVortexMatCancelled", "crossfade", function(self)
        self:StopSounds("teleport")
        self:ClearTeleportCrossfade()
    end)

    ENT:OnMessage("demat", function(self, data, ply)
        self:SetData("demat",true)
        self:SetData("step",1)
        self:SetStepDelay()
        self:SetData("teleport",true)
        self:SetData("teleport-interrupt-fade", nil)
        self:ClearTeleportCrossfade()
        if TARDIS:GetSetting("teleport-sound") and TARDIS:GetSetting("sound") then
            local shouldPlayExterior = self:CallHook("ShouldPlayDematSound", false)~=false
            local shouldPlayInterior = self:CallHook("ShouldPlayDematSound", true)~=false
            if not (shouldPlayExterior or shouldPlayInterior) then return end
            local ext = self.metadata.Exterior.Sounds.Teleport
            local int = self.metadata.Interior.Sounds.Teleport

            local sound_demat_ext = ext.demat
            local sound_demat_int = int.demat or ext.demat

            if (self:IsLowHealth() or self:GetData("force-demat", false))
                and not self:GetData("redecorate")
            then
                sound_demat_ext = ext.demat_damaged
                sound_demat_int = int.demat_damaged or ext.demat_damaged
            end

            local sound_demat_hads_ext = ext.demat_hads
            local sound_demat_hads_int = int.demat_hads or sound_demat_hads_ext

            if LocalPlayer():GetTardisExterior()==self then
                if self:GetData("hads-demat") then
                    self:PlayTeleportSound(sound_demat_hads_ext, sound_demat_hads_int, shouldPlayExterior, shouldPlayInterior)
                else
                    local int_h, ext_h = self:PlayTeleportSound(sound_demat_ext, sound_demat_int, shouldPlayExterior, shouldPlayInterior)
                    if self:GetFastRemat() then
                        -- Hold onto the sound handles so the crossfade can ramp them up/down around the jump.
                        local stored = {}
                        if int_h then stored[#stored + 1] = int_h end
                        if ext_h then stored[#stored + 1] = ext_h end
                        self.tp_crossfade_demat_sounds = stored
                        -- Rough jump time so the dev graph's playhead runs from demat start; premat refines it.
                        self.tp_crossfade_jump = CurTime() + self:GetDematDuration()
                    end
                end
            elseif shouldPlayExterior then
                local dematsnd = sound_demat_ext
                if self:GetData("hads-demat") then
                    dematsnd = sound_demat_hads_ext
                end
                self:PlaySound({ path = dematsnd, tag = "teleport", pin_on_jump = BYSTANDER_PIN_JUMP, resumable = true, linger = self:GetData("redecorate") })
            end
        end
        self:CallCommonHook("DematStart")
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
            ---@type Vector
            local pos=data[1]
            local mat_ext = self:IsLowHealth() and ext.mat_damaged or ext.mat
            local mat_int = self:IsLowHealth() and (int.mat_damaged or ext.mat_damaged) or (int.mat or ext.mat)
            -- If the PrematDelay is longer than demat duration, trim the mat sound so it lines up
            local lead = self:GetPrematLead()
            local seek = self.metadata.Exterior.Teleport.PrematDelay - lead
            seek = seek > 0 and seek or nil
            if LocalPlayer():GetTardisExterior()==self then
                -- Inside: the crossfade ramp masks the seeked sound's abrupt entry.
                local matH_int, matH_ext = self:PlayTeleportSound(mat_ext, mat_int, shouldPlayExterior, shouldPlayInterior, seek)
                self:StartTeleportCrossfade(matH_int, matH_ext, CurTime() + lead)
            elseif shouldPlayExterior then
                ---@type number?
                local fade_in
                if seek then
                    -- Fade in the exterior mat sound if it was trimmed so it doesn't jump in abruptly
                    local _, mf = self:GetTeleportCrossfadeTimings()
                    fade_in = mf
                end
                self:PlaySound({ path = mat_ext, tag = "teleport", pos = pos, attach = self, resumable = true, seek = seek, fade_in = fade_in })
            end
        end
        self:CallCommonHook("PreMatStart")
    end)

    ENT:OnMessage("mat", function(self, data, ply)
        self:SetData("demat",false)
        self:SetData("mat",true)
        self:SetData("teleport",true)
        self:SetData("vortex",false)
        self:SetData("step",1)
        self:SetStepDelay()
        self:CallHook("MatStart")
    end)

    function ENT:StopDemat()
        self:SetData("demat",false)
        self:SetData("step",1)
        self:SetData("step-delay",nil)
        self:SetData("hads-demat",false)
        self:SetData("vortex",true)
        self:SetData("vortex_enter_time",CurTime())
        self:SetData("teleport",false)
        self:SetData("teleport-interrupt-fade", nil)
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

---@api
function ENT:IsTeleporting()
    return self:GetData("teleport", false)
end

---@api
function ENT:IsInVortex()
    return self:GetData("vortex", false)
end

function ENT:SetStepDelay()
    local demat=self:GetData("demat")
    local mat=self:GetData("mat")
    local hads=self:GetData("hads-demat")
    if not (demat or mat) then return end

    local teleport_md = self.metadata.Exterior.Teleport
    local sequence_delays
    if hads then
        sequence_delays = teleport_md.DematHadsSequenceDelays
    elseif demat then
        sequence_delays = teleport_md.DematSequenceDelays
    else
        sequence_delays = teleport_md.MatSequenceDelays
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
    local hads = self:GetData("hads-demat")
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
    local restoring = self:GetData("teleport-interrupt-fade", false)
    if not (demat or mat or restoring) then return end

    local alpha=self:GetData("alpha",255)
    local teleport_md = self.metadata.Exterior.Teleport

    if restoring then
        local target = 255
        local speed = teleport_md.DematInterruptSpeed
        alpha=math.Approach(alpha,target,delta*66*speed)
        self:SetData("alpha",alpha)
        self:SetAttachedTransparency(alpha)

        if alpha==target then
            self:SetData("teleport-interrupt-fade", nil)
        end
        return
    end

    local target=self:GetTargetAlpha()
    local step=self:GetData("step",1)

    local demat_steps = hads and #teleport_md.HadsDematSequence or #teleport_md.DematSequence

    if alpha==target then
        if demat then
            if step >= demat_steps then
                self:StopDemat()
                -- Fast remat has no vortex phase, so immediately trigger mat after demat finishes
                if SERVER and self:GetFastRemat() and not self:GetData("redecorate") then
                    self:NoVortexMat()
                end
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
    local sequencespeed = teleport_md.SequenceSpeed
    if self:IsLowHealth() then
        sequencespeed = teleport_md.SequenceSpeedWarning
    end
    if self:GetData("hads-demat") then
        sequencespeed = teleport_md.SequenceSpeedHads
    end
    if istable(sequencespeed) then
        local speeds = sequencespeed
        sequencespeed = demat and speeds.Demat or speeds.Mat
    end
    alpha=math.Approach(alpha,target,delta*66*sequencespeed)
    self:SetData("alpha",alpha)
    self:SetAttachedTransparency(alpha)
end)

-- returns the progress of the current sequence on a scale from 0 to 1
---@api
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
