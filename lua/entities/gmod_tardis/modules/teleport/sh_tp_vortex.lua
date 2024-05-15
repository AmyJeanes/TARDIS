-- Vortex / fast remat related functions

function ENT:GetFastRemat()
    return self:GetData("demat-fast",false)
end

if CLIENT then
    return
end

ENT:AddHook("StopDemat", "no_vortex", function(self)
    if self:GetFastRemat() then
        self:Timer("fastremat", 0.3, function()
            if not IsValid(self) then return end
            self:Mat()
        end)
    end
end)

function ENT:ToggleFastRemat()
    local on = not self:GetFastRemat()
    return self:SetFastRemat(on)
end

function ENT:SetFastRemat(on, force)
    if self:CallHook("CanToggleFastRemat", force) == false then
        return false
    end

    self:SetData("demat-fast",on,true)
    self:CallHook("FastRematToggled", on)
    return true
end

ENT:AddHook("CanToggleFastRemat", "vortex", function(self, force)
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
