-- Parts

---@class gmod_tardis_part
---@field ID string?
---@field Name string?
---@field Model string?
---@field AutoSetup boolean?
---@field AutoPosition boolean?
---@field Collision boolean?
---@field CollisionUse boolean?
---@field PortalNoCollide boolean?
---@field NoStrictUse boolean?
---@field ShouldTakeDamage boolean?
---@field BypassIsomorphic boolean?
---@field Motion boolean?
---@field StartFrozen boolean?
---@field ResetPositionOnUse boolean?
---@field UnfreezeHint boolean?
---@field EnabledOnStart boolean?
---@field PowerOffUse boolean?
---@field HasUse boolean?
---@field HasUseBasic boolean?
---@field Animate boolean?
---@field AnimateSpeed number?
---@field AnimateOptions tardis_part_animation?
---@field ExtraAnimations table<string, tardis_part_animation>?
---@field animation tardis_part_animation_state?
---@field Sound string?
---@field SoundOn string?
---@field SoundOff string?
---@field SoundNoPower string|false|nil
---@field SoundOnNoPower string?
---@field SoundOffNoPower string?
---@field SoundLoop string?
---@field SoundLoopVolume number?
---@field SoundStop string?
---@field SoundPos Vector?
---@field PowerOffSound boolean?
---@field ClientThinkOverride boolean?
---@field ClientDrawOverride boolean?
---@field ShouldDrawOverride boolean?
---@field Translucent boolean?
---@field CustomAlpha boolean?
---@field NoShadow boolean?
---@field NoShadowCopy boolean?
---@field NoCloak boolean?
---@field NoDraw boolean?
---@field InvisibleFade boolean?
---@field InvisibleCollision boolean?
---@field FadeSpeed number?
---@field Scale number?
---@field InteriorPart boolean?
---@field ExteriorPart boolean?
---@field AllowThroughPortals boolean?
---@field DrawThroughPortal boolean?
---@field ShadowCollision boolean?
---@field ShadowPending boolean?
---@field ShadowLocalPos Vector?
---@field ShadowLocalAng Angle?
---@field LastShadowTarget Vector?
---@field exterior gmod_tardis
---@field interior gmod_tardis_interior
---@field parent gmod_tardis|gmod_tardis_interior
---@field o tardis_part_original
---@field Control string
---@field Pos Vector
---@field Ang Angle
---@field static boolean?
---@field Invisible boolean?
---@field Enabled boolean?
---@field MatrixScale Vector?
---@field Exteriors table<string, table>?
---@field Interiors table<string, table>?
---@field UseTransparencyFix boolean?
---@field Use fun(self: gmod_tardis_part, activator: Player, caller?: Entity, useType?: number, value?: number)?
---@field UseBasic fun(self: gmod_tardis_part, activator: Player)?
---@field PreDraw fun(self: gmod_tardis_part)?
---@field PostDraw fun(self: gmod_tardis_part)?
---@field OnBodygroupChanged fun(self: gmod_tardis_part, bodygroup: number, value: number)?

---@class tardis_part_animation
---@field Type string?
---@field MaxPos number?
---@field MinPos number?
---@field StartPos number?
---@field Speed number?
---@field PoseParameter string?
---@field StopAnywhere boolean?
---@field NoDirectionChange boolean?
---@field NoPowerFreeze boolean?
---@field ReturnAfterStop boolean?
---@field SpeedOverrideFunc function?
---@field ConditionFunc function?
---@field CustomAnimationFunc function?

---@class tardis_part_animation_state
---@field type string
---@field max number
---@field min number
---@field pos number
---@field speed number
---@field pose_param string
---@field stop_anywhere boolean?
---@field constant_dir boolean?
---@field no_power boolean?
---@field should_return boolean?
---@field speed_override_func function?
---@field condition_func function?
---@field custom_func function?

