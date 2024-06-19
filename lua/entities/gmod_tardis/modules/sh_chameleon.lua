if SERVER then
    ENT:OnMessage("chameleon_change_exterior", function(self,data,ply)
        if self:CheckSecurity(ply) then
            self:ChangeExterior(data[1], data[2], data[3], data[4])
        end
    end)

    ENT:AddHook("Initialize", "chameleon", function(self)
        local init_ext = self:GetData("chameleon_current_exterior")
        if init_ext ~= nil then
            self:SetData("chameleon_initial_exterior", init_ext, true)
        end
        self:SetData("chameleon_current_exterior", false, true)
    end)

    ENT:AddHook("PostInitialize", "chameleon", function(self)
        local id = self.metadata.ID

        local init_ext = self:GetData("chameleon_initial_exterior")
        if init_ext then
            self:ChangeExterior(init_ext, false)
            return
        end

        local default_ext = TARDIS:GetCustomSetting(id, "exterior_default", self)
        if not default_ext then return end

        local ext_enabled = TARDIS:GetCustomSetting(id, "exterior_enabled", self)
        if not ext_enabled then return end

        self:ChangeExterior(default_ext, false)
    end)
else
    ENT:OnMessage("exterior_changed", function(self,data,ply)
        self:CallHook("ExteriorChanged", data[1])
    end)

    ENT:OnMessage("chameleon_exterior_animation", function(self,data,ply)
        local csound = self.metadata.Exterior.Sounds.Chameleon
        local csound_int = self.metadata.Interior.Sounds.Chameleon or csound

        if TARDIS:GetSetting("sound") and csound then
            self:EmitSound(csound)
            self.interior:EmitSound(csound_int)
        end

        local delay = self.metadata.Exterior.Chameleon.AnimTime / 2
        self:SetData("chameleon_animation", true, false)
        self:SetData("chameleon_animation_start", CurTime(), false)
        self:SetData("chameleon_animation_delay", delay, false)
        self:SetData("chameleon_animation_speed", 1.5 / delay, false)
        self:CallHook("ChameleonAnimationStarted")
    end)

    ENT:AddHook("Think", "chameleon_animation", function(self)
        local animating = self:GetData("chameleon_animation", false)
        if not animating then return end

        local start_time = self:GetData("chameleon_animation_start")
        local delay = self:GetData("chameleon_animation_delay")
        local speed = self:GetData("chameleon_animation_speed")

        local passed = CurTime() - start_time
        local first_half = (passed < delay)
        self:SetData("chameleon_animation_first_half", first_half)
        passed = passed % delay

        local target = first_half and -0.5 or 1
        local percent = self:GetData("chameleon-phase-percent",1)

        if percent == target then
            if not first_half then
                self:SetData("chameleon_animation", false)
                self:SetData("chameleon_animation_start", nil)
                self:CallHook("ChameleonAnimationFinished")
                self:SetData("chameleon-phase-lastTick", nil)
                self:SetData("chameleon_animation_first_half", nil)
            end
            return
        end

        local timepassed = CurTime() - self:GetData("chameleon-phase-lastTick",CurTime())
        self:SetData("chameleon-phase-lastTick", CurTime())

        local new_percent = math.Approach(percent, target, speed * timepassed) or 1
        local high_percent = math.Clamp(new_percent + 0.5, 0, 1) or 1
        self:SetData("chameleon-phase-percent", new_percent)
        self:SetData("chameleon-phase-highPercent", high_percent)

        local modelmaxs = self:GetData("modelmaxs")
        local modelheight = self:GetData("modelheight")

        local pos = self:GetPos() + self:GetUp() * (modelmaxs.z - (modelheight * high_percent))
        local pos2 = self:GetPos() + self:GetUp() * (modelmaxs.z - (modelheight * new_percent))

        self:SetData("phase-highPos", pos)
        self:SetData("phase-pos", pos2)
    end)

    ENT:AddHook("ShouldDrawPhaseAnimation", "chameleon", function(self)
        if self:GetData("chameleon_animation",false) then
            return true
        end
    end)

    ENT:AddHook("ExteriorChanged", "scale", function(self)
        self:DisableMatrix("RenderMultiply")
    end)
end

