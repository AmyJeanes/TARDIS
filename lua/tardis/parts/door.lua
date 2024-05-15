local PART={}
PART.ID = "door"
PART.Name = "Door"
PART.Model = "models/drmatt/tardis/exterior/door.mdl"
PART.AutoSetup = true
PART.AutoPosition = false
PART.ClientThinkOverride = true
PART.Collision = true
PART.NoStrictUse = true
PART.ShouldTakeDamage = true
PART.BypassIsomorphic = true

if SERVER then
    function PART:Initialize()
        if self.ExteriorPart then
            self.ClientDrawOverride = true
            self:SetSolid(SOLID_VPHYSICS)
            --self:SetCollisionGroup(COLLISION_GROUP_WORLD)
        elseif self.InteriorPart then
            self.DrawThroughPortal = true
            table.insert(self.interior.stuckfilter, self)
        end

        local metadata=self.exterior.metadata
        local portal=self.ExteriorPart and metadata.Exterior.Portal or metadata.Interior.Portal
        if portal then
            local pos=(self.posoffset or Vector(26*(self.InteriorPart and 1 or -1),0,-51.65))
            local ang=(self.angoffset or Angle(0,self.InteriorPart and 180 or 0,0))

            local portal_pos = portal.pos
            local portal_ang = portal.ang

            if self.use_exit_point_offset and portal.exit_point_offset then
                portal_pos = portal_pos + portal.exit_point_offset.pos
                portal_ang = portal_ang + portal.exit_point_offset.ang
            elseif self.use_exit_point_offset and portal.exit_point then
                portal_pos = portal.exit_point.pos
                portal_ang = portal.exit_point.ang
            end

            pos,ang=LocalToWorld(pos,ang,portal_pos,portal_ang)
            self:SetPos(self.parent:LocalToWorld(pos))
            self:SetAngles(self.parent:LocalToWorldAngles(ang))
            self:SetParent(self.parent)
        end

        self:SetSkin(self.exterior:GetSkin())
    end

    function PART:Use(a)
        if self:GetData("locked") then
            if IsValid(a) and a:IsPlayer() then
                if self.exterior:CallHook("LockedUse",a)==nil then
                    TARDIS:Message(a, "Parts.Door.Locked")
                end
                self:EmitSound(self.exterior.metadata.Exterior.Sounds.Door.locked)
            end
        else
            if self:GetData("legacy_door_type") and a:KeyDown(IN_WALK) then
                if self.ExteriorPart then
                    self.exterior:PlayerEnter(a)
                    self.exterior:PlayerThirdPerson(a, true)
                else
                    self.exterior:PlayerExit(a)
                    a:ScreenFade(SCREENFADE.IN, color_black, 1, 0)
                end
            elseif a:KeyDown(IN_WALK) or not IsValid(self.interior) or self:GetData("legacy_door_type") then
                if self.ExteriorPart then
                    self.exterior:PlayerEnter(a)
                    a:ScreenFade(SCREENFADE.IN, color_black, 1, 0)
                else
                    self.exterior:PlayerExit(a)
                    a:ScreenFade(SCREENFADE.IN, color_black, 1, 0)
                end
            else
                if self.exterior.metadata.EnableClassicDoors == true and not self.ExteriorPart then return end
                if (self.exterior:GetRepairPrimed() or self.exterior:GetRepairing()) and self.ExteriorPart then return end
                self.exterior:ToggleDoor()
            end
        end
    end

    hook.Add("SkinChanged", "tardisi-door", function(ent,i)
        if ent.TardisExterior then
            local door=ent:GetPart("door")
            if IsValid(door) and door:GetSkin() ~= i then
                door:SetSkin(i)
            end
            if IsValid(ent.interior) then
                local door=ent.interior:GetPart("door")
                if IsValid(door) and door:GetSkin() ~= i then
                    door:SetSkin(i)
                end
            end
        end
        if ent.TardisPart and ent.ID == "door" and IsValid(ent.exterior) and ent.exterior:GetSkin()~=i then
            ent.exterior:SetSkin(i)
        end
    end)
else
    function PART:Initialize()
        self.DoorPos=0
        self.DoorTarget=0
    end

    function PART:Think()
        if self.ExteriorPart then
            self.DoorTarget=self.exterior.DoorOverride or (self:GetData("doorstatereal",false) and 1 or 0)

            local animtime = self.exterior.metadata.Exterior.DoorAnimationTime

            -- Have to spam it otherwise it glitches out (http://facepunch.com/showthread.php?t=1414695)
            self.DoorPos = self.exterior.DoorOverride or
                math.Approach(self.DoorPos, self.DoorTarget, FrameTime() * (1 / animtime))

            -- for extension tweaks
            if self.ExtOnlyAnimation
                and self.ExtOnlyAnimation == self.DoorTarget
                and self.DoorPos == self.DoorTarget
            then
                self.ExtOnlyAnimation = nil
            end

            self:SetPoseParameter("switch", self.DoorPos)
            self:InvalidateBoneCache()
        elseif self.InteriorPart then -- copy exterior, no need to redo the calculation
            local door=self.exterior:GetPart("door")
            if IsValid(door) and not door.ExtOnlyAnimation then
                self:SetPoseParameter("switch", door.DoorPos)
                self:InvalidateBoneCache()
            end
        end
    end
end

TARDIS:AddPart(PART)