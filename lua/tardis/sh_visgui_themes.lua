---@class tardis_gui_theme
---@field id string
---@field name string
---@field base_id string?
---@field bgcolor Color?
---@field folder string?
---@field frames table<string, string>?
---@field backgrounds table<string, string>?
---@field text_icons_off table<string, string>?
---@field text_icons_on table<string, string>?

---@type table<string, tardis_gui_theme>
TARDIS.gui_themes={}

local theme_basefolder = "materials/vgui/tardis-themes/"

-- Functionally identical to {} but gives proper type checking for GUI themes
---@return tardis_gui_theme
function TARDIS:NewGUITheme()
    return {}
end

function TARDIS:AddGUITheme(theme)
    ---@type tardis_gui_theme
    local copy = table.Copy(theme)
    self.gui_themes[theme.id] = copy
    if theme.folder ~= nil then
        copy.folder = theme_basefolder .. theme.folder .. "/"
    end
end

TARDIS:LoadFolder("themes/visgui", nil, true)

---@param screen TardisScreen
function TARDIS:GetScreenGUITheme(screen)
    local setting = TARDIS:GetSetting("gui_interface_theme")
    if setting ~= "default_interior" and self.gui_themes[setting] then
        return setting
    end

    local ext = screen.ext
    if ext and ext.metadata and ext.metadata.Interior
        and ext.metadata.Interior.UI_Theme
    then
        return ext.metadata.Interior.UI_Theme
    end

    return "default"
end

---@param screen TardisScreen
function TARDIS:GetScreenGUIColor(screen, theme)
    if theme == nil then
        theme = self.gui_themes[TARDIS:GetScreenGUITheme(screen)]
    end
    if not theme then return Color(0,0,0,255) end
    if theme.bgcolor then
        return theme.bgcolor
    end
    if theme.base_id then
        return TARDIS:GetScreenGUIColor(screen, theme.base_id)
    end
    return Color(0,0,0,255)
end

---@return table<string, tardis_gui_theme>
function TARDIS:GetGUIThemes()
    return self.gui_themes
end

---@return tardis_gui_theme?
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
        local element_path = folder..theme[section][element]
        if file.Exists(element_path, "GAME") then
            return element_path
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
