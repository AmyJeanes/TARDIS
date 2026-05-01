-- Virtual console

local function new_virtual_console(self,ext,int,frame,screen)
    frame:SetBackgroundColor(Color(0,0,0))

    --background

    local background=vgui.Create("DImage", frame)

    local theme = TARDIS:GetScreenGUITheme(screen)
    local background_img = TARDIS:GetGUIThemeElement(theme, "backgrounds", "virtualconsole")
    background:SetImage(background_img)
    background:SetSize(frame:GetWide(), frame:GetTall())

    local layout_rows
    if screen.is3D2D then
        if screen.gui_rows == nil or TARDIS:GetSetting("gui_override_numrows") then
            layout_rows = math.floor(TARDIS:GetSetting("gui_screen_numrows"))
        else
            layout_rows = math.floor(screen.gui_rows)
        end
    else
        layout_rows = math.floor(TARDIS:GetSetting("gui_popup_numrows"))
    end
    local layout = HexagonalLayout:new(frame, layout_rows, 0.2)

    -- controls

    for _,control in pairs(TARDIS:GetControls()) do
        local options = control.screen_button
        if options and options.virt_console and not (screen.is3D2D and options.popup_only) then
            local button = TardisScreenButton:new(frame, screen)

            if not control.id and not options.id then
                error("control id is required for TARDIS screen button")
            end
            if options.id then
                button:SetID(options.id)
            else
                button:SetID(control.id)
            end
            button:SetControl(control.id)

            if options.toggle ~= nil then
                button:SetIsToggle(options.toggle)
            end
            if options.frame_type ~= nil then
                button:SetFrameType(options.frame_type[1], options.frame_type[2])
            end
            if options.text ~= nil then
                button:SetText(TARDIS:GetPhrase(options.text))
            end
            if options.pressed_state_data ~= nil then
                button:SetPressedStateData(ext, options.pressed_state_data)
            end
            if options.order ~= nil then
                button:SetOrder(options.order)
            end

            layout:AddNewButton(button)
        end
    end

    -- We keep these just in case someone needs custom buttons
    if IsValid(ext) then
        ext:CallHook("SetupVirtualConsole", screen, frame, layout)
    end
    if IsValid(int) then
        int:CallHook("SetupVirtualConsole", screen, frame, layout)
    end

    layout:DrawButtons()

    layout.scroll_size = math.max(1, layout:GetCols() - 1)

    frame.left_arrow_func = function()
        if layout:CanMoveRight()
            and not screen.left_arrow:IsPressed()
            and not screen.right_arrow:IsPressed()
        then
            layout:ScrollButtons(layout.scroll_size)
        end
    end
    frame.right_arrow_func = function()
        if layout:CanMoveLeft()
            and not screen.right_arrow:IsPressed()
            and not screen.left_arrow:IsPressed()
        then
            layout:ScrollButtons(-layout.scroll_size)
        end
    end

end

