function TARDIS:SetExteriorCategory(ext_id, category)
    for _,v in pairs(self.ExteriorCategories) do
        if v[ext_id] then
            v[ext_id] = nil
        end
    end
    local cat = self.ExteriorCategories[category] or {}
    self.ExteriorCategories[category] = cat
    cat[ext_id] = true
end

function TARDIS:ClearExteriorMetadata(id)
    self.ExteriorsMetadata[id] = nil
    for k,v in pairs(self.ExteriorsMetadataRaw) do
        if v.Base == id then
            self:ClearExteriorMetadata(k)
        end
    end
end

-- Functionally identical to E = {} but gives proper type checking for exteriors
---@api
---@return tardis_exterior_metadata
function TARDIS:NewExterior()
    return {}
end

---@api
---@param exterior table
function TARDIS:AddExterior(exterior)
    local id = exterior.ID
    exterior.Category = exterior.Category or "Exteriors.Categories.Misc"

    self:ClearExteriorMetadata(id)
    self.ExteriorsMetadataRaw[id] = exterior

    self:SetExteriorCategory(id, exterior.Category)
end

--[[
supported import_options:
    ext_id
    base
    name
    category
    modify_func
]]
---@api
---@param int_id string
---@param import_options table?
function TARDIS:ImportExterior(int_id, import_options)
    import_options = import_options or {}

    TARDIS.ImportedExteriors[int_id] = import_options

    local T = self:GetInterior(int_id)
    if not T or not T.Exterior then return false end

    local E = self:CopyTable(T.Exterior)
    E.ID = import_options.ext_id or int_id
    E.Base = import_options.base or "base"
    E.Name = import_options.name or T.Name or int_id

    if import_options.category then
        E.Category = import_options.category
    end

    if import_options.modify_func then
        E = import_options.modify_func(E) or E
    end

    self:AddExterior(E)

    return true
end

function TARDIS:MergeExteriorMetadata(base, t)
    local copy=table.Copy(base)
    self:PreMergeExteriorMetadata(t)
    table.Merge(copy,t)
    self:PostMergeExteriorMetadata(copy)
    return copy
end

function TARDIS:SetupExteriorMetadata(id)
    if self.ExteriorsMetadata[id] then return end
    local t = self.ExteriorsMetadataRaw[id]
    if not t then return end

    local base = t.Base

    if base == true then
        self.ExteriorsMetadata[id] = t
        return
    end

    self:SetupExteriorMetadata(base)

    local m_base = self.ExteriorsMetadata[base]
    if not m_base then return end

    self.ExteriorsMetadata[id] = self:MergeExteriorMetadata(m_base, t)
end

---@api
---@param id string
---@return tardis_exterior_metadata
function TARDIS:CreateExteriorMetadata(id)
    self:SetupExteriorMetadata(id)

    local raw = self.ExteriorsMetadata[id]
    if raw == nil then
        return self:CreateExteriorMetadata("default")
    end

    local metadata = TARDIS:CopyTable(raw)
    metadata.TextureSets = TARDIS:GetMergedTextureSets(metadata.TextureSets)

    return metadata
end

---@api
function TARDIS:GetExteriors()
    return self.ExteriorsMetadataRaw
end

---@api
function TARDIS:GetExteriorCategories()
    return self.ExteriorCategories
end

TARDIS:LoadInteriors()
