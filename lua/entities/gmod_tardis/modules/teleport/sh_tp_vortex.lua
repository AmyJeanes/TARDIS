-- Vortex / autoland related functions

---@api
function ENT:GetAutoland()
    return self:GetData("autoland",false)
end

if CLIENT then
    return
end

ENT:AddHook("DematStart", "no_vortex_premat", function(self)
    if self:GetAutoland() and not self:GetData("redecorate") then
        local tp = self.metadata.Exterior.Teleport
        local premat_lead = math.max(0, self:GetDematDuration() - tp.PrematDelay)
        self:Timer("premat", premat_lead, function()
            if not IsValid(self) then return end
            self:SendMessage("premat", { self:GetDestinationPos(true) })
            self:SetData("premat-start", CurTime(), true)
            self:CallCommonHook("PreMatStart")
        end)
    end
end)

---@api
---@return boolean
function ENT:ToggleAutoland()
    local on = not self:GetAutoland()
    return self:SetAutoland(on)
end

---@api
---@param on boolean
---@param force boolean?
function ENT:SetAutoland(on, force)
    if self:CallHook("CanToggleAutoland", force) == false then
        return false
    end

    self:SetData("autoland",on,true)
    self:CallHook("AutolandToggled", on)
    return true
end

ENT:AddHook("CanToggleAutoland", "vortex", function(self, force)
    if not force and (self:GetData("vortex") or self:GetData("teleport")) then
        return false
    end
end)

ENT:AddHook("ShouldStopSmoke", "vortex", function(self)
    if self:GetData("vortex") or self:GetData("demat") then return true end
end)

ENT:AddHook("ShouldTakeDamage", "vortex", function(self)
    if self:GetData("vortex",false) then return false end
end)

ENT:AddHook("ShouldTurnOffRotorwash", "vortex", function(self)
    if self:GetData("vortex") then
        return true
    end
end)