local function old_virtual_console(self,ext,int,frame,screen)
    local power=vgui.Create("DButton",frame)
    power:SetSize( frame:GetWide()*0.2, frame:GetTall()*0.2 )
    power:SetPos(frame:GetWide()*0.13 - power:GetWide()*0.5,frame:GetTall()*0.15 - power:GetTall()*0.5)
    power:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.TogglePower"))
    power:SetFont(TARDIS:GetScreenFont(screen, "Default"))
    power.DoClick = function()
        TARDIS:Control("power", LocalPlayer())
    end

    local repair=vgui.Create("DButton",frame)
    repair:SetSize( frame:GetWide()*0.2, frame:GetTall()*0.2 )
    repair:SetPos(frame:GetWide()*0.35 - repair:GetWide()*0.5,frame:GetTall()*0.15 - repair:GetTall()*0.5)
    repair:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.Repair"))
    repair:SetFont(TARDIS:GetScreenFont(screen, "Default"))
    repair.DoClick = function()
        TARDIS:Control("repair", LocalPlayer())
    end

    local vortex_flight=vgui.Create("DButton",frame)
    vortex_flight:SetSize( frame:GetWide()*0.2, frame:GetTall()*0.2 )
    vortex_flight:SetPos(frame:GetWide()*0.13 - vortex_flight:GetWide()*0.5,frame:GetTall()*0.4 - vortex_flight:GetTall()*0.5)
    vortex_flight:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.FastRemat").." "..TARDIS:GetPhrase(ext:GetFastRemat() and "Common.Enabled.Lower" or "Common.Disabled.Lower"))
    vortex_flight:SetFont(TARDIS:GetScreenFont(screen, "Default"))
    vortex_flight.DoClick = function(self)
        TARDIS:Control("vortex_flight", LocalPlayer())
    end
    vortex_flight.oldon = ext:GetFastRemat()
    function vortex_flight:Think()
        local on = ext:GetFastRemat()
        if self.oldon == on then return end
        if on then
            self:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.FastRemat").." "..TARDIS:GetPhrase("Common.Enabled.Lower"))
        else
            self:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.FastRemat").." "..TARDIS:GetPhrase("Common.Disabled.Lower"))
        end
        self.oldon = on
    end

    local physlock = vgui.Create("DButton",frame)
    physlock:SetSize( frame:GetWide()*0.2, frame:GetTall()*0.2)
    physlock:SetFont(TARDIS:GetScreenFont(screen, "Default"))
    physlock:SetPos((frame:GetWide()*0.35)-(physlock:GetWide()*0.5),(frame:GetTall()*0.4)-(physlock:GetTall()*0.5))
    physlock:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.Physlock").." "..TARDIS:GetPhrase(ext:GetPhyslock() and "Common.Enabled.Lower" or "Common.Disabled.Lower"))
    physlock.DoClick = function()
        TARDIS:Control("physlock", LocalPlayer())
    end
    physlock.oldon = ext:GetPhyslock()
    function physlock:Think()
        local on = ext:GetPhyslock()
        if self.oldon == on then return end
        if on then
            self:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.Physlock").." "..TARDIS:GetPhrase("Common.Enabled.Lower"))
        else
            self:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.Physlock").." "..TARDIS:GetPhrase("Common.Disabled.Lower"))
        end
        self.oldon = on
    end

    local fastreturn=vgui.Create("DButton",frame)
    fastreturn:SetSize( frame:GetWide()*0.2, frame:GetTall()*0.2 )
    fastreturn:SetPos(frame:GetWide()*0.13 - fastreturn:GetWide()*0.5,frame:GetTall()*0.65 - fastreturn:GetTall()*0.5)
    fastreturn:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.FastReturn"))
    fastreturn:SetFont(TARDIS:GetScreenFont(screen, "Default"))
    fastreturn.DoClick = function()
        TARDIS:Control("fastreturn", LocalPlayer())
    end

    local hads=vgui.Create("DButton",frame)
    hads:SetSize( frame:GetWide()*0.2, frame:GetTall()*0.2 )
    hads:SetPos(frame:GetWide()*0.35 - power:GetWide()*0.5,frame:GetTall()*0.65 - power:GetTall()*0.5)
    hads:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.HADS").." "..TARDIS:GetPhrase(ext:GetData("hads") and "Common.Enabled.Lower" or "Common.Disabled.Lower"))
    hads:SetFont(TARDIS:GetScreenFont(screen, "Default"))
    hads.DoClick = function()
        TARDIS:Control("hads", LocalPlayer())
    end
    hads.oldon = ext:GetData("hads")
    function hads:Think()
        local on = ext:GetData("hads", false)
        if self.oldon == on then return end
        if on then
            self:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.HADS").." "..TARDIS:GetPhrase("Common.Enabled.Lower"))
        else
            self:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.HADS").." "..TARDIS:GetPhrase("Common.Disabled.Lower"))
        end
        self.oldon = on
    end

    local doorswitch = vgui.Create("DButton",frame)
    local doorlock = vgui.Create("DButton",frame)

    doorswitch:SetSize( frame:GetWide()*0.2, frame:GetTall()*0.1)
    doorswitch:SetFont(TARDIS:GetScreenFont(screen, "Default"))
    doorswitch:SetPos((frame:GetWide()*0.57)-(doorswitch:GetWide()*0.5),(frame:GetTall()*0.15)-(doorswitch:GetTall()*1))
    doorswitch:SetText(TARDIS:GetPhrase(ext:DoorOpen() and "Screens.VirtualConsole.Old.CloseDoor" or "Screens.VirtualConsole.Old.OpenDoor"))

    doorlock:SetSize( frame:GetWide()*0.2, frame:GetTall()*0.1)
    doorlock:SetFont(TARDIS:GetScreenFont(screen, "Default"))
    doorlock:SetPos((frame:GetWide()*0.57)-(doorlock:GetWide()*0.5),(frame:GetTall()*0.15)-(doorlock:GetTall()*0))
    doorlock:SetText(TARDIS:GetPhrase(ext:Locked() and "Screens.VirtualConsole.Old.UnlockDoor" or "Screens.VirtualConsole.Old.LockDoor"))

    doorswitch.DoClick = function()
        TARDIS:Control("door", LocalPlayer())
    end

    doorlock.DoClick = function()
        TARDIS:Control("doorlock", LocalPlayer())
    end

    function doorswitch:Think()
        if ext:DoorMoving() then
            doorswitch.moving = true
            doorswitch.first = true
            if doorswitch:IsEnabled() then
                if doorswitch.open then
                    doorswitch:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.DoorClosing"))
                else
                    doorswitch:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.DoorOpening"))
                end
                doorswitch:SetEnabled(false)
            end
        elseif not doorswitch:IsEnabled() and not doorlock.lock then
            if not doorswitch.open then
                doorswitch.moving = false
            end
            doorswitch:SetEnabled(true)
        elseif ext:DoorOpen() and (not doorswitch.open) or doorswitch.first then
            if not doorswitch.moving then
                doorswitch.open = true
            end
            doorswitch:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.CloseDoor"))
            if doorswitch.first then
                doorswitch.first=nil
            end
        elseif not ext:DoorOpen() and doorswitch.open or doorswitch.first then
            doorswitch.open=false
            doorswitch:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.OpenDoor"))
            if doorswitch.first then
                doorswitch.first=nil
            end
        end
    end

    function doorlock:Think()
        if ext:Locking() then
            if doorlock:IsEnabled() then
                if ext:Locked() then
                    doorlock:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.LockUnlocking"))
                else
                    doorlock:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.LockLocking"))
                end
                doorlock:SetEnabled(false)
            end
        elseif not doorlock:IsEnabled() then
            doorlock:SetEnabled(true)
        elseif ext:Locked() and (not doorlock.lock) or doorlock.first then
            doorlock.lock=true
            doorlock:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.UnlockDoor"))
            doorswitch:SetEnabled(false)
            if doorlock.first then
                doorlock.first=nil
            end
        elseif not ext:Locked() and doorlock.lock or doorlock.first then
            doorlock.lock=false
            doorlock:SetText(TARDIS:GetPhrase("Screens.VirtualConsole.Old.LockDoor"))
            doorswitch:SetEnabled(true)
            if doorlock.first then
                doorlock.first=nil
            end
        end
    end
end

TARDIS:AddScreen("Virtual Console", {id="virtualconsole",text="Screens.VirtualConsole",menu=false, order=1}, function(self,ext,int,frame,screen)
    if not TARDIS:GetSetting("gui_old") then
        new_virtual_console(self,ext,int,frame,screen)
    else
        old_virtual_console(self,ext,int,frame,screen)
    end
end)