-- List all part fields for casing normalisation e.g. soundon -> SoundOn so interior
-- part field overrides can be written in any casing without causing issues.
local PART_FIELDS = {
    "ID", "Name", "Model", "AutoSetup", "AutoPosition", "Collision", "CollisionUse",
    "PortalNoCollide", "NoStrictUse", "ShouldTakeDamage", "BypassIsomorphic", "Motion",
    "StartFrozen", "ResetPositionOnUse", "UnfreezeHint", "EnabledOnStart", "PowerOffUse",
    "Animate", "AnimateSpeed", "AnimateOptions", "ExtraAnimations", "Sound", "SoundOn",
    "SoundOff", "SoundNoPower", "SoundOnNoPower", "SoundOffNoPower", "SoundLoop",
    "SoundLoopVolume", "SoundStop", "SoundPos", "PowerOffSound", "ClientThinkOverride",
    "ClientDrawOverride", "ShouldDrawOverride", "Translucent", "CustomAlpha", "NoShadow",
    "NoShadowCopy", "NoCloak", "NoDraw", "InvisibleFade", "InvisibleCollision", "FadeSpeed",
    "Scale", "AllowThroughPortals", "DrawThroughPortal", "ShadowCollision", "Pos", "Ang",
    "Invisible", "Enabled", "MatrixScale", "Exteriors", "Interiors", "UseTransparencyFix",
}

local PART_FIELDS_NORMALIZED = {}
for _, name in ipairs(PART_FIELDS) do
    PART_FIELDS_NORMALIZED[string.lower(name)] = name
end

---@param tbl table
local function NormalizePartFields(tbl)
    local remaps
    for k in pairs(tbl) do
        if isstring(k) then
            local canon = PART_FIELDS_NORMALIZED[k:lower()]
            if canon and canon ~= k then
                remaps = remaps or {}
                remaps[k] = canon
            end
        end
    end
    if not remaps then return end
    for k, canon in pairs(remaps) do
        if tbl[canon] == nil then
            tbl[canon] = tbl[k]
        end
        tbl[k] = nil
    end
end

if SERVER then
    util.AddNetworkString("TARDIS-SetupPart")
end

---@param self gmod_tardis_part
function TARDIS.ShouldDrawInteriorPart(self)
    local int=self.interior
    local ext=self.exterior

    if self.AllowThroughPortals then
        return true
    end

    if not IsValid(int) then
        return false
    end

    if int:CallHook("ShouldDraw") ~= false then
        return true
    end

    if ext:DoorOpen() and self.ClientDrawOverride then
        local dist_to_portal = LocalPlayer():GetPos():Distance(ext:GetPos())
        local close_dist = TARDIS:GetSetting("portals-closedist")
        if dist_to_portal < close_dist then
            return true
        end
    end

    if self.DrawThroughPortal then
        return (int.scannerrender or (IsValid(wp.drawingent) and wp.drawingent:GetParent()==int))
    end

    return false
end

---@param self gmod_tardis_part
function TARDIS.ShouldDrawExteriorPart(self)
    local ext=self.exterior

    if ext:CallHook("ShouldDraw") ~= false then
        return true
    end

    if self.ShouldDrawOverride then
        return true
    end

    return false
end

---@param self gmod_tardis_part
---@param override boolean?
function TARDIS.DrawOverride(self,override)
    if self.NoDraw then return end
    if self:IsInvisible() and not (self.alpha and self.alpha > 0) then return end

    local ext=self.exterior

    if IsValid(ext) then
        if (self.InteriorPart and TARDIS.ShouldDrawInteriorPart(self))
            or (self.ExteriorPart and TARDIS.ShouldDrawExteriorPart(self))
        then
            if not IsValid(self.parent) then return end

            if self.parent:CallHook("ShouldDrawPart", self) == false then return end
            if self.parent:CallHook("PreDrawPart",self) == false then return end
            if self.PreDraw then self:PreDraw() end
            if self.UseTransparencyFix and (not override) then
                render.SetBlend(0)
                self.o.Draw(self)
                render.SetBlend(1)
            else
                if self.alpha and self.alpha < 1 then
                    if self.alpha > 0 then
                        render.OverrideColorWriteEnable(true, false)
                        self.o.Draw(self)
                        render.OverrideColorWriteEnable(false, false)
                    end
                    render.SetBlend(self.alpha)
                end
                self.o.Draw(self)
                if self.alpha and self.alpha < 1 then
                    render.SetBlend(1)
                end
            end
            if self.PostDraw then self:PostDraw() end
            self.parent:CallHook("PostDrawPart",self)
        end
    end
end

