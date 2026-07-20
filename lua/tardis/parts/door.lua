---@class part_door : gmod_tardis_part
local PART={}
PART.ID = "door"
PART.Name = "Door"
PART.Model = "models/drmatt/tardis/exterior/door.mdl"
PART.AutoSetup = true
PART.AutoPosition = false
PART.ClientThinkOverride = true
PART.Collision = true
PART.ShadowCollision = true
PART.PortalNoCollide = true
PART.NoStrictUse = true
PART.ShouldTakeDamage = true
PART.BypassIsomorphic = true

function PART:Initialize()
    local metadata=self.exterior.metadata
    local portal=self.ExteriorPart and metadata.Exterior.Portal or metadata.Interior.Portal
    self.portal=portal
    if portal then
        self.posoffset=(self.posoffset or Vector(26*(self.InteriorPart and 1 or -1),0,-51.65))
        self.angoffset=(self.angoffset or Angle(0,self.InteriorPart and 180 or 0,0))

        local portal_pos = portal.pos
        local portal_ang = portal.ang

        if self.use_exit_point_offset and portal.exit_point_offset then
            portal_pos = portal_pos + portal.exit_point_offset.pos
            portal_ang = portal_ang + portal.exit_point_offset.ang
        elseif self.use_exit_point_offset and portal.exit_point then
            portal_pos = portal.exit_point.pos
            portal_ang = portal.exit_point.ang
        end

        self.portal_pos=portal_pos
        self.portal_ang=portal_ang

        local pos,ang=LocalToWorld(self.posoffset,self.angoffset,self.portal_pos,self.portal_ang)
        self:SetPos(self.parent:LocalToWorld(pos))
        self:SetAngles(self.parent:LocalToWorldAngles(ang))
    end

    if SERVER then
        if self.ExteriorPart then
            -- un-parented: collision follows the shell as a swept shadow (ShadowCollision)
            self.ClientDrawOverride = true
            self:DrawShadow(false)
        elseif self.InteriorPart then
            self.DrawThroughPortal = true
        end

        self:SetSkin(self.exterior:GetSkin())
    else
        self.DoorPos=0
        self.DoorTarget=0

        -- door open animation may go beyond render bounds of the model
        -- increase bounds by the maximum distance the door can move
        -- calculated by the width of the door (y axis)
        local mins, maxs = self:OBBMins(), self:OBBMaxs()
        local reach = maxs.y - mins.y
        self:SetRenderBounds(
            Vector(mins.x - reach, mins.y - reach, mins.z),
            Vector(maxs.x + reach, maxs.y + reach, maxs.z)
        )
    end
end

