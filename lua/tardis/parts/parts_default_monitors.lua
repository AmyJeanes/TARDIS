local HIDE_COLLISIONS = true


local PART = {}
PART.Model = "models/molda/toyota_int/monitor.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.poses_flip = { 0.5, 1, 0.5, 0, }
PART.poses_down = { 0.5, 0, 1, }


-- Initialize: set data names for each monitor

function PART:Initialize(ply)
    self.data_flip = self.ID .. "_flip"
    self.data_flip_pos = self.ID .. "_flip_pos"
    self.data_down = self.ID .. "_down"
    self.data_down_pos = self.ID .. "_down_pos"

    self.data_rotation = self.ID .. "_rotation"
    self.data_rotated_by = self.ID .. "_rotated_by"

    self.data_other_rotation = self.OtherID .. "_rotation"

    self.handles_hitbox_id = self.ID .. "_hitbox_handles"
    self.screen_hitbox_id = self.ID .. "_hitbox_screen"
    self.static_hitbox_id = self.ID .. "_hitbox_static"

    if self.ScreenID then
        self.data_screen_enabled = "default_screen_enabled_" .. self.ScreenID
    end

    self:SetBodygroup(0, 1)
end

-- Getting other monitor and parts

function PART:GetOther()
    return self.interior:GetPart(self.OtherID)
end

local function rotation_get_other(r)
    r = r + 0.5
    return (r > 1) and (r - 1) or r
end

function PART:GetOtherRotation()
    local r = self:GetData(self.data_other_rotation, 0)
    return rotation_get_other(r)
end

function PART:GetHitboxScreen()
    return self.interior:GetPart(self.screen_hitbox_id)
end

function PART:GetHitboxHandles()
    return self.interior:GetPart(self.handles_hitbox_id)
end

function PART:GetHitboxStatic()
    return self.interior:GetPart(self.static_hitbox_id)
end


-- Animation functions

function PART:AnimateRotation(anim)
    local target = self:GetData(self.data_rotation,0)

    local other = self:GetOtherRotation()

    local increase = (anim.pos < target)
    local through_other = false

    if increase then
        if anim.pos < other and other < target then
            through_other = true
        end
    else
        if anim.pos > other and other > target then
            through_other = true
        end
    end

    if not through_other then
        TARDIS.DoPartAnimation(self, true, anim, target, false)
    elseif increase then
        TARDIS.DoPartAnimation(self, true, anim, 0, true)
    else
        TARDIS.DoPartAnimation(self, true, anim, 1, true)
    end
end

function PART:AnimateDownMovement(anim)
    local target = self:GetData(self.data_down_pos, 0.5)
    TARDIS.DoPartAnimation(self, true, anim, target, false)
end

function PART:AnimateFlip(anim)
    local target = self:GetData(self.data_flip_pos, 0.5)
    TARDIS.DoPartAnimation(self, true, anim, target, false)
end


-- Data / state functions

function PART:IsStatic()
    return self:GetBodygroup(0) == 0
end

function PART:IsVertical()
    return self:GetBodygroup(0) == 1 and (self:GetData(self.data_flip_pos, 0.5) ~= 0.5)
end

function PART:CanMove()
    return self:GetBodygroup(0) ~= 0
end

function PART:CanFlip()
    return self:GetBodygroup(0) == 2
end

function PART:GetScreenPosition()
    local matrix = self:GetBoneMatrix(4)
    if not matrix then return end
    local pos = self.interior:WorldToLocal(matrix:GetTranslation())
    local ang = matrix:GetAngles()
    return pos, ang
end


-- Monitor position (all values between 0 and 1)

local function trace_console_angle(int, ply)
    local origin = ply:EyePos()
    local aim = ply:GetAimVector()
    local delta = Vector(aim.x, aim.y, 0)

    local circle_pos = int:LocalToWorld(Vector(0,0,0))
    circle_pos.z = origin.z

    local r = 70

    local p1, p2 = util.IntersectRayWithSphere(origin, delta, circle_pos, 50)
    if not p1 then return nil end

    local point = int:WorldToLocal(origin + p1 * aim)
    if point.z < 140 or point.z > 165 then return nil end

    local d = point - Vector(0,0,point.z)
    local ang = d:Angle()

    return ang.y, point.z
end

