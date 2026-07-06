-- Debug projected light

CreateClientConVar("tardis2_debug_projectedlight", "0", true, false, "Draw the exterior projected light details for debugging")
local cv = GetConVar("tardis2_debug_projectedlight")

local col_origin   = Color(50, 255, 50)    -- light source
local col_stub     = Color(255, 55, 55)    -- clipped near region (no light)
local col_cone_on  = Color(0, 235, 255)    -- live cone, light emitting
local col_cone_off = Color(95, 115, 150)   -- cone, light not emitting
local col_wall     = Color(255, 150, 0)    -- portal occluding wall (full size)

---@param origin Vector
---@param fwd Vector
---@param right Vector
---@param up Vector
---@param dist number
---@param tanh number
---@param tanv number
local function frustumCorners(origin, fwd, right, up, dist, tanh, tanv)
    local c = origin + fwd * dist
    local hw, hh = dist * tanh, dist * tanv
    return {
        c - right * hw - up * hh, c + right * hw - up * hh,
        c + right * hw + up * hh, c - right * hw + up * hh,
    }
end

---@param corners Vector[]
---@param col Color
local function drawRect(corners, col)
    for i = 1, 4 do render.DrawLine(corners[i], corners[i % 4 + 1], col, false) end
end

local function drawFrustum(self)
    -- Use the live light when it's emitting, otherwise reconstruct where it would be from metadata.
    local pl = self.projectedlight
    local active = IsValid(pl)
    local origin, ang, hfov, vfov, nearz, farz
    if active then
        origin, ang = pl:GetPos(), pl:GetAngles()
        hfov, vfov = pl:GetHorizontalFOV(), pl:GetVerticalFOV()
        nearz, farz = pl:GetNearZ(), pl:GetFarZ()
    else
        local exterior = self.metadata and self.metadata.Exterior
        local m = exterior and exterior.ProjectedLight
        if not (m and m.offset) then return end
        origin, ang = self:LocalToWorld(m.offset), self:GetAngles()
        hfov = m.horizfov or (exterior.Portal.width + 10)
        vfov = m.vertfov or exterior.Portal.height
        nearz, farz = self:PickProjectedLightNearZ(), self:PickProjectedLightDistance()
    end

    local fwd, right, up = ang:Forward(), ang:Right(), ang:Up()
    local tanh = math.tan(math.rad(hfov * 0.5))
    local tanv = math.tan(math.rad(vfov * 0.5))
    local near = frustumCorners(origin, fwd, right, up, nearz, tanh, tanv)
    local far = frustumCorners(origin, fwd, right, up, farz, tanh, tanv)

    -- clipped near stub: light origin -> NearZ
    for i = 1, 4 do render.DrawLine(origin, near[i], col_stub, false) end
    drawRect(near, col_stub)

    -- cone: NearZ -> FarZ (dimmed when the light isn't emitting)
    local cone = active and col_cone_on or col_cone_off
    for i = 1, 4 do render.DrawLine(near[i], far[i], cone, false) end
    drawRect(far, cone)

    -- the door portal's occluding wall, full-size, with the frustum overlap highlighted
    local portal = IsValid(self.interior) and self.interior.portals.exterior
    if IsValid(portal) and portal.RenderMin and portal.RenderMax then
        local rmin, rmax = portal.RenderMin, portal.RenderMax
        local backX = math.min(rmin.x, rmax.x)
        local wall = {
            portal:LocalToWorld(Vector(backX, rmin.y, rmin.z)),
            portal:LocalToWorld(Vector(backX, rmax.y, rmin.z)),
            portal:LocalToWorld(Vector(backX, rmax.y, rmax.z)),
            portal:LocalToWorld(Vector(backX, rmin.y, rmax.z)),
        }
        drawRect(wall, col_wall)
    end

    render.DrawWireframeSphere(origin, 4, 8, 8, col_origin, false)
end

hook.Add("PostDrawTranslucentRenderables", "tardis_debug_projectedlight", function(bDrawingDepth, bDrawingSkybox)
    if bDrawingDepth or bDrawingSkybox or not cv:GetBool() then return end
    cam.IgnoreZ(true)
    render.SetColorMaterial()
    for _, self in ipairs(ents.FindByClass("gmod_tardis")) do
        drawFrustum(self)
    end
    cam.IgnoreZ(false)
end)

local legend = {
    { col_origin,   "Light origin" },
    { col_cone_on,  "Light spread (visible, rendered)" },
    { col_stub,     "Light spread (cut off, not rendered)" },
    { col_cone_off, "Light spread (disabled e.g. doors closed)" },
    { col_wall,     "Portal back wall" },
}
hook.Add("HUDPaint", "tardis_debug_projectedlight_legend", function()
    if not cv:GetBool() then return end
    local x, y, lh = 16, 140, 20
    surface.SetDrawColor(0, 0, 0, 190)
    surface.DrawRect(x - 8, y - 26, 250, #legend * lh + 34)
    draw.SimpleText("Projected light debug", "DermaDefaultBold", x, y - 22, color_white)
    for i, item in ipairs(legend) do
        local iy = y + (i - 1) * lh
        surface.SetDrawColor(item[1].r, item[1].g, item[1].b, 255)
        surface.DrawRect(x, iy + 6, 26, 4)
        draw.SimpleText(item[2], "DermaDefault", x + 36, iy, color_white)
    end
end)
