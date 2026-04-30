---@class TardisScreenButton
---@field visible boolean
---@field transparency number
---@field outside boolean
---@field parent Panel
---@field clickable boolean
---@field text string
---@field click_time number
---@field icon DImageButton
---@field frame DImageButton
---@field label DLabel
---@field is_toggle boolean
---@field theme table
---@field frame_off string
---@field frame_on string
---@field icon_off string
---@field icon_on string
---@field on boolean
---@field pos number[]
---@field size number[]
---@field moving TardisScreenButtonMove
---@field toggle_images boolean
---@field id string?
---@field order integer?
TardisScreenButton = {}

---@class TardisScreenButtonMove
---@field now boolean?
---@field parent TardisScreenButton?
---@field speed number?
---@field aim number[]?
---@field now_outside boolean?
---@field aim_outside boolean?
---@field transp_aim number?
---@field move fun()?

---@return TardisScreenButton
function TardisScreenButton:new(parent,screen)
    local sb = {}

    sb.visible = true
    sb.transparency = 0
    sb.outside = false
    sb.parent = parent
    sb.clickable = true
    sb.text = ""
    sb.click_time = 0.5

    sb.icon = vgui.Create("DImageButton", parent)
    sb.frame = vgui.Create("DImageButton", parent)
    sb.label = vgui.Create("DLabel", parent)
    sb.label:SetColor(Color(255,255,255,0))
    sb.label:SetText("")
    sb.label:SetFont(TARDIS:GetScreenFont(screen, "Default"))

    sb.is_toggle = false

    sb.theme = TARDIS:GetScreenGUITheme(screen)

    sb.frame_off = TARDIS:GetGUIThemeElement(sb.theme, "frames", "off")
    sb.frame_on  = TARDIS:GetGUIThemeElement(sb.theme, "frames", "on")
    sb.icon_off  = TARDIS:GetGUIThemeElement(sb.theme, "text_icons_off")
    sb.icon_on   = TARDIS:GetGUIThemeElement(sb.theme, "text_icons_on")

    sb.icon:SetImage(sb.icon_off)
    sb.frame:SetImage(sb.frame_off)

    sb.on = false
    sb.pos = {0, 0}
    sb.size = {10, 10}

    sb.moving = {}
    sb.moving.now = false

    sb.toggle_images = false

    sb.Think = function() end
    sb.DoClick = function() end

    sb.SetVisibleCustom = function(vis)
        if vis then
            sb.transparency = 255
        else
            sb.transparency = 0
        end
    end

    sb.ThinkInternal = function()
        if not IsValid(parent) then return end

        sb.transparency = math.Clamp(sb.transparency, 0, 255)

        if not sb.is_toggle and sb.on and CurTime() > sb.click_end_time then
            sb.icon:SetImage(sb.icon_off)
            sb.frame:SetImage(sb.frame_off)
            sb.on = false
        end

        if sb.moving.now then
            sb.moving.move()
            sb.icon:SetColor(Color(255, 255, 255, sb.transparency))
            sb.frame:SetColor(Color(255, 255, 255, sb.transparency))
            sb.label:SetColor(Color(0, 0, 0, sb.transparency))
            sb.clickable = (sb.transparency ~= 0)
        end

        if sb.lastpos == nil or sb.lastpos[1] ~= sb.pos[1] or sb.lastpos[2] ~= sb.pos[2] then

            local realpos = { math.Clamp(sb.pos[1], 0, sb.parent:GetWide() - sb.size[1]),
                            math.Clamp(sb.pos[2], 0, sb.parent:GetTall() - sb.size[2]) }

            sb.icon:SetPos(realpos[1], realpos[2])
            sb.frame:SetPos(realpos[1], realpos[2])
            sb.label:SetPos(sb.pos[1], sb.pos[2])

            sb.icon:SetSize(sb.size[1], sb.size[2])
            sb.frame:SetSize(sb.size[1], sb.size[2])
            sb.label:SetSize(sb.size[1], sb.size[2])

            sb.lastpos = {sb.pos[1], sb.pos[2]}
        end

        if not sb.moving.now then
            sb.outside = (sb.pos[1] < 0) or (sb.pos[2] < 0)
                or (sb.pos[1] + sb.size[1] > sb.parent:GetWide())
                or (sb.pos[2] + sb.size[2] > sb.parent:GetTall())
            sb.SetVisibleCustom(not sb.outside)
        end
        sb.Think()
    end

    sb.DoClickInternal = function()
        if not sb.clickable then return end
        if sb.is_toggle then
            sb.DoClick()
            sb.on = not sb.on
            if sb.toggle_images then
                if sb.on then
                    sb.icon:SetImage(sb.icon_on)
                    sb.frame:SetImage(sb.frame_on)
                else
                    sb.icon:SetImage(sb.icon_off)
                    sb.frame:SetImage(sb.frame_off)
                end
            end
        else
            if not sb.on then
                sb.DoClick()
                sb.on = true
                sb.icon:SetImage(sb.icon_on)
                sb.frame:SetImage(sb.frame_on)
                sb.click_end_time = CurTime() + sb.click_time
            end
        end
    end

    sb.label.Think = sb.ThinkInternal

    sb.icon.DoClick = sb.DoClickInternal
    sb.frame.DoClick = sb.DoClickInternal
    sb.label.DoClick = sb.DoClickInternal
    sb.ThinkInternal()

    setmetatable(sb,self)
    self.__index = self
    return sb
