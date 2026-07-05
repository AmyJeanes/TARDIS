-- Events

---@api
function ENT:IsAprilFoolsEvent()
    return IsValid(self.exterior) and self.exterior:IsAprilFoolsEvent()
end

---@api
function ENT:IsHalloweenEvent()
    return IsValid(self.exterior) and self.exterior:IsHalloweenEvent()
end

---@api
function ENT:IsChristmasEvent()
    return IsValid(self.exterior) and self.exterior:IsChristmasEvent()
end

---@api
---@return integer?
function ENT:GetEvent()
    return IsValid(self.exterior) and self.exterior:GetEvent()
end

---@api
---@param force boolean?
---@param all boolean?
function ENT:NotifyEvent(force, all)
    return IsValid(self.exterior) and self.exterior:NotifyEvent(force, all)
end
