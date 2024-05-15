-- Destination

local function EnsureEnabled(self, on)
    if self:IsEnabled() ~= on then
        self:SetEnabled(on)
    end
end

TARDIS:AddScreen("Destination", {id="coordinates", text="Screens.Coordinates", menu=false, order=2, popuponly=false}, function(self,ext,int,frame,screen)
    local map = game.GetMap()

    local w = frame:GetWide()
    local h = frame:GetTall()
    local d = 0.05 * math.min( w,h )
    local round_digits = 4
    local font = TARDIS:GetScreenFont(screen, "Default")
    local font_important = TARDIS:GetScreenFont(screen, "DefaultBold")
    local bgcolor = TARDIS:GetScreenGUIColor(screen)

    local background=vgui.Create("DImage", frame)

    local theme = TARDIS:GetScreenGUITheme(screen)
    local background_img = TARDIS:GetGUIThemeElement(theme, "backgrounds", "coordinates")
    background:SetImage(background_img)
    background:SetSize(w, h)

    local llist
    if screen.is3D2D then
        llist = ListView3D:new(frame,screen,34,bgcolor)
    else
        llist = vgui.Create("DListView",frame)
    end
    llist:SetSize( (w - 3 * d) / 2,(h - 2 * d) )
    llist:SetPos( d,d )
    llist:AddColumn(TARDIS:GetPhrase("Screens.Coordinates.LocationsList"))
    llist:SetMultiSelect(false)

    local panel_w = (w - 3 * d) / 2
    local panel_h = (h - 4 * d) / 3
    local panel_d = (screen.is3D2D and 0.01 or 0.02) * math.min(w,h)
    local panel_left = 0.5 * w + 0.5 * d

    local position_panel = vgui.Create( "DPanel",frame )
    position_panel:SetPos(panel_left, d)
    position_panel:SetSize(panel_w, panel_h)
    position_panel:SetBackgroundColor( bgcolor)

    local pos_elem_w = (panel_w - 5 * panel_d) / 4
    local pos_elem_h = (panel_h - 4 * panel_d) / 3

    local pos_title = vgui.Create("DLabel",position_panel)
    pos_title:SetText(TARDIS:GetPhrase("Screens.Coordinates.CurrentPosition"))
    pos_title:SetPos(panel_d, panel_d)
    pos_title:SetSize(panel_w - 2 * panel_d, pos_elem_h)
    pos_title:SetFont(font_important)

    local pos_x = vgui.Create("DTextEntry",position_panel)
    pos_x:SetPlaceholderText("")
    pos_x:SetPos(panel_d, pos_elem_h + 2 * panel_d)
    pos_x:SetSize(pos_elem_w,pos_elem_h)
    pos_x:SetNumeric(true)
    pos_x:SetEnabled(false)
    pos_x:SetFont(font)

    local pos_y = vgui.Create("DTextEntry",position_panel)
    pos_y:SetPlaceholderText("")
    pos_y:SetPos(pos_elem_w + 2 * panel_d, pos_elem_h + 2 * panel_d)
    pos_y:SetSize(pos_elem_w,pos_elem_h)
    pos_y:SetNumeric(true)
    pos_y:SetEnabled(false)
    pos_y:SetFont(font)

    local pos_z = vgui.Create("DTextEntry",position_panel)
    pos_z:SetPlaceholderText("")
    pos_z:SetPos(pos_elem_w*2 + 3 * panel_d, pos_elem_h + 2 * panel_d)
    pos_z:SetSize(pos_elem_w,pos_elem_h)
    pos_z:SetNumeric(true)
    pos_z:SetEnabled(false)
    pos_z:SetFont(font)

    local pos_pitch = vgui.Create("DTextEntry",position_panel)
    pos_pitch:SetPlaceholderText("")
    pos_pitch:SetPos(panel_d, 2 * pos_elem_h + 3 * panel_d)
    pos_pitch:SetSize(pos_elem_w,pos_elem_h)
    pos_pitch:SetNumeric(true)
    pos_pitch:SetEnabled(false)
    pos_pitch:SetFont(font)

    local pos_yaw = vgui.Create("DTextEntry",position_panel)
    pos_yaw:SetPlaceholderText("")
    pos_yaw:SetPos(pos_elem_w + 2 * panel_d, 2 * pos_elem_h + 3 * panel_d)
    pos_yaw:SetSize(pos_elem_w,pos_elem_h)
    pos_yaw:SetNumeric(true)
    pos_yaw:SetEnabled(false)
    pos_yaw:SetFont(font)

    local pos_roll = vgui.Create("DTextEntry",position_panel)
    pos_roll:SetPlaceholderText("")
    pos_roll:SetPos(pos_elem_w * 2 + 3 * panel_d, 2 * pos_elem_h + 3 * panel_d)
    pos_roll:SetSize(pos_elem_w,pos_elem_h)
    pos_roll:SetNumeric(true)
    pos_roll:SetEnabled(false)
    pos_roll:SetFont(font)

    local pos_save = vgui.Create("DButton", position_panel)
    pos_save:SetSize(pos_elem_w,pos_elem_h)
    pos_save:SetPos(pos_elem_w * 3 + 4 * panel_d, pos_elem_h + 2 * panel_d)
    pos_save:SetText(TARDIS:GetPhrase("Screens.Coordinates.Save"))
    pos_save:SetFont(font)

    local pos_copy = vgui.Create("DButton", position_panel)
    pos_copy:SetSize(pos_elem_w,pos_elem_h)
    pos_copy:SetPos(pos_elem_w * 3 + 4 * panel_d, 2 * pos_elem_h + 3 * panel_d)
    pos_copy:SetText(TARDIS:GetPhrase("Screens.Coordinates.Copy"))
    pos_copy:SetFont(font)

    local function generate_vortex_coordinate()
        if not TARDIS:GetSetting("gui_animations") then
            return "???"
        end
        return math.random(-99999999, 99999999) * 0.0001
    end

    position_panel.Think = function(self)
        if not IsValid(ext) then return end
        local vortex = ext:GetData("vortex")
        if vortex then
            pos_x:SetText(generate_vortex_coordinate())
            pos_y:SetText(generate_vortex_coordinate())
            pos_z:SetText(generate_vortex_coordinate())
        else
            local pos = ext:GetPos()
            pos_x:SetText(math.Round(pos.x, round_digits))
            pos_y:SetText(math.Round(pos.y, round_digits))
            pos_z:SetText(math.Round(pos.z, round_digits))
        end
        local ang = ext:GetAngles()
        pos_pitch:SetText(math.Round(ang.p, round_digits))
        pos_yaw:SetText(math.Round(ang.y, round_digits))
        pos_roll:SetText(math.Round(ang.r, round_digits))

        EnsureEnabled(pos_save, not vortex)
        EnsureEnabled(pos_copy, not vortex)
    end





    local destination_panel = vgui.Create( "DPanel",frame )
    destination_panel:SetPos(panel_left, 2 * d + panel_h)
    destination_panel:SetSize(panel_w, panel_h)
    destination_panel:SetBackgroundColor( bgcolor)

    local dst_elem_w = (panel_w - 5 * panel_d) / 4
    local dst_elem_h = (panel_h - 4 * panel_d) / 3

    local dst_progress = vgui.Create("DProgress", frame)
    dst_progress:SetSize(panel_w, dst_elem_h / 4)
    dst_progress:SetPos(panel_left, 2 * d + panel_h - dst_elem_h / 4)

    local dst_title = vgui.Create("DLabel",destination_panel)
    dst_title:SetText(TARDIS:GetPhrase("Screens.Coordinates.Destination"))
    dst_title:SetPos(panel_d, panel_d)
    dst_title:SetSize(panel_w - 2 * panel_d, dst_elem_h)
    dst_title:SetFont(font_important)

    local dst_x = vgui.Create("DTextEntry",destination_panel)
    dst_x:SetPlaceholderText("")
    dst_x:SetPos(panel_d, dst_elem_h + 2 * panel_d)
    dst_x:SetSize(dst_elem_w,dst_elem_h)
    dst_x:SetNumeric(true)
    dst_x:SetEnabled(false)
    dst_x:SetFont(font)

    local dst_y = vgui.Create("DTextEntry",destination_panel)
    dst_y:SetPlaceholderText("")
    dst_y:SetPos(dst_elem_w + 2 * panel_d, dst_elem_h + 2 * panel_d)
    dst_y:SetSize(dst_elem_w,dst_elem_h)
    dst_y:SetNumeric(true)
    dst_y:SetEnabled(false)
    dst_y:SetFont(font)

    local dst_z = vgui.Create("DTextEntry",destination_panel)
    dst_z:SetPlaceholderText("")
    dst_z:SetPos(dst_elem_w*2 + 3 * panel_d, dst_elem_h + 2 * panel_d)
    dst_z:SetSize(dst_elem_w,dst_elem_h)
    dst_z:SetNumeric(true)
    dst_z:SetEnabled(false)
    dst_z:SetFont(font)

    local dst_pitch = vgui.Create("DTextEntry",destination_panel)
    dst_pitch:SetPlaceholderText("")
    dst_pitch:SetPos(panel_d, 2 * dst_elem_h + 3 * panel_d)
    dst_pitch:SetSize(dst_elem_w,dst_elem_h)
    dst_pitch:SetNumeric(true)
    dst_pitch:SetEnabled(false)
    dst_pitch:SetFont(font)

    local dst_yaw = vgui.Create("DTextEntry",destination_panel)
    dst_yaw:SetPlaceholderText("")
    dst_yaw:SetPos(dst_elem_w + 2 * panel_d, 2 * dst_elem_h + 3 * panel_d)
    dst_yaw:SetSize(dst_elem_w,dst_elem_h)
    dst_yaw:SetNumeric(true)
    dst_yaw:SetEnabled(false)
    dst_yaw:SetFont(font)

    local dst_roll = vgui.Create("DTextEntry",destination_panel)
    dst_roll:SetPlaceholderText("")
    dst_roll:SetPos(dst_elem_w * 2 + 3 * panel_d, 2 * dst_elem_h + 3 * panel_d)
    dst_roll:SetSize(dst_elem_w,dst_elem_h)
    dst_roll:SetNumeric(true)
    dst_roll:SetEnabled(false)
    dst_roll:SetFont(font)

    local dst_save = vgui.Create("DButton", destination_panel)
    dst_save:SetSize(dst_elem_w,dst_elem_h)
    dst_save:SetPos(dst_elem_w * 3 + 4 * panel_d, dst_elem_h + 2 * panel_d)
    dst_save:SetText(TARDIS:GetPhrase("Screens.Coordinates.Save"))
    dst_save:SetFont(font)

    local dst_copy = vgui.Create("DButton", destination_panel)
    dst_copy:SetSize(dst_elem_w,dst_elem_h)
    dst_copy:SetPos(dst_elem_w * 3 + 4 * panel_d, 2 * dst_elem_h + 3 * panel_d)
    dst_copy:SetText(TARDIS:GetPhrase("Screens.Coordinates.Copy"))
    dst_copy:SetFont(font)




    destination_panel.Think = function(self)
        if not IsValid(ext) then return end

        dst_progress:UpdateState()

        local dst_pos = ext:GetDestinationPos()
        local dst_ang = ext:GetDestinationAng()
        EnsureEnabled(dst_save, dst_pos ~= nil)
        EnsureEnabled(dst_copy, dst_pos ~= nil)

        if not dst_pos then
            dst_x:SetText("")
            dst_y:SetText("")
            dst_z:SetText("")
            dst_pitch:SetText("")
            dst_yaw:SetText("")
            dst_roll:SetText("")
            return
        end

        dst_x:SetText(math.Round(dst_pos.x, round_digits))
        dst_y:SetText(math.Round(dst_pos.y, round_digits))
        dst_z:SetText(math.Round(dst_pos.z, round_digits))
        dst_pitch:SetText(math.Round(dst_ang.p, round_digits))
        dst_yaw:SetText(math.Round(dst_ang.y, round_digits))
        dst_roll:SetText(math.Round(dst_ang.r, round_digits))
    end

    dst_progress.UpdateState = function(self)
        local teleport = ext:GetData("teleport")
        local vortex = ext:GetData("vortex")

        if not TARDIS:GetSetting("gui_animations")
            or (not teleport and not vortex)
        then
            if dst_progress:IsVisible() then
                dst_progress:SetVisible(false)
            end
            return
        end

        local function get_vortex_progress()
            return ((CurTime() - ext:GetData("vortex_enter_time",0)) % 4) / 4
        end

        local tp_metadata = ext.metadata.Exterior.Teleport
        local fast = ext:GetFastRemat()
        local mat, demat = ext:GetData("mat"), ext:GetData("demat")
        dst_progress:SetVisible(true)

        if demat then
            dst_progress:SetFraction((fast and 0.55 or 0.45) * ext:GetSequenceProgress())
            return
        end

        if mat then
            dst_progress:SetFraction(0.7 + 0.3 * ext:GetSequenceProgress())
            return
        end

        if vortex and not teleport then
            dst_progress:SetFraction(0.45 + 0.1 * (fast and 1 or get_vortex_progress()))
            return
        end

        if teleport and not mat then -- premat
            local delay = (fast and tp_metadata.PrematDelayFast or tp_metadata.PrematDelay)
            local time_passed = CurTime() - ext:GetData("premat_start_time")

            dst_progress:SetFraction(0.55 + 0.15 * time_passed / delay)
            return
        end
    end





    local input_panel = vgui.Create( "DPanel",frame )
    input_panel:SetPos(panel_left, 3 * d + 2 * panel_h)
    input_panel:SetSize(panel_w, panel_h)
    input_panel:SetBackgroundColor( bgcolor)

    local inp_elem_w = (panel_w - 5 * panel_d) / 4
    local inp_elem_h = (panel_h - 4 * panel_d) / 3

    local namebox = vgui.Create("DTextEntry3D2D", input_panel)
    namebox.is3D2D = screen.is3D2D
    namebox:SetPlaceholderText(TARDIS:GetPhrase("Screens.Coordinates.Name"))
    namebox:SetPos(panel_d, panel_d)
    namebox:SetSize(panel_w - 3 * panel_d - inp_elem_w, inp_elem_h)
    namebox:SetFont(font)

    local x = vgui.Create("DTextEntry3D2D",input_panel)
    x.is3D2D = screen.is3D2D
    x:SetPlaceholderText(TARDIS:GetPhrase("Screens.Coordinates.X"))
    x:SetPos(panel_d, inp_elem_h + 2 * panel_d)
    x:SetSize(inp_elem_w,inp_elem_h)
    x:SetNumeric(true)
    x:SetFont(font)
    local y = vgui.Create("DTextEntry3D2D",input_panel)
    y.is3D2D = screen.is3D2D
    y:SetPlaceholderText(TARDIS:GetPhrase("Screens.Coordinates.Y"))
    y:SetPos(inp_elem_w + 2 * panel_d, inp_elem_h + 2 * panel_d)
    y:SetSize(inp_elem_w,inp_elem_h)
    y:SetNumeric(true)
    y:SetFont(font)
    local z = vgui.Create("DTextEntry3D2D",input_panel)
    z.is3D2D = screen.is3D2D
    z:SetPlaceholderText(TARDIS:GetPhrase("Screens.Coordinates.Z"))
    z:SetPos(inp_elem_w*2 + 3 * panel_d, inp_elem_h + 2 * panel_d)
    z:SetSize(inp_elem_w,inp_elem_h)
    z:SetNumeric(true)
    z:SetFont(font)

    local pitch = vgui.Create("DTextEntry3D2D",input_panel)
    pitch:SetPlaceholderText(TARDIS:GetPhrase("Screens.Coordinates.Pitch"))
    pitch:SetPos(panel_d, 2 * inp_elem_h + 3 * panel_d)
    pitch:SetSize(inp_elem_w,inp_elem_h)
    pitch:SetNumeric(true)
    pitch:SetFont(font)
    local yaw = vgui.Create("DTextEntry3D2D",input_panel)
    yaw:SetPlaceholderText(TARDIS:GetPhrase("Screens.Coordinates.Yaw"))
    yaw:SetPos(inp_elem_w + 2 * panel_d, 2 * inp_elem_h + 3 * panel_d)
    yaw:SetSize(inp_elem_w,inp_elem_h)
    yaw:SetNumeric(true)
    yaw:SetFont(font)
    local roll = vgui.Create("DTextEntry3D2D",input_panel)
    roll:SetPlaceholderText(TARDIS:GetPhrase("Screens.Coordinates.Roll"))
    roll:SetPos(inp_elem_w * 2 + 3 * panel_d, 2 * inp_elem_h + 3 * panel_d)
    roll:SetSize(inp_elem_w,inp_elem_h)
    roll:SetNumeric(true)
    roll:SetFont(font)

    local input_save = vgui.Create("DButton", input_panel)
    input_save:SetSize(inp_elem_w,inp_elem_h)
    input_save:SetPos( inp_elem_w * 3 + 4 * panel_d, panel_d )
    input_save:SetText(TARDIS:GetPhrase("Screens.Coordinates.Save"))
    input_save:SetFont(font)

    local input_delete = vgui.Create("DButton", input_panel)
    input_delete:SetSize(inp_elem_w,inp_elem_h)
    input_delete:SetPos(inp_elem_w * 3 + 4 * panel_d, inp_elem_h + 2 * panel_d)
    input_delete:SetText(TARDIS:GetPhrase("Screens.Coordinates.Delete"))
    input_delete:SetFont(font)

    local input_set = vgui.Create("DButton", input_panel)
    input_set:SetSize(inp_elem_w,inp_elem_h)
    input_set:SetPos(inp_elem_w * 3 + 4 * panel_d, 2 * inp_elem_h + 3 * panel_d)
    input_set:SetText(TARDIS:GetPhrase("Screens.Coordinates.Set"))
    input_set:SetFont(font)

    input_panel.Think = function(self)
        local line = llist:GetSelectedLine()
        local loc = TARDIS.Locations[map]

        local namebox_empty = (namebox:GetText() == "")
        local coords_empty = (x:GetText() == "")
        coords_empty = coords_empty or (y:GetText() == "")
        coords_empty = coords_empty or (z:GetText() == "")
        -- angles can just be 0 by default so we don't have to check for them

        EnsureEnabled(input_delete, (line ~= nil and loc ~= nil and line <= #loc))
        EnsureEnabled(input_save, not namebox_empty and not coords_empty)
        EnsureEnabled(input_set, not coords_empty)
    end





    local function updatetextinputs(pos,ang,name)
        pitch:SetText(ang.p or 0.0)
        yaw:SetText(ang.y or 0.0)
        roll:SetText(ang.r or 0.0)
        x:SetText(pos.x or 0.0)
        y:SetText(pos.y or 0.0)
        z:SetText(pos.z or 0.0)
        if name then namebox:SetText(name) end
    end

    local function fetchtextinputs()
        local name = namebox:GetText()

        local n_x = tonumber(x:GetText()) or 0
        local n_y = tonumber(y:GetText()) or 0
        local n_z = tonumber(z:GetText()) or 0
        local n_pitch = tonumber(pitch:GetText()) or 0
        local n_yaw = tonumber(yaw:GetText()) or 0
        local n_roll = tonumber(roll:GetText()) or 0

        pos = Vector(n_x, n_y, n_z)
        ang = Angle(n_pitch, n_yaw, n_roll)

        if name == "" then name = TARDIS:GetPhrase("Screens.Coordinates.Unnamed") end
        return pos,ang,name
    end

    local function cleartextinputs()
        llist:ClearSelection()
        namebox:SetText("")
        x:SetText("")
        y:SetText("")
        z:SetText("")
        pitch:SetText("")
        yaw:SetText("")
        roll:SetText("")
    end

    local function updatelist()
        local scr
        if screen.is3D2D then
            scr = llist:GetScroll()
        end

        llist:Clear()
        if TARDIS.Locations[map] ~= nil then
            for k,v in pairs(TARDIS.Locations[map]) do
                llist:AddLine(v.name)
            end
        end
        llist:AddLine(TARDIS:GetPhrase("Screens.Coordinates.RandomGround"))
        llist:AddLine(TARDIS:GetPhrase("Screens.Coordinates.Random"))

        if screen.is3D2D and scr then
            llist:SetScroll(scr)
        end
    end





    updatelist()

    function llist:OnRowSelected(i,row)
        local locations_num = 0
        if TARDIS.Locations[map] ~= nil then
            locations_num = #TARDIS.Locations[map]
        end
        local name,pos,ang
        if i > locations_num then
            local ground = (i == locations_num + 1)
            local ext = LocalPlayer():GetTardisData("exterior")
            pos = ext:GetRandomLocation(ground) or ext:GetPos()
            ang = {p = 0, y = 0, r = 0}
            if ground then
                name = TARDIS:GetPhrase("Screens.Coordinates.RandomLocationGround")
            else
                name = TARDIS:GetPhrase("Screens.Coordinates.RandomLocation")
            end
        else
            pos = TARDIS.Locations[map][i].pos
            ang = TARDIS.Locations[map][i].ang
            name = TARDIS.Locations[map][i].name
        end
        updatetextinputs(pos,ang,name)
    end

    function llist:OnRowSelectionRemoved(i,row)
        cleartextinputs()
    end

    function pos_copy:DoClick()
        llist:ClearSelection()
        updatetextinputs(ext:GetPos(), ext:GetAngles(), "")
    end

    function dst_copy:DoClick()
        llist:ClearSelection()
        x:SetText(dst_x:GetText())
        y:SetText(dst_y:GetText())
        z:SetText(dst_z:GetText())
        pitch:SetText(dst_pitch:GetText())
        yaw:SetText(dst_yaw:GetText())
        roll:SetText(dst_roll:GetText())
        namebox:SetText("")
    end

    function pos_save:DoClick()
        Derma_StringRequest(
            TARDIS:GetPhrase("Screens.Coordinates.NewLocation"),
            TARDIS:GetPhrase("Screens.Coordinates.NameNewLocation"),
            TARDIS:GetPhrase("Screens.Coordinates.NewLocation"),
            function(name)
                pos = ext:GetPos()
                ang = ext:GetAngles()
                if name == "" then name = TARDIS:GetPhrase("Screens.Coordinates.Unnamed") end
                TARDIS:AddLocation(pos,ang,name,map)
                updatelist()
            end
        )
    end

    function dst_save:DoClick()
        Derma_StringRequest(
            TARDIS:GetPhrase("Screens.Coordinates.NewLocation"),
            TARDIS:GetPhrase("Screens.Coordinates.NameNewLocation"),
            TARDIS:GetPhrase("Screens.Coordinates.NewLocation"),
            function(name)

                local n_x = tonumber(dst_x:GetText()) or 0
                local n_y = tonumber(dst_y:GetText()) or 0
                local n_z = tonumber(dst_z:GetText()) or 0
                local n_pitch = tonumber(dst_pitch:GetText()) or 0
                local n_yaw = tonumber(dst_yaw:GetText()) or 0
                local n_roll = tonumber(dst_roll:GetText()) or 0

                pos = Vector(n_x, n_y, n_z)
                ang = Angle(n_pitch, n_yaw, n_roll)
                if name == "" then name = TARDIS:GetPhrase("Screens.Coordinates.Unnamed") end
                TARDIS:AddLocation(pos,ang,name,map)
                updatelist()
            end
        )
    end

    function input_save:DoClick()
        local vortex = ext:GetData("vortex", false)
        local pos, ang, name = fetchtextinputs()

        if name == "" then name = TARDIS:GetPhrase("Screens.Coordinates.Unnamed") end
        TARDIS:AddLocation(pos,ang,name,map)
        updatelist()
        cleartextinputs()
    end

    function input_delete:DoClick()
        local index = llist:GetSelectedLine()
        if not index then return end
        if not TARDIS.Locations[map] then return end
        if index > #TARDIS.Locations[map] then return end
        Derma_Query(
            TARDIS:GetPhrase("Screens.Coordinates.ConfirmRemoveLocation"),
            TARDIS:GetPhrase("Screens.Coordinates.RemoveLocation"),
            TARDIS:GetPhrase("Common.Yes"),
            function()
                TARDIS:RemoveLocation(map,index)
                updatelist()
            end,
            TARDIS:GetPhrase("Common.No")
        )
    end

    function input_set:DoClick()
        local pos,ang = fetchtextinputs()

        ext:SendMessage("destination-demat", { pos, ang } )
        if TARDIS:GetSetting("dest-onsetdemat") then
            TARDIS:RemoveHUDScreen()
        end
        cleartextinputs()
    end

    local clr = function(self)
        llist:ClearSelection()
    end

    namebox.OnChange = clr
    x.OnChange = clr
    y.OnChange = clr
    z.OnChange = clr
    pitch.OnChange = clr
    yaw.OnChange = clr
    roll.OnChange = clr

end)