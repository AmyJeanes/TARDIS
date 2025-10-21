-- Events

function ENT:IsAprilFoolsEvent()
    return self:GetData("events-aprilfools", false)
end

function ENT:IsHalloweenEvent()
    return self:GetData("events-halloween", false)
end

function ENT:IsChristmasEvent()
    return self:GetData("events-christmas", false)
end

function ENT:GetEvent()
    return self:GetData("event")
end

function ENT:NotifyEvent(force, all)
    local event = self:GetEvent()
    if not event then return end
    local target
    if all then
        target = nil
    else
        target = self:GetCreator()
    end
    if SERVER then
        self:SendMessage("events-notify", {force, all}, target)
    elseif CLIENT and (all or LocalPlayer() == target) then
        if self:GetData("events-notified", false) and not force then return end
        TARDIS:NotifyEvent(event)
        self:SetData("events-notified", true)
    end
end

if SERVER then
    ENT:AddHook("PreMetadataInitialize", "halloween", function(self)
        local event = TARDIS:GetCurrentEvent(self)
        self:SetData("event", event, true)
        if event == TARDIS_EVENTS_APRIL_FOOLS then
            self:SetData("events-aprilfools", true, true)
        elseif event == TARDIS_EVENTS_HALLOWEEN then
            self:SetData("events-halloween", true, true)
        elseif event == TARDIS_EVENTS_CHRISTMAS then
            self:SetData("events-christmas", true, true)
        end
    end)
else
    ENT:OnMessage("events-notify", function(self, data, ply)
        self:NotifyEvent(data[1], data[2])
        self:SetData("events-notified", true)
    end)
end
