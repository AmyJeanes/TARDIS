-- Lock

function ENT:Locked()
    return self:GetData("locked",false)
end

function ENT:Locking()
    return self:GetData("locking",false)
end

if SERVER then
    function ENT:ToggleLocked(callback, force)
        return self:SetLocked(not self:Locked(), callback, nil, force)
    end

    function ENT:ActualSetLocked(locked,callback,silent)
        self:SetData("locking",false,true)
        self:SetData("locked",locked,true)
        self:FlashLight(0.6)
        if not silent then self:SendMessage("locksound", {locked}) end
        self:CallHook("DoorLockToggled", locked)
        if callback then callback(true) end
    end

    function ENT:SetLocked(locked, callback, silent, force)
        if not self:CallHook("CanLock") then return false end
        if locked then
            self:SetData("locking",true,true)

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

    ENT:AddHook("CanPlayerEnter","lock",function(self,ply)
        if self:Locked() then
            return false
        end
    end)

    ENT:AddHook("CanToggleDoor","lock",function(self,state)
        if (not state) and self:Locked() then
            return false
        end
    end)

    ENT:AddHook("Use", "lock", function(self,a,c)
        if self:GetData("locked") and IsValid(a) and a:IsPlayer() then
            if self:CallHook("LockedUse",a,c)==nil then
                TARDIS:Message(a, "Lock.Locked")
            end
            self:EmitSound(self.metadata.Exterior.Sounds.Door.locked)
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
        if locked then
            self:EmitSound(extsoundon)
        else
            self:EmitSound(extsoundoff)
        end
        if IsValid(self.interior) then
            if locked then
                self.interior:EmitSound(intsoundon)
            else
                self.interior:EmitSound(intsoundoff)
            end
        end
    end)
end