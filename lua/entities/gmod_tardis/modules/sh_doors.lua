-- Open door with E, go in with Alt-E

if SERVER then
    local function runcallbacks(callbacks,state)
        for k,v in pairs(callbacks) do
            k(state)
            callbacks[k]=nil
        end
    end

    local function delay(callback,state) -- Ensures callback is always called async
        timer.Simple(0,function()
            callback(state)
        end)
    end

    function ENT:ToggleDoor(callback)
        if not IsValid(self.interior) then return false end
        if not self:GetData("doorchangecallback",false) then
            self:SetData("doorchangecallback",{})
        end
        local callbacks=self:GetData("doorchangecallback")
        local doorstate=self:GetData("doorstatereal",false)
        if self:CallHook("CanToggleDoor", doorstate)==false then
            if callback then
                callback(doorstate)
            end
            runcallbacks(callbacks,doorstate)
            return false
        end
        doorstate=not doorstate

        self:SetData("doorstatereal",doorstate,true)
        self:SetData("doorchangewait",not doorstate)

        self:CallHook("ToggleDoorReal",doorstate)

        if doorstate then
            self:SetData("doorstate",true,true)
            self:SetData("doorchange",CurTime())
            self:CallHook("ToggleDoor",true)
            if callback then
                delay(callback,true)
            end
            runcallbacks(callbacks,true)
        else
            if callback then
                callbacks[callback]=true
            end
            local dooranimtime = self.metadata.Exterior.DoorAnimationTime
            if self.metadata.EnableClassicDoors == true then
                dooranimtime = math.max(dooranimtime, self.metadata.Interior.IntDoorAnimationTime)
            end
            self:SetData("doorchange",CurTime() + dooranimtime)
        end
        return true
    end

    function ENT:OpenDoor(callback)
        if self:GetData("doorstate",false) then
            delay(callback,true)
            return true
        else
            return self:ToggleDoor(callback)
        end
    end

    function ENT:CloseDoor(callback)
        if self:GetData("doorstate",false) ~= self:GetData("doorstatereal",false) then
            local callbacks=self:GetData("doorchangecallback")
            callbacks[callback]=true
            return true
        elseif not self:GetData("doorstate",false) then
            delay(callback,false)
            return false
        else
            return self:ToggleDoor(callback)
        end
    end

    function ENT:DoorOpen(real)
        if real then
            return self:GetData("doorstatereal",false)
        else
            return self:GetData("doorstate",false)
        end
    end

    ENT:AddHook("HandleE2", "doors", function(self, name, e2, ...)
        local args = {...}
        if name == "SetDoors" and TARDIS:CheckPP(e2.player, self) then
            local on = args[1]
            local open = self:DoorOpen(true)
            if on == 1 then
                if (not open) and self:OpenDoor() then
                    return 1
                end
            else
                if open and self:CloseDoor() then
                    return 1
                end
            end
            return 0
        elseif name == "ToggleDoors" and TARDIS:CheckPP(e2.player, self) then
            return self:ToggleDoor() and 1 or 0
        elseif name == "GetDoors" then
            return self:DoorOpen(true) and 1 or 0
        end
    end)

    ENT:AddHook("Initialize", "legacy_door_type", function(self,open)
        local islegacy = self.metadata.Exterior.UseLegacyDoors or TARDIS:GetSetting("legacy_door_type", self)
        self:SetData("legacy_door_type", islegacy, true)
    end)

    ENT:AddHook("CanToggleDoor","legacy_door_type",function(self,state)
        if self:GetData("legacy_door_type") then
            return false
        end
    end)

    ENT:AddHook("ShouldFailDemat", "door", function(self, force)
        -- preventing stack overflow if doors can't get closed during force demat
        if self:DoorOpen() and self:CallHook("CanToggleDoor",false) == false then
            return false
        end
    end)

    ENT:AddHook("ToggleDoorReal", "classic_doors_collision", function(self,open)
        if self.metadata.EnableClassicDoors ~= true then return end

        local int_classic_door=TARDIS:GetPart(self.interior,"intdoor")
        if IsValid(int_classic_door) then
            int_classic_door:SetCollide(not open, true)
        end
    end)

    ENT:AddHook("ToggleDoor", "doorcollision",function(self,open)
        self:UpdateDoorCollision()
    end)

    ENT:AddHook("SlowThink", "doorcollision",function(self,open)
        if self:DoorOpen(true) then
            self:UpdateDoorCollision()
        end
    end)

    function ENT:UpdateDoorCollision()
        local open = self:DoorOpen(true)
        local override = self:CallHook("DoorCollisionOverride")

        local door_ext = TARDIS:GetPart(self,"door")
        local door_int=TARDIS:GetPart(self.interior,"door")

        if (override == nil and open) or override==false then
            if IsValid(door_ext) then door_ext:SetSolid(SOLID_NONE) end
            if IsValid(door_int) then door_int:SetCollisionGroup( COLLISION_GROUP_WORLD ) end
        elseif override or override==nil then
            if IsValid(door_ext) then door_ext:SetSolid(SOLID_VPHYSICS) end
            if IsValid(door_int) then door_int:SetCollisionGroup( COLLISION_GROUP_NONE ) end
        end
    end

    ENT:AddHook("ShouldExteriorDoorCollide", "dooropen", function(self,open)
        local override = self:CallHook("DoorCollisionOverride")
        if (override == nil and open) or override==false then
            return false
        elseif override or override==nil then
            return true
        end
    end)

    ENT:AddHook("ToggleDoorReal", "doors", function(self,open)
        self:SendMessage("ToggleDoorReal", {open})
    end)

    ENT:AddHook("ToggleDoor", "doors", function(self,open)
        self:SendMessage("ToggleDoor", {open})
    end)

    ENT:AddHook("Think", "doors", function(self)
        if self:GetData("doorchangewait",false) and CurTime()>self:GetData("doorchange",0) then
            self:SetData("doorchangewait",nil)
            self:SetData("doorstate",false,true)
            self:CallHook("ToggleDoor",false)
            local callbacks=self:GetData("doorchangecallback")
            runcallbacks(callbacks,false)
            self:SetData("doorchangecallback",nil)
        end
        local door = TARDIS:GetPart(self,"door")
        if IsValid(door) then
            if self:CallHook("ShouldExteriorDoorCollide",self:GetData("doorstatereal",false)) then
                door:SetSolid(SOLID_VPHYSICS)
            else
                door:SetSolid(SOLID_NONE)
            end
        end
    end)

    ENT:AddHook("ShouldThinkFast","doors",function(self)
        if self:GetData("doorchangewait") then
            return true
        end
    end)

    ENT:AddHook("Think", "int_door_skin", function(self)
        -- this fixes interior door skin if it's chosen at spawn
        -- we can not do it at the beginning because the interior doesn't exist yet
        if self:GetData("intdoor_skin_needs_update", false) and IsValid(self.interior) then
            local intdoor=TARDIS:GetPart(self.interior,"door")
            if IsValid(intdoor) then
                self:SetData("intdoor_skin_needs_update", false, true)
                intdoor:SetSkin(self:GetSkin())
            end
        end
    end)

    ENT:AddHook("SkinChanged","doors",function(self,i)
        local door=TARDIS:GetPart(self,"door")
        local intdoor=TARDIS:GetPart(self.interior,"door")
        if IsValid(door) then
            door:SetSkin(i)
        end
        if IsValid(intdoor) then
            intdoor:SetSkin(i)
        end
    end)

    ENT:AddHook("BodygroupChanged","doors",function(self,bodygroup,value)
        if not self.metadata.SyncExteriorBodygroupToDoors then return end
        if self:IsChameleonActive() then return end

        local door=TARDIS:GetPart(self,"door")
        local intdoor=TARDIS:GetPart(self.interior,"door")

        if IsValid(door) and door:GetBodygroup(bodygroup) ~= value then
            door:SetBodygroup(bodygroup,value)
        end

        if IsValid(intdoor)  and door:GetBodygroup(bodygroup) ~= value then
            intdoor:SetBodygroup(bodygroup,value)
        end
    end)

    ENT:AddHook("PartBodygroupChanged", "doors", function(self, part, bodygroup, value)
        if not self.metadata.SyncDoorBodygroups then return end
        if self:IsChameleonActive() then return end

        if not IsValid(part) or part ~= self:GetPart("door") then return end
        if not IsValid(self.interior) then return end
        local door_int = self.interior:GetPart("door")
        if not IsValid(door_int) then return end

        if door_int:GetBodygroup(bodygroup) ~= value then
            door_int:SetBodygroup(bodygroup, value)
        end
    end)

    ENT:AddHook("CanChangeExterior","doors",function(self)
        if self:DoorOpen() then
            return false,false,"Chameleon.FailReasons.DoorsOpen",false
        end
    end)

    ENT:AddHook("LockedUse", "door", function(self, a)
        self:SendMessage("LockedUse", {a})
    end)

