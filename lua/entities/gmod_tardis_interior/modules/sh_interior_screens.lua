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

function ENT:GetScreensOn()
    return self:GetData("screens_on", false)
end

function ENT:SetScreensOn(on)
    if not on or self:CallHook("CanEnableScreens") ~= false then
        self:SetData("screens_on", on, true)
        self:CallHook("ScreensToggled", on)
    end
    return true
end

function ENT:ToggleScreens()
    if self:CallHook("CanToggleScreens") ~= false then
        self:SetScreensOn(not self:GetScreensOn())
        return true
    end
    return false
end

if SERVER then
    ENT:LoadFolder("modules/screens")
    return
end

local screens={}
function ENT:AddScreen(name,func)
    screens[name]=func
end
ENT:LoadFolder("modules/screens")

function ENT:GetScreens()
    return screens
end

function ENT:RemoveScreens()
    if self.screens3D then
        for k,v in pairs(self.screens3D) do
            if IsValid(v) then
                v:Remove()
            end
        end
    end
end

function ENT:LoadScreens()
    self:RemoveScreens()
    local screens=self.metadata.Interior.Screens
    if screens then
        self.screens3D={}
        for k,v in pairs(screens) do
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
function ENT:ShouldRenderScreen(screen)
    local camOrigin = GetViewEntity():EyePos()
    local pos = self:LocalToWorld(screen.pos3D)
    local ang = self:LocalToWorldAngles(screen.ang3D)
    local distance = camOrigin:Distance(pos)
    local disappearDist = self.metadata.Interior.ScreenDistance

    if not (disappearDist <= 0) and distance > disappearDist then return false end

    --don't render if the view is behind the portal
    local behind = TARDIS:IsBehind( camOrigin, pos, ang:Up() )
    if behind then return false end

    return true, pos, ang
end

ENT:AddHook("PostDrawTranslucentRenderables", "screens", function(self)
    if self.screens3D then
        for k,v in pairs(self.screens3D) do
            local should,pos,ang = self:ShouldRenderScreen(v)
            if should then
                local col=Color(0,0,0,0)
                vgui.Start3D2D(pos,ang,0.0624*(1/v.res))
                    draw.RoundedBox(0,0,0,v.width,v.height,col)
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
