-- TARDIS debug pointer
-- Creators: Brundoob, Parar020100 and RyanM2711

include('shared.lua')

function ENT:Initialize()
    self:UpdateRenderBounds()
end

function ENT:Draw()
    self:DrawModel()

    if self:GetDrawAABox() then
        local other = self:GetOther()
        if not IsValid(other) then return end
        local mins, maxs = self:GetRenderBounds()
        render.DrawWireframeBox(self:GetPos(), angle_zero, vector_origin, other:GetPos() - self:GetPos(), Color(255, 0, 0), true)
    end
end

function ENT:UpdateRenderBounds()
    local other = self:GetOther()
    if IsValid(other) then
        local mins, maxs = self:GetPos(), self:GetOther():GetPos()
        self:SetRenderBoundsWS(mins, maxs)
    else
        self:SetRenderBounds(self:OBBMins(), self:OBBMaxs())
    end
end

function ENT:Think()
    if self:GetDrawAABox() then
        self:UpdateRenderBounds()
    end
end