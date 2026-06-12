
if SERVER then
    util.AddNetworkString("TARDIS-Debug-Portals")
    util.AddNetworkString("TARDIS-Debug-Portals-Update")

    -- Dynamic read/write counts not handled by analyzer.
    ---@diagnostic disable-next-line: gmod-net-read-write-order-mismatch
    net.Receive("TARDIS-Debug-Portals-Update",function(len,ply)
        if not ply:IsAdmin() then return end

        local portal = net.ReadEntity()
        if not IsValid(portal) then return end

        local update_type = net.ReadString()

        if update_type == "pos" then
            portal:SetPos(net.ReadVector())
        elseif update_type == "ang" then
            portal:SetAngles(net.ReadAngle())
        elseif update_type == "size" then
            portal:SetWidth(net.ReadFloat())
            portal:SetHeight(net.ReadFloat())
        elseif update_type == "exit_offset" then
            portal:SetExitPosOffset(net.ReadVector())
            portal:SetExitAngOffset(net.ReadAngle())
        elseif update_type == "3d" then
            -- Depth wins when > 0 (modern cavity); 0 falls back to thickness (legacy). FaceOffset
            -- places the opening off GetPos without moving the wormhole plane.
            portal:SetDepth(net.ReadFloat())
            portal:SetThickness(net.ReadFloat())
            portal:SetFaceOffset(net.ReadFloat())
        end
    end)