---@param self gmod_tardis_part
---@param can_move boolean
---@param a tardis_part_animation_state
---@param target number
---@param should_reset boolean
function TARDIS.DoPartAnimation(self, can_move, a, target, should_reset)
    local pose_pos = a.pos
    local speed = a.speed

    if a.condition_func then
        can_move = can_move and a.condition_func(self, a, target, should_reset)
    end

    if can_move then
        if a.speed_override_func then
            speed = a.speed_override_func(self, a, target, should_reset)
        end

        pose_pos = math.Approach(pose_pos, target, FrameTime() * speed)

        if pose_pos == target and should_reset then
            pose_pos = (a.max == pose_pos and a.min) or a.max
        end
    end

    self:SetPoseParameter(a.pose_param, pose_pos)
    self:InvalidateBoneCache()
    a.pos = pose_pos
end

---@param self gmod_tardis_part
---@param anim tardis_part_animation
function TARDIS.InitAnimation(self, anim)
    -- `anim` is either the part or extra animation table

    local a = {}

    a.type = anim.Type or "toggle"
    -- toggle / perpetual_use / travel / idle / custom

    a.max = anim.MaxPos or 1
    a.min = anim.MinPos or 0
    a.pos = anim.StartPos or (self.EnabledOnStart and self.posemax) or a.min
    a.speed = anim.Speed or 1.5
    a.pose_param = anim.PoseParameter or "switch"
    a.stop_anywhere = anim.StopAnywhere -- applies to perpetual_use
    a.constant_dir = anim.NoDirectionChange -- applies to perpetual_use and toggle
    a.no_power = not anim.NoPowerFreeze -- applies to travel and idle
    a.should_return = anim.ReturnAfterStop -- applies to travel and idle
    a.speed_override_func = anim.SpeedOverrideFunc
    a.condition_func = anim.ConditionFunc
    a.custom_func = anim.CustomAnimationFunc

    if a.pos ~= 0 then
        self:SetPoseParameter(a.pose_param, a.pos)
        self:InvalidateBoneCache()
    end

    return a
end

---@param self gmod_tardis_part
---@param a tardis_part_animation_state
function TARDIS.ProcessAnimation(self, a)

    if a.type == "travel" then
        local power_ok = self.exterior:GetPower() or a.no_power
        local returning = a.should_return and a.pos ~= a.min
        local move = power_ok and (self.exterior:IsTravelling() or returning)

        TARDIS.DoPartAnimation(self, move, a, a.max, move)

    elseif a.type == "idle" then
        local returning = a.should_return and a.pos ~= a.min
        local move = self.exterior:GetPower() or a.no_power
        TARDIS.DoPartAnimation(self, move or returning, a, a.max, true)

    elseif a.type == "perpetual_use" or a.type == "toggle" then

        local target = (a.constant_dir or self:GetOn()) and a.max or a.min

        if a.type == "perpetual_use" then
            local ply = LocalPlayer()
            local looked_at = self:BeingLookedAtByLocalPlayer()

            local function is_sonic_pressed()
                if not looked_at then
                    return false
                end
                if ply:GetActiveWeapon() ~= ply:GetWeapon("swep_sonicsd") then
                    return false
                end
                return ply:KeyDown(IN_ATTACK) or ply:KeyDown(IN_ATTACK2)
            end

            local moving = looked_at and ply:KeyDown(IN_USE)

            if is_sonic_pressed() then
                self.sonic_activation_start = self.sonic_activation_start or CurTime()
                if CurTime() - self.sonic_activation_start > 0.5 then
                    moving = true
                end
            elseif self.sonic_activation_start then
                self.sonic_activation_start = nil
            end

            local move = (not a.stop_anywhere) or moving

            if moving then
                self.last_moved = CurTime()
            end

            local moved_recently = CurTime() - (self.last_moved or 0) < 0.1

            if moving and self.SoundLoop and not self.use_sound then
                self.use_sound = CreateSound(self, self.SoundLoop)
                self.use_sound:SetSoundLevel(90)
                self.use_sound:PlayEx(self.SoundLoopVolume or 0.75, 100)
            elseif self.use_sound and not moved_recently then
                self.use_sound:Stop()
                self.use_sound = nil

                if self.SoundStop then
                    self:EmitSound(self.SoundStop)
                end
            end

            TARDIS.DoPartAnimation(self, move, a, target, moving)
        else
            TARDIS.DoPartAnimation(self, true, a, target, false)
        end

    elseif a.type == "custom" then
        local custom_func = a.custom_func
        if custom_func then custom_func(self, a) end
    end
end

