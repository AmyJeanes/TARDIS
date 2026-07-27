---@vendored
--[[

3D2D VGUI Wrapper
Copyright (c) 2015-2017 Alexander Overvoorde, Matt Stevens

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

]]--

local origin = Vector(0, 0, 0)
local angle = Angle(0, 0, 0)
local normal = Vector(0, 0, 0)
local scale = 0
local maxrange = 0

-- Helper functions

local ANGLE_ZERO = Angle(0, 0, 0)

local function getCursorPos()
    local ply = LocalPlayer()
    local eyePos = ply:EyePos()
    local p = util.IntersectRayWithPlane(eyePos, ply:GetAimVector(), origin, normal)

    -- if there wasn't an intersection, don't calculate anything.
    if not p then return end
    -- Behind the plane when the eye sits on the normal's negative side
    -- (the scalar form of WorldToLocal(...).z < 0).
    local sp = ply:GetShootPos()
    if (sp.x - origin.x) * normal.x
        + (sp.y - origin.y) * normal.y
        + (sp.z - origin.z) * normal.z < 0 then return end

    if maxrange > 0 then
        if p:Distance(eyePos) > maxrange then
            return
        end
    end

    local pos = WorldToLocal(p, ANGLE_ZERO, origin, angle)

    return pos.x, -pos.y
end

---@param pnl Panel
local function absolutePanelPos(pnl)
    local x, y = pnl:GetPos()
    local parent = pnl:GetParent()
    while parent do
        local px, py = parent:GetPos()
        x = x + px
        y = y + py
        parent = parent:GetParent()
    end

    return x, y
end

---@param pnl Panel
---@param x number?
---@param y number?
local function pointInsidePanel(pnl, x, y)
    local px, py = absolutePanelPos(pnl)
    local sx, sy = pnl:GetSize()

    if not x or not y then return end

    x = x / scale
    y = y / scale

    return pnl:IsVisible() and x >= px and y >= py and x <= px + sx and y <= py + sy
end

-- Input

local inputWindows = {}
---@type table<Panel, any[]>
local usedpanel = {}

---@param pnl Panel
---@param event string
---@param ... any
local function postPanelEvent(pnl, event, ...)
    if not IsValid(pnl) or not pnl:IsVisible() or not pointInsidePanel(pnl, getCursorPos()) then return false end

    local handled = false

    local children = pnl:GetChildren()
    for i = #children, 1, -1 do
        if postPanelEvent(children[i], event, ...) then
            handled = true
            break
        end
    end

    if not handled and pnl[event] then
        pnl[event](pnl, ...)
        usedpanel[pnl] = {...}
        return true
    else
        return false
    end
end

-- Always have issue, but less
---@param pnl Panel
---@param x number?
---@param y number?
---@param found boolean?
local function checkHover(pnl, x, y, found)
    if not (x and y) then
        x, y = getCursorPos()
    end

    local validchild = false
    local children = pnl:GetChildren()
    for i = #children, 1, -1 do
        local check = checkHover(children[i], x, y, found or validchild)

        if check then
            validchild = true
        end
    end

    if found then
        if pnl.Hovered then
            pnl.Hovered = false
            if pnl.OnCursorExited then pnl:OnCursorExited() end
        end
    else
        if not validchild and pointInsidePanel(pnl, x, y) then
            pnl.Hovered = true
            if pnl.OnCursorEntered then pnl:OnCursorEntered() end

            return true
        else
            pnl.Hovered = false
            if pnl.OnCursorExited then pnl:OnCursorExited() end
        end
    end

    return false
end

-- Mouse input

hook.Add("KeyPress", "VGUI3D2DMousePress", function(_, key)
    if key == IN_USE then
        for pnl in pairs(inputWindows) do
            if IsValid(pnl) then
                origin = pnl.Origin
                scale = pnl.Scale
                angle = pnl.Angle
                normal = pnl.Normal

                local mouse_button = input.IsKeyDown(KEY_LSHIFT) and MOUSE_RIGHT or MOUSE_LEFT

                postPanelEvent(pnl, "OnMousePressed", mouse_button)
            end
        end
    end
end)

hook.Add("KeyRelease", "VGUI3D2DMouseRelease", function(_, key)
    if key == IN_USE then
        for pnl, used_key in pairs(usedpanel) do
            if IsValid(pnl) then
                origin = pnl.Origin
                scale = pnl.Scale
                angle = pnl.Angle
                normal = pnl.Normal

                if pnl["OnMouseReleased"] then
                    pnl["OnMouseReleased"](pnl, used_key[1])
                end

                usedpanel[pnl] = nil
            end
        end
    end
end)

---@param pos Vector
---@param ang Angle
---@param res number
function vgui.Start3D2D(pos, ang, res)
    origin = pos
    scale = res
    angle = ang
    normal = ang:Up()
    maxrange = 0

    cam.Start3D2D(pos, ang, res)
end

---@param range number?
function vgui.MaxRange3D2D(range)
    maxrange = isnumber(range) and range or 0
end

---@param pnl Panel
function vgui.IsPointingPanel(pnl)
    origin = pnl.Origin
    scale = pnl.Scale
    angle = pnl.Angle
    normal = pnl.Normal

    return pointInsidePanel(pnl, getCursorPos())
end

local Panel = assert(FindMetaTable("Panel"))

-- Shared gui.MouseX/MouseY overrides, fed per paint via upvalues.
local curX, curY = 0, 0
local function mouse3D2DX()
    return curX / scale
end
local function mouse3D2DY()
    return curY / scale
end

function Panel:Paint3D2D()
    if not self then return end
    if not self:IsValid() then return end

    -- Add it to the list of windows to receive input
    inputWindows[self] = true

    -- Override gui.MouseX and gui.MouseY for certain stuff
    local oldMouseX = gui.MouseX
    local oldMouseY = gui.MouseY
    local cx, cy = getCursorPos()
    curX, curY = cx or 0, cy or 0

    gui.MouseX = mouse3D2DX
    gui.MouseY = mouse3D2DY

    -- Override think of DFrame's to correct the mouse pos by changing the active orientation
    if self.Think then
        if not self.OThink then
            self.OThink = self.Think

            self.Think = function()
                origin = self.Origin
                scale = self.Scale
                angle = self.Angle
                normal = self.Normal

                self:OThink()
            end
        end
    end

    -- Update the hover state of controls: walk only while the cursor is over
    -- the panel, plus one pass after it leaves so OnCursorExited still fires.
    local inRoot = cx ~= nil and pointInsidePanel(self, cx, cy)
    if inRoot or self.Hover3D2DArmed then
        checkHover(self, cx, cy)
        self.Hover3D2DArmed = inRoot or nil
    end

    -- Store the orientation of the window to calculate the position outside the render loop
    self.Origin = origin
    self.Scale = scale
    self.Angle = angle
    self.Normal = normal

    -- Draw it manually
    self:SetPaintedManually(false)
        self:PaintManual()
    self:SetPaintedManually(true)

    gui.MouseX = oldMouseX
    gui.MouseY = oldMouseY
end

function vgui.End3D2D()
    cam.End3D2D()
end
