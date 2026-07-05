-- Icons

if SERVER then
    TARDIS:LoadFolder("iconpacks", true, true)
    return
end

---@class tardis_icon_pack
---@field ID string
---@field Folder string?
---@field Name string
---@field IsBase true?

---@type table<string, tardis_icon_pack>
TARDIS.iconpacks = TARDIS.iconpacks or {}

TARDIS.IconCategory = {
    Spawnicon = "spawnicons",
    Exterior  = "exteriors",
    Interior  = "interiors",
}

TARDIS.SpawnmenuIconMode = {
    InteriorOnHover  = "interior_on_hover",
    SpawniconOnHover = "spawnicon_on_hover",
    InteriorOnly     = "interior_only",
    SpawniconOnly    = "spawnicon_only",
}

local ICON_EXTENSIONS = {"vmt", "png", "jpg"}
local EXT_PRIORITY = { vmt = 1, png = 2, jpg = 3 }

TARDIS.iconpack_index = TARDIS.iconpack_index or {}

local function pick_best_ext(ext_to_name)
    for _, ext in ipairs(ICON_EXTENSIONS) do
        if ext_to_name[ext] then return ext_to_name[ext] end
    end
end

local function scan_dir(rel)
    local files = file.Find("materials/" .. rel .. "*", "GAME")
    return files or {}
end

local function build_pack_index(pack)
    local index = {
        icons   = { spawnicons = {}, exteriors = {}, interiors = {} },
        missing = {},
    }
    local pack_root
    if pack.IsBase then
        pack_root = "vgui/entities/tardis/"
    else
        pack_root = "vgui/entities/tardis/iconpacks/" .. pack.Folder .. "/"
    end

    -- Index keys are stored lowercase so lookups survive Workshop's
    -- filename-lowercasing pass — a pack that works locally with mixed-case
    -- filenames still resolves once it's served from the workshop VPK.
    for cat in pairs(index.icons) do
        local cat_root = pack_root .. cat .. "/"
        local by_id = {}
        for _, name in ipairs(scan_dir(cat_root)) do
            local id, ext = name:match("^(.+)%.([^%.]+)$")
            if id and ext then
                id, ext = id:lower(), ext:lower()
                if EXT_PRIORITY[ext] then
                    by_id[id] = by_id[id] or {}
                    by_id[id][ext] = name
                end
            end
        end
        for id, ext_to_name in pairs(by_id) do
            local picked = pick_best_ext(ext_to_name)
            if picked then
                if id == "missing" then
                    index.missing[cat] = cat_root .. picked
                else
                    index.icons[cat][id] = cat_root .. picked
                end
            end
        end
    end

    -- Pack-root missing icon
    do
        local by_ext = {}
        for _, name in ipairs(scan_dir(pack_root)) do
            local id, ext = name:match("^(.+)%.([^%.]+)$")
            if id and ext then
                id, ext = id:lower(), ext:lower()
                if id == "missing" and EXT_PRIORITY[ext] then
                    by_ext[ext] = name
                end
            end
        end
        local picked = pick_best_ext(by_ext)
        if picked then index.missing.root = pack_root .. picked end
    end

    -- Base + spawnicons: legacy top-level paths fold into the spawnicon map.
    if pack.IsBase then
        local by_id = {}
        for _, name in ipairs(scan_dir("vgui/entities/tardis/")) do
            local id, ext = name:match("^(.+)%.([^%.]+)$")
            if id and ext then
                id, ext = id:lower(), ext:lower()
                if EXT_PRIORITY[ext] and id ~= "missing" then
                    by_id[id] = by_id[id] or {}
                    by_id[id][ext] = name
                end
            end
        end
        for id, ext_to_name in pairs(by_id) do
            if not index.icons.spawnicons[id] then
                local picked = pick_best_ext(ext_to_name)
                if picked then index.icons.spawnicons[id] = "vgui/entities/tardis/" .. picked end
            end
        end
    end

    return index
end

function TARDIS:RebuildIconPackIndex(pack_id)
    local pack = self.iconpacks[pack_id]
    if pack then
        self.iconpack_index[pack_id] = build_pack_index(pack)
    end
end

---@api
---@return table<string, tardis_icon_pack>
function TARDIS:GetIconPacks()
    return self.iconpacks
end

---@api
---@param id string
---@return tardis_icon_pack?
function TARDIS:GetIconPack(id)
    return self.iconpacks[id]
end

-- Functionally identical to {} but gives proper type checking for icon packs
---@api
---@return tardis_icon_pack
function TARDIS:NewIconPack()
    return {}
end

---@api
---@param iconpack table
function TARDIS:AddIconPack(iconpack)
    ---@type tardis_icon_pack
    local pack = table.Copy(iconpack)

    if not pack.ID then
        ErrorNoHalt("TARDIS: Icon pack missing ID\n")
        return
    end

    if pack.ID ~= string.lower(pack.ID) then
        ErrorNoHalt("TARDIS: Icon pack ID '"..pack.ID.."' must be lowercase\n")
        return
    end

    if pack.IsBase then
        ErrorNoHalt("TARDIS: Icon pack '"..pack.ID.."' must not set IsBase (reserved for internal use)\n")
        return
    end

    if not pack.Folder then
        ErrorNoHalt("TARDIS: Icon pack '"..pack.ID.."' missing Folder\n")
        return
    end

    self.iconpacks[pack.ID] = pack
    self:RebuildIconPackIndex(pack.ID)
end

function TARDIS:PackHasCategory(pack, category)
    if pack.IsBase then return true end
    local idx = self.iconpack_index[pack.ID]
    if not idx then return false end
    local cat = idx.icons[category]
    return cat and next(cat) ~= nil or false
end