else
    ENT:OnMessage("LockedUse", function(self,data,ply)
        self:CallHook("LockedUse", data[1])
    end)

    function ENT:DoorOpen(real)
        local door=self:GetPart("door")
        if real and IsValid(door) then
            return door.DoorPos ~= 0
        else
            return self:GetData("doorstate",false)
        end
    end

    function ENT:DoorMoving()
        local door=self:GetPart("door")
        if IsValid(door) then
            return door.DoorPos ~= door.DoorTarget
        else
            return false
        end
    end

    ENT:OnMessage("ToggleDoorReal", function(self, data, ply)
        self:CallHook("ToggleDoorReal", data[1])
    end)

    ENT:OnMessage("ToggleDoor", function(self, data, ply)
        self:CallHook("ToggleDoor", data[1])
    end)

    ENT:AddHook("ToggleDoorReal","doorsounds",function(self,open)
        local extsnds = self.metadata.Exterior.Sounds.Door
        local intsnds = self.metadata.Interior.Sounds.Door or extsnds

        if TARDIS:GetSetting("doorsounds-enabled") and TARDIS:GetSetting("sound") then
            if extsnds.enabled then
                local extpart = self:GetPart("door")
                local extsnd = open and extsnds.open or extsnds.close
                if IsValid(extpart) and extpart.exterior:CallHook("ShouldEmitDoorSound")~=false then
                    extpart:EmitSound(extsnd)
                end
            end
            if intsnds.enabled and IsValid(self.interior) then
                local intpart = self.interior:GetPart("door")
                local intsnd = open and intsnds.open or intsnds.close
                if IsValid(intpart) then
                    intpart:EmitSound(intsnd)
                end
            end
        end
    end)
