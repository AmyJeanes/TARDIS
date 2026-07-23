-- Interior screens

ENT:AddHook("Initialize", "screens-toggle", function(self)
    local screens_on = self.metadata.Interior.ScreensEnabled
    self:SetData("screens_on", screens_on, true)
end)

ENT:AddHook("CanToggleScreens", "power", function(self)
    if not self:GetData("power-state") then
        return false
    end
end)

ENT:AddHook("CanEnableScreens", "power", function(self)
    if not self:GetData("power-state") then
        return false
    end
end)

---@api
function ENT:GetScreensOn()
    return self:GetData("screens_on", false)
end

---@api
---@param on boolean
function ENT:SetScreensOn(on)
    if not on or self:CallHook("CanEnableScreens") ~= false then
        self:SetData("screens_on", on, true)
        self:CallHook("ScreensToggled", on)
    end
    return true
end

---@api
function ENT:ToggleScreens()
    if self:CallHook("CanToggleScreens") ~= false then
        self:SetScreensOn(not self:GetScreensOn())
        return true
    end
    return false
end

if SERVER then
    return
end

---@class gmod_tardis_interior
---@field screensWorldOrigin Vector?

function ENT:RemoveScreens()
    if self.screens3D then
        for _,v in pairs(self.screens3D) do
            if IsValid(v) then
                v:Remove()
            end
        end
    end
end

function ENT:LoadScreens()
    self:RemoveScreens()
    local metadata_screens=self.metadata.Interior.Screens
    if metadata_screens then
        self.screens3D={}
        for k,v in pairs(metadata_screens) do
            local black = v.power_off_black
            if black == nil then
                black = true
            end
            self.screens3D[k] = TARDIS:LoadScreen(k, {
                width = v.width,
                height = v.height,
                ext = self.exterior,
                int = self,
                gui_rows = v.gui_rows,
                power_off_black = black,
            })
            self.screens3D[k].pos3D=v.pos
            self.screens3D[k].ang3D=v.ang
        end
    end
end

ENT:AddHook("Initialize", "screens", function(self)
    self:LoadScreens()
end)

ENT:AddHook("LanguageChanged", "screens", function(self)
    self:LoadScreens()
end)

local settings_upd_screen = {
    ["gui_old"] = true,
    ["gui_screen_numrows"] = true,
    ["gui_override_numrows"] = true,
    ["gui_interface_theme"] = true,
}

ENT:AddHook("SettingChanged", "screen_settings", function(self, id, val)
    if not settings_upd_screen[id] then return end

    self:LoadScreens()
end)

ENT:AddHook("OnRemove", "screens", function(self)
    self:RemoveScreens()
end)

-- Thanks world-portals
---@param screen TardisScreen
function ENT:ShouldRenderScreen(screen)
    if self:CallHook("ShouldDraw") == false then return false end

    -- A screen carried by a moving part supplies its pose here, in the frame it
    -- is drawn; taken any earlier it trails the part it is mounted on.
    if screen.GetPose3D then
        local p, a = screen.GetPose3D()
        if p and a then
            screen.pos3D = p
            screen.ang3D = a
        end
    end

    local pos3D = screen.pos3D
    local ang3D = screen.ang3D
    if not pos3D or not ang3D then return false end

    -- Cached per screen, rebuilt when the pose it was built from changes - a
    -- monitor part rewrites its screen's local pose as it moves. The render
    -- hook drops the caches too, for the interior itself moving.
    local pos, ang, up = screen.worldpos, screen.worldang, screen.worldup
    if pos == nil or pos3D ~= screen.worldsrcpos or ang3D ~= screen.worldsrcang then
        pos = self:LocalToWorld(pos3D)
        ang = self:LocalToWorldAngles(ang3D)
        up = ang:Up()
        screen.worldpos = pos
        screen.worldang = ang
        screen.worldup = up
        screen.worldsrcpos = pos3D
        screen.worldsrcang = ang3D
    end

    --don't render if the view is behind the portal
    local behind = TARDIS:IsBehind( EyePos(), pos, up )
    if behind then return false end

    return true, pos, ang
end

local COL_CLEAR = Color(0, 0, 0, 0)

ENT:AddHook("PreDrawTranslucentRenderables", "screens", function(self)
    if self.screens3D then
        local int_pos = self:GetPos()
        if self.screensWorldOrigin ~= int_pos then
            self.screensWorldOrigin = int_pos
            for _,v in pairs(self.screens3D) do
                v.worldpos = nil
            end
        end
        for _,v in pairs(self.screens3D) do
            local should,pos,ang = self:ShouldRenderScreen(v)
            if should then
                vgui.Start3D2D(pos,ang,0.0624*(1/v.res))
                    draw.RoundedBox(0,0,0,v.width,v.height,COL_CLEAR)
                    v:Paint3D2D()
                vgui.End3D2D()
            end
        end
    end
end)

ENT:AddHook("ShouldNotDrawScreen", "screens", function(self)
    if not self:GetScreensOn() then
        return true
    end
end)
