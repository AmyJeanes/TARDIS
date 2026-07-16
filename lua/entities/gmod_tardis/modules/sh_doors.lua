-- Open door with E, go in with Alt-E

if SERVER then
    ---@param callbacks table<function, boolean>
    ---@param state boolean
    local function runcallbacks(callbacks,state)
        for k,_ in pairs(callbacks) do
            k(state)
            callbacks[k]=nil
        end
    end

    ---@param callback fun(state: boolean)?
    ---@param state boolean
    local function delay(callback,state) -- Ensures callback (if given) is called async
        if not callback then return end
        timer.Simple(0,function()
            callback(state)
        end)
    end

    ---@api
    ---@param callback fun(state: boolean)?
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

    ---@api
    ---@param callback fun(state: boolean)?
    function ENT:OpenDoor(callback)
        if self:GetData("doorstate",false) then
            delay(callback,true)
            return true
        else
            return self:ToggleDoor(callback)
        end
    end

    ---@api
    ---@param callback fun(state: boolean)?
    function ENT:CloseDoor(callback)
        if self:GetData("doorstate",false) ~= self:GetData("doorstatereal",false) then
            local callbacks=self:GetData("doorchangecallback")
            if callback then callbacks[callback]=true end
            return true
        elseif not self:GetData("doorstate",false) then
            delay(callback,false)
            return false
        else
            return self:ToggleDoor(callback)
        end
    end

    ---@api
    ---@param real boolean?
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

    ENT:AddHook("DematStart", "doorcollision", function(self)
        self:UpdateDoorCollision()
    end)

    ENT:AddHook("MatStart", "doorcollision", function(self)
        self:UpdateDoorCollision()
    end)

    ENT:AddHook("StopMat", "doorcollision", function(self)
        self:UpdateDoorCollision()
    end)

    ENT:AddHook("ToggleDoorReal", "doorcollision", function(self)
        self:UpdateDoorCollision()
    end)

    ENT:AddHook("ExteriorChanged", "doorcollision", function(self)
        self:UpdateDoorCollision()
    end)

    ENT:AddHook("InteriorReady", "doorcollision", function(self)
        self:UpdateDoorCollision()
    end)

    function ENT:UpdateDoorCollision()
        local door_ext = TARDIS:GetPart(self, "door")
        local door_int = TARDIS:GetPart(self.interior, "door")

        local open = self:DoorOpen(true)
        local teleporting = self:GetData("teleport") or self:GetData("vortex")

        -- The portal frame only funnels props through an actually-open doorway, so collide
        -- only when the door is open and we're landed - a closed door already blocks props.
        if IsValid(self.interior) and self.interior.portals then
            local portals = self.interior.portals
            local frame_enabled = open and not teleporting
            if IsValid(portals.exterior) then portals.exterior:SetEnableCollision(frame_enabled) end
            if IsValid(portals.interior) then portals.interior:SetEnableCollision(frame_enabled) end
        end

        if not IsValid(door_ext) then return end

        local colgroup = self:GetCollisionGroup()

        -- If the tardis is teleporting or in the vortex, the interior doors should always
        -- be solid even if the door is open (e.g. looking at the vortex) to prevent the player
        -- from phasing through the door. If not teleporting or in the vortex and the doors are
        -- open then both exterior and interior doors become non-solid to allow passage. Otherwise
        -- we match the collision group of exterior and interior doors to match the tardis exterior.

        if teleporting then
            if open then
                door_ext:SetCollisionGroup(COLLISION_GROUP_WORLD)
            else
                door_ext:SetCollisionGroup(colgroup)
            end
            if IsValid(door_int) then door_int:SetCollisionGroup(COLLISION_GROUP_NONE) end
        elseif open then
            door_ext:SetCollisionGroup(COLLISION_GROUP_WORLD)
            if IsValid(door_int) then door_int:SetCollisionGroup(COLLISION_GROUP_WORLD) end
        else
            door_ext:SetCollisionGroup(colgroup)
            if IsValid(door_int) then door_int:SetCollisionGroup(colgroup) end
        end
    end

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

        local door=TARDIS:GetPart(self,"door")

        local name=self:GetBodygroupName(bodygroup)

        if IsValid(door) then
            local doorbodygroup = door:FindBodygroupByName(name)
            if doorbodygroup > -1 and door:GetBodygroup(doorbodygroup) ~= value then
                door:SetBodygroup(doorbodygroup,value)
            end
        end
        
        if self:IsChameleonActive() then return end
        
        local intdoor=TARDIS:GetPart(self.interior,"door")
        if IsValid(intdoor) then
            local intdoorbodygroup = intdoor:FindBodygroupByName(name)
            if intdoorbodygroup > -1 and intdoor:GetBodygroup(intdoorbodygroup) ~= value then
                intdoor:SetBodygroup(intdoorbodygroup,value)
            end
        end
    end)

    ENT:AddHook("PartBodygroupChanged", "doors", function(self, part, bodygroup, value)
        if not IsValid(part) or part ~= self:GetPart("door") then return end

        local name = part:GetBodygroupName(bodygroup)

        if self.metadata.SyncExteriorBodygroupToDoors then
            local exterior_bodygroup = self:FindBodygroupByName(name)
            if exterior_bodygroup > -1 and self:GetBodygroup(exterior_bodygroup) ~= value then
                self:SetBodygroup(exterior_bodygroup, value)
            end
        end
        
        if self.metadata.SyncDoorBodygroups then
            if self:IsChameleonActive() then return end

            if not IsValid(self.interior) then return end
            local intdoor = self.interior:GetPart("door")
            if not IsValid(intdoor) then return end

            local intdoorbodygroup = intdoor:FindBodygroupByName(name)
            if intdoorbodygroup > -1 and intdoor:GetBodygroup(intdoorbodygroup) ~= value then
                intdoor:SetBodygroup(intdoorbodygroup, value)
            end
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

    ---@api
    ---@param real boolean?
    function ENT:DoorOpen(real)
        local door=self:GetPart("door")
        if real and IsValid(door) and not self:Locked() then
            return door.DoorPos ~= 0
        else
            return self:GetData("doorstate",false)
        end
    end

    ---@api
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
                    TARDIS:PlayManagedSound({ path = extsnd, owner = self, tag = "door", ent = extpart })
                end
            end
            if intsnds.enabled and IsValid(self.interior) then
                local intpart = self.interior:GetPart("door")
                local intsnd = open and intsnds.open or intsnds.close
                if IsValid(intpart) then
                    TARDIS:PlayManagedSound({ path = intsnd, owner = self, tag = "door", ent = intpart })
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
        if ply ~= LocalPlayer() then return end
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
            TARDIS:PlayManagedSound({ path = door_sound, owner = self, tag = "door",
                ent = self.interior, offset = self.metadata.Interior.Fallback.pos })
        end
    end)
end