local function trace_monitor_pos(ply, part)
    local ang_y, down = trace_console_angle(part.interior, ply)
    if not ang_y then return end

    local rotation = math.Clamp((ang_y - part:GetAngles().y) % 360 / 360, 0, 1)
    local down = 1 - (down - 140) / 25

    return rotation, down
end


local function rotations_colliding (r1, r2)
    local border = 0.11
    if math.abs(r1 - r2) < border then
        return true
    end
    if r1 + math.abs(1 - r2) < border then
        return true
    end
    if r2 + math.abs(1 - r1) < border then
        return true
    end
    return false
end

local function rotations_distance(r1, r2)
    local d1 = math.abs(r1 - r2)
    local d2 = r1 + math.abs(1 - r2)
    local d3 = math.abs(1 - r1) + r2

    return math.min(d1, d2, d3)
end

function PART:ChangePosition(rotation, down)
    local other_r = self:GetOtherRotation()

    if not rotations_colliding(rotation, other_r) then
        self:SetData(self.data_rotation, rotation, SERVER)
    end

    self:SetData(self.data_down_pos, down, SERVER)
end

function PART:GetPosition()
    local rotation = self:GetData(self.data_rotation, 0)
    local down = self:GetData(self.data_down_pos, 0.5)
    return rotation, down
end


-- Hitbox part positions

if SERVER then
    function PART:UpdateHitboxCollision()
        local static = self:IsStatic()

        local function do_collision(part, collide)
            if not IsValid(part) then return end
            if collide then
                part:SetCollide(true)
            else
                part:SetCollide(false, true)
            end
        end

        do_collision(self:GetHitboxHandles(), not static)
        do_collision(self:GetHitboxScreen(), not static)
        do_collision(self:GetHitboxStatic(), static)
    end

    function PART:MoveHitboxes(pos, ang)
        local handles_hitbox = self:GetHitboxHandles()
        local screen_hitbox = self:GetHitboxScreen()

        if IsValid(handles_hitbox) then
            handles_hitbox:Move(pos, ang)
        end

        if IsValid(screen_hitbox) then
            screen_hitbox:Move(pos, ang)
        end
    end
end


-- Actions

if SERVER then
    function PART:Use(ply)
        if ply:KeyDown(IN_WALK) then

            local rotation, down = trace_monitor_pos(ply, self)

            local rot_this = self:GetData(self.data_other_rotation, 0)
            local rot_other = self:GetOtherRotation()

            local to_this = rotations_distance(rot_this, rotation)
            local to_other = rotations_distance(rot_other, rotation)

            -- select closest one
            if to_other < to_this then
                local other = self:GetOther()
                if IsValid(other) then
                    other:RotateToEyePos(ply)
                end
            else
                self:RotateToEyePos(ply)
            end
        end
    end

    function PART:MoveDown(ply)
        if not self:CanMove() then return end

        local down_state = self:GetData(self.data_down, 1) % #self.poses_down
        self:SetData(self.data_down, down_state + 1, true)
        self:SetData(self.data_down_pos, self.poses_down[down_state + 1], true)
        self:EmitSound("p00gie/tardis/default/monitor_move_vert.ogg")

        self:RequestHitboxUpdate(ply)
    end

    function PART:Flip(ply)
        if not self:CanFlip() then return end

        local flip_state = self:GetData(self.data_flip, 1) % #self.poses_flip
        self:SetData(self.data_flip, flip_state + 1, true)
        self:SetData(self.data_flip_pos, self.poses_flip[flip_state + 1], true)
        self:EmitSound("p00gie/tardis/default/monitor_flip.ogg")
        self:RequestHitboxUpdate(ply)
    end

    function PART:RotateToEyePos(ply)
        local prev = self:GetData(self.data_rotated_by)

        if not ply then
            if IsValid(prev) then
                self:EmitSound("p00gie/tardis/default/monitor_release.ogg")
            end
            self:SetData(self.data_rotated_by, nil, true)
            return
        end

        if not self:CanMove() then return end
        if IsValid() then return end

        self:SetData(self.data_rotated_by, ply, true)
        self:EmitSound("p00gie/tardis/default/monitor_hold.ogg")
    end

    function PART:Think()
        local ply = self:GetData(self.data_rotated_by)
        if not IsValid(ply) then return end

        if not ply:KeyDown(IN_USE) then
            self:RotateToEyePos(nil)

            if self:CanMove() then
                local rotation, down = trace_monitor_pos(ply, self)
                if rotation then
                    self:ChangePosition(rotation, down)
                end
                self:RequestFullUpdate(ply)
            end
        end
    end

    function PART:OnBodygroupChanged(bodygroup, value)
        if not IsValid(self.interior) then return end

        local other = self:GetOther()
        if IsValid(other) and other:GetBodygroup(bodygroup) ~= value then
            other:SetBodygroup(bodygroup, value)
        end

        local ring = self.interior:GetPart("default_rotor_ring")
        if IsValid(ring) then
            if bodygroup == 0 and value == 0 then
                ring:SetBodygroup(0,0)
            else
                ring:SetBodygroup(0,1)
            end
        end

        self:UpdateHitboxCollision()
    end
