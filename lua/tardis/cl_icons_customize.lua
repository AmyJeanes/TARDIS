-- Icon pack customize menu

local function clone_list(list)
    local out = {}
    for i, entry in ipairs(list) do
        out[i] = { id = entry.id, enabled = entry.enabled }
    end
    return out
end

local function clone_missing(missing)
    local out = {}
    for k, v in pairs(missing) do out[k] = v end
    return out
end

local function clone_config(config)
    local out = {}
    for key, value in pairs(config) do
        if key == "missing" then
            out[key] = clone_missing(value)
        else
            out[key] = clone_list(value)
        end
    end
    return out
end

local function lists_equal(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do
        if a[i].id ~= b[i].id then return false end
        if (a[i].enabled and true or false) ~= (b[i].enabled and true or false) then return false end
    end
    return true
end

local function maps_equal(a, b)
    for k, v in pairs(a) do
        if b[k] ~= v then return false end
    end
    for k, v in pairs(b) do
        if a[k] ~= v then return false end
    end
    return true
end

local function configs_equal(a, b)
    for key, value in pairs(a) do
        if b[key] == nil then return false end
        if key == "missing" then
            if not maps_equal(value, b[key]) then return false end
        else
            if not lists_equal(value, b[key]) then return false end
        end
    end
    for key in pairs(b) do
        if a[key] == nil then return false end
    end
    return true
end

-- Ensure at least one pack is always enabled in the given list. If nothing is
-- enabled, fall back to base.
local function ensure_any_enabled(list)
    for _, entry in ipairs(list) do
        if entry.enabled then return false end
    end
    for _, entry in ipairs(list) do
        if entry.id == "base" then
            entry.enabled = true
            return true
        end
    end
    return false
end

local function pack_display_name(pack)
    local key = "IconPacks." .. pack.Name
    if TARDIS:PhraseExists(key) then return TARDIS:GetPhrase(key) end
    return pack.Name
end

local function interior_entries()
    local out = {}
    for id, t in pairs(TARDIS:GetInteriors()) do
        if not (t.Base == true or t.Hidden or t.IsVersionOf) then
            table.insert(out, { id = id, name = TARDIS:GetPhrase(t.Name or id) })
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

local function exterior_entries()
    local out = {}
    for id, ext_md in pairs(TARDIS:GetExteriors()) do
        if not (ext_md.Base == true or ext_md.Hide == true) then
            table.insert(out, { id = id, name = TARDIS:GetPhrase(ext_md.Name or id) })
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

local TABS = {
    {
        id = "spawn",
        category = TARDIS.IconCategory.Spawnicon,
        phrase = "IconPacks.Customize.Tab.Spawn",
        entries = interior_entries,
        resolve = function(id, cfg)
            return TARDIS:GetSpawnIcon(id, cfg)
                or TARDIS:GetInteriorIcon(id, cfg)
                or TARDIS:GetMissingIcon(TARDIS.IconCategory.Spawnicon, cfg)
        end,
    },
    {
        id = "interior",
        category = TARDIS.IconCategory.Interior,
        phrase = "IconPacks.Customize.Tab.Interior",
        entries = interior_entries,
        resolve = function(id, cfg)
            return TARDIS:GetInteriorIcon(id, cfg)
                or TARDIS:GetMissingIcon(TARDIS.IconCategory.Interior, cfg)
        end,
    },
    {
        id = "exterior",
        category = TARDIS.IconCategory.Exterior,
        phrase = "IconPacks.Customize.Tab.Exterior",
        entries = exterior_entries,
        resolve = function(id, cfg)
            return TARDIS:GetExteriorIcon(id, cfg)
                or TARDIS:GetMissingIcon(TARDIS.IconCategory.Exterior, cfg)
        end,
    },
}

function TARDIS:CustomizeIconPack()
    if IsValid(TARDIS.IconCustomizeFrame) then
        TARDIS.IconCustomizeFrame:Close()
    end

    local working_config = clone_config(TARDIS:GetIconPackConfig())
    local saved_snapshot = clone_config(working_config)
    local active_tab = TABS[1]
    local title_base = TARDIS:GetPhrase("IconPacks.Customize.Title")
    local pressed_row -- the row currently captured by left-mouse (drag source)
    local press_x, press_y -- screen coords at left-press, used to discriminate click vs drag
    local selected_pack_id -- nil unless user is filtering the grid by a pack
    local refresh_pack_list, refresh_grid -- forward declarations

    local function active_list()
        return working_config[active_tab.category]
    end

    local function clear_selection()
        if selected_pack_id == nil then return end
        selected_pack_id = nil
        if refresh_pack_list then refresh_pack_list() end
        if refresh_grid then refresh_grid() end
    end

    local function toggle_selection(id)
        if selected_pack_id == id then
            selected_pack_id = nil
        else
            selected_pack_id = id
        end
        if refresh_pack_list then refresh_pack_list() end
        if refresh_grid then refresh_grid() end
    end

    -- Wires up a panel so left-clicks anywhere on its blank area clear the
    -- selected-pack highlight. Children with their own OnMousePressed (rows,
    -- icons, buttons) intercept first; this only fires for clicks that
    -- otherwise fall through.
    local function clear_on_blank_click(panel)
        panel.OnMousePressed = function(_, mc)
            if mc == MOUSE_LEFT then clear_selection() end
        end
    end

    local sw, sh = ScrW(), ScrH()
    local fw = math.min(sw * 0.85, 1400)
    local fh = math.min(sh * 0.85, 900)

    local frame = vgui.Create("DFrame")
    TARDIS.IconCustomizeFrame = frame
    frame:SetTitle(title_base)

    local function is_dirty()
        return not configs_equal(working_config, saved_snapshot)
    end

    local update_dirty -- forward declaration so frame.Close can call it

    local function commit_save()
        TARDIS:SetSetting("icon_pack_config", working_config)
        saved_snapshot = clone_config(working_config)
        if update_dirty then update_dirty() end
    end

    local original_close = frame.Close
    frame.Close = function(self)
        if not is_dirty() then
            return original_close(self)
        end
        Derma_Query(
            TARDIS:GetPhrase("Common.UnsavedChangesWarning"),
            TARDIS:GetPhrase("Common.UnsavedChanges"),
            TARDIS:GetPhrase("Common.Yes"), function()
                commit_save()
                original_close(self)
            end,
            TARDIS:GetPhrase("Common.No"), function()
                original_close(self)
            end,
            TARDIS:GetPhrase("Common.Cancel"), nil
        )
    end
    frame:SetSize(fw, fh)
    frame:Center()
    frame:MakePopup()
    frame:SetDraggable(true)
    frame:SetSizable(true)
    frame:SetMinWidth(800)
    frame:SetMinHeight(500)

    local sidebar_w = 280
    local pad = 8
    local tab_h = 28

    local tab_bar = vgui.Create("DPanel", frame)
    tab_bar:Dock(TOP)
    tab_bar:SetTall(tab_h + pad)
    tab_bar.Paint = function() end
    clear_on_blank_click(tab_bar)

    local body = vgui.Create("DPanel", frame)
    body:Dock(FILL)
    body.Paint = function() end
    clear_on_blank_click(body)

    local sidebar = vgui.Create("DPanel", body)
    sidebar:Dock(RIGHT)
    sidebar:SetWide(sidebar_w)
    sidebar:DockMargin(pad, 0, 0, 0)
    sidebar.Paint = function(self, w, h)
        derma.SkinHook("Paint", "Panel", self, w, h)
    end
    clear_on_blank_click(sidebar)

    local grid_panel = vgui.Create("DScrollPanel", body)
    grid_panel:Dock(FILL)
    clear_on_blank_click(grid_panel)
    clear_on_blank_click(grid_panel:GetCanvas())

    local grid = vgui.Create("DIconLayout", grid_panel)
    grid:Dock(FILL)
    grid:SetSpaceX(4)
    grid:SetSpaceY(4)
    clear_on_blank_click(grid)

    -- set_active_tab forward decl (refresh_pack_list / refresh_grid declared above)
    local set_active_tab

    -- Tabs
    local tab_buttons = {}
    local tab_x = 4
    for _, tab in ipairs(TABS) do
        local btn = vgui.Create("DButton", tab_bar)
        btn:SetText(TARDIS:GetPhrase(tab.phrase))
        btn:SizeToContentsX(20)
        btn:SetTall(tab_h)
        btn:SetPos(tab_x, 0)
        tab_x = tab_x + btn:GetWide() + 4
        btn.DoClick = function() set_active_tab(tab) end
        tab_buttons[tab.id] = btn
    end

    -- "How to use" help button — top-right of the tab bar.
    local help_btn = vgui.Create("DButton", tab_bar)
    help_btn:SetText(TARDIS:GetPhrase("IconPacks.Customize.HowToUse"))
    help_btn:SizeToContentsX(20)
    help_btn:SetTall(tab_h)
    help_btn.PerformLayout = function(self)
        self:SetPos(tab_bar:GetWide() - self:GetWide() - 4, 0)
    end

    -- Dirty/unsaved-changes indicator — sits to the left of the help button.
    local dirty_label = vgui.Create("DLabel", tab_bar)
    dirty_label:SetTall(tab_h)
    dirty_label:SetFont("DermaDefaultBold")
    dirty_label:SetTextColor(Color(170, 80, 80, 255))
    dirty_label:SetText("")
    dirty_label:SetContentAlignment(5)
    dirty_label.PerformLayout = function(self)
        self:SizeToContentsX()
        self:SetPos(tab_bar:GetWide() - 4 - help_btn:GetWide() - 8 - self:GetWide(), 0)
    end
    help_btn.DoClick = function()
        local POPUP_W = 480
        local PAD_X = 12
        local TEXT_PAD_TOP = 4
        local TEXT_PAD_BOTTOM = 8
        local BTN_H = 28
        local BTN_PAD_BOTTOM = 12
        local TITLE_H = 25
        local FONT = "DermaDefault"

        local help_text = TARDIS:GetPhrase("IconPacks.Customize.HelpText")

        -- Measure wrapped text height: split into lines on \n, then wrap each
        -- paragraph word-by-word against the available width.
        surface.SetFont(FONT)
        local _, line_h = surface.GetTextSize("Mg")
        local text_w = POPUP_W - PAD_X * 2
        local total_lines = 0
        for paragraph in (help_text .. "\n"):gmatch("([^\n]*)\n") do
            -- gmatch's iterator only yields non-nil while the loop runs, but
            -- the analyzer types it as `string?` and doesn't narrow through
            -- the equality check. Re-bind to a non-nil local for the body.
            local para = paragraph or ""
            if para == "" then
                total_lines = total_lines + 1
            else
                local current_line = ""
                for word in para:gmatch("%S+") do
                    local candidate = current_line == "" and word or (current_line .. " " .. word)
                    local w = surface.GetTextSize(candidate)
                    if w > text_w and current_line ~= "" then
                        total_lines = total_lines + 1
                        current_line = word
                    else
                        current_line = candidate
                    end
                end
                if current_line ~= "" then total_lines = total_lines + 1 end
            end
        end
        local text_h = total_lines * line_h

        local f = vgui.Create("DFrame")
        f:SetTitle(TARDIS:GetPhrase("IconPacks.Customize.HowToUse"))
        f:SetSize(POPUP_W, TITLE_H + TEXT_PAD_TOP + text_h + TEXT_PAD_BOTTOM + BTN_H + BTN_PAD_BOTTOM)
        f:Center()
        f:MakePopup()

        local text = vgui.Create("DLabel", f)
        text:Dock(TOP)
        text:SetTall(text_h)
        text:DockMargin(PAD_X, TEXT_PAD_TOP, PAD_X, TEXT_PAD_BOTTOM)
        text:SetFont(FONT)
        text:SetText(help_text)
        text:SetWrap(true)
        text:SetContentAlignment(7) -- top-left
        text:SetDark(true)

        local workshop_btn = vgui.Create("DButton", f)
        workshop_btn:Dock(TOP)
        workshop_btn:DockMargin(PAD_X, 0, PAD_X, BTN_PAD_BOTTOM)
        workshop_btn:SetTall(BTN_H)
        workshop_btn:SetText(TARDIS:GetPhrase("IconPacks.Customize.OpenWorkshop"))
        workshop_btn.DoClick = function()
            gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=590303919")
        end
    end

    local refresh_missing_grid -- forward decl, defined below

    set_active_tab = function(tab)
        active_tab = tab
        selected_pack_id = nil
        for _, t in ipairs(TABS) do
            tab_buttons[t.id]:SetEnabled(t ~= tab)
        end
        refresh_pack_list()
        if refresh_missing_grid then refresh_missing_grid() end
        refresh_grid()
    end

    -- Sidebar layout: BOTTOM stack first (reset → save → dirty), then list_wrapper
    -- fills the remaining space and splits it 50/50 between the pack-order and
    -- missing-icon sections.
    local reset_btn = vgui.Create("DButton", sidebar)
    reset_btn:Dock(BOTTOM)
    reset_btn:SetTall(28)
    reset_btn:DockMargin(0, 4, 0, 0)
    reset_btn:SetText(TARDIS:GetPhrase("IconPacks.Customize.Reset"))
    reset_btn.DoClick = function()
        working_config = clone_config(TARDIS:GetDefaultIconPackConfig())
        update_dirty()
        refresh_pack_list()
        refresh_missing_grid()
        refresh_grid()
    end

    local save_row = vgui.Create("DPanel", sidebar)
    save_row:Dock(BOTTOM)
    save_row:SetTall(40)
    save_row.Paint = function() end

    local undo_btn = vgui.Create("DButton", save_row)
    undo_btn:Dock(RIGHT)
    undo_btn:SetWide(80)
    undo_btn:DockMargin(4, 0, 0, 0)
    undo_btn:SetText(TARDIS:GetPhrase("IconPacks.Customize.Undo"))
    undo_btn:SetEnabled(false)
    undo_btn.DoClick = function()
        working_config = clone_config(saved_snapshot)
        update_dirty()
        refresh_pack_list()
        refresh_missing_grid()
        refresh_grid()
    end

    local save_btn = vgui.Create("DButton", save_row)
    save_btn:Dock(FILL)
    save_btn:SetText(TARDIS:GetPhrase("IconPacks.Customize.Save"))
    save_btn.DoClick = function()
        commit_save()
        frame:Close()
    end

    -- Wrapper that splits its area 50/50 between the pack-order section (top)
    -- and the missing-icon section (bottom).
    local list_wrapper = vgui.Create("DPanel", sidebar)
    list_wrapper:Dock(FILL)
    list_wrapper.Paint = function() end
    clear_on_blank_click(list_wrapper)

    local SECTION_GAP = pad
    local SECTION_PAD = 6

    local order_section = vgui.Create("DPanel", list_wrapper)
    order_section:Dock(TOP)
    order_section:DockPadding(SECTION_PAD, SECTION_PAD, SECTION_PAD, SECTION_PAD)
    order_section.Paint = function(self, w, h)
        derma.SkinHook("Paint", "Panel", self, w, h)
    end
    clear_on_blank_click(order_section)

    local pack_list_panel = vgui.Create("DScrollPanel", order_section)
    pack_list_panel:Dock(FILL)
    clear_on_blank_click(pack_list_panel)
    clear_on_blank_click(pack_list_panel:GetCanvas())

    local missing_section = vgui.Create("DPanel", list_wrapper)
    missing_section:Dock(FILL)
    missing_section:DockMargin(0, SECTION_GAP, 0, 0)
    missing_section:DockPadding(SECTION_PAD, SECTION_PAD, SECTION_PAD, SECTION_PAD)
    missing_section.Paint = function(self, w, h)
        derma.SkinHook("Paint", "Panel", self, w, h)
    end
    clear_on_blank_click(missing_section)

    local missing_label = vgui.Create("DLabel", missing_section)
    missing_label:Dock(TOP)
    missing_label:SetTall(18)
    missing_label:DockMargin(0, 0, 0, 4)
    missing_label:SetText(TARDIS:GetPhrase("IconPacks.Customize.MissingIcon"))
    missing_label:SetDark(true)
    missing_label:SetFont("DermaDefaultBold")

    local missing_scroll = vgui.Create("DScrollPanel", missing_section)
    missing_scroll:Dock(FILL)
    clear_on_blank_click(missing_scroll)
    clear_on_blank_click(missing_scroll:GetCanvas())

    local missing_grid = vgui.Create("DIconLayout", missing_scroll)
    missing_grid:Dock(FILL)
    missing_grid:SetSpaceX(4)
    missing_grid:SetSpaceY(4)
    clear_on_blank_click(missing_grid)

    list_wrapper.PerformLayout = function(self, w, h)
        order_section:SetTall(math.floor((h - SECTION_GAP) / 2))
    end

    update_dirty = function()
        local dirty = is_dirty()
        frame:SetTitle(dirty and (title_base .. " *") or title_base)
        dirty_label:SetText(dirty and TARDIS:GetPhrase("Common.UnsavedChanges") or "")
        dirty_label:InvalidateLayout(true)
        undo_btn:SetEnabled(dirty)
    end

    refresh_missing_grid = function()
        missing_grid:Clear()

        local cat = active_tab.category

        -- Collect packs that provide a missing icon for this category. Order:
        -- base first, then user packs sorted by display name.
        local pack_ids = {}
        if TARDIS:PackProvidesMissingIcon("base", cat) then
            table.insert(pack_ids, "base")
        end

        local others = {}
        for id in pairs(TARDIS:GetIconPacks()) do
            if id ~= "base" and TARDIS:PackProvidesMissingIcon(id, cat) then
                table.insert(others, id)
            end
        end
        table.sort(others, function(a, b)
            return pack_display_name(TARDIS:GetIconPack(a)) < pack_display_name(TARDIS:GetIconPack(b))
        end)
        for _, id in ipairs(others) do
            table.insert(pack_ids, id)
        end

        local CELL_SIZE = 118

        for _, pack_id in ipairs(pack_ids) do
            local pack = TARDIS:GetIconPack(pack_id)
            local mat_path = TARDIS:GetPackMissingIcon(pack_id, cat)
            if mat_path and pack then
                local mat = Material(mat_path, "smooth mips")

                local cell = missing_grid:Add("DPanel")
                cell:SetSize(CELL_SIZE, CELL_SIZE)
                cell:SetCursor("hand")
                cell:SetTooltip(pack_display_name(pack))
                cell.Paint = function(self, w, h)
                    surface.SetDrawColor(255, 255, 255, 20)
                    surface.DrawRect(0, 0, w, h)

                    local pad_x = 4
                    surface.SetDrawColor(255, 255, 255, 255)
                    surface.SetMaterial(mat)
                    surface.DrawTexturedRect(pad_x, pad_x, w - pad_x * 2, h - pad_x * 2)

                    local selected = (working_config.missing[cat] == pack_id)
                    if selected then
                        surface.SetDrawColor(70, 200, 100, 255)
                        surface.DrawOutlinedRect(0, 0, w, h, 3)
                    else
                        surface.SetDrawColor(0, 0, 0, 110)
                        surface.DrawOutlinedRect(0, 0, w, h, 1)
                    end
                end
                cell.OnMousePressed = function(_, mc)
                    if mc ~= MOUSE_LEFT then return end
                    if working_config.missing[cat] == pack_id then return end
                    working_config.missing[cat] = pack_id
                    update_dirty()
                    refresh_missing_grid()
                    refresh_grid()
                end
            end
        end
    end

    -- Pack list rows
    local ROW_H = 24
    local ROW_GAP = 4
    local ROW_PITCH = ROW_H + ROW_GAP  -- 28; vertical space one row occupies

    local function compute_target_index(receiver, my, ignore_row)
        local target = #active_list() + 1
        for _, child in ipairs(receiver:GetChildren()) do
            if child.pack_index and child ~= ignore_row and child:IsVisible() then
                local cy = child:GetY() + child:GetTall() / 2
                if my < cy then
                    target = child.pack_index
                    break
                end
            end
        end
        return target
    end

    refresh_pack_list = function()
        pack_list_panel:Clear()
        local list = active_list()
        local list_inner = vgui.Create("DPanel", pack_list_panel)
        list_inner:Dock(TOP)
        -- Stretch to fill the visible pack list area when there's blank space
        -- below the last row, so the drop receiver covers the whole section.
        list_inner:SetTall(math.max(#list * ROW_PITCH, pack_list_panel:GetTall()))
        list_inner.Paint = function() end
        clear_on_blank_click(list_inner)
        pack_list_panel:AddItem(list_inner)

        list_inner:Receiver("tardis_iconpack", function(receiver, dropped, is_drop, _, _, my)
            if not is_drop then return end
            local row = dropped[1]
            if not row or not row.pack_index then return end

            local current = active_list()
            local from = row.pack_index
            local target = compute_target_index(receiver, my, row)

            if target == from or target == from + 1 then return end

            local entry = table.remove(current, from)
            if target > from then target = target - 1 end
            table.insert(current, target, entry)

            update_dirty()
            refresh_pack_list()
            refresh_grid()
        end)

        -- Drop preview + drag-source hiding: while a row is being dragged, hide
        -- the source row from the list and open a row-sized gap at the predicted
        -- drop location.
        list_inner.preview_target = nil
        list_inner.preview_dragged = nil
        list_inner.Think = function(self)
            local dragging = dragndrop.IsDragging()
            local dragged = (dragging and IsValid(pressed_row) and pressed_row.pack_index) and pressed_row or nil
            local viewport_h = pack_list_panel:GetTall()

            -- Receiver spans the full section, so bounds-check against self's
            -- own height — dropping below the last row lands at the end.
            local target = nil
            if dragged then
                local mx, my = self:CursorPos()
                if mx >= 0 and mx < self:GetWide() and my >= 0 and my < self:GetTall() then
                    target = compute_target_index(self, my, dragged)
                end
            end

            if target == self.preview_target and dragged == self.preview_dragged then
                -- Fast path: no drag change. Still keep size in sync with the
                -- pack list viewport so the receiver always fills the section.
                local content_h = #active_list() * ROW_PITCH
                local desired = math.max(content_h, viewport_h)
                if self:GetTall() ~= desired then self:SetTall(desired) end
                return
            end
            self.preview_target = target
            self.preview_dragged = dragged

            local visible_count = 0
            local source_idx = dragged and dragged.pack_index or nil
            for _, child in ipairs(self:GetChildren()) do
                if child.pack_index then
                    local is_dragged = (child == dragged)
                    child:SetVisible(not is_dragged)
                    if not is_dragged then
                        visible_count = visible_count + 1
                        local top = (target and child.pack_index == target) and ROW_PITCH or 0
                        child:DockMargin(0, top, 0, ROW_GAP)
                    end

                    if child.number_label then
                        local original = child.pack_index
                        local displayed = original
                        if source_idx and target then
                            if is_dragged then
                                -- Dragged row lands at `target`; if dropping after
                                -- its current position, the post-removal index is
                                -- target - 1.
                                displayed = (target > source_idx) and (target - 1) or target
                            elseif target <= source_idx then
                                if target <= original and original < source_idx then
                                    displayed = original + 1
                                end
                            else
                                if source_idx < original and original < target then
                                    displayed = original - 1
                                end
                            end
                        end
                        child.number_label.display_num = displayed
                    end
                end
            end

            local extra = 0
            if target then
                extra = ROW_PITCH -- always reserve a row of slack while previewing
            end
            -- Keep covering the full section height so dropping in the blank
            -- area below the last row still lands at the end.
            local content_h = visible_count * ROW_PITCH + extra
            self:SetTall(math.max(content_h, viewport_h))
            self:InvalidateLayout(true)
        end

        local enabled_count = 0
        for _, e in ipairs(list) do
            if e.enabled then enabled_count = enabled_count + 1 end
        end

        for index, entry in ipairs(list) do
            local pack = TARDIS:GetIconPack(entry.id)
            if pack then

            local row = vgui.Create("DPanel", list_inner)
            row:Dock(TOP)
            row:SetTall(24)
            row:DockMargin(0, 0, 0, 4)
            row.pack_index = index
            row:Droppable("tardis_iconpack")
            row:SetCursor("sizeall")
            row.Paint = function(_, w, h)
                -- Very subtle lightening so the row picks up the sidebar's theme
                -- color almost transparently — borders do the heavy lifting.
                surface.SetDrawColor(255, 255, 255, 20)
                surface.DrawRect(0, 0, w, h)
                if entry.id == selected_pack_id then
                    surface.SetDrawColor(70, 130, 200, 200)
                    surface.DrawRect(0, 0, w, h)
                end
                surface.SetDrawColor(0, 0, 0, 110)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
            row.OnMousePressed = function(self, mouse_code)
                if mouse_code == MOUSE_RIGHT and entry.id ~= "base" then
                    local dmenu = DermaMenu()
                    local copy = dmenu:AddOption(TARDIS:GetPhrase("Spawnmenu.CopyID"), function()
                        SetClipboardText(entry.id)
                    end)
                    copy:SetIcon("icon16/page_copy.png")
                    dmenu:Open()
                    return
                end
                if mouse_code == MOUSE_LEFT then
                    pressed_row = self
                    press_x, press_y = gui.MouseX(), gui.MouseY()
                end
                -- Pass left-click through to dragndrop machinery so :Droppable still works.
                self:DragMousePress(mouse_code)
                self:MouseCapture(true)
            end

            row.OnMouseReleased = function(self, mouse_code)
                if mouse_code == MOUSE_LEFT and pressed_row == self and press_x then
                    -- Treat as a click (not drag) if cursor barely moved.
                    local dx = gui.MouseX() - press_x
                    local dy = gui.MouseY() - press_y
                    if dx * dx + dy * dy < 25 then
                        if not entry.enabled then
                            entry.enabled = true
                            selected_pack_id = entry.id
                            update_dirty()
                            refresh_pack_list()
                            refresh_grid()
                        else
                            toggle_selection(entry.id)
                        end
                    end
                    pressed_row = nil
                    press_x, press_y = nil, nil
                end
                self:DragMouseRelease(mouse_code)
                self:MouseCapture(false)
            end

            -- Custom-painted: DLabel runs SetText through language.GetPhrase,
            -- which strips the leading '#' (it treats it as a translation key).
            -- We bypass that by drawing the text via surface APIs directly.
            local number_label = vgui.Create("DPanel", row)
            number_label:Dock(LEFT)
            number_label:SetWide(28)
            number_label:DockMargin(2, 0, 0, 0)
            number_label.display_num = index
            number_label.Paint = function(self, w, h)
                draw.SimpleText("#" .. self.display_num, "DermaDefaultBold", w / 2, h / 2 - 1,
                    Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            row.number_label = number_label

            local check_wrap = vgui.Create("DPanel", row)
            check_wrap:Dock(LEFT)
            check_wrap:DockMargin(4, 0, 4, 0)
            check_wrap:SetWide(16)
            check_wrap.Paint = function() end

            local check = vgui.Create("DCheckBox", check_wrap)
            check:SetSize(14, 14)
            check_wrap.PerformLayout = function(self, w, h)
                check:SetPos((w - 14) / 2, (h - 14) / 2 + 1)
            end
            check:SetChecked(entry.enabled)
            local locked = (entry.id == "base" and entry.enabled and enabled_count == 1)
            if locked then
                check:SetEnabled(false)
            end
            check.OnChange = function(_, val)
                entry.enabled = val
                ensure_any_enabled(active_list())
                update_dirty()
                refresh_pack_list()
                refresh_grid()
            end

            -- Dock(RIGHT) pushes later children left. Creation order [down, up]
            -- yields visual order [up, down] from left to right.
            local down = vgui.Create("DButton", row)
            down:Dock(RIGHT)
            down:SetWide(20)
            down:DockMargin(0, 0, 2, 0)
            down:SetText("\xe2\x96\xbc") -- ▼
            down:SetEnabled(index < #list)
            down.DoClick = function()
                local cur = active_list()
                if index < #cur then
                    cur[index], cur[index + 1] = cur[index + 1], cur[index]
                    update_dirty()
                    refresh_pack_list()
                    refresh_grid()
                end
            end

            local up = vgui.Create("DButton", row)
            up:Dock(RIGHT)
            up:SetWide(20)
            up:DockMargin(0, 0, 2, 0)
            up:SetText("\xe2\x96\xb2") -- ▲
            up:SetEnabled(index > 1)
            up.DoClick = function()
                local cur = active_list()
                if index > 1 then
                    cur[index], cur[index - 1] = cur[index - 1], cur[index]
                    update_dirty()
                    refresh_pack_list()
                    refresh_grid()
                end
            end

            local label = vgui.Create("DLabel", row)
            label:Dock(FILL)
            label:DockMargin(2, 0, 0, 0)
            label:SetText(pack_display_name(pack))
            label:SetDark(true)
            end
        end
    end

    refresh_grid = function()
        grid:Clear()

        -- Validate the selected pack: clear selection if it's no longer enabled
        -- (or no longer in this category's list at all).
        if selected_pack_id then
            local valid = false
            for _, entry in ipairs(active_list()) do
                if entry.id == selected_pack_id and entry.enabled then
                    valid = true
                    break
                end
            end
            if not valid then selected_pack_id = nil end
        end

        local entries = active_tab.entries()

        local WIN_COLOR  = Color(70, 200, 100, 255)
        local LOSE_COLOR = Color(220, 80, 80, 255)
        local BORDER_THICKNESS = 3

        for _, entry in ipairs(entries) do
            local mat
            local in_pack = false
            local won = false
            if selected_pack_id then
                in_pack = TARDIS:PackProvidesIcon(selected_pack_id, active_tab.category, entry.id)
                if in_pack then
                    -- Render this pack's icon as if it had absolute priority.
                    mat = TARDIS:GetPackIcon(selected_pack_id, active_tab.category, entry.id)
                    won = TARDIS:GetIconProvider(active_tab.category, entry.id, working_config) == selected_pack_id
                else
                    mat = active_tab.resolve(entry.id, working_config)
                end
            else
                mat = active_tab.resolve(entry.id, working_config)
            end
            local icon = grid:Add("ContentIcon")
            icon:SetContentType("entity")
            icon:SetSpawnName(entry.id)
            icon:SetName(entry.name)
            icon:SetMaterial(mat or "vgui/entities/gmod_tardis")
            icon:SetColor(Color(205, 92, 92, 255))
            if selected_pack_id then
                if in_pack then
                    local border_color = won and WIN_COLOR or LOSE_COLOR
                    icon.PaintOver = function(_, w, h)
                        surface.SetDrawColor(border_color)
                        surface.DrawOutlinedRect(0, 0, w, h, BORDER_THICKNESS)
                    end
                else
                    -- Dim icons not in the selected pack (overlay handles $alphatest).
                    icon.PaintOver = function(_, w, h)
                        surface.SetDrawColor(20, 20, 20, 220)
                        surface.DrawRect(0, 0, w, h)
                    end
                end
            end
            icon.DoClick = function() end
            icon.OnMousePressed = function(self, mc)
                if mc == MOUSE_RIGHT then self:OpenMenu() end
            end
            icon.OpenMenu = function(self)
                local dmenu = DermaMenu()
                local copy = dmenu:AddOption(TARDIS:GetPhrase("Spawnmenu.CopyID"), function()
                    SetClipboardText(entry.id)
                end)
                copy:SetIcon("icon16/page_copy.png")
                dmenu:Open()
            end
        end
    end

    set_active_tab(TABS[1])
end
