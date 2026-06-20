-- Spacebuild

ENT:AddHook("Initialize", "spacebuild", function(self)
    if not (CAF and CAF.GetAddon("Spacebuild")) then
        return
    end

    self:SetData("spacebuild", true)
end)

ENT:AddHook("FloatToggled", "spacebuild", function(self, on)
    local environment = self.environment
    if not self:GetData("spacebuild", false) or not environment then
        return
    end

    if not on then
        self.gravity = nil
        environment:UpdateGravity(self)
    end
end)
