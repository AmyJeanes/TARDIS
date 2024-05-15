-- TARDIS debug pointer
-- Creators: Brundoob, Parar020100 and RyanM2711

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName       = "TARDIS Debug Pointer"
ENT.Author          = "Brundoob"
ENT.Purpose         = "Print locations in the TARDIS"
ENT.Category        = "Doctor Who - TARDIS"
ENT.Spawnable       = false
ENT.AdminOnly       = true

-- debugging functions

concommand.Add("tardis2_debug_pointer_clear", function(ply,cmd,args)
    for k,v in pairs(ents.FindByClass("gmod_tardis_debug_pointer")) do
        v:Remove()
    end
end)

concommand.Add("tardis2_debug_pointer_color", function(ply,cmd,args)
    for k,v in pairs(ents.FindByClass("gmod_tardis_debug_pointer")) do
        v:SetColor(Color(10,0,255))
    end
end)

concommand.Add("tardis2_debug_pointer", function(ply,cmd,args)
    if not (ply:IsAdmin() and gamemode.Call("PlayerSpawnSENT", ply, "gmod_tardis_debug_pointer")) then return end

    local ent = ents.Create("gmod_tardis_debug_pointer")
    ent:SetCreator(ply)

    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:EyeAngles():Forward() * 10000,
        filter = function( ent ) if ( ent:GetClass() == "prop_physics" ) then return true end end
    })

    local close_pos = ply:EyePos() + ply:EyeAngles():Forward() * 40

    if ply:EyePos():Distance(tr.HitPos) < ply:EyePos():Distance(close_pos) then
        ent:SetPos(tr.HitPos)
    else
        ent:SetPos(close_pos)
    end

    local interior = ply:GetTardisData("interior")

    for i,v in ipairs(args) do
        if v == "model" then
            if file.Exists(args[i + 1], "GAME") then
                ent.model = args[i + 1]
            end
        elseif v == "part" then
            local part = TARDIS:GetRegisteredPart(args[i + 1])
            if part then ent.model = part.Model end
        elseif v == "scale" then
            ent.scale = args[i + 1]
        elseif v == "pos" or v == "ang" or v == "worldpos" then
            local a = tonumber(args[i + 1])
            local b = tonumber(args[i + 2])
            local c = tonumber(args[i + 3])
            local ok = (a and b and c)

            if ok and v == "pos" and interior then
                ent:SetPos(interior:LocalToWorld(Vector(a, b, c)))
            elseif ok and v == "worldpos" then
                ent:SetPos(Vector(a, b, c))
            elseif ok then
                ent:SetAngles(Angle(a, b, c))
            end
        end
    end

    ent:Spawn()
    gamemode.Call("PlayerSpawnedSENT",ply,ent)
    undo.Create("TARDIS Debug Pointer")
    undo.AddEntity(ent)
    undo.SetPlayer(ply)
    undo.Finish()
    ply:AddCleanup("sents",ent)
end)

function ENT:SetupDataTables()
    self:NetworkVar("Entity",0,"Other")
    self:NetworkVar("Bool",0,"DrawAABox")

    if CLIENT then
        self:NetworkVarNotify("DrawAABox",self.UpdateRenderBounds)
        self:NetworkVarNotify("Other",self.UpdateRenderBounds)
    end
end

if SERVER then
    util.AddNetworkString("TARDIS-Pointer-Debug")
    util.AddNetworkString("TARDIS-Pointer-Debug-Update")
    util.AddNetworkString("TARDIS-Pointer-Use")

    net.Receive("TARDIS-Pointer-Debug-Update",function(len,ply)
        local pointer = net.ReadEntity()
        if not IsValid(pointer) then return end

        local update_type = net.ReadString()

        if update_type == "pos" then
            pointer:SetPos(net.ReadVector())
        elseif update_type == "ang" then
            pointer:SetAngles(net.ReadAngle())
        elseif update_type == "scale" then
            local scale = net.ReadFloat()
            pointer:SetModelScale(scale)
        end
    end)

    net.Receive("TARDIS-Pointer-Use",function(len,ply)
        local pointer = net.ReadEntity()
        if not IsValid(pointer) then return end
        pointer:Use(ply,ply)
    end)