end


--
-- Classic doors support
--
if CLIENT then

    ENT:AddHook("ShouldDraw", "classic_doors_exterior", function(self)
        if IsValid(self.interior) and self.metadata.EnableClassicDoors
            and wp.drawing and wp.drawingent == self.interior.portals.interior
        then
            return false
        end

    end)

    ENT:AddHook("ShouldDrawPart", "classic_doors_exterior_door", function(self, part)
        if IsValid(self.interior) and self.metadata.EnableClassicDoors == true and part ~= nil
            and wp.drawing and wp.drawingent == self.interior.portals.interior
            and part == TARDIS:GetPart(self, "door")
        then
            return false
        end
    end)

    ENT:AddHook("PlayerEnter", "classic_doors_intdoor_sound", function(self,ply,notp)
        if not IsValid(self.interior) then return end
        if self.metadata.EnableClassicDoors ~= true then return end
        if self.metadata.NoSoundOnEnter == true then return end

        local intdoor = TARDIS:GetPart(self.interior, "intdoor")
        if not IsValid(intdoor) then return end

        local door_sounds = self.metadata.Interior.Sounds.Door
        if not door_sounds then return end

        local door_sound = self:GetData("doorstatereal") and door_sounds.open or door_sounds.close
        if not door_sound then return end

        if intdoor.IntDoorPos ~= nil and intdoor.IntDoorPos ~= 0 and intdoor.IntDoorPos ~= 1 then
            sound.Play(door_sound, self.interior:LocalToWorld( self.metadata.Interior.Fallback.pos ))
        end
    end)
end