function ENT:ChangeExteriorMetadata(id)
    if SERVER then
        self:SendMessage("exterior_metadata_update", {id})
    end

    if self.metadata.ExteriorOriginal == nil then
        self.metadata.ExteriorOriginal = self.metadata.Exterior
    end
    local original_md = self.metadata.ExteriorOriginal

    local ext_md = (id == false and original_md) or TARDIS:CreateExteriorMetadata(id)

    local oldvortex = self.metadata.Exterior.Parts.vortex
    if oldvortex then
        ext_md.Parts.vortex = TARDIS:CopyTable(oldvortex)
    end

    ext_md.Teleport = TARDIS:CopyTable(original_md.Teleport)
    ext_md.Sounds.Teleport = TARDIS:CopyTable(original_md.Sounds.Teleport)

    if original_md.ProjectedLight and original_md.ProjectedLight.color then
        ext_md.ProjectedLight = ext_md.ProjectedLight or {}
        ext_md.ProjectedLight.color = original_md.ProjectedLight.color
    end

    self.metadata.Exterior = ext_md
    if IsValid(self.interior) then
        self.interior.metadata.Exterior = ext_md
    end

    return ext_md
end

if CLIENT then
    ENT:OnMessage("exterior_metadata_update", function(self,data,ply)
        self:ChangeExteriorMetadata(data[1])
    end)
end

function ENT:ChangeExterior(id, animate, ply, retry)
    if CLIENT then
        self:SendMessage("chameleon_change_exterior", {id, animate, ply, retry})
        return
    end

    if id == nil then
        id = false
    end

    local can_apply,select_failed,msg,msg_is_err = self:CallCommonHook("CanChangeExterior", id, retry)

    if can_apply == false then
        if select_failed then
            TARDIS:ErrorMessage(ply, "Chameleon.FailedExteriorSelect")
        else
            self:SetData("chameleon_selected_exterior", id, true)
            self:SetData("chameleon_exterior_last_selector", ply, true)
            TARDIS:Message(ply, "Chameleon.ExteriorSelected")
        end

        if msg then
            if msg_is_err then
                TARDIS:ErrorMessage(ply, msg)
            else
                TARDIS:Message(ply, msg)
            end
        end

        return
    end
    self:SetData("chameleon_selected_exterior", nil, true)
    self:SetData("chameleon_exterior_last_selector", nil, true)

    local ext_md = self:ChangeExteriorMetadata(id)

    if animate then
        self:SendMessage("chameleon_exterior_animation")
    end

    local anim_time = self.metadata.Exterior.Chameleon.AnimTime
    local delay = (animate and anim_time / 2) or 0

    if animate then
        self:UpdateShadow()
        self:SetData("chameleon_changing", true, true)

        self:Timer("chameleon_changing_reset", anim_time, function()
            self:SetData("chameleon_changing", false, true)
            self:UpdateShadow()
        end)
    end

    self:Timer("chameleon_change", delay, function()
        self:SetData("chameleon_current_exterior", id, true)

        local oldVelocity
        if IsValid(self.phys) then
            oldVelocity = self.phys:GetVelocity()
        end

        self:SetMaterial()
        self:SetSubMaterial()
        -- reset submaterials etc.
        self:SetModel(ext_md.Model)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self.phys = self:GetPhysicsObject()

        if (IsValid(self.phys)) then
            self.phys:SetMass(ext_md.Mass)
            self.phys:EnableGravity(not self:GetData("float"))
            self.phys:EnableMotion(not self:GetPhyslock())
            self.phys:Wake()
            if oldVelocity then
                self.phys:SetVelocity(oldVelocity)
            end
        end

        if IsValid(self.interior) and IsValid(self.interior.portals.exterior) then
            local extportal = self.interior.portals.exterior
            local portal_md = ext_md.Portal

            extportal:SetParent(nil)
            extportal:SetPos(self:LocalToWorld(portal_md.pos))
            extportal:SetAngles(self:LocalToWorldAngles(portal_md.ang))
            extportal:SetWidth(portal_md.width)
            extportal:SetHeight(portal_md.height)
            extportal:SetThickness(portal_md.thickness or 0)
            extportal:SetInverted(portal_md.inverted)
            extportal:SetParent(self)


            -- aligning interior portal
            local intportal = self.interior.portals.interior
            local fallback = self.interior.Fallback.pos

            local floor_z

            if self.metadata.Interior.FloorLevel then
                floor_z = self.metadata.Interior.FloorLevel
            else
                local floor = util.QuickTrace(self.interior:LocalToWorld(fallback) + Vector(0, 0, 30), Vector(0, 0, -0.1) * 99999999).HitPos
                floor = self.interior:WorldToLocal(floor)
                floor_z = floor.z
            end

            local prev_int_z_offset = self:GetData("chameleon_intportal_z_offset", 0)

            local intp_offset = intportal:GetExitPosOffset()
            local intp_offset_real_z = intp_offset.z - prev_int_z_offset

            local intp_midtofloor = self.interior:WorldToLocal(intportal:GetPos()).z - floor_z

            local new_int_z_offset

            if id == false then
                new_int_z_offset = 0
            else
                new_int_z_offset = 0.5 * extportal:GetHeight() - intp_midtofloor
            end

            intportal:SetExitPosOffset(Vector(intp_offset.x, intp_offset.y, intp_offset_real_z + new_int_z_offset))
            self:SetData("chameleon_intportal_z_offset", new_int_z_offset)


            -- aligning exterior portal

            local prev_ext_z_offset = self:GetData("chameleon_extportal_z_offset", 0)

            local extp_offset = extportal:GetExitPosOffset()
            local extp_offset_real_z = extp_offset.z - prev_ext_z_offset

            local new_ext_z_offset
            if id == false then
                new_ext_z_offset = 0
            else
                new_ext_z_offset = intp_midtofloor - 0.5 * extportal:GetHeight()
            end

            extportal:SetExitPosOffset(Vector(extp_offset.x, extp_offset.y, extp_offset_real_z + new_ext_z_offset))
            self:SetData("chameleon_extportal_z_offset", new_ext_z_offset)
        end

        -- exterior parts replacement
        for k,v in pairs(self:GetParts()) do
            if IsValid(v) then
                v:Remove()
            end
        end

        TARDIS:SetupParts(self)
        TARDIS:SetupRandomSkin(self)
        self.Fallback=self.metadata.Exterior.Fallback

        self:CallCommonHook("ExteriorChanged", id)
        self:SendMessage("exterior_changed", {id})

        self:SetData("chameleon_active", (id ~= false), true)

        TARDIS:StatusMessage(ply, "Chameleon.Status", (id ~= false), "Chameleon.Status.Activated", "Chameleon.Status.Deactivated")
    end)