function TARDIS:PackProvidesIcon(pack_id, category, id)
    local idx = self.iconpack_index[pack_id]
    if not idx then return false end
    local cat = idx.icons[category]
    return cat and id and cat[id:lower()] ~= nil or false
end

function TARDIS:GetPackIcon(pack_id, category, id)
    local idx = self.iconpack_index[pack_id]
    if not idx then return nil end
    local cat = idx.icons[category]
    return cat and id and cat[id:lower()] or nil
end

function TARDIS:GetIconProvider(category, id, config_override)
    if id == nil or category == nil then return nil end
    local config = config_override or self:GetIconPackConfig()
    local entries = config[category]
    if not entries then return nil end
    for _, entry in ipairs(entries) do
        if entry.enabled and self:PackProvidesIcon(entry.id, category, id) then
            return entry.id
        end
    end
    return nil
end

local function build_category_list(self, stored_list, category)
    stored_list = stored_list or {}
    local seen = {}
    local valid = {}
    for _, entry in ipairs(stored_list) do
        local pack = self.iconpacks[entry.id]
        if pack and not seen[entry.id] and self:PackHasCategory(pack, category) then
            seen[entry.id] = true
            table.insert(valid, { id = entry.id, enabled = entry.enabled and true or false })
        end
    end
    -- Custom packs (other than base) get appended to the working list. They land
    -- above base by default so enabling one will override base.
    for id, pack in pairs(self.iconpacks) do
        if id ~= "base" and not seen[id] and self:PackHasCategory(pack, category) then
            table.insert(valid, { id = id, enabled = false })
            seen[id] = true
        end
    end
    -- Base goes at the very bottom by default, since the top of the list takes
    -- priority and base is the foundational fallback.
    if not seen["base"] then
        table.insert(valid, { id = "base", enabled = true })
    end
    return valid
end

local function lookup_pack_missing(self, pack_id, category)
    local idx = self.iconpack_index[pack_id]
    if not idx then return nil end
    return (category and idx.missing[category]) or idx.missing.root
end

function TARDIS:PackProvidesMissingIcon(pack_id, category)
    return lookup_pack_missing(self, pack_id, category) ~= nil
end

function TARDIS:GetPackMissingIcon(pack_id, category)
    return lookup_pack_missing(self, pack_id, category)
end

local function build_missing_map(self, stored)
    stored = stored or {}
    local out = {}
    for _, cat in pairs(self.IconCategory) do
        local pack_id = stored[cat]
        if pack_id and self.iconpacks[pack_id] and self:PackProvidesMissingIcon(pack_id, cat) then
            out[cat] = pack_id
        else
            out[cat] = "base"
        end
    end
    return out
end

function TARDIS:GetIconPackConfig()
    local stored = self:GetSetting("icon_pack_config") or {}
    local result = {}
    for _, cat in pairs(self.IconCategory) do
        result[cat] = build_category_list(self, stored[cat], cat)
    end
    result.missing = build_missing_map(self, stored.missing)
    return result
end

function TARDIS:GetDefaultIconPackConfig()
    local result = {}
    for _, cat in pairs(self.IconCategory) do
        result[cat] = build_category_list(self, nil, cat)
    end
    result.missing = build_missing_map(self, nil)
    return result
end

local function lookup_pack_icon(self, pack_id, category, id)
    local idx = self.iconpack_index[pack_id]
    if not idx then return nil end
    local cat = idx.icons[category]
    return cat and id and cat[id:lower()] or nil
end

---@api
---@param category string
---@param id string
---@param config_override? table
---@return string?
function TARDIS:GetIcon(category, id, config_override)
    if id == nil or category == nil then return nil end

    local config = config_override or self:GetIconPackConfig()
    local entries = config[category]
    if not entries then return nil end
    for _, entry in ipairs(entries) do
        if entry.enabled then
            local found = lookup_pack_icon(self, entry.id, category, id)
            if found then return found end
        end
    end

    return nil
end

---@api
---@param category string
---@param config_override? table
---@return string?
function TARDIS:GetMissingIcon(category, config_override)
    if category == nil then return nil end

    local config = config_override or self:GetIconPackConfig()
    local missing = config.missing or {}
    local pack_id = missing[category] or "base"

    local found = lookup_pack_missing(self, pack_id, category)
    if found then return found end

    if pack_id ~= "base" then
        found = lookup_pack_missing(self, "base", category)
        if found then return found end
    end

    return nil
end

---@api
---@param id string
---@param config_override? table
---@return string?
function TARDIS:GetSpawnIcon(id, config_override)
    return self:GetIcon(self.IconCategory.Spawnicon, id, config_override)
end

---@api
---@param id string
---@param config_override? table
---@return string?
function TARDIS:GetExteriorIcon(id, config_override)
    return self:GetIcon(self.IconCategory.Exterior, id, config_override)
end

---@api
---@param id string
---@param config_override? table
---@return string?
function TARDIS:GetInteriorIcon(id, config_override)
    return self:GetIcon(self.IconCategory.Interior, id, config_override)
end

-- internal base pack registration (bypasses AddIconPack since users can't set IsBase)
TARDIS.iconpacks["base"] = {
    ID     = "base",
    IsBase = true,
    Name   = "Base",
}
TARDIS:RebuildIconPackIndex("base")

TARDIS:AddMigration("iconmode-from-bool", "2026.1.0", function(self)
    if self.LocalSettings["spawnmenu_interior_icons"] == true then
        self:SetSetting("spawnmenu_icon_mode", TARDIS.SpawnmenuIconMode.InteriorOnly)
    end
    self.LocalSettings["spawnmenu_interior_icons"] = nil
end)

TARDIS:LoadFolder("iconpacks", false, true)
