-- Scanner

local mat = CreateMaterial(
    "UnlitGeneric",
    "GMODScreenspace",
    {
        ["$basetexturetransform"] = "center .5 .5 scale -1 -1 rotate 0 translate 0 0",
        ["$texturealpha"] = "0",
        ["$vertexalpha"] = "1",
    }
)

local uid=0
TARDIS:AddScreen("Scanner", {id="scanner",text="Screens.Scanner", menu=false, order=3}, function(self,ext,int,frame,screen)
    screen.scanner=GetRenderTarget("tardisi_scanner_screen_"..uid.."_"..screen.id,
        screen.width*screen.res,
        screen.height*screen.res
    )
    uid=uid+1
    screen.scannerang=Angle()
    screen.scannerfov=120

    local scanner=vgui.Create("DImage",frame)
    scanner:SetSize(frame:GetWide(),frame:GetTall())
    scanner:SetMaterial(mat)
    scanner.OldPaint=scanner.Paint
    scanner.Paint=function()
        mat:SetTexture( "$basetexture", screen.scanner )
        scanner:OldPaint()
    end

    local label = vgui.Create("DLabel",frame)
    label:SetFont(TARDIS:GetScreenFont(screen, "Med"))
    label.DoLayout = function()
        label:SizeToContents()
        label:SetPos(frame:GetWide()/2-label:GetWide()/2-screen.gap,frame:GetTall()-label:GetTall()-screen.gap)
    end
    label:SetText(TARDIS:GetPhrase("Screens.Scanner.Front"))
    label:DoLayout()

    local function updatetext(y)
        local text
        if y==-180 or y==180 then
            text="Screens.Scanner.Back"
        elseif y==-90 then
            text="Screens.Scanner.Right"
        elseif y==0 then
            text="Screens.Scanner.Front"
        elseif y==90 then
            text="Screens.Scanner.Left"
        end
        label:SetText(TARDIS:GetPhrase(text))
        label:DoLayout()
    end


    if TARDIS:GetSetting("gui_old") then
        local back=vgui.Create("DButton",frame)
        back:SetSize(frame:GetTall()*0.2-screen.gap,frame:GetTall()*0.15-screen.gap)
        back:SetPos(screen.gap+1,frame:GetTall()-back:GetTall()-screen.gap-1)
        back:SetText("<")
        back:SetFont(TARDIS:GetScreenFont(screen, "Med"))
        back.DoClick = function()
            screen.scannerang.y=screen.scannerang.y+90
            if screen.scannerang.y>=180 then
                screen.scannerang.y=-180
            end
            updatetext(screen.scannerang.y)
        end

        local nxt=vgui.Create("DButton",frame)
        nxt:SetSize(frame:GetTall()*0.2-screen.gap,frame:GetTall()*0.15-screen.gap)
        nxt:SetPos(frame:GetWide()-nxt:GetWide()-screen.gap-1,frame:GetTall()-nxt:GetTall()-screen.gap-1)
        nxt:SetText(">")
        nxt:SetFont(TARDIS:GetScreenFont(screen, "Med"))
        nxt.DoClick = function()
            screen.scannerang.y=screen.scannerang.y-90
            if screen.scannerang.y<=-180 then
                screen.scannerang.y=180
            end
            updatetext(screen.scannerang.y)
        end
    else
        frame.left_arrow_func = function()
            screen.scannerang.y=screen.scannerang.y+90
            if screen.scannerang.y>=180 then
                screen.scannerang.y=-180
            end
            updatetext(screen.scannerang.y)
        end
        frame.right_arrow_func = function()
            screen.scannerang.y=screen.scannerang.y-90
            if screen.scannerang.y<=-180 then
                screen.scannerang.y=180
            end
            updatetext(screen.scannerang.y)
        end
    end
end)