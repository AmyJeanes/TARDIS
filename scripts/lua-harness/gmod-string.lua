-- GMod string library extensions for the headless harness.
-- Ported from GMod's lua/includes/extensions/string.lua (GMod-Lua !/!= -> Lua):
-- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/extensions/string.lua

function string.ToTable(input)
    local str = tostring(input)
    local tbl = {}
    for i = 1, #str do tbl[i] = string.sub(str, i, i) end
    return tbl
end

local pattern_escape_replacements = {
    ['('] = '%(', [')'] = '%)', ['.'] = '%.', ['%'] = '%%', ['+'] = '%+',
    ['-'] = '%-', ['*'] = '%*', ['?'] = '%?', ['['] = '%[', [']'] = '%]',
    ['^'] = '%^', ['$'] = '%$', ['\0'] = '%z',
}
function string.PatternSafe(str)
    return (string.gsub(str, '.', pattern_escape_replacements))
end

function string.Explode(separator, str, withpattern)
    if separator == '' then return string.ToTable(str) end
    if withpattern == nil then withpattern = false end
    local ret = {}
    local current_pos = 1
    for i = 1, string.len(str) do
        local start_pos, end_pos = string.find(str, separator, current_pos, not withpattern)
        if not start_pos then break end
        ret[i] = string.sub(str, current_pos, start_pos - 1)
        current_pos = end_pos + 1
    end
    ret[#ret + 1] = string.sub(str, current_pos)
    return ret
end

function string.Split(str, delimiter)
    return string.Explode(delimiter, str)
end

function string.Left(str, num) return string.sub(str, 1, num) end
function string.Right(str, num) return string.sub(str, -num) end

function string.Replace(str, tofind, toreplace)
    local tbl = string.Explode(tofind, str)
    if tbl[1] then return table.concat(tbl, toreplace) end
    return str
end

function string.Trim(s, char)
    if char then char = string.PatternSafe(char) else char = '%s' end
    return string.match(s, '^' .. char .. '*(.-)' .. char .. '*$') or s
end

function string.TrimRight(s, char)
    if char then char = string.PatternSafe(char) else char = '%s' end
    return string.match(s, '^(.-)' .. char .. '*$') or s
end

function string.TrimLeft(s, char)
    if char then char = string.PatternSafe(char) else char = '%s' end
    return string.match(s, '^' .. char .. '*(.+)$') or s
end

function string.StartsWith(str, start)
    return string.sub(str, 1, string.len(start)) == start
end
string.StartWith = string.StartsWith

function string.EndsWith(str, endStr)
    return endStr == '' or string.sub(str, -string.len(endStr)) == endStr
end

function string.GetExtensionFromFilename(path)
    for i = #path, 1, -1 do
        local c = string.sub(path, i, i)
        if c == '/' or c == '\\' then return nil end
        if c == '.' then return string.sub(path, i + 1) end
    end
    return nil
end

function string.StripExtension(path)
    for i = #path, 1, -1 do
        local c = string.sub(path, i, i)
        if c == '/' or c == '\\' then return path end
        if c == '.' then return string.sub(path, 1, i - 1) end
    end
    return path
end

function string.GetFileFromFilename(path)
    for i = #path, 1, -1 do
        local c = string.sub(path, i, i)
        if c == '/' or c == '\\' then return string.sub(path, i + 1) end
    end
    return path
end
