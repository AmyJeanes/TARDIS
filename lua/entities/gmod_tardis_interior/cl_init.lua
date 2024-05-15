include('shared.lua')

ENT:AddHook("PlayerInitialize", "interior", function(self)
    local id = net.ReadString()
    if net.ReadBool() then
        self.templates = TARDIS.von.deserialize(net.ReadString())
        if self.exterior then
            self.exterior.templates = self.templates
        end
    end

    self.metadata=TARDIS:CreateInteriorMetadata(id, self)

    self.Model=self.metadata.Interior.Model
    self.Fallback=self.metadata.Interior.Fallback
    self.Portal=self.metadata.Interior.Portal
    if self.metadata.Interior.ExitBox then
        self.ExitBox=self.metadata.Interior.ExitBox
    else
        self.ExitDistance=self.metadata.Interior.ExitDistance
    end
    self.mins=self.metadata.Interior.Size.Min
    self.maxs=self.metadata.Interior.Size.Max
end)

