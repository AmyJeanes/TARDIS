-- a modified version of table.Copy() to deal with Vectors / Angles / ...
---@api
---@generic T
---@param tbl T
---@param lookup_table table?
---@return T
function TARDIS:CopyTable(tbl, lookup_table)
    if not tbl or not istable(tbl) then return nil end

    local copy = {}
    -- debug.getmetatable deliberately (flagged deprecated upstream): it reads through
    -- __metatable protection, so a protected source still copies its real metatable.
    ---@diagnostic disable-next-line: deprecated
    setmetatable(copy, debug.getmetatable(tbl))

    for i,v in pairs(tbl) do
        if istable(v) then -- also works for colors
            lookup_table = lookup_table or {}
            lookup_table[tbl] = copy
            if (lookup_table[v]) then
                copy[i] = lookup_table[v]
                -- we already copied this table. reuse the copy.
            else
                copy[i] = TARDIS:CopyTable(v, lookup_table)
                -- not yet copied. copy it.
            end
        elseif isvector(v) then
            copy[i] = Vector(0,0,0) + v
        elseif isangle(v) then
            copy[i] = Angle(0,0,0) + v
        else
            copy[i] = v
        end
    end

    return copy
end
