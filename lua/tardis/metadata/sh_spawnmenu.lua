function TARDIS:SpawnByID(id)
    RunConsoleCommand("tardis2_spawn", id)
    surface.PlaySound("ui/buttonclickrelease.wav")
end

TARDIS.InteriorIcons = TARDIS.InteriorIcons or {}

list.Set( "ContentCategoryIcons", "#TARDIS.Spawnmenu.Category", "vgui/tardis_icon.png" )
list.Set( "ContentCategoryIcons", "#TARDIS.Spawnmenu.CategoryTools", "vgui/tardis_icon.png" )

if CLIENT then

    -- this option would be very useful for developers but noone else
    CreateClientConVar("tardis2_spawnmenu_copy_id", 0, {FCVAR_ARCHIVE}, "TARDIS - show 'copy id' option in the spawnmenu")
    TARDIS.spawnmenu_copy_id = GetConVar("tardis2_spawnmenu_copy_id"):GetBool()

    hook.Add("OnSpawnMenuOpen", "tardis-spawnmenu-copy-id-setting", function(ply,ent)
        TARDIS.spawnmenu_copy_id = GetConVar("tardis2_spawnmenu_copy_id"):GetBool()
    end)

    function TARDIS:SelectForRedecoration(id)
        TARDIS:SetSetting("redecorate-interior", id)
        local current_tardis = LocalPlayer():GetTardisData("exterior")

        if not current_tardis or not current_tardis:GetData("redecorate") then
            TARDIS:Message(LocalPlayer(), "Spawnmenu.RedecorationSelected")
        else
            TARDIS:Message(LocalPlayer(), "Spawnmenu.RedecorationSelectedRestart")
        end
    end

    TARDIS.Spawnmenu = {}

    function TARDIS.Spawnmenu.AddLabel(dmenu, text)
        local label = vgui.Create("DLabel", dmenu)
        label:SetText("  " .. TARDIS:GetPhrase(text))
        label:SetTextColor(Color(0,0,0))
        dmenu:AddPanel(label)
    end

    function TARDIS.Spawnmenu.AddSingleVersion(dmenu, id)
        if TARDIS.spawnmenu_copy_id then
            local copy = dmenu:AddOption("#spawnmenu.menu.copy", function()
                SetClipboardText(id)
            end)
            copy:SetIcon("icon16/page_copy.png")
        end

        local spawn = dmenu:AddOption(TARDIS:GetPhrase("Spawnmenu.Spawn"), function()
            TARDIS:SpawnByID(id)
        end)
        spawn:SetIcon("icon16/add.png")

        local select_redecoration = dmenu:AddOption(TARDIS:GetPhrase("Spawnmenu.SelectForRedecoration"), function()
            TARDIS:SelectForRedecoration(id)
        end)
        select_redecoration:SetIcon("icon16/color_wheel.png")

        local spawn_toolgun = dmenu:AddOption("#spawnmenu.menu.spawn_with_toolgun", function()
            RunConsoleCommand( "gmod_tool", "creator" )
            RunConsoleCommand( "creator_type", "0" )
            RunConsoleCommand( "creator_name", "gmod_tardis" )
            RunConsoleCommand( "tardis2_selected_interior", id)
        end)
        spawn_toolgun:SetIcon("icon16/brick_add.png")
    end

    function TARDIS.Spawnmenu.AddDoubleVersion(dmenu, classic_doors_id, double_doors_id)
        TARDIS.Spawnmenu.AddLabel(dmenu, "Spawnmenu.ClassicDoorsVersion")
        TARDIS.Spawnmenu.AddSingleVersion(dmenu, classic_doors_id)

        dmenu:AddSpacer()

        TARDIS.Spawnmenu.AddLabel(dmenu, "Spawnmenu.DoubleDoorsVersion")
        TARDIS.Spawnmenu.AddSingleVersion(dmenu, double_doors_id)
    end

    function TARDIS.Spawnmenu.AddVersion(dmenu, version)
        if version.classic_doors_id then
            TARDIS.Spawnmenu.AddDoubleVersion(dmenu, version.classic_doors_id, version.double_doors_id)
        else
            TARDIS.Spawnmenu.AddSingleVersion(dmenu, version.id)
        end
        dmenu:AddSpacer()
    end

    function TARDIS.Spawnmenu.AddVersionSubMenu(dmenu, version)
        if not version or not version.name then return end

        local submenu = dmenu:AddSubMenu(TARDIS:GetPhrase(version.name), function()
            TARDIS:SpawnByID( TARDIS:SelectDoorVersionID(version, LocalPlayer()) )
        end)
        TARDIS.Spawnmenu.AddVersion(submenu, version)

        return submenu
    end

    function TARDIS.Spawnmenu.AddBoolSetting(dmenu, int_id, setting_id, name)
        local setting_button = dmenu:AddOption(TARDIS:GetPhrase(name), function(self)
            TARDIS:ToggleCustomSetting(int_id, setting_id)
        end)
        setting_button:SetIsCheckable(true)

        function setting_button:Think()
            local value = TARDIS:GetCustomSetting(int_id, setting_id, LocalPlayer(), false)
            if self:GetChecked() ~= value then
                self:SetChecked(value)
            end
        end

        return setting_button
    end

    function TARDIS.Spawnmenu.AddListSetting(dmenu, int_id, setting_id, name, options, compare_func)
        local submenu = dmenu:AddSubMenu(TARDIS:GetPhrase(name), nil)

        local option_buttons = {}

        if not options then return end
        for option_value, option_text in SortedPairsByValue(options) do

            local option_button = submenu:AddOption(TARDIS:GetPhrase(option_text), function(self)
                TARDIS:SetCustomSetting(int_id, setting_id, option_value)
            end)
            option_button:SetIsCheckable(true)

            table.insert(option_buttons, {option_value, option_button})
        end

        function submenu:Think()
            local value = TARDIS:GetCustomSetting(int_id, setting_id, LocalPlayer())
            for i,v in ipairs(option_buttons) do
                local checked = (value == v[1])
                if compare_func then
                    checked = compare_func(value, v[1])
                end
                v[2]:SetChecked(checked)
            end
        end

    end

    function TARDIS.Spawnmenu.AddChameleonSetting(parent, int_id)
        local exterior_setting_submenu = parent:AddSubMenu(TARDIS:GetPhrase("Spawnmenu.Chameleon"), nil)

        TARDIS.Spawnmenu.AddBoolSetting(exterior_setting_submenu, int_id, "exterior_enabled", "Spawnmenu.Chameleon.Enable")

        for category,exteriors in pairs(TARDIS:GetExteriorCategories()) do
            if not table.IsEmpty(exteriors) then
                local exteriors_tbl = {}
                for id,v in pairs(exteriors) do
                    local ext_md = TARDIS:GetExteriors()[id]
                    if v and ext_md.Base ~= true and ext_md.Hide ~= true then
                        exteriors_tbl[id] = TARDIS:GetPhrase(ext_md.Name or id)
                    end
                end
                TARDIS.Spawnmenu.AddListSetting(exterior_setting_submenu, int_id, "exterior_default", TARDIS:GetPhrase(category), exteriors_tbl)
            end
        end
    end

    function TARDIS.Spawnmenu.AddSettings(parent, int_id)
        local int_id = TARDIS:GetMainVersionId(int_id)

        local versions = TARDIS.MetadataVersions[int_id]
        local custom_settings = TARDIS.IntCustomSettings[int_id]

        local other_versions_exist = not table.IsEmpty(versions.other)
        local custom_versions_exist = not table.IsEmpty(versions.custom)

        local versions_exist = other_versions_exist or custom_versions_exist
        local dmenu = parent:AddSubMenu(TARDIS:GetPhrase("Spawnmenu.Settings"), nil)

        if versions_exist then

            local option_versions = {}

            local function add_version_option(option_name, option_id, order)
                local prefixes = { "  ", "  ", "  ", "  " } -- spaces are different symbols
                option_versions[option_id] = prefixes[order] .. TARDIS:GetPhrase(option_name)
            end

            add_version_option("Spawnmenu.VersionOptions.Default", "main", 1)

            if other_versions_exist then
                add_version_option("Spawnmenu.VersionOptions.Random", "random", 2)
            end
            if custom_versions_exist then
                add_version_option("Spawnmenu.VersionOptions.RandomOriginal", "random", 2)
                add_version_option("Spawnmenu.VersionOptions.RandomOriginalAndCustom", "random_custom", 2)
            end

            if other_versions_exist then
                for k,v in SortedPairs(versions.other) do
                    add_version_option(v.name, v, 3)
                end
            end
            if custom_versions_exist then
                for k,v in SortedPairs(versions.custom) do
                    add_version_option(v.name, v, 4)
                end
            end

            local function versions_compare(a, b)
                if istable(a) ~= istable(b) then return false end
                if not istable(a) then
                    return (a == b)
                end
                local ok = true
                ok = ok and (a.id == b.id)
                ok = ok and (a.classic_doors_id == b.classic_doors_id)
                ok = ok and (a.double_doors_id == b.double_doors_id)
                return ok
            end

            TARDIS.Spawnmenu.AddListSetting(dmenu, int_id, "preferred_version", "Spawnmenu.PreferredVersion", option_versions, versions_compare)
        end

        local function search_for_double_versions(version_list, current_val)
            if current_val then return true end
            for k,v in pairs(version_list) do
                if v.classic_doors_id then
                    return true
                end
            end
            return false
        end

        local has_double_versions = (versions.main.classic_doors_id ~= nil)
        has_double_versions = search_for_double_versions(versions.other, has_double_versions)
        has_double_versions = search_for_double_versions(versions.custom, has_double_versions)

        if has_double_versions then
            TARDIS.Spawnmenu.AddListSetting(dmenu, int_id, "preferred_door_type", "Spawnmenu.PreferredDoorType", {
                ["default"] = " ".. TARDIS:GetPhrase("Spawnmenu.PreferredDoorType.Default"),
                ["random"] = " ".. TARDIS:GetPhrase("Spawnmenu.PreferredDoorType.Random"),
                ["classic"] = " " .. TARDIS:GetPhrase("Spawnmenu.PreferredDoorType.Classic"),
                ["double"] = " " .. TARDIS:GetPhrase("Spawnmenu.PreferredDoorType.Double"),
            })
        end

        TARDIS.Spawnmenu.AddBoolSetting(dmenu, int_id, "redecoration_exclude", "Spawnmenu.RedecorationExclude")

        if custom_settings then
            local custom_categories = {}

            for cust_setting_id, custom_setting in SortedPairs(custom_settings) do
                local custom_dmenu = dmenu

                if custom_setting.category then
                    if not custom_categories[custom_setting.category] then
                        local submenu = dmenu:AddSubMenu(custom_setting.category, nil)
                        custom_categories[custom_setting.category] = submenu
                    end
                    custom_dmenu = custom_categories[custom_setting.category]
                end

                if custom_setting.value_type == "bool" then
                    TARDIS.Spawnmenu.AddBoolSetting(custom_dmenu, int_id, cust_setting_id, custom_setting.text)
                elseif custom_setting.value_type == "list" then
                    TARDIS.Spawnmenu.AddListSetting(custom_dmenu, int_id, cust_setting_id, custom_setting.text, custom_setting.options)
                end
            end

        end

        local reset_button = dmenu:AddOption(TARDIS:GetPhrase("Spawnmenu.ResetSettings"), function(self)
            TARDIS:ResetCustomSettings(int_id)
        end)

    end

    function TARDIS:AprilFools_RandomizeInteriorIcons(container)
        local keys = table.GetKeys(TARDIS.InteriorIcons)
        local total = table.Count(TARDIS.InteriorIcons)
        local offset = math.random(total)

        local spawnname_overrides = {}

        for i,k in ipairs(keys) do
            local n = (i - 1 + offset) % total + 1
            spawnname_overrides[k] = keys[n]
        end

        for k,v in pairs(container.tardis_icons) do
            if v.is_tardis_icon then
                v.spawnname_override = spawnname_overrides[v.original_spawnname]
                v.interior_material = TARDIS.InteriorIcons[v.spawnname_override]
            end
        end
    end

    function TARDIS.Spawnmenu.UpdateIconMaterial(container, update_current)
        local setting = TARDIS:GetSetting("spawnmenu_interior_icons") and not TARDIS:IsAprilFools()

        if setting ~= container.interior_icons_applied then

            for k,v in pairs(container.tardis_icons) do
                if v.is_tardis_icon then
                    v:SetMaterial( (setting and v.interior_material) or v.original_material )
                end
            end

            container.interior_icons_applied = setting
        end

        if setting then return end

        local hovered = vgui.GetHoveredPanel()
        if hovered == container.hovered and not update_current then return end

        if hovered and hovered.is_tardis_icon and TARDIS:IsAprilFools() then
            TARDIS:AprilFools_RandomizeInteriorIcons(container)
        end

        if container.hovered then
            if TARDIS:IsAprilFools() and TARDIS:GetSetting("spawnmenu_interior_icons") then
                container.hovered:SetMaterial(container.hovered.interior_material)
            else
                container.hovered:SetMaterial(container.hovered.original_material)
            end
        end

        if hovered and hovered.is_tardis_icon and hovered.interior_material then
            container.hovered = hovered
            hovered:SetMaterial(hovered.interior_material)
        end
    end

    function TARDIS.Spawnmenu.DoToggleFavorite(obj)
        TARDIS:ToggleFavoriteInt(obj.spawnname)
        TARDIS:AddSpawnmenuInterior(obj.spawnname)
        TARDIS:Message(LocalPlayer(), "Spawnmenu.FavoritesUpdated")
        RunConsoleCommand("spawnmenu_reload")
    end

    function TARDIS.Spawnmenu.OpenRightClickMenu(obj)
        local dmenu = DermaMenu()
        local versions = TARDIS.MetadataVersions[obj.spawnname]

        if versions then
            TARDIS.Spawnmenu.AddVersion(dmenu, versions.main)
            dmenu:AddSpacer()

            if not table.IsEmpty(versions.other) then
                TARDIS.Spawnmenu.AddLabel(dmenu, "Spawnmenu.AlternativeVersions")
                for k,v in SortedPairs(versions.other) do
                    TARDIS.Spawnmenu.AddVersionSubMenu(dmenu, v)
                end
                dmenu:AddSpacer()
            end

            if not table.IsEmpty(versions.custom) then
                TARDIS.Spawnmenu.AddLabel(dmenu, "Spawnmenu.CustomVersions")
                for k,v in SortedPairs(versions.custom) do
                    TARDIS.Spawnmenu.AddVersionSubMenu(dmenu, v)
                end
                dmenu:AddSpacer()
            end
        end

        local favorite = dmenu:AddOption(TARDIS:GetPhrase("Spawnmenu.AddToFavourites"), function(self)
            TARDIS.Spawnmenu.DoToggleFavorite(obj)
        end)

        local fav = TARDIS:IsFavoriteInt(obj.spawnname, LocalPlayer())
        local fav_icon = fav and "heart_delete.png" or "heart_add.png"
        local fav_text = fav and "Spawnmenu.RemoveFromFavourites" or "Spawnmenu.AddToFavourites"
        favorite:SetIcon("icon16/" .. fav_icon)
        favorite:SetText(TARDIS:GetPhrase(fav_text))

        TARDIS.Spawnmenu.AddChameleonSetting(dmenu, obj.spawnname)
        TARDIS.Spawnmenu.AddSettings(dmenu, obj.spawnname)

        dmenu:Open()
    end

    function TARDIS.Spawnmenu.DoClickIconMenu(container, obj, icon)
        local id = TARDIS:SelectSpawnID(icon.spawnname_override or obj.spawnname, LocalPlayer())
        TARDIS:SpawnByID(id)
    end

    function TARDIS.Spawnmenu.OpenIconMenu(container, obj)
        if TARDIS:IsAprilFools() then
            TARDIS:AprilFools_RandomizeInteriorIcons(container)
            TARDIS.Spawnmenu.UpdateIconMaterial(container, true)
            return
        end
        TARDIS.Spawnmenu.OpenRightClickMenu(obj)
    end

    function TARDIS.Spawnmenu.CreateIcon(container, obj)
        if not obj.material then return end
        if not obj.nicename then return end
        if not obj.spawnname then return end

        local icon = vgui.Create("ContentIcon", container)
        icon:SetContentType("entity")
        icon:SetSpawnName(obj.spawnname)
        icon:SetName(obj.nicename)
        icon:SetMaterial(obj.material)
        icon:SetAdminOnly(obj.admin)
        icon:SetColor(Color(205, 92, 92, 255))

        icon.is_tardis_icon = true
        icon.original_material = obj.material
        icon.original_spawnname = obj.spawnname
        icon.interior_material = TARDIS.InteriorIcons[obj.spawnname]

        icon.DoClick = function()
            TARDIS.Spawnmenu.DoClickIconMenu(container, obj, icon)
        end

        if container.Think ~= TARDIS.Spawnmenu.UpdateIconMaterial then
            container.Think = TARDIS.Spawnmenu.UpdateIconMaterial
        end

        container.tardis_icons = container.tardis_icons or {}
        table.insert(container.tardis_icons, icon)

        icon.OpenMenu = function()
            TARDIS.Spawnmenu.OpenIconMenu(container, obj)
        end

        if IsValid(container) then
            container:Add(icon)
        end

        return icon
    end

    function TARDIS.Spawnmenu.Populate()
        if not spawnmenu then return end
        spawnmenu.AddContentType("tardis", TARDIS.Spawnmenu.CreateIcon)
    end

    hook.Add("PostGamemodeLoaded", "tardis-interiors", TARDIS.Spawnmenu.Populate)

    hook.Add("TARDIS_LanguageChanged", "tardis-spawnmenu", function()
        for k,v in pairs(TARDIS:GetInteriors()) do
            TARDIS:AddSpawnmenuInterior(k)
        end
        RunConsoleCommand("spawnmenu_reload")
    end)

    hook.Add("PreReloadToolsMenu", "tardis-spawnmenu", function()
        for k,v in pairs(TARDIS:GetInteriors()) do
            TARDIS:AddSpawnmenuInterior(k)
        end
    end)