--- The original SENT methods, saved by SetupOverrides before they are wrapped.
---@class tardis_part_original
---@field Initialize fun(self: gmod_tardis_part)
---@field Think fun(self: gmod_tardis_part)
---@field Draw fun(self: gmod_tardis_part, flags?: number)
---@field Use fun(self: gmod_tardis_part, activator: Entity, caller?: Entity, useType?: number, value?: number)

local overrides={
    ["Draw"]={TARDIS.DrawOverride, CLIENT},
    ["Initialize"]={
        ---@param self gmod_tardis_part
        function(self)
        if CLIENT then
            if self.Animate then
                self.AnimateOptions = self.AnimateOptions or {}

                -- supporting old format
                if self.AnimateSpeed then
                    self.AnimateOptions.Speed = self.AnimateSpeed
                end

                self.animation = TARDIS.InitAnimation(self, self.AnimateOptions)

                if self.ExtraAnimations then
                    self.extra_animations = {}
                    for k,v in pairs(self.ExtraAnimations) do
                        self.extra_animations[k] = TARDIS.InitAnimation(self, v)
                    end
                end

                if self.InvisibleFade then
                    self.lastinvisible = self:IsInvisible()
                    self.alpha = 1
                end
            end
            net.Start("TARDIS-SetupPart")
                net.WriteEntity(self)
            net.SendToServer()
        else
            if not IsValid(self.exterior) then
                self:Remove()
                return
            end
            self.o.Initialize(self)
            local col = self:GetColor()
            if col.a ~= 255 then
                -- compatibility workaround for older addons that set alpha on init
                self:SetRenderMode( RENDERMODE_TRANSALPHA )
            end
            self.init_pos = self:GetPos()
            self.init_ang = self:GetAngles()
        end
    end, CLIENT or SERVER},
    ["Think"]={
        ---@param self gmod_tardis_part
        function(self)
        local int=self.interior
        local ext=self.exterior
        if self._init and IsValid(ext) then
            local function is_visible_through_door()
                if not ext:DoorOpen() then return false end
                if not self.ClientThinkOverride then return false end
                local ply_pos = LocalPlayer():GetPos()
                local ext_pos = ext:GetPos()
                local close_dist = TARDIS:GetSetting("portals-closedist")

                return ply_pos:Distance(ext_pos) < close_dist
            end

            if (IsValid(int) and (int:CallHook("ShouldThink") ~= false)) or self.ExteriorPart or self.AllowThroughPortals or is_visible_through_door() then
                if self.Animate then
                    TARDIS.ProcessAnimation(self, self.animation)

                    if self.extra_animations then
                        for _,v in pairs(self.extra_animations) do
                            TARDIS.ProcessAnimation(self, v)
                        end
                    end
                end

                if self.InvisibleFade then
                    local invisible,nofade = self:IsInvisible()
                    if invisible ~= self.lastinvisible then
                        self.lastinvisible = invisible
                        self.invisibletarget = invisible and 0 or 1
                        if nofade then
                            self.alpha = self.invisibletarget
                        end
                    end
                    if self.alpha ~= self.invisibletarget then
                        self.alpha = math.Approach(self.alpha or 1, self.invisibletarget, FrameTime() * (self.FadeSpeed or 1))
                    end
                end
                return self.o.Think(self)
            end
        end
    end, CLIENT},
    ["Use"]={
        ---@param self gmod_tardis_part
        ---@param a Entity
        function(self,a,...)
        if SERVER and TARDIS.debug_tips and self.InteriorPart then
            return TARDIS.DebugTipsFunction(self, a, ...)
        end

        if SERVER then
            self.parent:SendMessage("part_use", {self, a, ...})
        end

        local res
        if (not self.NoStrictUse) and IsValid(a) and a:IsPlayer() and a:GetEyeTraceNoCursor().Entity~=self then return end
        local allowed, animate
        if self.ExteriorPart then
            allowed, animate = self.exterior:CallHook("CanUsePart",self,a)
        else
            allowed, animate = self.interior:CallHook("CanUsePart",self,a)
        end

        if self.PowerOffUse == false and not self.interior:GetPower() then
            if SERVER then
                TARDIS:ErrorMessage(a, "Common.PowerDisabledControl")
            end
        else
            if allowed~=false then
                if self.HasUseBasic and self.UseBasic then
                    self.UseBasic(self,a,...)
                end
                local blockuse=false
                if SERVER and self.Control and (not self.HasUse) then
                    TARDIS:Control(self.Control,a,self)
                    blockuse=true
                end

                if SERVER and self.Motion and IsValid(a) and a:IsPlayer() and (self.parent:CheckSecurity(a) or self.BypassIsomorphic) then
                    local phys = self:GetPhysicsObject()
                    local walk = a:KeyDown(IN_WALK)
                    if walk and self.StartFrozen and IsValid(phys) and not phys:IsMoveable() and not self.unfrozen then
                        phys:EnableMotion(true)
                        phys:Wake()
                        if self.ResetPositionOnUse then
                            TARDIS:Message(a, "Parts.Moveable.UnfreezeWithResetPositionOnUse")
                        else
                            TARDIS:Message(a, "Parts.Moveable.Unfreeze")
                        end
                        blockuse=true
                        self.unfrozen=true
                    elseif walk and self.ResetPositionOnUse then
                        self:SetPos(self.init_pos)
                        self:SetAngles(self.init_ang)
                        if self.StartFrozen and IsValid(phys) then
                            phys:EnableMotion(false)
                            self.unfrozen=nil
                            self.unfreezehint=nil
                        end
                        TARDIS:Message(a, "Parts.Moveable.Reset")
                        blockuse=true
                    elseif not walk and self.StartFrozen and IsValid(phys) and not phys:IsMoveable() then
                        if not self.unfreezehint then
                            self.unfreezehint={}
                        end
                        if not self.unfreezehint[a] then
                            self.unfreezehint[a]=true
                            TARDIS:Message(a, "Parts.Moveable.UnfreezeHint")
                        end
                    end
                end

                if not blockuse then
                    res=self.o.Use(self,a,...)
                end
            end

            if SERVER and (animate~=false) and (res~=false) then
                TARDIS:TogglePart(self)
                if self.ExteriorPart then
                    self.exterior:CallHook("PartUsed",self,a)
                elseif self.interior then
                    self.interior:CallHook("PartUsed",self,a)
                end
            end
        end

        if SERVER and self.Motion and IsValid(a) and a:IsPlayer()
            and not (self.ResetPositionOnUse and a:KeyDown(IN_WALK))
            and not self:IsPlayerHolding() then

            local phys = self:GetPhysicsObject()
            if IsValid(phys) and phys:IsMoveable() then 
                a:PickupObject(self)
            end
        end
        return res
    end, SERVER or CLIENT},
    ["OnRemove"]={function(self,a,...)
        if self.use_sound then
            self.use_sound:Stop()
            self.use_sound = nil
        end
    end, CLIENT},
}

