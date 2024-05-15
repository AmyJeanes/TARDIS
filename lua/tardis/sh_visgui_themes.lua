TARDIS.gui_themes={}

local theme_basefolder = "materials/vgui/tardis-themes/"

function TARDIS:AddGUITheme(theme)
    self.gui_themes[theme.id] = table.Copy(theme)
    if theme.folder ~= nil then
        self.gui_themes[theme.id].folder = theme_basefolder .. theme.folder .. "/"
    end
end

TARDIS:LoadFolder("themes/visgui", nil, true)

function TARDIS:GetScreenGUITheme(screen)
    local setting = TARDIS:GetSetting("gui_interface_theme")
    if setting ~= "default_interior" then
        return setting
    end

    if screen.ext.metadata and screen.ext.metadata.Interior
        and screen.ext.metadata.Interior.UI_Theme
    then
        return screen.ext.metadata.Interior.UI_Theme
    end

    return "default"
end

function TARDIS:GetScreenGUIColor(screen, theme)
    if theme == nil then
        theme = self.gui_themes[TARDIS:GetScreenGUITheme(screen)]
    end
    if theme.bgcolor then
        return theme.bgcolor
    end
    if theme.base_id then
        return TARDIS:GetScreenGUIColor(screen, theme.base_id)
    end
    return Color(0,0,0,255)
end

function TARDIS:GetGUIThemes()
    return self.gui_themes
end

function TARDIS:GetGUITheme(id)
    return self.gui_themes[id]
end

function TARDIS:GetGUIThemeFolder(id)
    local theme = self.gui_themes[id]
    if not theme then
        return nil
    end
    if theme.folder then
        return theme.folder
    end
    if theme.base_id then
        return TARDIS:GetGUIThemeFolder(theme.base_id)
    end
    return nil
end

function TARDIS:GetGUIThemeElement(theme_id, section, element, no_defaults)
    if element == nil then
        return TARDIS:GetGUIThemeElement(theme_id, section, "default")
    end
    if theme_id == nil then
        error("Attempt to access theme without id")
    end
    local theme = self.gui_themes[theme_id]
    if theme == nil then
        error("Attempt to access non-existing theme: "..theme_id)
        return nil
    end
    if theme[section] == nil then
        if theme.base_id ~= nil then
            return TARDIS:GetGUIThemeElement(theme.base_id, section, element, no_defaults)
        else
            return nil
        end
    end
    if theme[section][element] ~= nil then
        local folder = TARDIS:GetGUIThemeFolder(theme_id)
        if folder == nil then
            error("Trying to open non-existing folder: "..folder)
        end
        if theme[section].subfolder ~= nil then
            folder = folder..theme[section].subfolder.."/"
        end
        local element = folder..theme[section][element]
        if file.Exists(element, "GAME") then
            return element
        end
    end
    if theme.base_id ~= nil then
        local inherited = TARDIS:GetGUIThemeElement(theme.base_id, section, element, true)
        if inherited then
            return inherited
        end
    end
    if not no_defaults then
        return TARDIS:GetGUIThemeElement(theme_id, section, "default", true)
    end
    return nil
end