if SERVER then
    function PART:Use(ply)
        if self:GetData("locked") then
            if IsValid(ply) and ply:IsPlayer() then
                if self.exterior:CallHook("LockedUse",ply)==nil then
                    TARDIS:Message(ply, "Parts.Door.Locked")
                    self.exterior:SendMessage("lockattempted", {ply})
                end
                local door_sounds = self.exterior.metadata.Exterior.Sounds.Door
                Doors:PlaySound({ path = door_sounds.locked, ent = self })
                local otherdoor
                if self.ExteriorPart and IsValid(self.interior) then
                    otherdoor = self.interior:GetPart("door")
                elseif self.InteriorPart then
                    otherdoor = self.exterior:GetPart("door")
                end
                if IsValid(otherdoor) then
                    Doors:PlaySound({ path = door_sounds.locked, ent = otherdoor })
                end
            end
        else
            if ply:KeyDown(IN_WALK) or not IsValid(self.interior) or self:GetData("legacy_door_type") then
                local allowed, reason
                if self.ExteriorPart then
                    allowed, reason = self.exterior:CallHook("CanPlayerEnterDoor", ply)
                else
                    allowed, reason = self.exterior:CallHook("CanPlayerExitDoor", ply)
                end
                if allowed == false then
                    if reason then TARDIS:Message(ply, reason) end
                    return
                end
            end
            if self:GetData("legacy_door_type") and ply:KeyDown(IN_WALK) then
                if self.ExteriorPart then
                    self.exterior:PlayerEnter(ply)
                    self.exterior:PlayerThirdPerson(ply, true)
                else
                    self.exterior:PlayerExit(ply)
                    ply:ScreenFade(SCREENFADE.IN, color_black, 1, 0)
                end
            elseif ply:KeyDown(IN_WALK) or not IsValid(self.interior) or self:GetData("legacy_door_type") then
                if self.ExteriorPart then
                    self.exterior:PlayerEnter(ply)
                    ply:ScreenFade(SCREENFADE.IN, color_black, 1, 0)
                else
                    self.exterior:PlayerExit(ply)
                    ply:ScreenFade(SCREENFADE.IN, color_black, 1, 0)
                end
            else
                if self.exterior.metadata.EnableClassicDoors == true and not self.ExteriorPart then return end
                if self.exterior:GetRepairing() and self.ExteriorPart then return end
                self.exterior:ToggleDoor()
            end
        end
    end

    local BUMP_COOLDOWN = 3 -- min seconds between bump messages per player
    local BUMP_CONTACT_GAP = 0.5 -- contact events further apart than this count as a new bump

    -- Walking into the blocked-solid interior door explains itself with the veto's reason.
    -- The engine re-fires Start/EndTouch every frame while a player pushes against a solid
    -- entity, so "stopped touching" is detected as a gap in contact events, not EndTouch.
    ---@param ent Entity
    function PART:StartTouch(ent)
        if not self.InteriorPart then return end
        if not IsValid(self.exterior) then return end
        if not (ent:IsPlayer() and self.exterior:DoorOpen(true)) then return end

        self.bump_msgs = self.bump_msgs or setmetatable({}, {__mode = "k"})
        local state = self.bump_msgs[ent] or { last_contact = 0, next_ok = 0 }
        self.bump_msgs[ent] = state

        local now = CurTime()
        local new_bump = now - state.last_contact > BUMP_CONTACT_GAP
        state.last_contact = now
        if not new_bump or now < state.next_ok then return end

        local allowed, reason = self.exterior:CallHook("CanPlayerExitDoor", ent)
        if allowed == false and reason then
            state.next_ok = now + BUMP_COOLDOWN
            TARDIS:Message(ent, reason)
        end
    end

    hook.Add("SkinChanged", "tardisi-door", function(ent,i)
        if ent.TardisExterior then
            local exterior_door=ent:GetPart("door")
            if IsValid(exterior_door) and exterior_door:GetSkin() ~= i then
                exterior_door:SetSkin(i)
            end
            if IsValid(ent.interior) then
                local interior_door=ent.interior:GetPart("door")
                if IsValid(interior_door) and interior_door:GetSkin() ~= i then
                    interior_door:SetSkin(i)
                end
            end
        end
        if ent.TardisPart and ent.ID == "door" and IsValid(ent.exterior) and ent.exterior:GetSkin()~=i then
            ent.exterior:SetSkin(i)
        end
    end)
else
    function PART:Think()
        if self.ExteriorPart then
            local animtime = self.exterior.metadata.Exterior.DoorAnimationTime
            local lockeddoor = self.exterior.metadata.Exterior.LockedDoor
            if lockeddoor.AnimEnabled and (self:GetData("locked") or self.LockedAnim) then
                if self.LockedAnim then
                    if self.DoorPos>=lockeddoor.AnimPos then
                        self.LockedAnim=false
                        self.DoorTarget=0
                    else
                        self.DoorTarget=lockeddoor.AnimPos
                    end
                else
                    self.DoorTarget=0
                end
                local animpos = math.abs(lockeddoor.AnimPos or 0)
                animtime = lockeddoor.AnimTime / (2 * animpos)
            else
                self.DoorTarget=self.exterior.DoorOverride or (self:GetData("doorstatereal",false) and 1 or 0)
            end

            -- Have to spam it otherwise it glitches out (http://facepunch.com/showthread.php?t=1414695)
            self.DoorPos = math.Approach(self.DoorPos, self.DoorTarget, FrameTime() * (1 / animtime))

            -- for extension tweaks
            if self.ExtOnlyAnimation
                and self.ExtOnlyAnimation == self.DoorTarget
                and self.DoorPos == self.DoorTarget
            then
                self.ExtOnlyAnimation = nil
            end

            self:SetPoseParameter("switch", self.DoorPos)
            self:InvalidateBoneCache()

            local interior = self.exterior.interior
            if IsValid(interior) and not self.ExtOnlyAnimation then
                local intdoor = interior:GetPart("door")
                if IsValid(intdoor) then
                    intdoor:SetPoseParameter("switch", self.DoorPos)
                    intdoor:InvalidateBoneCache()
                end
            end
        end
    end
end

TARDIS:AddPart(PART)