---@param e gmod_tardis_part
function SetupOverrides(e)
    local name=e.ClassName
    if not e.o then
        e.o={}
    end
    for k,v in pairs(overrides) do
        local o=scripted_ents.GetMember(name, k)
        if o and v[2] then
            if not e.o[k] then
                e.o[k] = o
            end
            e[k] = v[1]
        end
    end
    scripted_ents.Register(e,name)
end

---@type table<string, {class: string, source: string}>
local parts={}

---@api
---@param ent Entity
---@param id string
---@return Entity
function TARDIS:GetPart(ent,id)
    return IsValid(ent) and ent.parts and ent.parts[id] or NULL
end

-- Functionally identical to PART = {} but gives proper type checking for parts
---@api
---@return gmod_tardis_part
function TARDIS:NewPart()
    return {}
end

---@api
---@param ent Entity
---@return table<string, gmod_tardis_part>|false|nil
function TARDIS:GetParts(ent)
    return IsValid(ent) and ent.parts
end

local overridequeue={}
postinit=postinit or false -- local vars cannot stay on autorefresh

---@api
---@param part gmod_tardis_part
function TARDIS:AddPart(part)
    local source = debug.getinfo(2).short_src

    if string.lower(part.ID) ~= part.ID then
        error("The part ID \"" .. part.ID .. "\" contains uppercase symbols. All part IDs have to be lowercase.")
    end

    if parts[part.ID] and parts[part.ID].source ~= source then
        error("Duplicate part ID registered: " .. part.ID .. " (exists in both " .. parts[part.ID].source .. " and " .. source .. ")")
    end

    if not part.Name then
        part.Name = part.ID -- most creators just copy the ID anyway
    end

    part=table.Copy(part)
    part.HasUseBasic = part.UseBasic ~= nil
    part.HasUse = part.Use ~= nil
    part.Base = "gmod_tardis_part"
    local class="gmod_tardis_part_"..part.ID
    scripted_ents.Register(part,class)
    if postinit then
        SetupOverrides(part)
    else
        overridequeue[part.ID] = part
    end
    parts[part.ID] = { class = class, source = source }
