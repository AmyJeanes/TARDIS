-- Music

--Custom music

local custom_music
local favourite_music
local CUSTOM_MUSIC_FILE = "tardis/custom_music.txt"
local FAVOURITE_MUSIC_FILE = "tardis/favourite_music.txt"

function TARDIS:LoadCustomMusic()
    if file.Exists(CUSTOM_MUSIC_FILE,"DATA") then
        custom_music = TARDIS.von.deserialize(file.Read(CUSTOM_MUSIC_FILE,"DATA"))
    else
        custom_music = {}
    end
end

function TARDIS:LoadFavouriteMusic()
    if file.Exists(FAVOURITE_MUSIC_FILE, "DATA") then
        favourite_music = TARDIS.von.deserialize(file.Read(FAVOURITE_MUSIC_FILE, "DATA"))
    else
        favourite_music = {}
    end
end

function TARDIS:SaveCustomMusic()
    file.Write(CUSTOM_MUSIC_FILE, TARDIS.von.serialize(custom_music))
end

function TARDIS:SaveFavouriteMusic()
    file.Write(FAVOURITE_MUSIC_FILE, TARDIS.von.serialize(favourite_music))
end

TARDIS:LoadCustomMusic()
TARDIS:LoadFavouriteMusic()

TARDIS:AddMigration("music-move", "2025.2.0", function(self)
    if file.Exists("tardis2_custom_music.txt", "DATA") then
        if file.Exists(CUSTOM_MUSIC_FILE, "DATA") then
            file.Delete(CUSTOM_MUSIC_FILE)
        end
        file.Rename("tardis2_custom_music.txt", CUSTOM_MUSIC_FILE)
        self:LoadCustomMusic()
    end
end)

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

    local categories = {}
    local list_categories
    local list_songs
    local default_song_lookup = {}

    if screen.is3D2D then
        list_categories = ListView3D:new(frame,screen,34,bgcolor)
        list_songs = ListView3D:new(frame,screen,34,bgcolor)
    else
        list_categories = vgui.Create("DListView",frame)
        list_songs = vgui.Create("DListView",frame)
    end

    list_categories:SetSize(listW, listT)
    list_categories:SetPos(gap, gap)
    list_categories:SetSortable(false)
    list_categories:AddColumn(TARDIS:GetPhrase("Screens.Music.Categories"))
    list_categories:SetMultiSelect(false)

    list_songs:SetSize(listW, listT)
    list_songs:SetPos(2 * gap + listW, gap)
    list_songs:SetSortable(false)
    list_songs:AddColumn(TARDIS:GetPhrase("Screens.Music.Songs"))
    list_songs:SetMultiSelect(false)

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

    if not screen.is3D2D then
        local el1,el2 = TARDIS:CreateOptionInterface("music-volume", TARDIS:GetSettingData("music-volume"))
        local volume_setting = vgui.Create("DPanel",panel)
        volume_setting:SetPos(gap2, 10 * gap2 + 3 * tbT)
        volume_setting:SetSize(tbW, el1:GetTall() + el2:GetTall() + 3 * gap2)

        el1:SetParent(volume_setting)
        el2:SetParent(volume_setting)
        el2:SetWide(tbW)

        el1:SetPos(gap2, gap2)
        el2:SetPos(gap2, 2 * gap2 + el1:GetTall())
    end

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

    local add_remove_fav_button = vgui.Create("DButton", panel)
    add_remove_fav_button:SetSize(tbW, bT)
    add_remove_fav_button:SetPos(gap2, 4 * gap2 + 2 * tbT + bT)
    add_remove_fav_button:SetText(TARDIS:GetPhrase("Common.AddToFavourites"))
    add_remove_fav_button:SetFont(TARDIS:GetScreenFont(screen, "Default"))
    add_remove_fav_button:SetEnabled(false)
    function add_remove_fav_button:DoClick()
        local sel_cat = list_categories:GetSelectedLine()
        if not sel_cat then return end
        local cat = categories[sel_cat]
        local sel_song = list_songs:GetSelectedLine()
        if not sel_song then return end
        if cat.id == "favourites" then
            -- Remove from favourites
            table.remove(favourite_music, sel_song)
            TARDIS:SaveFavouriteMusic()
            list_songs:UpdateFavouriteSongs()
            add_remove_fav_button:SetEnabled(false)
        elseif cat.id ~= "custom" then
            -- Add to favourites if not already
            local song = cat.songs[sel_song]
            if song and not table.HasValue(favourite_music, song.id) then
                table.insert(favourite_music, song.id)
                TARDIS:SaveFavouriteMusic()
                add_remove_fav_button:SetEnabled(false)
            end
        end
    end