end

TARDIS_OVERRIDES = TARDIS_OVERRIDES or {}
local c_overrides = TARDIS_OVERRIDES.Categories or {}
local n_overrides = TARDIS_OVERRIDES.Names or {}

function TARDIS:AddSpawnmenuInterior(id)
    local t = self.MetadataRaw[id]

    if t.Base == true or t.Hidden or t.IsVersionOf then
        return
    end

    local ent={}

    local cat_override
    if c_overrides then
        for category,cat_interiors in pairs(c_overrides) do
            if table.HasValue(cat_interiors, t.ID) or table.HasValue(cat_interiors, t.Name) then
                cat_override = category
                break
            end
        end
    end

    local name_override = (n_overrides ~= nil) and (n_overrides[t.ID] or n_overrides[t.Name]) or nil

    local default_category = TARDIS_OVERRIDES.MainCategory or "#TARDIS.Spawnmenu.Category"

    ent.Category = cat_override or t.Category or default_category
    ent.PrintName = TARDIS:GetPhrase(name_override or t.Name)

    if TARDIS:IsAprilFools() then
        ent.PrintName = TARDIS:GetPhrase("Common.TARDIS")
    end

    if CLIENT then
        if TARDIS:IsFavoriteInt(t.ID, LocalPlayer()) then
            ent.PrintName = "  " .. ent.PrintName -- move to the top
        end

        local function try_icon(filename)
            if ent.IconOverride ~= nil then return end
            if file.Exists("materials/vgui/entities/" .. filename, "GAME") then
                ent.IconOverride="vgui/entities/" .. filename
            end
        end

        local function try_int_icon(filename)
            if TARDIS.InteriorIcons[t.ID] ~= nil then return end
            if file.Exists("materials/vgui/entities/" .. filename, "GAME") then
                TARDIS.InteriorIcons[t.ID] = "vgui/entities/" .. filename
            end
        end

        TARDIS.InteriorIcons[t.ID] = nil

        try_int_icon("tardis/interiors/" .. t.ID .. ".vmt")
        try_int_icon("tardis/interiors/" .. t.ID .. ".vtf")
        try_int_icon("tardis/interiors/" .. t.ID .. ".jpg")
        try_int_icon("tardis/interiors/" .. t.ID .. ".png")
        try_int_icon("tardis/interiors/default/" .. t.ID .. ".jpg")

        try_icon("tardis/" .. t.ID .. ".vmt")
        try_icon("tardis/" .. t.ID .. ".vtf")
        try_icon("tardis/" .. t.ID .. ".png")
        try_icon("tardis/" .. t.ID .. ".jpg")
        try_icon("tardis/default/" .. t.ID .. ".jpg")

        -- trying interior icons if we haven't found one for exterior mode
        try_icon("tardis/interiors/" .. t.ID .. ".vmt")
        try_icon("tardis/interiors/" .. t.ID .. ".vtf")
        try_icon("tardis/interiors/" .. t.ID .. ".png")
        try_icon("tardis/interiors/" .. t.ID .. ".jpg")
        try_icon("tardis/interiors/default/" .. t.ID .. ".jpg")

        try_icon("gmod_tardis.vmt")

        if TARDIS:IsAprilFools() then
            ent.IconOverride="vgui/entities/gmod_tardis.vmt"

            if t.ID == "default" then
                TARDIS.InteriorIcons[t.ID] = "vgui/entities/tardis/interiors/default0401.vmt"
            end
        end
    end

    ent.ScriptedEntityType="tardis"
    list.Set("SpawnableEntities", t.ID, ent)
end
