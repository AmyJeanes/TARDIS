-- Music

--Custom music

local custom_music
local MUSIC_FILE = "tardis2_custom_music.txt"

function TARDIS:LoadCustomMusic()
    if file.Exists(MUSIC_FILE,"DATA") then
        custom_music = TARDIS.von.deserialize(file.Read(MUSIC_FILE,"DATA"))
    else
        custom_music = {}
    end
end

TARDIS:LoadCustomMusic()

function TARDIS:SaveCustomMusic()
    file.Write(MUSIC_FILE, TARDIS.von.serialize(custom_music))
end

--[[ TODO: Add back in before release
TARDIS:AddMigration("music-move", "2023.8.0", function(self)
    if file.Exists("tardis2_custom_music.txt", "DATA") then
        if file.Exists(MUSIC_FILE, "DATA") then
            file.Delete(MUSIC_FILE)
        end
        file.Rename("tardis2_custom_music.txt", MUSIC_FILE)
        self:LoadCustomMusic()
    end
end)
]]

function TARDIS:AddCustomMusic(name, url)
    if name == nil or name == "" then
        TARDIS:ErrorMessage(LocalPlayer(), "Screens.Music.MissingName")
        return
    end
    if url == nil or url == "" then
        TARDIS:ErrorMessage(LocalPlayer(), "Screens.Music.MissingUrl")
        return
    end

    for k,v in pairs(custom_music) do
        if v[1] == name then
            TARDIS:ErrorMessage(LocalPlayer(), "Screens.Music.Conflict")
            return
        end
    end

    local next = table.insert(custom_music,{name, url})
    TARDIS:Message(LocalPlayer(), "Screens.Music.CustomAdded", name, url)
    TARDIS:SaveCustomMusic()
end

function TARDIS:RemoveCustomMusic(index)
    TARDIS:Message(LocalPlayer(), "Screens.Music.CustomRemoved", custom_music[index][1], custom_music[index][2])
    table.remove(custom_music, index)
    TARDIS:SaveCustomMusic()
end


