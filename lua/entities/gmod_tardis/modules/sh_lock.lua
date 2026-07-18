-- Lock

---@api
function ENT:Locked()
    return self:GetData("locked",false)
end

---@api
function ENT:Locking()
    return self:GetData("locking",false)
end

if SERVER then
    ---@api
    ---@param callback fun(state: boolean)?
    ---@param force boolean?
    ---@return boolean
    function ENT:ToggleLocked(callback, force)
        return self:SetLocked(not self:Locked(), callback, nil, force)
    end

    ---@param locked boolean
    ---@param callback fun(state: boolean)?
    ---@param silent boolean?
    function ENT:ActualSetLocked(locked,callback,silent)
        self:SetData("locking",false,true)
        self:SetData("locked",locked,true)
        self:FlashLight(0.6)
        if not silent then self:SendMessage("locksound", {locked}) end
        self:CallHook("DoorLockToggled", locked)
        self:CallClientHook("DoorLockToggled", locked)
        if callback then callback(true) end
    end

    ---@api
    ---@param locked boolean
    ---@param callback fun(state: boolean)?
    ---@param silent boolean?
    ---@param force boolean?
    function ENT:SetLocked(locked, callback, silent, force)
        if not self:CallHook("CanLock") then return false end
        if locked then
            self:SetData("locking",true,true)

            ---@param state boolean
            local dolock = function(state)
                if state then
                    self:SetData("locking",false,true)
                    if callback then callback(false) end
                    return false
                else
                    self:ActualSetLocked(true,callback,silent)
                    return true
                end
            end

            if self:DoorOpen() and (TARDIS:GetSetting("lock_autoclose", self) or force) then
                return self:CloseDoor(dolock)
            else
                return dolock(self:GetData("doorstatereal"))
            end
        else
            self:ActualSetLocked(false,callback,silent)
        end
        return true
    end

    ENT:AddHook("CanToggleDoor","lock",function(self,state)
        if (not state) and self:Locked() then
            return false
        end
    end)

    ENT:AddHook("Use", "lock", function(self,a,c)
        if self:GetData("locked") and IsValid(a) and a:IsPlayer() then
            if self:CallHook("LockedUse",a,c)==nil then
                TARDIS:Message(a, "Lock.Locked")
                self.exterior:SendMessage("lockattempted", {a})
            end
            Doors:PlaySound({ path = self.metadata.Exterior.Sounds.Door.locked, ent = self })
        end
    end)

    ENT:AddHook("HandleE2", "lock", function(self, name, e2, ...)
        local args = {...}
        if name == "GetLocked" then
            if self:Locked() or self:Locking() then
                return 1
            else
                return 0
            end
        elseif name == "Lock" and TARDIS:CheckPP(e2.player, self) then
            return self:ToggleLocked() and 1 or 0
        elseif name == "SetLock" and TARDIS:CheckPP(e2.player, self) then
            local on = args[1]
            local locked = self:Locked()
            if on == 1 then
                if (not locked) and self:SetLocked(true) then
                    return 1
                end
            else
                if locked and self:SetLocked(false) then
                    return 1
                end
            end
            return 0
        end
    end)
else
    ENT:OnMessage("locksound", function(self, data, ply)
        if not (TARDIS:GetSetting("locksound-enabled") and TARDIS:GetSetting("sound")) then return end
        local locked = data[1]
        local extsoundon = self.metadata.Exterior.Sounds.Lock
        local extsoundoff = self.metadata.Exterior.Sounds.Unlock
        local intsoundon = self.metadata.Interior.Sounds.Lock or extsoundon
        local intsoundoff = self.metadata.Interior.Sounds.Unlock or extsoundoff
        Doors:PlaySound({ path = locked and extsoundon or extsoundoff, ent = self })
        -- the interior copy plays right as players head through the door, so it's managed (the exterior
        -- clicks are too short to cut)
        if IsValid(self.interior) then
            Doors:PlaySound({ path = locked and intsoundon or intsoundoff,
                owner = self, tag = "lock", ent = self.interior, resumable = true })
        end
    end)

    ENT:OnMessage("lockattempted", function(self, data, ply)
        local door = self:GetPart("door")
        if IsValid(door) then
            door.LockedAnim = true
        end
    end)

    ENT:AddHook("DoorLockToggled", "lockattempted", function(self, locked)
        if locked then return end
        local door = self:GetPart("door")
        if IsValid(door) then
            door.LockedAnim = nil
        end
    end)
end

-- Shared so world-portals' predicted teleport (SetupMove on the client) can veto
-- too, via CanPlayerEnter -> ShouldTeleportPortal. Locked() reads networked
-- GetData, so it's realm-safe.
ENT:AddHook("CanPlayerEnter","lock",function(self,ply)
    if self:Locked() then
        return false
    end
end)