-- a modified version of table.Copy() to deal with Vectors / Angles / ...
function TARDIS:CopyTable(t)
    if not t or not istable(t) then return nil end

    local copy = {}
    setmetatable(copy, debug.getmetatable(t))

    local lookup_table

    for i,v in pairs(t) do
        if istable(v) then -- also works for colors
            lookup_table = lookup_table or {}
            lookup_table[t] = copy
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