end

function ENT:RetryChameleon(animate)
    local id = self:GetData("chameleon_selected_exterior")
    local ply = self:GetData("chameleon_exterior_last_selector")
    if id ~= nil then
        self:ChangeExterior(id, animate, ply, true)
    end
end

ENT:AddHook("ToggleDoor", "chameleon", function(self,open)
    if open then return end
    self:RetryChameleon(true)
end)

ENT:AddHook("PowerToggled", "chameleon", function(self,on)
    if not on then return end
    self:RetryChameleon(true)
end)

ENT:AddHook("MigrateData", "chameleon", function(self,parent,data)
    self:SetData("chameleon_selected_exterior", self:GetData("chameleon_current_exterior"), true)
end)

ENT:AddHook("MatStart", "chameleon", function(self)
    local planned_ext = self:GetData("chameleon_planned_exterior")
    if planned_ext then
        self:SetData("chameleon_selected_exterior", planned_ext)
        self:SetData("chameleon_planned_exterior", nil)
    end
    self:RetryChameleon(false)
end)

ENT:AddHook("CanToggleDoor", "chameleon", function(self)
    if self:GetData("chameleon_changing") then
        return false
    end
end)

ENT:AddHook("ShouldDrawShadow", "chameleon", function(self)
    if self:GetData("chameleon_changing") then
        return false
    end
end)


ENT:AddHook("CanChangeExterior", "chameleon", function(self, id, retry)
    if self:GetData("chameleon_changing") then
        return false,true,"Chameleon.FailReasons.AlreadyChanging",true
    end

    if not retry then
        local selected = self:GetData("chameleon_selected_exterior")
        local current = self:GetData("chameleon_current_exterior", nil)

        if id == selected then
            return false,true,"Chameleon.FailReasons.AlreadySelected",true
        elseif selected == nil and id == current then
            return false,true,"Chameleon.FailReasons.SameSelected",true
        end
    end
end)

ENT:AddHook("ShouldDraw", "chameleon", function(self)
    if IsValid(self.interior) and self:GetData("chameleon_active", false)
        and wp.drawing and wp.drawingent == self.interior.portals.interior
    then
        return false
    end
end)

ENT:AddHook("ShouldDrawPart", "chameleon_door", function(self, part)
    if IsValid(self.interior) and self:GetData("chameleon_active", false) and part ~= nil
        and wp.drawing and wp.drawingent == self.interior.portals.interior
        and part == TARDIS:GetPart(self, "door")
    then
        return false
    end
end)

function ENT:IsChameleonActive()
    return self:GetData("chameleon_active", false)
end