end

---@param id string
function TARDIS:GetRegisteredPart(id)
    return scripted_ents.Get(parts[id].class)
end

hook.Add("InitPostEntity", "tardis-parts", function()
    for _,v in pairs(overridequeue) do
        SetupOverrides(v)
    end
    overridequeue={}
    postinit=true
end)

---@param portal linked_portal_door
---@param ent Entity
hook.Add("wp-shouldghost", "tardis-parts", function(portal, ent)
    if ent.TardisPart and not ent.AllowThroughPortals then return false end
end)

---@param self gmod_tardis|gmod_tardis_interior
---@param e gmod_tardis_part
---@param id string
local function GetData(self,e,id)
    local data={}
    if self.TardisExterior then
        if e.Exteriors and e.Exteriors[self.metadata.ID] then
            data=e.Exteriors[self.metadata.ID]
        elseif TARDIS.Exteriors and TARDIS.Exteriors[self.metadata.ID] then
            data=TARDIS.Exteriors[self.metadata.ID]
        elseif self.metadata.Exterior.Parts and self.metadata.Exterior.Parts[id] then
            data=self.metadata.Exterior.Parts[id]
        end
    elseif self.TardisInterior then
        if e.Interiors and e.Interiors[self.metadata.ID] then
            data=e.Interiors[self.metadata.ID]
        elseif TARDIS.Interiors and TARDIS.Interiors[self.metadata.ID] then
            data=TARDIS.Interiors[self.metadata.ID]
        elseif self.metadata.Interior.Parts and self.metadata.Interior.Parts[id] then
            data=self.metadata.Interior.Parts[id]
        end
    end
    return data
end

-- Swept-shadow collision: a part's own physobj follows the shell so it pushes props as
-- the TARDIS moves. Driven each tick from the exterior parts module over its GetParts().
local SHADOW_TELEPORT_DIST = 128
local SHADOW_MASS = 50000

---@param part gmod_tardis_part
local function SetupPartShadow(part)
    local phys = part:GetPhysicsObject()
    if not IsValid(phys) then return end
    phys:EnableMotion(false)
    phys:SetMass(SHADOW_MASS)
    if IsValid(part.parent) then
        constraint.NoCollide(part.parent, part, 0, 0)
    end
    part.ShadowPending = true -- promoted next tick, past the spawn-tick stuck-push that would fling the parent
    part.LastShadowTarget = nil
    part.ShadowLocalPos = nil
    part.ShadowLocalAng = nil
end

-- Captured on each realm right after Initialize: the WorldToLocal/LocalToWorld round-trip
-- gives the same offset wherever the shell is, so server and client agree.
---@param part gmod_tardis_part
local function CapturePartShadowOffset(part)
    if not (part.ShadowCollision and part.ExteriorPart) then return end
    if not IsValid(part.parent) then return end
    part.ShadowLocalPos = part.parent:WorldToLocal(part:GetPos())
    part.ShadowLocalAng = part.parent:WorldToLocalAngles(part:GetAngles())
end

---@param part gmod_tardis_part
function TARDIS:UpdatePartShadow(part)
    local parent = part.parent
    if not IsValid(parent) or not part.ShadowLocalPos then return end

    local tpos = parent:LocalToWorld(part.ShadowLocalPos)
    local tang = parent:LocalToWorldAngles(part.ShadowLocalAng)
    if part:GetPos() ~= tpos or part:GetAngles() ~= tang then
        part:SetPos(tpos)
        part:SetAngles(tang)
    end

    if CLIENT then return end

    if part:GetSolid() == SOLID_NONE then -- door open / dematerialising: dormant, re-snap on re-solidify
        part.LastShadowTarget = nil
        return
    end

    local phys = part:GetPhysicsObject()
    if not IsValid(phys) then return end

    if part.ShadowPending then
        part:MakePhysicsObjectAShadow(false, false)
        phys = part:GetPhysicsObject()
        if IsValid(phys) then phys:SetMass(SHADOW_MASS) end
        part.ShadowPending = false
        part.LastShadowTarget = nil
    end

    local last = part.LastShadowTarget
    if (not last) or tpos:Distance(last) > SHADOW_TELEPORT_DIST then
        phys:SetPos(tpos) -- single-tick warp (spawn/teleport): snap, don't sweep
        phys:SetAngles(tang)
    elseif (not phys:GetPos():IsEqualTol(tpos, 0.05)) or phys:GetAngles() ~= tang then
        phys:Wake()
        phys:UpdateShadow(tpos, tang, FrameTime())
    end
    part.LastShadowTarget = tpos
