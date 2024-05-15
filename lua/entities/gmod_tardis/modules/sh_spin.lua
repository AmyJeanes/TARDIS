-- Spin

function ENT:GetSpin()
    return self:GetData("spin", false)
end

function ENT:GetSpinDir(ignore_enabled)
    return ignore_enabled and self:GetData("spin-dir",-1) or (self:GetSpin() and self:GetData("spin-dir",-1) or 0)
end

function ENT:GetSpinDirText(ignore_enabled)
    local current = self:GetSpinDir(ignore_enabled)

    local text
    if current == -1 then
        text = "Spin.Directions.AntiClockwise"
    elseif current == 0 then
        text = "Spin.Directions.None"
    elseif current == 1 then
        text = "Spin.Directions.Clockwise"
    end

    return text
end

if SERVER then
    ENT:AddHook("Initialize", "spin", function(self)
        self:SetData("spin", true, true)
        self:SetData("spin-dir", -1, true)
    end)

    function ENT:SetSpinDir(dir)
        self:SetData("spin-dir", dir, true)
        self:CallHook("SpinChanged", self:GetSpinDir())
    end

    function ENT:SetSpin(on, dir)
        self:SetData("spin", on, true)
        if dir ~= nil then
            self:SetData("spin-dir", dir, true)
        end
        self:CallHook("SpinChanged", self:GetSpinDir())
    end

    function ENT:ToggleSpin()
        self:SetSpin(not self:GetSpin())
    end

    function ENT:CycleSpinDir()
        local lastCycle = self:GetData("spin-lastcycle", false)

        self:SetData("spin-lastcycle", not lastCycle)

        if lastCycle then
            self:SetSpin(false)
        else
            self:SetSpin(true, -self:GetSpinDir(true))
        end
    end

    function ENT:SwitchSpinDir()
        self:SetSpinDir(-self:GetSpinDir(true))
    end

    ENT:AddHook("ToggleDoorReal", "spin-dir", function(self,open)
        if TARDIS:GetSetting("opened-door-no-spin", self) then
            local current = self:GetSpinDir()
            local before = self:GetData("spindir-beforedoor", false)

            if open and self:GetSpinDir() ~= 0 then
                self:SetData("spindir-beforedoor", self:GetSpin())
                self:SetSpin(false)
            elseif not open and self:GetSpinDir() == 0 and before then
                self:SetData("spindir-beforedoor", nil)
                self:SetSpin(true)
            end
        end
    end)

    ENT:AddHook("HandleE2", "spin", function(self, name, e2, ...)
        local args = {...}
        if name == "SetSpinmode" and TARDIS:CheckPP(e2.player, self) then
            local spinmode = args[1]
            if spinmode == 0 then
                self:SetSpin(false)
            else
                self:SetSpin(true, spinmode)
            end
            return self:GetSpinDir()
        elseif name == "GetSpinmode" then
            return self:GetSpinDir()
        end
    end)
end