-- Metadata

function ENT:GetSphere()
    return self:GetData("sphere-center", Vector(0, 0, 0)), self:GetData("sphere-radius", 0)
end

-- hook.Add("PostDrawTranslucentRenderables", "tardis-sphere", function()
--     for k, v in pairs(ents.FindByClass("gmod_tardis_interior")) do
--         local center,radius = v:GetSphere()
--         if radius then
--             local pos = v:LocalToWorld(center)
--             render.DrawWireframeSphere(pos, radius, 20, 20, Color(255, 255, 255), true)
--         end
--     end
-- end)

if CLIENT then return end

function ENT:UpdateSphere()
    if self.ExitDistance then
        self:SetData("sphere-radius", self.ExitDistance, true)
        self:SetData("sphere-center", vector_origin, true)
        return
    end

    local mins, maxs = self.ExitBox.Min, self.ExitBox.Max
    local center = (maxs + mins) / 2
    local dx = maxs.x - center.x
    local dy = maxs.y - center.y
    local dz = maxs.z - center.z
    local radius = math.sqrt(dx^2 + dy^2 + dz^2)

    self:SetData("sphere-radius", radius, true)
    self:SetData("sphere-center", center, true)
end

ENT:AddHook("Initialize", "metadata", function(self)
    self:UpdateSphere()
end)