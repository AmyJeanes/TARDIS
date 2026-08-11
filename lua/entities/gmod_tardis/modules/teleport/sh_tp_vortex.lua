-- Vortex / autoland related functions

---@api
---@param real boolean? the actual applied setting, not the queued value
---@return boolean
function ENT:GetAutoland(real)
    if real then
        return self:GetData("autoland",false)
    end
    local queued = self:GetData("autoland-queued")
    if queued ~= nil then return queued end
    return self:GetData("autoland",false)
end

if CLIENT then
    return
end

ENT:AddHook("DematStart", "no_vortex_premat", function(self)
    if self:GetAutoland(true) and not self:GetData("redecorate") then
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
    return self:SetAutoland(not self:GetAutoland())
end

---@api
---@param on boolean
---@param force boolean?
---@return boolean
function ENT:SetAutoland(on, force)
    if self:CallHook("CanToggleAutoland", force) == false then
        return false
    end

    -- Queue it if we can't currently toggle it, or clear the queue if this
    -- toggle just brings it back to the value it's currently using
    if not force and (self:GetData("vortex") or self:GetData("teleport")) then
        if on == self:GetData("autoland", false) then
            self:SetData("autoland-queued", nil, true)
        else
            self:SetData("autoland-queued", on, true)
        end
        return true
    end

    self:SetData("autoland", on, true)
    self:SetData("autoland-queued", nil, true)
    self:CallHook("AutolandToggled", on)
    return true
end

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