else
    function TARDIS:ShowPointerDebugMenu(p)
        if IsValid(p.debug_window) then
            if not g_ContextMenu:IsVisible() then
                g_ContextMenu:Open()
            end
            local w = p.debug_window
            w:SetPos(ScrW() * 0.25 - w:GetWide() * 0.5, ScrH() * 0.5 - w:GetTall() * 0.5)
            return
        end

        local x = ScrW() * 0.2;
        local y = ScrH() * 0.8;

        g_ContextMenu:Open()
        local frame=g_ContextMenu:Add( "DFrame" )
        frame:SetTitle("TARDIS Pointer Debug")
        frame:SetSizable(true)
        frame:SetSize(x + 50, y + 50)
        frame:SetPos(ScrW() * 0.25 - frame:GetWide() * 0.5, ScrH() * 0.5 - frame:GetTall() * 0.5)
        frame:ShowCloseButton(true)
        frame:RequestFocus()

        p.debug_window = frame

        local pr = vgui.Create( "DProperties", frame )
        pr:SetSize(x, y)
        pr:Center()

        local ent = LocalPlayer():GetTardisData("interior")
        if not ent then
            frame:Close()
            LocalPlayer():ChatPrint("No TARDIS interior found")
            return
        end

        local x, x2, y, y2, z, z2
        local xr, xr2, yr, yr2, zr, zr2
        local xpv, xpv2, ypv, ypv2, zpv, zpv2

        local px, py, pz = ent:WorldToLocal(p:GetPos()):Unpack()
        local prx, pry, prz = 0, 0, 0 -- relative coordinates to pointer's rotation
        local ppvx, ppvy, ppvz = 0, 0, 0 -- relative coordinates to player's view
        local ang_p, ang_y, ang_r = ent:WorldToLocalAngles(p:GetAngles()):Unpack()

        local pv_ignore_vertical_angle = true

        local scale = p:GetModelScale() or 1

        local function RefreshRelativeCoords()
            local pos = Vector(px, py, pz)
            local ang = Angle(ang_p, ang_y, ang_r)

            local B = Matrix()
            B:SetForward(ang:Forward())
            B:SetRight(ang:Right())
            B:SetUp(ang:Up())
            local B_inv = B:GetInverse()

            prx, pry, prz = (B_inv * pos):Unpack()

            if xr then
                xr:SetValue(prx)
                xr2:SetValue(prx)
            end
            if yr then
                yr:SetValue(pry)
                yr2:SetValue(pry)
            end
            if zr then
                zr:SetValue(prz)
                zr2:SetValue(prz)
            end
        end

        local function RefreshAbsoluteCoords(src_player_view)
            local posr, ang

            if src_player_view then
                posr = Vector(ppvx, ppvy, ppvz)
                if pv_ignore_vertical_angle then
                    ang = Angle(0, LocalPlayer():EyeAngles().y, 0)
                else
                    ang = LocalPlayer():EyeAngles()
                end
            else
                posr = Vector(prx, pry, prz)
                ang = Angle(ang_p, ang_y, ang_r)
            end

            local B = Matrix()
            B:SetForward(ang:Forward())
            B:SetRight(ang:Right())
            B:SetUp(ang:Up())

            px, py, pz = (B * posr):Unpack()

            if x then
                x:SetValue(px)
                x2:SetValue(px)
            end
            if y then
                y:SetValue(py)
                y2:SetValue(py)
            end
            if z then
                z:SetValue(pz)
                z2:SetValue(pz)
            end
        end

        local function RefreshPlayerViewCoords()
            local pos = Vector(px, py, pz)
            local ang
            if pv_ignore_vertical_angle then
                ang = Angle(0, LocalPlayer():EyeAngles().y, 0)
            else
                ang = LocalPlayer():EyeAngles()
            end

            local B = Matrix()
            B:SetForward(ang:Forward())
            B:SetRight(ang:Right())
            B:SetUp(ang:Up())
            local B_inv = B:GetInverse()

            ppvx, ppvy, ppvz = (B_inv * pos):Unpack()

            if xpv then
                xpv:SetValue(ppvx)
                xpv2:SetValue(ppvx)
            end
            if ypv then
                ypv:SetValue(ppvy)
                ypv2:SetValue(ppvy)
            end
            if zpv then
                zpv:SetValue(ppvz)
                zpv2:SetValue(ppvz)
            end
        end

        local function RefreshRealCoords()
            px, py, pz = ent:WorldToLocal(p:GetPos()):Unpack()
            ang_p, ang_y, ang_r = ent:WorldToLocalAngles(p:GetAngles()):Unpack()
            RefreshRelativeCoords()
            RefreshPlayerViewCoords()
        end

        RefreshRealCoords()

        local function UpdatePointerPos(src_relative, src_player_view)
            if src_player_view then
                RefreshAbsoluteCoords(true)
                RefreshRelativeCoords()
            elseif src_relative then
                RefreshAbsoluteCoords()
                RefreshPlayerViewCoords()
            else
                RefreshRelativeCoords()
                RefreshPlayerViewCoords()
            end

            net.Start("TARDIS-Pointer-Debug-Update")
                net.WriteEntity(p)
                net.WriteString("pos")
                net.WriteVector(ent:LocalToWorld(Vector(px, py, pz)))
            net.SendToServer()
        end

        local function UpdatePointerAng()
            RefreshRelativeCoords()
            net.Start("TARDIS-Pointer-Debug-Update")
                net.WriteEntity(p)
                net.WriteString("ang")
                net.WriteAngle(ent:LocalToWorldAngles(Angle(ang_p, ang_y, ang_r)))
            net.SendToServer()
        end

        local function UpdatePointerScale()
            net.Start("TARDIS-Pointer-Debug-Update")
                net.WriteEntity(p)
                net.WriteString("scale")
                net.WriteFloat(scale)
            net.SendToServer()
        end

        local function SetupProperty(category, name, value, a, b, c, d)
            local vmin, vmax, update_func
            local vtype = "Float"
            if isnumber(b) then
                vmin = a
                vmax = b
                update_func = c
            else
                vmin = value - a
                vmax = value + a
                update_func = b
            end

            if d then
                vtype = d
            end

            local row1 = pr:CreateRow( category, name )
            local row2 = pr:CreateRow( category, name .. " (precise)" )

            row1:Setup( vtype, { min = vmin, max = vmax } )
            row1:SetValue(value)
            row1.DataChanged = function( _, val )
                row2:SetValue(val)
                update_func(val)
            end

            row2:Setup( "Generic" )
            row2:SetValue(value)
            row2.DataChanged = function( _, val )
                if tonumber(val) == nil then return end
                row1:SetValue(val)
                update_func(val)
            end

            return row1, row2
        end

        x, x2 = SetupProperty("Position", "X", px, 100, function(val)
            px = val
            UpdatePointerPos()
        end)
        y, y2 = SetupProperty("Position", "Y", py, 100, function(val)
            py = val
            UpdatePointerPos()
        end)
        z, z2 = SetupProperty("Position", "Z", pz, 100, function(val)
            pz = val
            UpdatePointerPos()
        end)

        xr, xr2 = SetupProperty("Relative position", "Forward / Back", prx, 100, function(val)
            prx = val
            UpdatePointerPos(true)
        end)
        yr, yr2 = SetupProperty("Relative position", "Right / Left", pry, 100, function(val)
            pry = val
            UpdatePointerPos(true)
        end)
        zr, zr2 = SetupProperty("Relative position", "Up / Down", prz, 100, function(val)
            prz = val
            UpdatePointerPos(true)
        end)

        xpv, xpv2 = SetupProperty("Player view position", "Forward / Back", ppvx, 400, function(val)
            ppvx = val
            UpdatePointerPos(false, true)
        end)
        ypv, ypv2 = SetupProperty("Player view position", "Right / Left", ppvy, 400, function(val)
            ppvy = val
            UpdatePointerPos(false, true)
        end)
        zpv, zpv2 = SetupProperty("Player view position", "Up / Down", ppvz, 400, function(val)
            ppvz = val
            UpdatePointerPos(false, true)
        end)

        local pv_iva = pr:CreateRow( "Player view position", "Ignore vertical angle" )
        pv_iva:Setup( "Bool" )
        pv_iva:SetValue(pv_ignore_vertical_angle)
        pv_iva.DataChanged = function( _, val )
            pv_ignore_vertical_angle = (val == 1)
        end

        local ap, ap2 = SetupProperty( "Angle", "Pitch", ang_p, 360, function(val)
            ang_p = val
            UpdatePointerAng()
        end)
        local ay, ay2 = SetupProperty( "Angle", "Yaw", ang_y, 360, function(val)
            ang_y = val
            UpdatePointerAng()
        end)
        local ar, ar2 = SetupProperty( "Angle", "Roll", ang_r, 360, function(val)
            ang_r = val
            UpdatePointerAng()
        end)

        local sc, sc2 = SetupProperty( "Scale", "Pointer scale", scale, 0.1, 10, function(val)
            scale = val
            UpdatePointerScale()
        end)

        function pr:Think()
            if not IsValid(p) then
                frame:Close()
                return
            end
            if pr.p_pos ~= p:GetPos() or pr.p_ang ~= p:GetAngles() then
                RefreshRealCoords()
            end
            if pr.eyeang ~= LocalPlayer():EyeAngles() then
                pr.eyeang = LocalPlayer():EyeAngles()
                RefreshPlayerViewCoords()
            end
        end

        local inv = pr:CreateRow( "Actions", "Print" )
        inv:Setup( "Bool" )
        inv:SetValue(false)
        inv.DataChanged = function( _, val )
            inv:SetValue(false)
            net.Start("TARDIS-Pointer-Use")
                net.WriteEntity(p)
            net.SendToServer()
        end
    end

    net.Receive("TARDIS-Pointer-Debug", function()
        local p = net.ReadEntity()
        if not IsValid(p) then return end
        TARDIS:ShowPointerDebugMenu(p)
    end)
end

concommand.Add("tardis2_pointer_debug", function(ply,cmd,args)
    local pointer = ply.last_used_tardis_debug_pointer

    if IsValid(pointer) then
        net.Start("TARDIS-Pointer-Debug")
            net.WriteEntity(pointer)
        net.Send(ply)
    else
        ply:ChatPrint("No pointer found")
    end
end)