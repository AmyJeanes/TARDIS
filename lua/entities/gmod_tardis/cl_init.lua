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

    -- Mirror the interior's cl_init Fallback plumbing for the exterior, so the
    -- predicted unstick can read the exterior fallback spot client-side: Doors'
    -- ResolveFallbackPos uses self.Fallback for the exit direction. The server
    -- sets this in init.lua; the metadata is rebuilt client-side just above.
    if self.metadata and self.metadata.Exterior then
        self.Fallback = self.metadata.Exterior.Fallback
    end
end)