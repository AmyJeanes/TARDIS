-- Parts

if SERVER then
    util.AddNetworkString("TARDIS-SetupPart")
end

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

function TARDIS.DrawOverride(self,override)
    if self.NoDraw then return end
    if self:IsInvisible() and not (self.alpha and self.alpha > 0) then return end

    local int=self.interior
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
        a.custom_func(self, a)
    end
end

local overrides={
    ["Draw"]={TARDIS.DrawOverride, CLIENT},
    ["Initialize"]={function(self)
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
    ["Think"]={function(self)
        local int=self.interior
        local ext=self.exterior
        if self._init and IsValid(int) and IsValid(ext) then
            local think_ok = (int:CallHook("ShouldThink") ~= false)

            local function is_visible_through_door()
                if not ext:DoorOpen() then return false end
                if not self.ClientThinkOverride then return false end
                local ply_pos = LocalPlayer():GetPos()
                local ext_pos = ext:GetPos()
                local close_dist = TARDIS:GetSetting("portals-closedist")

                return ply_pos:Distance(ext_pos) < close_dist
            end

            if think_ok or self.ExteriorPart or self.AllowThroughPortals or is_visible_through_door() then
                if self.Animate then
                    TARDIS.ProcessAnimation(self, self.animation)

                    if self.extra_animations then
                        for k,v in pairs(self.extra_animations) do
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
    ["Use"]={function(self,a,...)
        if SERVER and TARDIS.debug_tips and self.InteriorPart then
            return TARDIS.DebugTipsFunction(self, a, ...)
        end

        if SERVER then
            self.parent:SendMessage("part_use", {self, a, ...})
        end

        local call=false
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
                if self.HasUseBasic then
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

local parts={}

function TARDIS:GetPart(ent,id)
    return IsValid(ent) and ent.parts and ent.parts[id] or NULL
end

function TARDIS:GetParts(ent)
    return IsValid(ent) and ent.parts
end

local overridequeue={}
postinit=postinit or false -- local vars cannot stay on autorefresh

function TARDIS:AddPart(e)
    local source = debug.getinfo(2).short_src

    if string.lower(e.ID) ~= e.ID then
        error("The part ID \"" .. e.ID .. "\" contains uppercase symbols. All part IDs have to be lowercase.")
    end

    if parts[e.ID] and parts[e.ID].source ~= source then
        error("Duplicate part ID registered: " .. e.ID .. " (exists in both " .. parts[e.ID].source .. " and " .. source .. ")")
    end

    if not e.Name then
        e.Name = e.ID -- most creators just copy the ID anyway
    end

    e=table.Copy(e)
    e.HasUseBasic = e.UseBasic ~= nil
    e.HasUse = e.Use ~= nil
    e.Base = "gmod_tardis_part"
    local class="gmod_tardis_part_"..e.ID
    scripted_ents.Register(e,class)
    if postinit then
        SetupOverrides(e)
    else
        overridequeue[e.ID] = e
    end
    parts[e.ID] = { class = class, source = source }
end

function TARDIS:GetRegisteredPart(id)
    return scripted_ents.Get(parts[id].class)
end

hook.Add("InitPostEntity", "tardis-parts", function()
    for k,v in pairs(overridequeue) do
        SetupOverrides(v)
    end
    overridequeue={}
    postinit=true
end)

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

local function AutoSetup(self,e,id)
    local data=GetData(self,e,id)
    if not data then return end

    if e.model then
        e.Model = e.model
    end
    if e.motion then
        e.Motion = e.motion
    end
    if e.pos then
        e.Pos = e.pos
    end
    if e.ang then
        e.Ang = e.ang
    end
    if e.scale then
        e.Scale = e.scale
    end
    if e.invisible then
        e.Invisible = e.invisible
    end
    if e.invisiblefade then
        e.InvisibleFade = e.invisiblefade
    end
    if e.fadespeed then
        e.FadeSpeed = e.fadespeed
    end
    if e.resetpositiononuse then
        e.ResetPositionOnUse = e.resetpositiononuse
    end
    if e.startfrozen then
        e.StartFrozen = e.startfrozen
    end

    e:SetModel(e.Model)
    e:PhysicsInit( SOLID_VPHYSICS )
    e:SetMoveType( MOVETYPE_VPHYSICS )
    e:SetSolid( SOLID_VPHYSICS )
    e:SetRenderMode( RENDERMODE_NORMAL )
    e:SetUseType( SIMPLE_USE )
    e.phys = e:GetPhysicsObject()
    if e.phys:IsValid() then
        if e.Motion and not e.StartFrozen then
            e.phys:EnableMotion(true)
            e.phys:Wake()
        else
            e.phys:EnableMotion(false)
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

local function SetupPartControl(e)
    if (e.parent == e.interior) then
        controls_metadata = e.parent.metadata.Interior.Controls
    else
        controls_metadata = e.parent.metadata.Exterior.Controls
    end
    if controls_metadata ~= nil then
        if controls_metadata[e.ID] ~= nil then
            e.Control = controls_metadata[e.ID]
        end
    end
    if e.Control then
        e.parent.controlparts[e.Control] = e.parent.controlparts[e.Control] or {}
        e.parent.controlparts[e.Control][e.ID] = e
    end
end

if SERVER then
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
                local tbl=scripted_ents.GetStored(v.class).t
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
            local e=ents.Create(v)
            Doors:SetupOwner(e,ent:GetCreator())
            e.exterior=(ent.TardisExterior and ent or ent.exterior)
            e.interior=(ent.TardisInterior and ent or ent.interior)
            e.parent=ent
            e.ExteriorPart=(e.parent==e.exterior)
            e.InteriorPart=(e.parent==e.interior)
            local data=GetData(ent,e,k)
            if type(data)=="table" then
                table.Merge(e,data)
            end

            SetupPartControl(e)
            if e.EnabledOnStart then
                e:SetOn(true)
            end

            if e.enabled==false then
                e:Remove()
            else
                ent.parts[k]=e
                if e.AutoSetup then
                    AutoSetup(ent,e,k)
                end
                e:Spawn()
                e:Activate()
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
                net.WriteBool(e.InteriorPart)
                net.WriteString(e.ID)
            net.Send(ply)
        end
    end)

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
    function TARDIS:SetupPart(e,name,ext,int,parent)
        if IsValid(e) and IsValid(parent) then
            e.exterior=ext
            e.interior=int
            e.parent=parent
            e.ExteriorPart=(parent==ext)
            e.InteriorPart=(parent==int)
            local data=GetData(parent,e,name)
            if type(data)=="table" then
                table.Merge(e,data)
            end

            if e.Translucent then
                e.RenderGroup = RENDERGROUP_TRANSLUCENT
            end

            if not parent.controlparts then parent.controlparts = {} end
            SetupPartControl(e)
            if e.EnabledOnStart then
                e:SetOn(true)
            end

            if not parent.parts then parent.parts={} end
            parent.parts[name]=e
            if e.matrixScale then
                local matrix = Matrix()
                matrix:Scale(e.matrixScale)
                e:EnableMatrix("RenderMultiply",matrix)
            end
            if e.o.Initialize then
                e.o.Initialize(e)
            end
            e._init=true
        end
    end
    net.Receive("TARDIS-SetupPart", function(ply)
        local e=net.ReadEntity()
        local ext=net.ReadEntity()
        local int=net.ReadEntity()
        local extpart=net.ReadBool()
        local intpart=net.ReadBool()
        local parent
        if extpart then
            parent=ext
        else
            parent=int
        end
        local name = net.ReadString()
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