else
    function PART:Think()
        if self.pending_update and not self:IsAnimationPlaying() then
            self:SendMonitorsUpdate(self.pending_update_pos, self.pending_update_hitbox)
        end

        local ply = self:GetData(self.data_rotated_by)

        if self.ScreenID then

            if self.interior:GetScreensOn() and self:GetData(self.data_screen_enabled) then

                self:SetSubMaterial(2, "models/molda/toyota_int/screen_loading")
                self.loading_mat = true

                scr_pos, scr_ang = self:GetScreenPosition()

                if scr_pos and self.interior.screens3D then
                    local offset = Vector(-11.5, 6.8, 5.8)

                    if self:GetBodygroup(0) == 2 then
                        offset = Vector(-11.5, 6.8, 6.8)
                    end

                    offset:Rotate(scr_ang)
                    self.interior.screens3D[self.ScreenID].pos3D = scr_pos + offset
                    self.interior.screens3D[self.ScreenID].ang3D = scr_ang
                end
            elseif self.loading_mat then
                self.loading_mat = nil
                self:SetSubMaterial(2, nil)
            end
        end

        if ply ~= LocalPlayer() then return end

        local rotation, down = trace_monitor_pos(ply, self)

        if rotation then
            self:ChangePosition(rotation, down)
        end
    end

    function PART:IsAnimationPlaying()
        local a_rotate = self.animation
        local a_down = self.extra_animations.down
        local a_flip = self.extra_animations.flip

        if a_rotate.pos ~= self:GetData(self.data_rotation,0) then
            return true
        end
        if a_down.pos ~= self:GetData(self.data_down_pos, 0.5) then
            return true
        end
        if a_flip.pos ~= self:GetData(self.data_flip_pos, 0.5) then
            return true
        end
        return false
    end
end


-- Networking


if SERVER then
    util.AddNetworkString("TARDIS_DefaultMonitorsRequestUpdate")
    util.AddNetworkString("TARDIS_DefaultMonitorsUpdate")

    function PART:RequestUpdate(update_pos, update_hitbox, ply)
        net.Start("TARDIS_DefaultMonitorsRequestUpdate")
            net.WriteEntity(self)
            net.WriteBool(update_pos)
            net.WriteBool(update_hitbox)
        net.Send(ply)
    end

    function PART:RequestHitboxUpdate(ply) self:RequestUpdate(false, true, ply) end
    function PART:RequestPositionUpdate(ply) self:RequestUpdate(true, false, ply) end
    function PART:RequestFullUpdate(ply) self:RequestUpdate(true, true, ply) end

    net.Receive("TARDIS_DefaultMonitorsUpdate", function(len,ply)
        local part = net.ReadEntity()
        local update_pos = net.ReadBool()
        local update_hitbox = net.ReadBool()

        local message_valid = IsValid(part) and part.exterior.occupants[ply]

        if update_pos then
            local rotation, down = net.ReadFloat(), net.ReadFloat()
            if message_valid and rotation and down then
                part:ChangePosition(rotation, down)
            end
        end

        if update_hitbox then
            local scr_pos, scr_ang = net.ReadVector(), net.ReadAngle()
            if message_valid then
                part:MoveHitboxes(scr_pos, scr_ang)
            end
        end
    end)
