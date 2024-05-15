function TARDIS:GetCustomSettings(ent)
    return TARDIS:GetSetting("interior_custom_settings", ent) or {} -- nil is never allowed
end

function TARDIS:SetupCustomSettings(int_id)
    local csettings = {}

    local t = self.MetadataRaw[int_id]

    if t.CustomSettings then
        table.Merge(csettings, t.CustomSettings)
    end

    if t.Templates then
        for template_id, template in pairs(t.Templates) do
            if template and self.MetadataTemplates[template_id] and self.MetadataTemplates[template_id].CustomSettings then
                table.Merge(csettings, self.MetadataTemplates[template_id].CustomSettings)
            end
        end
    end

    self.IntCustomSettings[int_id] = csettings
end

local default_custom_setting_values = {
    ["preferred_door_type"] = "default",
    ["exterior_enabled"] = false,
    ["exterior_default"] = "ttcapsule_type40",
}

function TARDIS:GetCustomSetting(int_id, setting_id, ent, default_val)
    local int_id = self:GetMainVersionId(int_id)

    local custom_settings = self:GetCustomSettings(ent)
    local settings = custom_settings[int_id]
    if settings and settings[setting_id] ~= nil then
        return settings[setting_id]
    end

    if setting_id == "preferred_version" then
        return self:DefaultPreferredVersion(int_id)
    end

    for k,v in pairs(default_custom_setting_values) do
        if setting_id == k then
            return v
        end
    end

    -- getting the default setting value from metadata
    local md_settings = self.IntCustomSettings[int_id]
    if md_settings and md_settings[setting_id] and md_settings[setting_id].value ~= nil then
        local metadata_value = md_settings[setting_id].value
        return metadata_value
    end

    return default_val
end

if CLIENT then
    function TARDIS:SaveCustomSettings(settings)
        TARDIS:SetSetting("interior_custom_settings", settings)
    end

    function TARDIS:SetCustomSetting(int_id, setting_id, value)
        local int_id = self:GetMainVersionId(int_id)

        local custom_settings = self:GetCustomSettings(LocalPlayer())
        custom_settings[int_id] = custom_settings[int_id] or {}
        custom_settings[int_id][setting_id] = value
        self:SaveCustomSettings(custom_settings)
    end

    function TARDIS:ResetCustomSettings(int_id)
        local int_id = self:GetMainVersionId(int_id)

        if int_id == nil then
            self:SaveCustomSettings({})
            return
        end

        local custom_settings = self:GetCustomSettings(LocalPlayer())
        custom_settings[int_id] = {}
        self:SaveCustomSettings(custom_settings)
    end

    function TARDIS:ToggleCustomSetting(int_id, setting_id)
        local value = TARDIS:GetCustomSetting(int_id, setting_id, ent)
        TARDIS:SetCustomSetting(int_id, setting_id, (not value))
    end
end

----------------------------------------------------------------------------------------------------
-- Favorites

function TARDIS:IsFavoriteInt(id, ent)
    return self:GetCustomSetting(id, "is_favorite", ent, false)
end

if CLIENT then
    function TARDIS:SetFavoriteInt(id, favorite)
        self:SetCustomSetting(id, "is_favorite", favorite, ent)
    end

    function TARDIS:ToggleFavoriteInt(id)
        self:ToggleCustomSetting(id, "is_favorite")
    end
end

TARDIS:LoadInteriors()