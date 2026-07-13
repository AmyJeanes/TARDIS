---@api
---@param id string
function TARDIS:SpawnByID(id)
    RunConsoleCommand("tardis2_spawn", id)
    surface.PlaySound("ui/buttonclickrelease.wav")
end

TARDIS.InteriorIcons = TARDIS.InteriorIcons or {}

list.Set( "ContentCategoryIcons", "#TARDIS.Spawnmenu.Category", "vgui/tardis_icon.png" )
list.Set( "ContentCategoryIcons", "#TARDIS.Spawnmenu.CategoryTools", "vgui/tardis_icon.png" )

if CLIENT then

    ---@param id string
    function TARDIS:SelectForRedecoration(id)
        TARDIS:SetSetting("redecorate-interior", id)
        local current_tardis = LocalPlayer():GetTardisExterior()

        if not current_tardis or not current_tardis:GetData("redecorate") then
            TARDIS:Message(LocalPlayer(), "Spawnmenu.RedecorationSelected")
        else
            TARDIS:Message(LocalPlayer(), "Spawnmenu.RedecorationSelectedRestart")
        end
    end

    TARDIS.Spawnmenu = {}

    ---@param dmenu DMenu
    ---@param text string
    function TARDIS.Spawnmenu.AddLabel(dmenu, text)
        local label = vgui.Create("DLabel", dmenu)
        label:SetText("  " .. TARDIS:GetPhrase(text))
        label:SetTextColor(Color(0,0,0))
        -- stub types AddPanel as a class-name factory, but it also accepts a panel instance
        ---@diagnostic disable-next-line: param-type-mismatch
        dmenu:AddPanel(label)
    end

    ---@param dmenu DMenu
    ---@param id string
    function TARDIS.Spawnmenu.AddSingleVersion(dmenu, id)
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

        local copy = dmenu:AddOption(TARDIS:GetPhrase("Spawnmenu.CopyID"), function()
            SetClipboardText(id)
        end)
        copy:SetIcon("icon16/page_copy.png")
    end

    ---@param dmenu DMenu
    ---@param classic_doors_id string
    ---@param double_doors_id string
    function TARDIS.Spawnmenu.AddDoubleVersion(dmenu, classic_doors_id, double_doors_id)
        TARDIS.Spawnmenu.AddLabel(dmenu, "Spawnmenu.ClassicDoorsVersion")
        TARDIS.Spawnmenu.AddSingleVersion(dmenu, classic_doors_id)

        dmenu:AddSpacer()

        TARDIS.Spawnmenu.AddLabel(dmenu, "Spawnmenu.DoubleDoorsVersion")
        TARDIS.Spawnmenu.AddSingleVersion(dmenu, double_doors_id)
    end

    ---@param dmenu DMenu
    ---@param version tardis_version_entry
    function TARDIS.Spawnmenu.AddVersion(dmenu, version)
        if version.classic_doors_id and version.double_doors_id then
            TARDIS.Spawnmenu.AddDoubleVersion(dmenu, version.classic_doors_id, version.double_doors_id)
        else
            TARDIS.Spawnmenu.AddSingleVersion(dmenu, version.classic_doors_id or version.id)
        end
        dmenu:AddSpacer()
    end

    ---@param dmenu DMenu
    ---@param version tardis_version_entry
    function TARDIS.Spawnmenu.AddVersionSubMenu(dmenu, version)
        if not version or not version.name then return end

        local submenu = dmenu:AddSubMenu(TARDIS:GetPhrase(version.name), function()
            TARDIS:SpawnByID( TARDIS:SelectDoorVersionID(version, LocalPlayer()) )
        end)
        TARDIS.Spawnmenu.AddVersion(submenu, version)

        return submenu
    end

    ---@param dmenu DMenu
    ---@param int_id string
    ---@param setting_id string
    ---@param name string
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

    ---@param dmenu DMenu
    ---@param int_id string
    ---@param setting_id string
    ---@param name string
    ---@param options table?
    ---@param compare_func? fun(a: any, b: any): boolean
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
            for _,v in ipairs(option_buttons) do
                local checked = (value == v[1])
                if compare_func then
                    checked = compare_func(value, v[1])
                end
                local btn = v[2]
                if btn then
                    btn:SetChecked(checked)
                end
            end
        end

    end

    ---@param parent DMenu
    ---@param int_id string
    function TARDIS.Spawnmenu.AddChameleonSetting(parent, int_id)
        local exterior_setting_submenu = parent:AddSubMenu(TARDIS:GetPhrase("Spawnmenu.Chameleon"), nil)

        TARDIS.Spawnmenu.AddBoolSetting(exterior_setting_submenu, int_id, "exterior_enabled", "Spawnmenu.Chameleon.Enable")

        for category,exteriors in pairs(TARDIS:GetExteriorCategories()) do
            if not table.IsEmpty(exteriors) then
                local exteriors_tbl = {}
                for id,v in pairs(exteriors) do
                    local ext_md = assert(TARDIS:GetExteriors()[id])
                    if v and ext_md.Base ~= true and ext_md.Hide ~= true then
                        exteriors_tbl[id] = TARDIS:GetPhrase(ext_md.Name or id)
                    end
                end
                TARDIS.Spawnmenu.AddListSetting(exterior_setting_submenu, int_id, "exterior_default", TARDIS:GetPhrase(category), exteriors_tbl)
            end
        end
    end

    ---@param parent DMenu
    ---@param int_id string
    function TARDIS.Spawnmenu.AddSettings(parent, int_id)
        int_id = TARDIS:GetMainVersionId(int_id)

        local versions = TARDIS.MetadataVersions[int_id]
        local custom_settings = TARDIS.IntCustomSettings[int_id]

        local other_versions_exist = not table.IsEmpty(versions.other)
        local custom_versions_exist = not table.IsEmpty(versions.custom)

        local versions_exist = other_versions_exist or custom_versions_exist
        local dmenu = parent:AddSubMenu(TARDIS:GetPhrase("Spawnmenu.Settings"), nil)

        if versions_exist then

            local option_versions = {}

            ---@param option_name string
            ---@param option_id string|table
            ---@param order integer
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
                for _,v in SortedPairs(versions.other) do
                    add_version_option(v.name, v, 3)
                end
            end
            if custom_versions_exist then
                for _,v in SortedPairs(versions.custom) do
                    add_version_option(v.name, v, 4)
                end
            end

            ---@param a string|table
            ---@param b string|table
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

        ---@param version_list table
        ---@param current_val boolean
        local function search_for_double_versions(version_list, current_val)
            if current_val then return true end
            for _,v in pairs(version_list) do
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

        dmenu:AddOption(TARDIS:GetPhrase("Spawnmenu.ResetSettings"), function(self)
            TARDIS:ResetCustomSettings(int_id)
        end)

    end

    local MODE = TARDIS.SpawnmenuIconMode

    -- Primary face: what shows when not hovered.
    -- "Only" modes are strict — they fall back straight to the matching
    -- missing icon without trying the other type. Hover modes fall through
    -- to the other type first, since both faces are part of the experience,
    -- and only resort to the missing icon when neither real icon exists.
    ---@param v table
    ---@param mode integer
    local function get_primary(v, mode)
        if mode == MODE.InteriorOnly then
            return v.interior_icon or v.missing_interior
        end
        if mode == MODE.SpawniconOnly then
            return v.spawn_icon or v.missing_spawn
        end
        if mode == MODE.SpawniconOnHover then
            return v.interior_icon or v.spawn_icon or v.missing_interior
        end
        -- InteriorOnHover (default)
        return v.spawn_icon or v.interior_icon or v.missing_spawn
    end

    -- Hover face: only the icon type the mode swaps to, no fallback. If that
    -- icon doesn't exist for this entity, hover does nothing (caller treats
    -- nil as "leave material alone").
    ---@param v table
    ---@param mode integer
    local function get_hover(v, mode)
        if mode == MODE.InteriorOnHover then return v.interior_icon end
        if mode == MODE.SpawniconOnHover then return v.spawn_icon end
        return nil
    end

    ---@param container Panel
    ---@param update_current boolean?
    function TARDIS.Spawnmenu.UpdateIconMaterial(container, update_current)
        local mode = TARDIS:GetSetting("spawnmenu_icon_mode")
        local pack = TARDIS:GetSetting("icon_pack_config")

        if pack ~= container.iconpack_applied then
            for _,v in pairs(container.tardis_icons) do
                if v.is_tardis_icon then
                    local id = v.original_spawnname
                    v.spawn_icon = TARDIS:GetSpawnIcon(id)
                    v.interior_icon = TARDIS:GetInteriorIcon(id)
                    v.missing_spawn = TARDIS:GetMissingIcon(TARDIS.IconCategory.Spawnicon)
                    v.missing_interior = TARDIS:GetMissingIcon(TARDIS.IconCategory.Interior)
                end
            end
            container.iconpack_applied = pack
            container.iconmode_applied = nil
        end

        if mode ~= container.iconmode_applied then

            for _,v in pairs(container.tardis_icons) do
                if v.is_tardis_icon then
                    -- nil when even the missing icon isn't mounted (client has
                    -- the Lua but not the materials) - keep the existing icon.
                    local mat = get_primary(v, mode)
                    if mat then v:SetMaterial(mat) end
                end
            end

            container.iconmode_applied = mode
            container.hovered = nil
        end

        if mode == MODE.InteriorOnly or mode == MODE.SpawniconOnly then return end

        local hovered = vgui.GetHoveredPanel()
        if hovered == container.hovered and not update_current then return end

        if container.hovered then
            local mat = get_primary(container.hovered, mode)
            if mat then container.hovered:SetMaterial(mat) end
        end

        local hover_mat = hovered and hovered.is_tardis_icon and get_hover(hovered, mode) or nil
        if hover_mat then
            container.hovered = hovered
            hovered:SetMaterial(hover_mat)
        else
            container.hovered = nil
        end
    end

    ---@param obj table
    function TARDIS.Spawnmenu.DoToggleFavorite(obj)
        TARDIS:ToggleFavoriteInt(obj.spawnname)
        TARDIS:AddSpawnmenuInterior(obj.spawnname)
        TARDIS:Message(LocalPlayer(), "Spawnmenu.FavoritesUpdated")
        RunConsoleCommand("spawnmenu_reload")
    end

    ---@param obj table
    function TARDIS.Spawnmenu.OpenRightClickMenu(obj)
        local dmenu = DermaMenu()
        local versions = TARDIS.MetadataVersions[obj.spawnname]

        if versions then
            TARDIS.Spawnmenu.AddVersion(dmenu, versions.main)
            dmenu:AddSpacer()

            if not table.IsEmpty(versions.other) then
                TARDIS.Spawnmenu.AddLabel(dmenu, "Spawnmenu.AlternativeVersions")
                for _,v in SortedPairs(versions.other) do
                    TARDIS.Spawnmenu.AddVersionSubMenu(dmenu, v)
                end
                dmenu:AddSpacer()
            end

            if not table.IsEmpty(versions.custom) then
                TARDIS.Spawnmenu.AddLabel(dmenu, "Spawnmenu.CustomVersions")
                for _,v in SortedPairs(versions.custom) do
                    TARDIS.Spawnmenu.AddVersionSubMenu(dmenu, v)
                end
                dmenu:AddSpacer()
            end
        end

        local favorite = dmenu:AddOption("", function(self)
            TARDIS.Spawnmenu.DoToggleFavorite(obj)
        end)

        local fav = TARDIS:IsFavoriteInt(obj.spawnname, LocalPlayer())
        local fav_icon = fav and "heart_delete.png" or "heart_add.png"
        local fav_text = fav and "Common.RemoveFromFavourites" or "Common.AddToFavourites"
        fav_text = TARDIS:GetPhrase(fav_text) .. " (" .. string.lower(TARDIS:GetPhrase("Spawnmenu.ReloadRequired")) .. ")"
        favorite:SetIcon("icon16/" .. fav_icon)
        favorite:SetText(fav_text)

        TARDIS.Spawnmenu.AddChameleonSetting(dmenu, obj.spawnname)
        TARDIS.Spawnmenu.AddSettings(dmenu, obj.spawnname)

        dmenu:Open()
    end

    ---@param container Panel
    ---@param obj table
    ---@param icon Panel
    function TARDIS.Spawnmenu.DoClickIconMenu(container, obj, icon)
        local id = TARDIS:SelectSpawnID(icon.spawnname_override or obj.spawnname, LocalPlayer())
        TARDIS:SpawnByID(id)
    end

    ---@param container Panel
    ---@param obj table
    function TARDIS.Spawnmenu.OpenIconMenu(container, obj)
        TARDIS.Spawnmenu.OpenRightClickMenu(obj)
    end

    ---@param container Panel
    ---@param obj table
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
        icon.original_spawnname = obj.spawnname
        -- These get re-resolved by UpdateIconMaterial; populate now for the
        -- first frame so the icon doesn't pop in.
        icon.spawn_icon = TARDIS:GetSpawnIcon(obj.spawnname)
        icon.interior_icon = TARDIS.InteriorIcons[obj.spawnname]
        icon.missing_spawn = TARDIS:GetMissingIcon(TARDIS.IconCategory.Spawnicon)
        icon.missing_interior = TARDIS:GetMissingIcon(TARDIS.IconCategory.Interior)

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
        for k,_ in pairs(TARDIS:GetInteriors()) do
            TARDIS:AddSpawnmenuInterior(k)
        end
        RunConsoleCommand("spawnmenu_reload")
    end)

    hook.Add("PreReloadToolsMenu", "tardis-spawnmenu", function()
        for k,_ in pairs(TARDIS:GetInteriors()) do
            TARDIS:AddSpawnmenuInterior(k)
        end
    end)

    hook.Add("TARDIS_SettingChanged", "tardis-spawnmenu-iconpack", function(id)
        if id ~= "icon_pack_config" and id ~= "spawnmenu_icon_mode" then return end
        for k,_ in pairs(TARDIS:GetInteriors()) do
            TARDIS:AddSpawnmenuInterior(k)
        end
    end)
end

TARDIS_OVERRIDES = TARDIS_OVERRIDES or {}
local c_overrides = TARDIS_OVERRIDES.Categories or {}
local n_overrides = TARDIS_OVERRIDES.Names or {}

---@param id string
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

    if CLIENT then
        if TARDIS:IsFavoriteInt(t.ID, LocalPlayer()) then
            ent.PrintName = "  " .. ent.PrintName -- move to the top
        end

        TARDIS.InteriorIcons[t.ID] = TARDIS:GetInteriorIcon(t.ID)
        ent.IconOverride = TARDIS:GetSpawnIcon(t.ID) or TARDIS.InteriorIcons[t.ID] or TARDIS:GetMissingIcon(TARDIS.IconCategory.Spawnicon)
    end

    ent.ScriptedEntityType="tardis"
    list.Set("SpawnableEntities", t.ID, ent)
end
