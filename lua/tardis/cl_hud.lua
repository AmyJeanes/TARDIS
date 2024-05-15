-- HUD

local m, x_offset, y_offset, width, height, x, y, icon_size, number_offset

local function UpdateHudFont()
    surface.CreateFont("TARDIS-HUD", {
        font="HalfLife2",
        size= ScrH() / 15
    })

    surface.CreateFont("TARDIS-HUD-Glow", {
        font="HalfLife2",
        size = ScrH() / 15,
        scanlines = 3,
        antialias = true,
        additive = true,
        blursize = 6,
        weight = 10,
    })

    m = ScrH() / 1000 -- optimize calculations
    x_offset = 20 * m
    y_offset = 55 * m
    y_offset_2 = y_offset * 0.5
    y_offset_3 = y_offset * 0.27
    width = 165 * m
    height = 45 * m
    x = ScrW() * 0.02
    y = ScrH() * 0.025
    icon_size = 25 * m
    number_offset = 35 * m
end

hook.Add("OnScreenSizeChanged", "TARDIS-HUD", UpdateHudFont)

UpdateHudFont()

local fgcolor = NamedColor("FgColor")
local red = NamedColor("Caution")
local bgcolor = NamedColor("BgColor")
local deadtextcolor = Color(20, 20, 20, 210)
local deadheadcolor = Color(200, 200, 200, 200)
local health_icon = Material("vgui/tardis_health.png")
local energy_icon = Material("vgui/tardis_energy.png")
local shields_icon = Material("vgui/tardis_shields.png")

local function DrawNumber(icon_mat, value, x, y, bad_level, very_bad_level, dead_level)
    local dead = (dead_level ~= nil) and (value <= dead_level)

    local verybad = (very_bad_level ~= nil) and (value <= very_bad_level) and not dead
    local bad = verybad or ((bad_level ~= nil) and (value <= bad_level)) and not dead

    local textcolor = bad and red or fgcolor
    local alpha = 255

    if verybad then
        alpha = 255 * (0.6 + 0.1 * math.sin(CurTime() * 12))
    elseif bad then
        alpha = 200
    end

    textcolor = Color(textcolor.r, textcolor.g, textcolor.b, alpha)

    if dead then
        textcolor = deadtextcolor
    end

    surface.SetMaterial(icon_mat)
    surface.SetDrawColor(textcolor)

    surface.DrawTexturedRect( x, y + icon_size, icon_size, icon_size)

    draw.DrawText( tostring(value), "TARDIS-HUD", x + number_offset, y, textcolor, TEXT_ALIGN_LEFT)

    if verybad then
        draw.DrawText( tostring(value), "TARDIS-HUD-Glow", x + number_offset - 2, y - 2, textcolor, TEXT_ALIGN_LEFT)
    end
end

hook.Add("HUDPaint", "TARDIS-HUD", function()
    local ply = LocalPlayer()
    if ( GetConVarNumber( "cl_drawhud" ) == 0 ) then return end
    local tardis = ply:GetTardisData("exterior")
    if not IsValid(tardis) then return end

    local draw_health = TARDIS:GetSetting("health-enabled")
    local draw_artron = TARDIS:GetSetting("artron_energy") and tardis:IsAlive()
    local draw_shields = TARDIS:GetSetting("health-enabled") and tardis:GetShieldsOn()

    local count = 0
    if draw_health then count = count + 1 end
    if draw_artron then count = count + 1 end
    if draw_shields then count = count + 1 end
    if count == 0 then return end

    local yc = y

    draw.RoundedBox( 10, x, y, width, height + y_offset * count, bgcolor )
    local head_clr = tardis:IsAlive() and fgcolor or deadheadcolor
    draw.DrawText(TARDIS:GetPhrase("Common.TARDIS"), "HudDefault", x + x_offset, y + y_offset_3, head_clr, TEXT_ALIGN_LEFT )
    yc = yc + y_offset_2

    if draw_health then
        DrawNumber(health_icon, math.ceil(tardis:GetHealthPercent()), x + x_offset, yc, tardis.HEALTH_PERCENT_DAMAGED, tardis.HEALTH_PERCENT_BROKEN, 0)
        yc = yc + y_offset
    end
    if draw_shields then
        DrawNumber(shields_icon, math.ceil(tardis:GetShieldsPercent()), x + x_offset, yc, 10, 0)
        yc = yc + y_offset
    end
    if draw_artron then
        local artron_max = TARDIS:GetSetting("artron_energy_max")
        DrawNumber(energy_icon, math.ceil(tardis:GetArtron()), x + x_offset, yc, nil, artron_max * 0.1)
        yc = yc + y_offset
    end
end)

list.Set("DesktopWindows", "TardisHUD", {
    title = "TARDIS",
    icon = "materials/vgui/tardis_context_menu.png",
    init = function(icon, window)
        local ext = LocalPlayer():GetTardisData("exterior")
        if IsValid(ext) then
            TARDIS:HUDScreen(window)
        else
            TARDIS:ErrorMessage(LocalPlayer(), "Common.NotInTARDIS")
        end
    end
})

