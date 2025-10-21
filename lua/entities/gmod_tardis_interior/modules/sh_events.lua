-- Events

function ENT:IsAprilFoolsEvent()
    return IsValid(self.exterior) and self.exterior:IsAprilFoolsEvent()
end

function ENT:IsHalloweenEvent()
    return IsValid(self.exterior) and self.exterior:IsHalloweenEvent()
end

function ENT:IsChristmasEvent()
    return IsValid(self.exterior) and self.exterior:IsChristmasEvent()
end

function ENT:GetEvent()
    return IsValid(self.exterior) and self.exterior:GetEvent()
end

function ENT:NotifyEvent(force, all)
    return IsValid(self.exterior) and self.exterior:NotifyEvent(force, all)
end