else
    function PART:SendMonitorsUpdate(update_pos, update_hitbox)
        net.Start("TARDIS_DefaultMonitorsUpdate")

        net.WriteEntity(self)
        net.WriteBool(update_pos)
        net.WriteBool(update_hitbox)

        if update_pos then
            local rotation, down = self:GetPosition()
            net.WriteFloat(rotation)
            net.WriteFloat(down)
        end

        if update_hitbox then
            local scr_pos, scr_ang = self:GetScreenPosition()
            net.WriteVector(scr_pos)
            net.WriteAngle(scr_ang)
        end

        net.SendToServer()

        if self.pending_update then
            self.pending_update = nil
            self.pending_update_pos = nil
            self.pending_update_hitbox = nil
        end
    end

    net.Receive("TARDIS_DefaultMonitorsRequestUpdate", function(len,ply)
        local part = net.ReadEntity()

        local update_pos = net.ReadBool()
        local update_hitbox = net.ReadBool()

        if not IsValid(part) then return end

        if part:IsAnimationPlaying() then
            part.pending_update = true
            part.pending_update_pos = update_pos
            part.pending_update_hitbox = update_hitbox
        else
            part:SendMonitorsUpdate(update_pos, update_hitbox)
        end
    end)
end

-- Adding parts


PART.AnimateOptions = {
    Type = "custom",
    PoseParameter = "Bone",
    Speed = 0.3,
    CustomAnimationFunc = PART.AnimateRotation,
}

PART.ExtraAnimations = {
    down = {
        Type = "custom",
        PoseParameter = "arm",
        StartPos = 0.5,
        CustomAnimationFunc = PART.AnimateDownMovement,
    },
    flip = {
        Type = "custom",
        PoseParameter = "flip",
        StartPos = 0.5,
        CustomAnimationFunc = PART.AnimateFlip,
    },
}

PART.ID = "default_monitor_1"
PART.ScreenID = 1
PART.OtherID = "default_monitor_2"
TARDIS:AddPart(PART)

PART.ID = "default_monitor_2"
PART.ScreenID = 2
PART.OtherID = "default_monitor_1"
TARDIS:AddPart(PART)




-- Hitbox use functions

local function UseScreen(self,ply)
    local monitor = self:GetMonitor()
    if not IsValid(monitor) then return end

    if ply:KeyDown(IN_WALK) then
        monitor:MoveDown(ply)
    end
end

local function UseHandle(self,ply)
    local monitor = self:GetMonitor()
    if not IsValid(monitor) then return end

    if ply:KeyDown(IN_WALK) and monitor:CanFlip() then
        monitor:Flip(ply)
    elseif ply:KeyDown(IN_WALK) then
        monitor:MoveDown(ply)
    else
        monitor:RotateToEyePos(ply)
    end
end

local function UseStatic(self,ply)
    local monitor = self:GetMonitor()
    if not IsValid(monitor) then return end

end




-- Hitbox parts

local function Setup_Hitbox_Parts(MonitorID)
    local PART = {}
    PART.MonitorID = MonitorID
    PART.AutoSetup = true
    PART.Collision = false
    PART.NoDraw = HIDE_COLLISIONS

    if not HIDE_COLLISIONS then
        function PART:Initialize()
            self:SetColor(Color(255,255,255,100))
        end
    end

    PART.GetMonitor = function(self)
        return self.interior:GetPart(self.MonitorID)
    end


    -- static

    PART.ID = PART.MonitorID .. "_hitbox_static"
    PART.Model = "models/molda/toyota_int/hitboxes/static_monitor_hitbox.mdl"
    if SERVER then
        PART.Use = UseStatic
    end
    TARDIS:AddPart(PART)


    -- moving

    if SERVER then
        PART.Move = function(self, pos, ang)
            self:SetPos(pos)
            self:SetAngles(ang)
        end
    end


    -- handles

    PART.ID = PART.MonitorID .. "_hitbox_handles"
    PART.Model = "models/uriel/toyota_int/monitor_collision_handles.mdl"
    if SERVER then
        PART.Use = UseHandle
    end
    TARDIS:AddPart(PART)


    -- screen

    PART.ID = PART.MonitorID .. "_hitbox_screen"
    PART.Model = "models/uriel/toyota_int/monitor_collision_screen.mdl"
    if SERVER then
        PART.Use = UseScreen
    end
    TARDIS:AddPart(PART)
end

Setup_Hitbox_Parts("default_monitor_1")
Setup_Hitbox_Parts("default_monitor_2")



-- Rotor ring

local PART={}
PART.ID = "default_rotor_ring"
PART.Model = "models/molda/toyota_int/rotor_ring.mdl"
PART.AutoSetup = true

function PART:Initialize()
    self:SetBodygroup(0,1)
end

TARDIS:AddPart(PART)