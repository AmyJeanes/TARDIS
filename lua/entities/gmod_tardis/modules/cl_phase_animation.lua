-- Phase Animation

local function dodraw(self, ent)
    if not self:CallHook("ShouldDrawPhaseAnimation") then return end

    ent = ent or self

    local oldClip = render.EnableClipping(true)

    local normal = self:GetUp()
    local pos = self:GetData("phase-highPos",Vector(0,0,0))
    local dist = normal:Dot(pos)

    local normal2 = self:GetUp() * -1
    local pos2 = self:GetData("phase-pos",Vector(0,0,0))
    local dist2 = normal2:Dot(pos2)
    local dist3 = normal:Dot(pos2)

    local alpha = self:GetAlpha()

    local ignorez = self:CallHook("ShouldVortexIgnoreZ")
    if ignorez then
        cam.IgnoreZ(true)
    end

    local oldblend = render.GetBlend()
    render.SetBlend(alpha)

    render.PushCustomClipPlane(normal, dist)
        render.MaterialOverride(self.PhaseMaterial)
        render.PushCustomClipPlane(normal2, dist2)
            ent:DrawModel()
        render.PopCustomClipPlane()
        render.MaterialOverride()
    render.PopCustomClipPlane()

    render.PushCustomClipPlane(normal, dist3)
        ent:DrawModel()
    render.PopCustomClipPlane()

    render.EnableClipping(oldClip)

    render.SetBlend(oldblend)

    if ignorez then
        cam.IgnoreZ(false)
    end

    return false
end

ENT:AddHook("PreDraw", "phase_animation", dodraw)

ENT:AddHook("PreDrawPart", "phase_animation", function(self,part)
    if part.NoCloak ~= true then
        return dodraw(self,part)
    end
end)

ENT:AddHook("Initialize", "phase_animation", function(self)
    self.PhaseMaterial = Material(self.metadata.Exterior.PhaseMaterial)
end)

ENT:AddHook("ExteriorChanged", "phase_animation", function(self)
    self.PhaseMaterial = Material(self.metadata.Exterior.PhaseMaterial)
end)