-- Music GUI
TARDIS:AddScreen("Music", {id="music", text="Screens.Music", menu=false, order=10, popuponly=false}, function(self,ext,int,frame,screen)
--------------------------------------------------------------------------------
-- Layout calculations
--------------------------------------------------------------------------------
    local frW = frame:GetWide()
    local frT = frame:GetTall()

    local gap = math.min(frT, frW) * 0.06
    local gap2 = math.min(frT, frW) * 0.02

    local listW = frW * 0.3
    local listT = frT - 2 * gap
    local tbW = frW - 4 * gap - 2 * listW - 2 * gap2
    local tbT = frT * 0.1
    local bW = 0.5 * (tbW - gap2)
    local bT = frT * 0.1

    local midX = 3 * gap + 2 * listW

--------------------------------------------------------------------------------
-- Layout
--------------------------------------------------------------------------------
    local background=vgui.Create("DImage", frame)
    local theme = TARDIS:GetScreenGUITheme(screen)
    local background_img = TARDIS:GetGUIThemeElement(theme, "backgrounds", "music")
    background:SetImage(background_img)
    background:SetSize(frW, frT)
    local bgcolor = TARDIS:GetScreenGUIColor(screen)

    local list_premade
    local list_custom

    if screen.is3D2D then
        list_premade = ListView3D:new(frame,screen,34,bgcolor)
        list_custom = ListView3D:new(frame,screen,34,bgcolor)
    else
        list_premade = vgui.Create("DListView",frame)
        list_custom = vgui.Create("DListView",frame)
    end


    list_premade:SetSize(listW, listT)
    list_premade:SetPos(gap, gap)
    list_premade:AddColumn(TARDIS:GetPhrase("Screens.Music.DefaultMusic"))
    list_premade:SetMultiSelect(false)

    list_custom:SetSize(listW, listT)
    list_custom:SetPos(2 * gap + listW, gap)
    list_custom:AddColumn(TARDIS:GetPhrase("Screens.Music.CustomMusic"))
    list_custom:SetMultiSelect(false)

    local panel = vgui.Create( "DPanel", frame )
    panel:SetSize(tbW + 2 * gap2, listT)
    panel:SetPos(midX, gap)
    panel:SetBackgroundColor(bgcolor)

    local url_bar = vgui.Create( "DTextEntry3D2D", panel )
    url_bar.is3D2D = screen.is3D2D
    url_bar:SetPlaceholderText(TARDIS:GetPhrase("Screens.Music.UrlPlaceholder"))
    url_bar:SetFont(TARDIS:GetScreenFont(screen, "Default"))
    url_bar:SetSize(tbW, tbT)
    url_bar:SetPos(gap2, gap2)

    local name_bar = vgui.Create( "DTextEntry3D2D", panel )
    name_bar.is3D2D = screen.is3D2D
    name_bar:SetPlaceholderText(TARDIS:GetPhrase("Screens.Music.NamePlaceholder"))
    name_bar:SetFont(TARDIS:GetScreenFont(screen, "Default"))
    name_bar:SetSize(tbW, tbT)
    name_bar:SetPos(gap2, 2 * gap2 + tbT)

    local play_stop_button=vgui.Create("DButton", panel)
    play_stop_button:SetSize(tbW, bT * 1.3)
    play_stop_button:SetPos(gap2, listT - gap2 - bT * 1.3)
    play_stop_button:SetText(TARDIS:GetPhrase("Screens.Music.PlayStop"))
    play_stop_button:SetFont(TARDIS:GetScreenFont(screen, "Default"))

    local save_custom_button=vgui.Create("DButton", panel)
    save_custom_button:SetSize(bW, bT)
    save_custom_button:SetPos(gap2, 3 * gap2 + 2 * tbT)
    save_custom_button:SetText(TARDIS:GetPhrase("Common.Save"))
    save_custom_button:SetFont(TARDIS:GetScreenFont(screen, "Default"))

    local remove_custom_button=vgui.Create("DButton",panel)
    remove_custom_button:SetSize(bW, bT)
    remove_custom_button:SetPos(2 * gap2 + bW, 3 * gap2 + 2 * tbT)
    remove_custom_button:SetText(TARDIS:GetPhrase("Common.Remove"))
    remove_custom_button:SetFont(TARDIS:GetScreenFont(screen, "Default"))

    if not screen.is3D2D then
        local el1,el2 = TARDIS:CreateOptionInterface("music-volume", TARDIS:GetSettingData("music-volume"))
        local volume_setting = vgui.Create("DPanel",panel)
        volume_setting:SetPos(gap2, 4 * gap2 + 3 * tbT)
        volume_setting:SetSize(tbW, el1:GetTall() + el2:GetTall() + 3 * gap2)

        el1:SetParent(volume_setting)
        el2:SetParent(volume_setting)
        el2:SetWide(tbW)

        el1:SetPos(gap2, gap2)
        el2:SetPos(gap2, 2 * gap2 + el1:GetTall())
    end

--------------------------------------------------------------------------------
-- Loading data
--------------------------------------------------------------------------------
    local url = ""
    local default_music = {}

    list_premade:AddLine(TARDIS:GetPhrase("Common.Loading"))
    list_premade.loading = true

    http.Fetch("https://cdn.mattjeanes.com/tardis/music.json", function(body)
        default_music = util.JSONToTable(body)
        list_premade:Clear()
        if default_music == nil then
            default_music = {}
            TARDIS:ErrorMessage(LocalPlayer(), "Screens.Music.DefaultLoadError", "Screens.Music.UnableToDecodeList")
            list_premade:AddLine(TARDIS:GetPhrase("Screens.Music.DefaultLoadError", "Screens.Music.UnableToDecodeList"))
        else
            for k,v in pairs(default_music) do
                list_premade:AddLine(v[1])
            end
            list_premade.loading = false
        end
    end, function(error)
        TARDIS:ErrorMessage(LocalPlayer(), "Screens.Music.DefaultLoadError", error)
        list_premade:Clear()
        list_premade:AddLine(TARDIS:GetPhrase("Screens.Music.DefaultLoadError", "Screens.Music.UnableToDecodeList"))
    end)

    function list_custom:UpdateAll()
        self:Clear()
        if url_bar ~= nil then
            for k,v in pairs(custom_music) do
                self:AddLine(v[1])
            end
        end
    end

    list_custom:UpdateAll()

--------------------------------------------------------------------------------
-- Selecting the rows
--------------------------------------------------------------------------------

    function list_custom:OnRowSelected(rowIndex,row)
        list_premade:ClearSelection()
        url_bar:SetText(custom_music[rowIndex][2])
        name_bar:SetText(custom_music[rowIndex][1])
        url_bar:SetTextColor(Color(0,0,0))
        name_bar:SetTextColor(Color(0,0,0))
    end

    function list_custom:DoDoubleClick(rowIndex, row)
        ext:PlayMusic(custom_music[rowIndex][2])
        list_custom:ClearSelection()
    end

    function list_premade:OnRowSelected(rowIndex, row)
        if list_premade.loading then return end
        list_custom:ClearSelection()
        url = "https://cdn.mattjeanes.com/tardis/" .. default_music[rowIndex][2] ..".mp3"
        url_bar:SetTextColor(Color(139,139,139))
        name_bar:SetTextColor(Color(139,139,139))
    end

    function list_premade:DoDoubleClick(rowIndex, row)
        if list_premade.loading then return end
        ext:PlayMusic("https://cdn.mattjeanes.com/tardis/" .. default_music[rowIndex][2] ..".mp3")
        list_premade:ClearSelection()
    end

    local function highlight_custom()
        url_bar:SetTextColor(Color(0,0,0))
        name_bar:SetTextColor(Color(0,0,0))
        list_premade:ClearSelection()
        list_custom:ClearSelection()
    end

    function url_bar:OnGetFocus()
        highlight_custom()
    end
    function url_bar:OnValueChange()
        highlight_custom()
    end
    function name_bar:OnGetFocus()
        highlight_custom()
    end
    function name_bar:OnValueChange()
        highlight_custom()
    end

--------------------------------------------------------------------------------
-- Add / remove custom music
--------------------------------------------------------------------------------

    function name_bar:OnEnter()
        if screen.is3D2D then return end
        TARDIS:AddCustomMusic(name_bar:GetText(), url_bar:GetText())
        list_custom:UpdateAll()
    end

    function save_custom_button:DoClick()
        TARDIS:AddCustomMusic(name_bar:GetText(), url_bar:GetText())
        list_custom:UpdateAll()
    end

    function remove_custom_button:DoClick()
        local line = list_custom:GetSelectedLine()
        if not line then
            if list_premade:GetSelectedLine() then
                TARDIS:ErrorMessage(LocalPlayer(), "Screens.Music.CannotRemoveDefault")
            else
                TARDIS:ErrorMessage(LocalPlayer(), "Screens.Music.DeleteNoSelection")
            end
            return
        end

        Derma_Query(TARDIS:GetPhrase("Screens.Music.DeleteConfirm", custom_music[line][1]),
                    TARDIS:GetPhrase("Common.Interface"),
                    TARDIS:GetPhrase("Common.Yes"),
                    function()
                        TARDIS:RemoveCustomMusic(line)
                        list_custom:UpdateAll()
                    end,
                    TARDIS:GetPhrase("Common.No"),
                    function()
                    end):SetSkin("TARDIS")
    end

--------------------------------------------------------------------------------
-- Play music
--------------------------------------------------------------------------------

    function url_bar:OnEnter()
        if screen.is3D2D then return end
        if play_stop_button.disabled_time then return end
        ext:PlayMusic(url_bar:GetValue())
        play_stop_button:SetEnabled(false)
        play_stop_button.disabled_time = CurTime()
    end

    function play_stop_button:DoClick()
        if IsValid(ext.music) and ext.music:GetState()==GMOD_CHANNEL_PLAYING
            and not (list_premade:GetSelectedLine() or list_custom:GetSelectedLine())
        then
            ext:StopMusic(true)
        else
            if list_premade:GetSelectedLine() then
                ext:PlayMusic(url)
            elseif string.len(url_bar:GetValue())>0 then
                ext:PlayMusic(url_bar:GetValue())
            else
                TARDIS:ErrorMessage(LocalPlayer(), "Screens.Music.NoChoice")
                return
            end
            list_premade:ClearSelection()
            list_custom:ClearSelection()
            self:SetEnabled(false)
            self.disabled_time = CurTime()
        end
    end
    function play_stop_button:Think()
        if self.disabled_time and CurTime() - self.disabled_time > 3 then
            self.disabled_time = nil
            self:SetEnabled(true)
        end
    end

end)