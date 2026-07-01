-- Value constructors and type predicates for the headless content-loading
-- harness. One of the prelude files loaded by run-harness.ps1; see
-- gmod-stubs.lua for the overall design.
--
-- The constructors deliberately *record* their arguments (Vector/Angle keep
-- x/y/z, Material keeps its name) so a caller can read back what the content
-- files passed in - that is the whole point of running the addon headless.

local setmetatable, getmetatable, type, tostring = setmetatable, getmetatable, type, tostring
local sformat = string.format

-- == value constructors =====================================================

local vector_meta, angle_meta, color_meta, material_meta

local function newvector(x, y, z)
    return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, vector_meta)
end

vector_meta = {
    __index = function(self) return function() return self end end,
    __add = function(a, b) return newvector(a.x + b.x, a.y + b.y, a.z + b.z) end,
    __sub = function(a, b) return newvector(a.x - b.x, a.y - b.y, a.z - b.z) end,
    __mul = function(a, b)
        if type(b) == 'number' then return newvector(a.x * b, a.y * b, a.z * b) end
        if type(a) == 'number' then return newvector(b.x * a, b.y * a, b.z * a) end
        return newvector(a.x * b.x, a.y * b.y, a.z * b.z)
    end,
    __div = function(a, b)
        if type(b) == 'number' then return newvector(a.x / b, a.y / b, a.z / b) end
        return newvector(a.x / b.x, a.y / b.y, a.z / b.z)
    end,
    __unm = function(a) return newvector(-a.x, -a.y, -a.z) end,
    __eq = function(a, b) return a.x == b.x and a.y == b.y and a.z == b.z end,
    __tostring = function(s) return sformat('[%g %g %g]', s.x, s.y, s.z) end,
}

local function newangle(p, y, r)
    return setmetatable({ p = p or 0, y = y or 0, r = r or 0 }, angle_meta)
end

angle_meta = {
    __index = function(self) return function() return self end end,
    __add = function(a, b) return newangle(a.p + b.p, a.y + b.y, a.r + b.r) end,
    __sub = function(a, b) return newangle(a.p - b.p, a.y - b.y, a.r - b.r) end,
    __mul = function(a, b)
        if type(b) == 'number' then return newangle(a.p * b, a.y * b, a.r * b) end
        if type(a) == 'number' then return newangle(b.p * a, b.y * a, b.r * a) end
        return newangle(a.p * b.p, a.y * b.y, a.r * b.r)
    end,
    __unm = function(a) return newangle(-a.p, -a.y, -a.r) end,
    __eq = function(a, b) return a.p == b.p and a.y == b.y and a.r == b.r end,
    __tostring = function(s) return sformat('{%g %g %g}', s.p, s.y, s.r) end,
}

color_meta = {
    __index = function(self) return function() return self end end,
    __tostring = function(s) return sformat('Color(%g %g %g %g)', s.r, s.g, s.b, s.a) end,
}

material_meta = {
    __index = function(self) return function() return self end end,
    __tostring = function(s) return 'IMaterial[' .. tostring(s.__name) .. ']' end,
}

function Vector(x, y, z)
    if type(x) == 'table' then return newvector(x.x, x.y, x.z) end
    return newvector(x, y, z)
end

function Angle(p, y, r)
    if type(p) == 'table' then return newangle(p.p, p.y, p.r) end
    return newangle(p, y, r)
end

function Color(r, g, b, a)
    return setmetatable({ r = r or 255, g = g or 255, b = b or 255, a = a or 255 }, color_meta)
end

function ColorAlpha(c, a)
    return Color(c.r, c.g, c.b, a)
end

function NamedColor() return Color(255, 255, 255, 255) end
function HSVToColor() return Color(255, 255, 255, 255) end

function Material(name, params)
    return setmetatable({ __name = name, __params = params }, material_meta)
end

function CreateMaterial(name, shader, data)
    return setmetatable({ __name = name, __shader = shader, __data = data }, material_meta)
end

-- == type predicates ========================================================

function isnumber(v) return type(v) == 'number' end
function isstring(v) return type(v) == 'string' end
function istable(v) return type(v) == 'table' end
function isfunction(v) return type(v) == 'function' end
function isbool(v) return type(v) == 'boolean' end
function isvector(v) return getmetatable(v) == vector_meta end
function isangle(v) return getmetatable(v) == angle_meta end
function IsColor(v) return type(v) == 'table' and v.r ~= nil and v.g ~= nil and v.b ~= nil end
function isentity(v) return type(v) == 'table' and v.__isentity == true end
IsEntity = isentity
function IsValid(v) return v ~= nil and v ~= false and v ~= NULL end
function tobool(v)
    if v == nil or v == false or v == 0 or v == '0' or v == 'false' then return false end
    return true
end
function TypeID() return 0 end

-- == lerp helpers (operate on the above types) ==============================

function Lerp(t, a, b) return a + (b - a) * t end
function LerpVector(t, a, b) return newvector(Lerp(t, a.x, b.x), Lerp(t, a.y, b.y), Lerp(t, a.z, b.z)) end
function LerpAngle(t, a, b) return newangle(Lerp(t, a.p, b.p), Lerp(t, a.y, b.y), Lerp(t, a.r, b.r)) end

-- These metatables carry a permissive __index (any missing key returns a
-- function), so duck-typing a captured value (IsColor's r/g/b check) misfires.
-- Expose them by identity so the defaults extractor can tell the types apart.
__HARNESS.meta = {
    vector = vector_meta,
    angle = angle_meta,
    color = color_meta,
    material = material_meta,
}
