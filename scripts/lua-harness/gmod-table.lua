-- GMod table library extensions for the headless harness.
-- Ported from GMod's lua/includes/extensions/table.lua (GMod-Lua !/!= -> Lua):
-- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/extensions/table.lua
--
-- table.Copy / table.Merge run for real while content metadata is built, so
-- they match the engine's behaviour exactly (Merge deep-merges without an
-- IsColor guard; Copy preserves metatables via debug.getmetatable).

function table.Inherit(t, base)
    for k, v in pairs(base) do
        if t[k] == nil then t[k] = v end
    end
    t.BaseClass = base
    return t
end

function table.Copy(t, lookup_table)
    if t == nil then return nil end
    local copy = {}
    setmetatable(copy, debug.getmetatable(t))
    for i, v in pairs(t) do
        if not istable(v) then
            copy[i] = v
        else
            lookup_table = lookup_table or {}
            lookup_table[t] = copy
            if lookup_table[v] then
                copy[i] = lookup_table[v] -- we already copied this table. reuse the copy.
            else
                copy[i] = table.Copy(v, lookup_table) -- not yet copied. copy it.
            end
        end
    end
    return copy
end

function table.Empty(tab)
    for k in pairs(tab) do tab[k] = nil end
end

function table.IsEmpty(tab)
    return next(tab) == nil
end

function table.Merge(dest, source, forceOverride)
    for k, v in pairs(source) do
        if not forceOverride and istable(v) and istable(dest[k]) then
            -- don't overwrite one table with another; merge them recursively
            table.Merge(dest[k], v)
        else
            dest[k] = v
        end
    end
    return dest
end

function table.HasValue(t, val)
    for k, v in pairs(t) do
        if v == val then return true end
    end
    return false
end

function table.Add(dest, source)
    if dest == source then return dest end
    if not istable(source) then return dest end
    if not istable(dest) then dest = {} end
    for k, v in pairs(source) do
        table.insert(dest, v)
    end
    return dest
end

function table.Count(t)
    local i = 0
    for k in pairs(t) do i = i + 1 end
    return i
end

function table.Random(t)
    local rk = math.random(1, table.Count(t))
    local i = 1
    for k, v in pairs(t) do
        if i == rk then return v, k end
        i = i + 1
    end
end

function table.ForceInsert(t, v)
    if t == nil then t = {} end
    table.insert(t, v)
    return t
end

function table.KeyFromValue(tbl, val)
    for key, value in pairs(tbl) do
        if value == val then return key end
    end
end

function table.RemoveByValue(tbl, val)
    local key = table.KeyFromValue(tbl, val)
    if not key then return false end
    if isnumber(key) then
        table.remove(tbl, key)
    else
        tbl[key] = nil
    end
    return key
end

function table.GetKeys(tab)
    local keys = {}
    local id = 1
    for k, v in pairs(tab) do
        keys[id] = k
        id = id + 1
    end
    return keys
end