end

---@param self gmod_tardis|gmod_tardis_interior
---@param e gmod_tardis_part
---@param id string
local function AutoSetup(self,e,id)
    local data=GetData(self,e,id)
    if not data then return end

    e:SetModel(e.Model)
    e:PhysicsInit( SOLID_VPHYSICS )
    e:SetMoveType( MOVETYPE_VPHYSICS )
    e:SetSolid( SOLID_VPHYSICS )
    e:SetRenderMode( RENDERMODE_NORMAL )
    e:SetUseType( SIMPLE_USE )
    local phys = e:GetPhysicsObject()
    e.phys = phys
    if phys:IsValid() then
        if e.Motion and not e.StartFrozen then
            phys:EnableMotion(true)
            phys:Wake()
        else
            phys:EnableMotion(false)
        end
    end
    if not e.Collision then
        if e.CollisionUse == false then
            e:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
        else
            e:SetCollisionGroup(COLLISION_GROUP_WORLD)
        end
    end
    if e.AutoPosition ~= false then
        e:SetPos(self:LocalToWorld(e.Pos or Vector(0,0,0)))
        e:SetAngles(self:LocalToWorldAngles(e.Ang or Angle(0,0,0)))
    end
    if not e.Collision then
        e:SetParent(self)
    end
    if SERVER and e.ShadowCollision and e.ExteriorPart then
        SetupPartShadow(e)
    end
    if e.Scale then
        e:SetModelScale(e.Scale,0)
    end
    if e.NoShadow then
        e:DrawShadow(false)
    end
    if e.Invisible then
        e:SetInvisible(true, true)
    end
end

---@param e gmod_tardis_part
local function SetupPartControl(e)
    local parent = e.parent
    if (parent == e.interior) then
        controls_metadata = parent.metadata.Interior.Controls
    else
        controls_metadata = parent.metadata.Exterior.Controls
    end
    if controls_metadata ~= nil then
        if controls_metadata[e.ID] ~= nil then
            e.Control = controls_metadata[e.ID]
        end
    end
    if e.Control then
        parent.controlparts = parent.controlparts or {}
        parent.controlparts[e.Control] = parent.controlparts[e.Control] or {}
        parent.controlparts[e.Control][e.ID] = e
    end
end