--------------------------------------------------------------------------------
-- Loading data
--------------------------------------------------------------------------------
    local url = ""
    local default_music = {}
    local urls = {}

    list_categories:AddLine(TARDIS:GetPhrase("Common.Loading"))
    list_categories.loading = true

    http.Fetch("https://cdn.mattjeanes.com/tardis/songs.json", function(body)
        if not list_categories then return end
        default_music = util.JSONToTable(body)
        list_categories:Clear()
        categories = {}
        default_song_lookup = {}
        if default_music ~= nil then
            -- Build lookup for song id -> song
            for _,catObj in ipairs(default_music) do
                for _,song in ipairs(catObj.songs) do
                    default_song_lookup[song.id] = {cat=catObj, song=song}
                end
            end
            -- Remove any favourites that no longer exist
            local valid_favourite_music = {}
            for _,id in ipairs(favourite_music) do
                if default_song_lookup[id] then
                    table.insert(valid_favourite_music, id)
                end
            end
            if #valid_favourite_music ~= #favourite_music then
                favourite_music = valid_favourite_music
                TARDIS:SaveFavouriteMusic()
            end
            -- Insert Favourites category at the top
            table.insert(categories, {id = "favourites", name = TARDIS:GetPhrase("Common.Favourites"), songs = {}})
            for _,catObj in ipairs(default_music) do
                table.insert(categories, catObj)
            end
        else
            TARDIS:ErrorMessage(LocalPlayer(), "Screens.Music.DefaultLoadError", "Screens.Music.DefaultLoadError.InvalidJson")
        end
        table.insert(categories, {id = "custom", name = TARDIS:GetPhrase("Screens.Music.CustomMusic"), songs = {}})
        for _,cat in ipairs(categories) do
            list_categories:AddLine(cat.name)
        end
        list_categories.loading = false
        list_categories:SelectFirstItem()
    end, function(error)
        TARDIS:ErrorMessage(LocalPlayer(), "Screens.Music.DefaultLoadError", error)
        list_categories:Clear()
        categories = {}
        table.insert(categories, {id = "custom", name = TARDIS:GetPhrase("Screens.Music.CustomMusic"), songs = {}})
        for _,cat in ipairs(categories) do
            list_categories:AddLine(cat.name)
        end
        list_categories.loading = false
        list_categories:SelectFirstItem()
    end)

    function list_songs:UpdateCustomSongs()
        local sel = list_categories:GetSelectedLine()
        if not sel then return end
        if categories[sel].id ~= "custom" then
            return
        end
        self:Clear()
        urls = {}
        for k,v in pairs(custom_music) do
            self:AddLine(v[1])
            table.insert(urls, v[2])
        end
    end

    function list_songs:UpdateFavouriteSongs()
        self:Clear()
        urls = {}
        for _,id in ipairs(favourite_music) do
            local entry = default_song_lookup[id]
            if entry then
                self:AddLine(entry.song.name)
                table.insert(urls, "https://cdn.mattjeanes.com/tardis/"..entry.song.id..".mp3")
            end
        end
    end