end

function TardisScreenButton:Think()
    self.ThinkInternal()
end

function TardisScreenButton:SetSize(sizeX, sizeY)
    self.size = {sizeX, sizeY}
    self:AdjustTextOffset()
    self.ThinkInternal()
end

function TardisScreenButton:SetPos(posX, posY)
    if posY == nil then
        self.pos = {posX, 0}
    else
        self.pos = {posX, posY}
    end
    self.ThinkInternal()
end

function TardisScreenButton:SetImages(off, on)
    self.icon_off = off
    self.icon_on = on or off
    self.icon:SetImage(self.icon_off)
end

function TardisScreenButton:SetFrameImages(off, on)
    self.frame_off = off
    self.frame_on = on or off
    self.frame:SetImage(self.frame_off)
end

function TardisScreenButton:SetFrameType(type1, type2)
    if type2 == nil then
        type2 = type1
    end
    local function getFrameType(type)
        if type == 0 then
            return "default", true
        elseif type == 1 then
            return "on"
        elseif type == 2 then
            return "off"
        end
    end
    self.frame_off = TARDIS:GetGUIThemeElement(self.theme, "frames", getFrameType(type1))
    self.frame_on  = TARDIS:GetGUIThemeElement(self.theme, "frames", getFrameType(type2))
    self.frame:SetImage(self.frame_off)
end

function TardisScreenButton:SetID(id)
    self.id = id
end

function TardisScreenButton:SetOrder(order)
    self.order = order
end

function TardisScreenButton:SetText(text)
    if not self.id then error("You must set button id before calling SetText") end
    self.text = text
    local theme = self.theme
    local file_on =  TARDIS:GetGUIThemeElement(theme, "text_icons_on", self.id, true)
    local file_off = TARDIS:GetGUIThemeElement(theme, "text_icons_off", self.id, true)

    if file_on == nil then
        file_on = file_off
    end
    if file_off == nil then
        file_on =  TARDIS:GetGUIThemeElement(theme, "text_icons_on")
        file_off = TARDIS:GetGUIThemeElement(theme, "text_icons_off")
        self.label:SetColor(Color(0,0,0,255))
        self.label:SetText(TARDIS:GetPhrase(text))
    end

    self:SetImages(file_off, file_on)
    self:AdjustTextOffset()
end

function TardisScreenButton:AdjustTextOffset()
    local label = assert(self.label)
    local text = label:GetText()
    local w, h = label:GetTextSize()
    local size = self.size[1]

    label:SetBGColor(255,255,255,255)

    if w < size then
        surface.SetFont(label:GetFont())
        local spacesizeX, spacesizeY = surface.GetTextSize(" ")

        local spaces = math.floor(0.5 * (size - w) / spacesizeX)
        for i = 1, spaces do
            text = " "..text.." "
        end
        label:SetText(text)
    end