if SERVER then
    ---@param ent gmod_tardis|gmod_tardis_interior
    function TARDIS:SetupParts(ent)
        ent.parts={}
        local tempparts={}
        local data
        if ent.TardisExterior then
            data=ent.metadata.Exterior
        elseif ent.TardisInterior then
            data=ent.metadata.Interior
        end
        if data and data.Parts then
            for k,v in pairs(data.Parts) do
                if v then
                    local partid = k
                    if type(v)=="table" and v.id then
                        partid = v.id
                    end
                    local part=parts[partid]
                    if part then
                        tempparts[k]=part.class
                    else
                        ErrorNoHaltWithStack("Attempted to create invalid part: " .. k)
                    end
                end
            end
        end
        for k,v in pairs(parts) do
            if not tempparts[k] then
                local stored = assert(scripted_ents.GetStored(v.class))
                local tbl = assert(stored.t)
                local t
                if ent.TardisExterior then
                    t=tbl.Exteriors
                elseif ent.TardisInterior then
                    t=tbl.Interiors
                end
                if t and t[ent.metadata.ID] then
                    tempparts[k]=v.class
                end
            end
        end
        ent.controlparts = {}
        for k,v in pairs(tempparts) do
            local part_data = table.Copy(GetData(ent, scripted_ents.GetStored(v).t, k))
            NormalizePartFields(part_data)

            if part_data.Enabled ~= false then
                local e=ents.Create(v)
                -- Creation only fails on edict exhaustion, where spawning is already broken.
                ---@cast e gmod_tardis_part
                Doors:SetupOwner(e,ent:GetCreator())
                e.exterior=(ent.TardisExterior and ent or ent.exterior)
                e.interior=(ent.TardisInterior and ent or ent.interior)
                e.parent=ent
                e.ExteriorPart=(e.parent==e.exterior)
                e.InteriorPart=(e.parent==e.interior)
                table.Merge(e,part_data)

                SetupPartControl(e)
                if e.EnabledOnStart then
                    e:SetOn(true)
                end

                ent.parts[k]=e
                if e.AutoSetup then
                    AutoSetup(ent,e,k)
                end
                e:Spawn()
                e:Activate()
                CapturePartShadowOffset(e)
                ent:DeleteOnRemove(e)
            end
        end
    end
    net.Receive("TARDIS-SetupPart", function(_,ply)
        local e=net.ReadEntity()
        if e.ID then
            net.Start("TARDIS-SetupPart")
                net.WriteEntity(e)
                net.WriteEntity(e.exterior)
                net.WriteEntity(e.interior)
                net.WriteBool(e.ExteriorPart)
                net.WriteString(e.ID)
            net.Send(ply)
        end
    end)

    ---@api
    ---@param part gmod_tardis_part
    function TARDIS:TogglePart(part)
        local on = part:GetOn()
        if part.PowerOffSound ~= false or part.interior:GetPower() then
            local part_sound = nil

            if not part.exterior:GetPower() then
                if part.SoundOffNoPower and on then
                    part_sound = part.SoundOffNoPower
                elseif part.SoundOnNoPower and (not on) then
                    part_sound = part.SoundOnNoPower
                elseif part.SoundNoPower then
                    part_sound = part.SoundNoPower
                end
            end

            if part_sound == nil then
                if part.SoundOff and on then
                    part_sound = part.SoundOff
                elseif part.SoundOn and (not on) then
                    part_sound = part.SoundOn
                elseif part.Sound then
                    part_sound = part.Sound
                end
            end

            if part_sound and part.SoundPos then
                sound.Play(part_sound, part:LocalToWorld(part.SoundPos))
            elseif part_sound then
                part:EmitSound(part_sound)
            end
        end
        part:SetOn(not on)
    end
else
    ---@param ent Entity
    ---@param name string
    ---@param ext gmod_tardis
    ---@param int gmod_tardis_interior
    ---@param parent Entity
    function TARDIS:SetupPart(ent,name,ext,int,parent)
        if IsValid(ent) and IsValid(parent) then
            ent.exterior=ext
            ent.interior=int
            ent.parent=parent
            ent.ExteriorPart=(parent==ext)
            ent.InteriorPart=(parent==int)
            local data=table.Copy(GetData(parent,ent,name))
            NormalizePartFields(data)
            table.Merge(ent,data)

            if ent.Translucent then
                ent.RenderGroup = RENDERGROUP_TRANSLUCENT
            end

            if not parent.controlparts then parent.controlparts = {} end
            SetupPartControl(ent)
            if ent.EnabledOnStart then
                ent:SetOn(true)
            end

            if not parent.parts then parent.parts={} end
            parent.parts[name]=ent
            if ent.MatrixScale then
                local matrix = Matrix()
                matrix:Scale(ent.MatrixScale)
                ent:EnableMatrix("RenderMultiply",matrix)
            end
            local o = ent.o
            if o and o.Initialize then
                o.Initialize(ent)
            end
            CapturePartShadowOffset(ent)
            ent._init=true
        end
    end
    net.Receive("TARDIS-SetupPart", function(ply)
        local e=net.ReadEntity()
        local ext=net.ReadEntity()
        local int=net.ReadEntity()
        local extpart=net.ReadBool()
        local parent
        if extpart then
            parent=ext
        else
            parent=int
        end
        local name = net.ReadString()
        -- The TARDIS may have been removed before this message arrived, leaving parent a NULL entity.
        if not IsValid(parent) then return end
        if parent._init then
            TARDIS:SetupPart(e,name,ext,int,parent)
        else
            if not parent.partqueue then parent.partqueue = {} end
            parent.partqueue[e] = name
        end
    end)
end

-- Loads parts
TARDIS:LoadFolder("parts",false,true)