else
    function TARDIS:ShowPortalDebugMenu(p)
        local cmenu = g_ContextMenu --[[@as ContextMenuPanel]]
        if IsValid(p.debug_window) then
            if not cmenu:IsVisible() then
                cmenu:Open()
            end
            local w = p.debug_window
            w:SetPos(ScrW() * 0.25 - w:GetWide() * 0.5, ScrH() * 0.5 - w:GetTall() * 0.5)
            return
        end

        local menu_w = ScrW() * 0.2;
        local menu_h = ScrH() * 0.8;

        cmenu:Open()
        local frame=cmenu:Add( "DFrame" )
        frame:SetTitle("Portals Debug")
        frame:SetSizable(true)
        frame:SetSize(menu_w + 50, menu_h + 50)
        frame:SetPos(ScrW() * 0.25 - frame:GetWide() * 0.5, ScrH() * 0.5 - frame:GetTall() * 0.5)
        frame:ShowCloseButton(true)
        frame:RequestFocus()

        -- Release the cursor on close by closing the context menu that holds it.
        frame.OnClose = function()
            if IsValid(cmenu) then cmenu:Close() end
        end

        p.debug_window = frame

        local ent = p:GetParent()
        local rowX, rowY, rowZ, rowFB, rowRL, rowUD

        local px, py, pz = ent:WorldToLocal(p:GetPos()):Unpack()
        local ang_p, ang_y, ang_r = ent:WorldToLocalAngles(p:GetAngles()):Unpack()
        local prx, pry, prz = 0, 0, 0

        -- Migrate to depth on open: a legacy thickness portal is re-expressed as a depth cavity
        -- behind a face offset. GetPos (the wormhole/teleport plane) is NOT moved - the face offset
        -- alone reproduces the recessed opening, so the exit view + teleport stay put.
        local depth = p:GetDepth()
        local faceOffset = p:GetFaceOffset()
        local thickness = p:GetThickness()
        if depth <= 0 then
            faceOffset = math.max(-(5 + thickness), -5)
            depth = math.max(5, math.abs(thickness))
            thickness = 0
            net.Start("TARDIS-Debug-Portals-Update")
                net.WriteEntity(p)
                net.WriteString("3d")
                net.WriteFloat(depth)
                net.WriteFloat(thickness)
                net.WriteFloat(faceOffset)
            net.SendToServer()

            frame:SetTitle("Portals Debug (migrated to depth)")
            local note = vgui.Create("DLabel", frame)
            note:Dock(TOP)
            note:DockMargin(6, 4, 6, 2)
            note:SetTall(20)
            note:SetFont("DermaDefaultBold")
            note:SetTextColor(Color(255, 60, 60))
            note:SetText("Migrated from thickness to depth  (?)")
            note:SetMouseInputEnabled(true)
            note:SetTooltip("This portal used the legacy 'thickness' field. It was converted to the modern 'depth' (a cavity behind a face offset), keeping the visible face and the wormhole exactly where they were. Use 'Print to console' to save the new config.")
        end

        local function RefreshRelativeCoords()
            local pos = Vector(px, py, pz)
            local ang = Angle(ang_p, ang_y, ang_r)

            local B = Matrix()
            B:SetForward(ang:Forward())
            B:SetRight(ang:Right())
            B:SetUp(ang:Up())
            local B_inv = B:GetInverse()

            prx, pry, prz = (B_inv * pos):Unpack()

            if rowFB then rowFB:Refresh() end
            if rowRL then rowRL:Refresh() end
            if rowUD then rowUD:Refresh() end
        end

        local function RefreshAbsoluteCoords()
            local posr = Vector(prx, pry, prz)
            local ang = Angle(ang_p, ang_y, ang_r)

            local B = Matrix()
            B:SetForward(ang:Forward())
            B:SetRight(ang:Right())
            B:SetUp(ang:Up())

            px, py, pz = (B * posr):Unpack()

            if rowX then rowX:Refresh() end
            if rowY then rowY:Refresh() end
            if rowZ then rowZ:Refresh() end
        end

        RefreshRelativeCoords()

        local width = p:GetWidth()
        local height = p:GetHeight()

        -- exit pos offset, exit ang offset
        local epo_x, epo_y, epo_z = p:GetExitPosOffset():Unpack()
        local eao_p, eao_y, eao_r = p:GetExitAngOffset():Unpack()

        local orig_px, orig_py, orig_pz = px, py, pz
        local orig_prx, orig_pry, orig_prz = prx, pry, prz
        local orig_ang_p, orig_ang_y, orig_ang_r = ang_p, ang_y, ang_r
        local orig_depth = depth
        local orig_faceOffset = faceOffset
        local orig_width = width
        local orig_height = height
        local orig_epo_x, orig_epo_y, orig_epo_z = epo_x, epo_y, epo_z
        local orig_eao_p, orig_eao_y, orig_eao_r = eao_p, eao_y, eao_r

        local function UpdatePortalPos(src_relative)

            if src_relative then
                RefreshAbsoluteCoords()
            else
                RefreshRelativeCoords()
            end

            net.Start("TARDIS-Debug-Portals-Update")
                net.WriteEntity(p)
                net.WriteString("pos")
                net.WriteVector(ent:LocalToWorld(Vector(px, py, pz)))
            net.SendToServer()
        end

        local function UpdatePortalAng()
            RefreshRelativeCoords()
            net.Start("TARDIS-Debug-Portals-Update")
                net.WriteEntity(p)
                net.WriteString("ang")
                net.WriteAngle(ent:LocalToWorldAngles(Angle(ang_p, ang_y, ang_r)))
            net.SendToServer()
        end

        local function UpdatePortalSize()
            net.Start("TARDIS-Debug-Portals-Update")
                net.WriteEntity(p)
                net.WriteString("size")
                net.WriteFloat(width)
                net.WriteFloat(height)
            net.SendToServer()
        end

        local function UpdatePortal3D()
            net.Start("TARDIS-Debug-Portals-Update")
                net.WriteEntity(p)
                net.WriteString("3d")
                net.WriteFloat(depth)
                net.WriteFloat(thickness)
                net.WriteFloat(faceOffset)
            net.SendToServer()
        end

        local function UpdatePortalExitOffset()
            net.Start("TARDIS-Debug-Portals-Update")
                net.WriteEntity(p)
                net.WriteString("exit_offset")
                net.WriteVector(Vector(epo_x, epo_y, epo_z))
                net.WriteAngle(Angle(eao_p, eao_y, eao_r))
            net.SendToServer()
        end

        -- Custom panel: a DProperties grid has no per-row buttons. Each row is a 2dp DNumSlider with
        -- an undo button that enables only while the value differs from its open-time default.
        local scroll = vgui.Create("DScrollPanel", frame)
        scroll:Dock(FILL)
        scroll:DockMargin(4, 4, 4, 4)
        scroll:SetZPos(5)   -- laid out last, so it fills the space left by the docked note/buttons
        scroll.Think = function()
            if not IsValid(p) then frame:Close() end
        end

        local function makeCategory(label, expanded)
            local cat = vgui.Create("DCollapsibleCategory", scroll)
            cat:Dock(TOP)
            cat:DockMargin(0, 0, 0, 6)
            cat:SetLabel(label)
            local body = vgui.Create("DListLayout", cat)
            cat:SetContents(body)
            cat:SetExpanded(expanded)
            return body
        end

        local rows = {}
        local undoMat = Material("icon16/arrow_undo.png")
        local EPS = 0.005

        -- bounds is either a number (symmetric range around the default) or a {min, max} pair. The
        -- range maths lives here, on the default param, so the analyzer treats it as any (the Unpacked
        -- locals are typed nullable, and value +/- range at the call site would trip need-check-nil).
        local function makeRow(body, name, getter, default, bounds, onChange)
            local vmin, vmax
            if istable(bounds) then
                vmin, vmax = bounds[1], bounds[2]
            else
                vmin, vmax = default - bounds, default + bounds
            end

            local row = vgui.Create("DPanel")
            row:SetTall(22)
            row.Paint = function() end
            body:Add(row)

            local reset = vgui.Create("DButton", row)
            reset:Dock(RIGHT)
            reset:SetWide(20)
            reset:DockMargin(2, 1, 0, 1)
            reset:SetText("")
            reset:SetTooltip("Reset to default")

            local slider = vgui.Create("DNumSlider", row)
            slider:Dock(FILL)
            slider:SetText(name)
            slider:SetDecimals(2)
            slider:SetMinMax(vmin, vmax)

            local obj = {}
            local silent = false

            local function syncReset()
                reset:SetEnabled(math.abs(getter() - default) > EPS)
            end

            reset.Paint = function(s, w, h)
                local on = s:IsEnabled()
                if on and s:IsHovered() then
                    surface.SetDrawColor(255, 255, 255, 45)
                    surface.DrawRect(0, 0, w, h)
                end
                surface.SetDrawColor(255, 255, 255, on and 255 or 55)
                surface.SetMaterial(undoMat)
                surface.DrawTexturedRect((w - 16) * 0.5, (h - 16) * 0.5, 16, 16)
            end

            slider:SetValue(getter())
            slider.OnValueChanged = function(_, val)
                if silent then return end
                onChange(val)
                syncReset()
            end

            function obj:Refresh()
                silent = true
                slider:SetValue(getter())
                silent = false
                syncReset()
            end

            reset.DoClick = function()
                silent = true
                slider:SetValue(default)
                silent = false
                onChange(default)
                syncReset()
            end

            syncReset()
            rows[#rows + 1] = obj
            return obj
        end

        local posBody = makeCategory("Position", true)
        rowX = makeRow(posBody, "X", function() return px end, orig_px, 100, function(val)
            px = val
            UpdatePortalPos()
        end)
        rowY = makeRow(posBody, "Y", function() return py end, orig_py, 100, function(val)
            py = val
            UpdatePortalPos()
        end)
        rowZ = makeRow(posBody, "Z", function() return pz end, orig_pz, 100, function(val)
            pz = val
            UpdatePortalPos()
        end)
        rowFB = makeRow(posBody, "Forward / Back", function() return prx end, orig_prx, 100, function(val)
            prx = val
            UpdatePortalPos(true)
        end)
        rowRL = makeRow(posBody, "Right / Left", function() return pry end, orig_pry, 100, function(val)
            pry = val
            UpdatePortalPos(true)
        end)
        rowUD = makeRow(posBody, "Up / Down", function() return prz end, orig_prz, 100, function(val)
            prz = val
            UpdatePortalPos(true)
        end)

        local angBody = makeCategory("Angle", true)
        makeRow(angBody, "Pitch", function() return ang_p end, orig_ang_p, 360, function(val)
            ang_p = val
            UpdatePortalAng()
        end)
        makeRow(angBody, "Yaw", function() return ang_y end, orig_ang_y, 360, function(val)
            ang_y = val
            UpdatePortalAng()
        end)
        makeRow(angBody, "Roll", function() return ang_r end, orig_ang_r, 360, function(val)
            ang_r = val
            UpdatePortalAng()
        end)

        local sizeBody = makeCategory("Size", true)
        makeRow(sizeBody, "Width", function() return width end, orig_width, {0, 300}, function(val)
            width = val
            UpdatePortalSize()
        end)
        makeRow(sizeBody, "Height", function() return height end, orig_height, {0, 300}, function(val)
            height = val
            UpdatePortalSize()
        end)

        local depthBody = makeCategory("Depth", true)
        -- Depth min 5 (the rendered floor): keeps the slider in flush-cavity range so it can't drag
        -- into the depth 0 = unset boundary, which would snap the face back 5u to the legacy recess.
        makeRow(depthBody, "Depth", function() return depth end, orig_depth, {5, 150}, function(val)
            depth = val
            UpdatePortal3D()
        end)
        -- Render-only opening offset (0 = flush with GetPos, negative = recessed). Lets a migrated
        -- portal keep its recessed face without moving GetPos (the wormhole/teleport plane).
        makeRow(depthBody, "Face offset", function() return faceOffset end, orig_faceOffset, 50, function(val)
            faceOffset = val
            UpdatePortal3D()
        end)

        local exitBody = makeCategory("Exit point offset (asymmetric portals)", false)
        makeRow(exitBody, "X", function() return epo_x end, orig_epo_x, 300, function(val)
            epo_x = val
            UpdatePortalExitOffset()
        end)
        makeRow(exitBody, "Y", function() return epo_y end, orig_epo_y, 300, function(val)
            epo_y = val
            UpdatePortalExitOffset()
        end)
        makeRow(exitBody, "Z", function() return epo_z end, orig_epo_z, 300, function(val)
            epo_z = val
            UpdatePortalExitOffset()
        end)
        makeRow(exitBody, "Pitch", function() return eao_p end, orig_eao_p, 360, function(val)
            eao_p = val
            UpdatePortalExitOffset()
        end)
        makeRow(exitBody, "Yaw", function() return eao_y end, orig_eao_y, 360, function(val)
            eao_y = val
            UpdatePortalExitOffset()
        end)
        makeRow(exitBody, "Roll", function() return eao_r end, orig_eao_r, 360, function(val)
            eao_r = val
            UpdatePortalExitOffset()
        end)

        local btns = vgui.Create( "DPanel", frame )
        btns:Dock( BOTTOM )
        btns:DockMargin( 4, 2, 4, 4 )
        btns:SetTall( 30 )
        btns.Paint = function() end

        local resetAllBtn = vgui.Create( "DButton", btns )
        resetAllBtn:Dock( LEFT )
        resetAllBtn:SetWide( 110 )
        resetAllBtn:DockMargin( 0, 0, 4, 0 )
        resetAllBtn:SetText( "Reset all" )
        resetAllBtn.DoClick = function()
            px, py, pz = orig_px, orig_py, orig_pz
            ang_p, ang_y, ang_r = orig_ang_p, orig_ang_y, orig_ang_r
            depth = orig_depth
            faceOffset = orig_faceOffset
            width = orig_width
            height = orig_height

            epo_x, epo_y, epo_z = orig_epo_x, orig_epo_y, orig_epo_z
            eao_p, eao_y, eao_r = orig_eao_p, orig_eao_y, orig_eao_r

            UpdatePortalPos()
            UpdatePortalAng()
            UpdatePortalSize()
            UpdatePortal3D()
            UpdatePortalExitOffset()

            for _, r in ipairs(rows) do r:Refresh() end
        end

        local printBtn = vgui.Create( "DButton", btns )
        printBtn:Dock( FILL )
        printBtn:SetText( "Print to console" )
        printBtn.DoClick = function()
            -- 2dp is plenty for placement and keeps the generated config clean (the sliders already
            -- operate at 2dp; the raw locals can carry float round-trip noise like 30.899990081787).
            local function r(v) return math.Round(v, 2) end
            print("Portal = {")
            print("\t-- Generated by portals debug tool")
            print("\tpos = Vector(" .. r(px) .. ", " .. r(py) .. ", " .. r(pz) .. "),")
            print("\tang = Angle(" .. r(ang_p) .. ", " .. r(ang_y) .. ", " .. r(ang_r) .. "),")
            print("\twidth = " .. r(width) .. ",")
            print("\theight = " .. r(height) .. ",")

            if depth and depth > 0 then
                print("\tdepth = " .. r(depth) .. ",")
            end

            if faceOffset and faceOffset ~= 0 then
                print("\tfaceoffset = " .. r(faceOffset) .. ",")
            end

            print("},")
        end
    end

    net.Receive("TARDIS-Debug-Portals", function()
        local p = net.ReadEntity()
        if not IsValid(p) then return end
        TARDIS:ShowPortalDebugMenu(p)
    end)
end

concommand.Add("tardis2_debug_portals", function(ply,cmd,args)
    if not ply:IsAdmin() then return end

    local portal = wp.GetFirstPortalHit(ply:EyePos(), ply:EyeAngles():Forward())

    if IsValid(portal.Entity) then
        net.Start("TARDIS-Debug-Portals")
            net.WriteEntity(portal.Entity)
        net.Send(ply)
    else
        TARDIS:ErrorMessage(ply, "You're not looking at a portal")
    end
end)