--------------------------------------------------------------------------------
-- Selecting the rows
--------------------------------------------------------------------------------

    function list_songs:OnRowSelected(rowIndex,row)
        local sel = list_categories:GetSelectedLine()
        if not sel then return end
        local cat = categories[sel]
        if cat.id == "custom" then
            url_bar:SetText(custom_music[rowIndex][2])
            name_bar:SetText(custom_music[rowIndex][1])
        end
        url = urls[rowIndex]
        if cat.id == "favourites" then
            add_remove_fav_button:SetEnabled(true)
            add_remove_fav_button:SetText(TARDIS:GetPhrase("Common.RemoveFromFavourites"))
        elseif cat.id ~= "custom" then
            local song = cat.songs[rowIndex]
            if song and not table.HasValue(favourite_music, song.id) then
                add_remove_fav_button:SetEnabled(true)
                add_remove_fav_button:SetText(TARDIS:GetPhrase("Common.AddToFavourites"))
            else
                add_remove_fav_button:SetEnabled(false)
                add_remove_fav_button:SetText(TARDIS:GetPhrase("Common.AddToFavourites"))
            end
        else
            add_remove_fav_button:SetEnabled(false)
            add_remove_fav_button:SetText(TARDIS:GetPhrase("Common.AddToFavourites"))
        end
    end

    function list_songs:DoDoubleClick(rowIndex,row)
        local sel = list_categories:GetSelectedLine()
        if not sel then return end
        local cat = categories[sel]
        ext:PlayMusic(urls[rowIndex])
        list_songs:ClearSelection()
        add_remove_fav_button:SetEnabled(false)
        url = ""
    end

    function list_categories:OnRowSelected(rowIndex,row)
        if list_categories.loading then return end
        list_songs:Clear()
        url = ""
        url_bar:SetText("")
        name_bar:SetText("")
        local cat = categories[rowIndex]
        urls = {}
        add_remove_fav_button:SetEnabled(false)
        if cat.id == "custom" then
            for _,v in ipairs(custom_music) do list_songs:AddLine(v[1]) table.insert(urls, v[2]) end
            url_bar:SetEnabled(true)
            name_bar:SetEnabled(true)
            save_custom_button:SetEnabled(true)
            remove_custom_button:SetEnabled(true)
            add_remove_fav_button:SetEnabled(false)
            add_remove_fav_button:SetText(TARDIS:GetPhrase("Common.AddToFavourites"))
        elseif cat.id == "favourites" then
            list_songs:UpdateFavouriteSongs()
            url_bar:SetEnabled(false)
            name_bar:SetEnabled(false)
            save_custom_button:SetEnabled(false)
            remove_custom_button:SetEnabled(false)
            add_remove_fav_button:SetEnabled(false)
            add_remove_fav_button:SetText(TARDIS:GetPhrase("Common.RemoveFromFavourites"))
        else
            for _,song in ipairs(cat.songs or {}) do
                list_songs:AddLine(song.name)
                table.insert(urls, "https://cdn.mattjeanes.com/tardis/"..song.id..".mp3")
            end
            url_bar:SetEnabled(false)
            name_bar:SetEnabled(false)
            save_custom_button:SetEnabled(false)
            remove_custom_button:SetEnabled(false)
            add_remove_fav_button:SetEnabled(false)
            add_remove_fav_button:SetText(TARDIS:GetPhrase("Common.AddToFavourites"))
        end
    end

    function list_categories:DoDoubleClick(rowIndex,row)
        -- no-op: use right list for song selection
    end

--------------------------------------------------------------------------------
-- Add / remove custom music
--------------------------------------------------------------------------------

    function name_bar:OnEnter()
        if screen.is3D2D then return end
        TARDIS:AddCustomMusic(name_bar:GetText(), url_bar:GetText())
        list_songs:UpdateCustomSongs()
    end

    function save_custom_button:DoClick()
        TARDIS:AddCustomMusic(name_bar:GetText(), url_bar:GetText())
        list_songs:UpdateCustomSongs()
    end

    function remove_custom_button:DoClick()
        local line = list_songs:GetSelectedLine()
        if not line then
            TARDIS:ErrorMessage(LocalPlayer(), "Screens.Music.DeleteNoSelection")
            return
        end

        Derma_Query(TARDIS:GetPhrase("Screens.Music.DeleteConfirm", custom_music[line][1]),
                    TARDIS:GetPhrase("Common.Interface"),
                    TARDIS:GetPhrase("Common.Yes"),
                    function()
                        TARDIS:RemoveCustomMusic(line)
                        list_songs:UpdateCustomSongs()
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
        if IsValid(ext.music) and ext.music:GetState()==GMOD_CHANNEL_PLAYING and not list_songs:GetSelectedLine() then
            ext:StopMusic(true)
        else
            if url~=nil and url~="" then
                ext:PlayMusic(url)
            elseif string.len(url_bar:GetValue())>0 then
                ext:PlayMusic(url_bar:GetValue())
            else
                TARDIS:ErrorMessage(LocalPlayer(), "Screens.Music.NoChoice")
                return
            end
            list_songs:ClearSelection()
            add_remove_fav_button:SetEnabled(false)
            url = ""
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