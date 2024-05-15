-- Physical Lock

TARDIS:AddKeyBind("physlock-toggle",{
    name="TogglePhyslock",
    section="ThirdPerson",
    func=function(self,down,ply)
        if ply==self.pilot and down then
            TARDIS:Control("physlock", ply)
        end
    end,
    key=KEY_G,
    serveronly=true,
    exterior=true
})

function ENT:GetPhyslock()
    return self:GetData("physlock",false)
end

if CLIENT then return end

function ENT:ExplodeIfFast()
    local phys = self:GetPhysicsObject()
    local vel = phys:GetVelocity():Length()

    if vel > 50 and IsValid(self.interior) then
        util.ScreenShake(self.interior:GetPos(), 1, 20, 0.3, 700)
    end
    if vel > 1600 then
        self:Explode(math.max((vel - 2500) / 5, 0))
    end
end

function ENT:SetPhyslock(on)
    if not on and self:CallHook("CanTurnOffPhyslock") == false then
        return false
    end
    if on and self:CallHook("CanTurnOnPhyslock") == false then
        self:CallHook("FailedPhyslockEnable")
        return false
    end

    local phys = self:GetPhysicsObject()
    local vel = phys:GetVelocity():Length()
    if on then
        self:ExplodeIfFast()
    end
    if self:GetPower() then
        self:SetData("physlock", on, true)
        phys:EnableMotion(not on)
    else
        self:SetData("physlock", false, true)
        phys:EnableMotion(true)
    end
    phys:Wake()
    self:CallCommonHook("PhyslockToggled", on)
    return true
end

function ENT:TogglePhyslock()
    local on = not self:GetPhyslock()
    return self:SetPhyslock(on)
end

ENT:AddHook("MatStart", "physlock", function(self)
    if not self:GetPhyslock() then
        self.phys:EnableMotion(true)
        self.phys:Wake()
    end
end)

ENT:AddHook("PowerToggled", "physlock", function(self,on)
    if self:GetData("redecorate") then return end
    if on and self:GetData("power-lastphyslock", false) == true then
        self:SetPhyslock(true)
    else
        self:SetData("power-lastphyslock", self:GetPhyslock())
        self:SetPhyslock(false)
    end
end)

ENT:AddHook("CanTurnOnPhyslock", "physlock", function(self)
    if not self:GetPower() then
        return false
    end
end)

ENT:AddHook("HandleE2", "physlock", function(self, name, e2, ...)
    local args = {...}
    if name == "GetPhyslocked" then
        return self:GetPhyslock() and 1 or 0
    elseif name == "Physlock" and TARDIS:CheckPP(e2.player, self) then
        return self:TogglePhyslock() and 1 or 0
    elseif name == "SetPhyslock" and TARDIS:CheckPP(e2.player, self) then
        local on = args[1]
        local physlocked = self:GetPhyslock()
        if on == 1 then
            if (not physlocked) and self:SetPhyslock(true) then
                return 1
            end
        else
            if physlocked and self:SetPhyslock(false) then
                return 1
            end
        end
        return 0
    end
end)

ENT:AddHook("MigrateData", "physlock", function(self, parent, parent_data)
    self:SetPhyslock(parent_data["physlock"])
end)

ENT:AddHook("OnHealthChange", "physlock", function(self)
    if self:IsBroken() and self:GetPhyslock() then
        self:SetPhyslock(false)
    end
end)

ENT:AddHook("FailedPhyslockEnable", "physlock", function(self)
    if self:IsBroken() then
        local vel = self:GetPhysicsObject():GetVelocity():Length()
        self:Explode(math.max((vel - 2500) / 5, 0))
    end
end)
