HexagonalLayout = {}

local v3 = math.sqrt(3) -- sqrt(3)

function HexagonalLayout:new(screen, n_rows, gap_scale)
    local layout = {}

    -- From calculations:
    -- n = n_rows, m = n_cols
    -- k = gap_scale, x = button_side_length, w = screen_width, h = screen_height

    layout.screen = screen
    layout.screen_width = screen:GetWide()
    layout.screen_height = screen:GetTall()
    layout.n_rows = math.floor(n_rows)
    layout.gap_scale = gap_scale

    layout.button_side_length = 2 * layout.screen_height / (2 * gap_scale + (1 + n_rows) * (v3 + gap_scale))
    layout.n_cols = 2 * (layout.screen_width + layout.button_side_length) / (layout.button_side_length * (3 + v3 * gap_scale)) - 2
    layout.n_cols = math.floor(layout.n_cols)

    layout.dh = (v3 + gap_scale) * layout.button_side_length / 2
    layout.dw = (3 + v3 * gap_scale) * layout.button_side_length / 2

    layout.button_size = {2 * layout.button_side_length, v3 * layout.button_side_length}

    layout.buttons = {}

    setmetatable(layout,self)
    self.__index = self
    return layout
end

function HexagonalLayout:GetButtonPos(i, j)
    local px = v3 * self.gap_scale * self.button_side_length / 2
    px = px + self.dw * (j % 2 + 2 * (i - 1))
    local py = self.gap_scale * self.button_side_length + (j - 1) * self.dh
    return px,py
end

function HexagonalLayout:GetButtonSize(x)
    if x then
        return self.button_size[x]
    end
    return self.button_size[1], self.button_size[2]
end

function HexagonalLayout:GetRows()
    return self.n_rows
end
function HexagonalLayout:GetCols()
    return self.n_cols
end

function HexagonalLayout:AddNewButton(screen_button)
    screen_button:SetVisible(false)
    table.insert(self.buttons, screen_button)
end

function HexagonalLayout:DrawButtons()
    local n = self.n_rows
    local i = 1 -- cols
    local j = 0 -- rows
    local maxX = 0

    table.sort(self.buttons, function(a, b)
        if a.order and b.order then
            return (a.order < b.order)
        end
        if a.order then return true end
        if b.order then return false end
        return (a.text < b.text)
    end)

    for _,button in ipairs(self.buttons) do
        j = j + 2
        if j > n then
            if (j % 2) == 1 then
                j = 2
                i = i + 1
            else
                j = 1
            end
        end

        button:SetSize(self:GetButtonSize())
        button:SetPos(self:GetButtonPos(i, j))
        button:SetVisible(true)
        button:Think()
        maxX = math.max(button:GetPosX() + button:GetWide(), maxX)

    end

    maxX = maxX + 0.5 * v3 * self.gap_scale * self.button_side_length
    local unused = self.screen_width - maxX

    local offsetX = self.screen_width - self.button_side_length * (2 + v3 * self.gap_scale)

    if unused > 0 then
        offsetX = unused
    else
        offsetX = offsetX % self.dw
    end

    for _,button in ipairs(self.buttons) do
        button:InitiateMove(0.5 * offsetX, 0, true, 600)
    end
end

function HexagonalLayout:ScrollButtons(x)
    local cancel = false
    for _,button in ipairs(self.buttons) do
        if button.moving.now then
            cancel = true
        end
    end
    if not cancel then
        for _,button in ipairs(self.buttons) do
            button:InitiateMove(x * self.dw, 0, true, 500)
        end
    end
end

function HexagonalLayout:CanMoveLeft()
    local maxX = 0
    for _,button in ipairs(self.buttons) do
        maxX = math.max(button:GetPosX() + button:GetWide(), maxX)
    end
    return (maxX > self.screen_width)
end

function HexagonalLayout:CanMoveRight()
    local minX = 0
    for _,button in ipairs(self.buttons) do
        minX = math.min(button:GetPosX(), minX)
    end
    return (minX < 0)
end
