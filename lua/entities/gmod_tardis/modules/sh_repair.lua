function ENT:GetRepairPrimed()
    return self:GetData("repair-primed",false)
end

function ENT:GetRepairing()
    return self:GetData("repairing",false)
end

function ENT:GetRepairTime()
    return self:GetData("repair-time")-CurTime()
end

if SERVER then
    function ENT:ToggleRepair()
        local on = not self:GetRepairPrimed()
        return self:SetRepair(on)
    end

    function ENT:SetRepair(on)
        if not TARDIS:GetSetting("health-enabled")
            and self:GetHealth() ~= self:GetHealthMax()
        then
            self:ChangeHealth(self:GetHealthMax())
            return false
        end

        if self:CallHook("CanRepair") == false then return false end

        if on == true then
            for k,_ in pairs(self.occupants) do
                TARDIS:Message(k, "Health.RepairActivated")
            end
            local power = self:GetPower()
            self:SetData("power-before-repair", power)
            if power then self:SetPower(false) end
            self:SetData("repair-primed", true, true)

            if table.IsEmpty(self.occupants) then
                self:Timer("repair-nooccupants", 0, function()
                    self:SetData("repair-shouldstart", true)
                    self:SetData("repair-delay", CurTime()+0.3)
                end)
            end
        else
            self:SetData("repair-primed",false,true)
            self:CallCommonHook("RepairCancelled")

            local prev_power = self:GetData("power-before-repair")
            if (prev_power ~= nil) then
                self:SetPower(prev_power)
            else
                self:SetPower(true)
            end

            for k,_ in pairs(self.occupants) do
                TARDIS:Message(k, "Health.RepairCancelled")
            end
        end
        self:CallHook("RepairToggled", on)
        return true
    end

    function ENT:StartRepair()
        if not IsValid(self) then return end
        self:SetLocked(true,nil,true,true)
        local max_health = self:GetHealthMax()
        local cur_health = self:GetHealth()
        local maxtime = TARDIS:GetSetting("long_repair") and 60 or 15
        local repairtime = math.Clamp(maxtime * (max_health - cur_health) / max_health, 1, maxtime)

        local time = CurTime() + repairtime
        self:SetData("repair-time", time, true)
        self:SetData("repairing", true, true)
        self:SetData("repair-primed", false, true)
        self:CallHook("RepairStarted")
    end

    function ENT:FinishRepair()
        if self:GetData("redecorate") and self:Redecorate() then
            return
        end
        self:EmitSound(self.metadata.Exterior.Sounds.RepairFinish)
        self:SetData("repairing", false, true)
        self:ChangeHealth(self:GetHealthMax())
        self:CallHook("RepairFinished")
        self:SetPower(true)
        self:SetLocked(false, nil, true)
        TARDIS:Message(self:GetCreator(), "Health.RepairFinished")
        self:StopSmoke()
        self:FlashLight(1.5)
    end

    ENT:AddHook("CanLock", "repair", function(self)
        if (not self:GetRepairing()) then return true end
    end)

    ENT:AddHook("CanTogglePower", "repair", function(self, on)
        if on and (self:GetRepairing() or self:GetRepairPrimed()) then
            return false
        end
    end)

    ENT:AddHook("PostPlayerExit", "repair", function(self,ply,forced,notp)
        if (self:GetRepairPrimed()==true) and (table.IsEmpty(self.occupants)) then
            self:SetData("repair-shouldstart", true)
            self:SetData("repair-delay", CurTime()+0.3)
        end
    end)

    ENT:AddHook("PlayerEnter", "repair", function(self,ply,forced,notp)
        if (self:GetRepairPrimed()==true) and table.Count(self.occupants)>=0 then
            self:SetData("repair-shouldstart", false)
        end
    end)

    ENT:AddHook("LockedUse", "repair", function(self, a)
        if self:GetRepairing() then
            TARDIS:Message(a, "Health.Repairing", math.floor(self:GetRepairTime()))
            return true
        end
    end)

    ENT:AddHook("Think", "repair", function(self)
        if self:GetRepairPrimed() and self:CallHook("CanRepair") == false then
            self:SetData("repair-primed", false, true)
            self:SetPower(true)
            for k,_ in pairs(self.occupants) do
                TARDIS:Message(k, "Health.RepairCancelled")
            end
        end

        if self:GetRepairPrimed() and self:GetData("repair-shouldstart") and CurTime() > self:GetData("repair-delay") then
            self:SetData("repair-shouldstart", false)
            self:StartRepair()
        end

        if (self:GetRepairing() and CurTime()>self:GetData("repair-time",0)) then
            self:FinishRepair()
        end
    end)

    ENT:AddHook("ShouldUpdateArtron", "repair", function(self)
        if self:GetRepairPrimed() or self:GetRepairing() then
            return false
        end
    end)

    ENT:AddHook("ShouldTakeDamage", "repair", function(self, dmginfo)
        if self:GetRepairing() then return false end
    end)

    ENT:AddHook("HandleE2", "repair", function(self, name, e2, ...)
        local args = {...}
        if name == "Selfrepair" and TARDIS:CheckPP(e2.player, self) then
            return self:ToggleRepair() and 1 or 0
        elseif name == "SetSelfrepair" and TARDIS:CheckPP(e2.player, self) then
            local on = args[1]
            local primed = self:GetRepairPrimed()
            if on == 1 then
                if (not primed) and self:SetRepair(true) then
                    return 1
                end
            else
                if primed and self:SetRepair(false) then
                    return 1
                end
            end
            return 0
        elseif name == "GetSelfrepairing" then
            local repairing = self:GetRepairing()
            local primed = self:GetRepairPrimed()
            if repairing then
                return 1
            elseif primed then
                return 2
            else
                return 0
            end
        elseif name == "GetRepairTime" then
            if self:GetRepairing() then
                return self:GetRepairTime()
            else
                return 0
            end
        end
    end)
end