end

function TardisScreenButton:SetFont(font)
    self.label:SetFont(font)
    self:AdjustTextOffset()
end

function TardisScreenButton:GetPosX()
    return self.pos[1]
end
function TardisScreenButton:GetPosY()
    return self.pos[2]
end
function TardisScreenButton:GetWide()
    return self.size[1]
end
function TardisScreenButton:GetTall()
    return self.size[2]
end
function TardisScreenButton:GetSize()
    return self.size[1], self.size[2]
end

function TardisScreenButton:SetIsToggle(is_toggle)
    self.is_toggle=is_toggle
end

function TardisScreenButton:SetPressed(on)
    if self.on ~= on then
        self.on = on
        if on then
            self.icon:SetImage(self.icon_on)
            self.frame:SetImage(self.frame_on)
        else
            self.icon:SetImage(self.icon_off)
            self.frame:SetImage(self.frame_off)
        end
    end
end
function TardisScreenButton:IsPressed()
    return self.on
end

function TardisScreenButton:SetClickTime(t)
    self.click_time = t
end

function TardisScreenButton:SetVisible(visible)
    self.visible = visible
    self.icon:SetVisible(visible)
    self.frame:SetVisible(visible)
    self.label:SetVisible(visible)
end

function TardisScreenButton:IsVisible()
    return self.visible
end

function TardisScreenButton:SetTransparency(x)
    self.transparency = x
end

function TardisScreenButton:SetControl(control)
    self.DoClick = function()
        TARDIS:Control(control, LocalPlayer())
    end
end

function TardisScreenButton:SetPressedStateData(ent, data)
    if istable(data) then
        self.Think = function()
            if not ent._init then return end
            self:SetPressed(ent:GetData(data[1]) or ent:GetData(data[2]))
        end
    else
        self.Think = function()
            if not ent._init then return end
            self:SetPressed(ent:GetData(data))
        end
    end
end

---@param x number
---@param y number
---@param relative boolean?
---@param speed number?
function TardisScreenButton:InitiateMove(x, y, relative, speed)
    if self.moving.now then return end

    self.icon:SetVisible(true)
    self.frame:SetVisible(true)
    self.label:SetVisible(true)

    ---@type TardisScreenButtonMove
    local moving = {}
    moving.now = true
    moving.parent = self
    moving.speed = speed or 300

    if relative then
        moving.aim = { self.pos[1] + x, self.pos[2] + y }
    else
        moving.aim = { x, y }
    end

    moving.now_outside = (self.pos[1] < 0) or (self.pos[2] < 0)
        or (self.pos[1] + self.size[1] > self.parent:GetWide())
        or (self.pos[2] + self.size[2] > self.parent:GetTall())

    moving.aim_outside = (moving.aim[1] < 0) or (moving.aim[2] < 0)
        or (moving.aim[1] + self.size[1] > self.parent:GetWide())
        or (moving.aim[2] + self.size[2] > self.parent:GetTall())

    if moving.aim_outside then
        moving.transp_aim = 0
    else
        moving.transp_aim = 255
    end

    moving.move = function()
        local sb = moving.parent

        if TARDIS:GetSetting("gui_animations") then
            sb.pos[1] = math.Approach(sb.pos[1], moving.aim[1], moving.speed * FrameTime())
            sb.pos[2] = math.Approach(sb.pos[2], moving.aim[2], moving.speed * FrameTime())
            sb.transparency = math.Approach(sb.transparency, moving.transp_aim, moving.speed * FrameTime() * 1.5)
        else
            self.pos[1] = moving.aim[1]
            self.pos[2] = moving.aim[2]
            self.transparency = moving.transp_aim
        end

        if sb.pos[1] == moving.aim[1] and sb.pos[2] == moving.aim[2] and sb.transparency == moving.transp_aim then
            moving.now = false
            sb.icon:SetVisible(sb.transparency ~= 0)
            sb.frame:SetVisible(sb.transparency ~= 0)
            sb.label:SetVisible(sb.transparency ~= 0)
        end
    end
    self.moving = moving
end
