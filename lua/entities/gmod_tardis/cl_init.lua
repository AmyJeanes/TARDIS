include('shared.lua')

ENT:AddHook("PlayerInitialize", "interior", function(self)
    local id = net.ReadString()
    if net.ReadBool() then
        self.templates = TARDIS.von.deserialize(net.ReadString())
        if self.interior then
            self.interior.templates = self.templates
        end
    end

    self.metadata=TARDIS:CreateInteriorMetadata(id, self)

    -- The predicted unstick reads self.Fallback on the client (set server-side in init.lua).
    if self.metadata and self.metadata.Exterior then
        self.Fallback = self.metadata.Exterior.Fallback
    end
end)