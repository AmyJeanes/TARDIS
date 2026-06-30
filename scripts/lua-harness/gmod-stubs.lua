-- GMod environment stubs for the headless content-loading harness.
--
-- The interpreter is plain Lua; the prelude files fill in the Garry's Mod
-- globals the addon expects so its content-definition files load without
-- crashing. Only load-time behaviour needs to be faithful: constructors that
-- record their args, the GMod string/table/math extensions used while building
-- definition tables, and a real file.Find/include backed by the host bridge.
-- The long tail of engine calls (render/surface/net/...) is absorbed by
-- permissive namespace stubs, so a member never reached at load time is a
-- silent no-op rather than a missing-global crash.
--
-- run-harness.ps1 loads the prelude in pieces (order-independent - every
-- cross-file reference resolves at call time):
--   gmod-stubs.lua   this file: harness machinery + engine environment
--   gmod-types.lua   Vector/Angle/Color/Material constructors + predicates
--   gmod-string.lua  ) GMod stdlib extensions, ported verbatim from Facepunch's
--   gmod-table.lua   ) source (linked at the top of each) so they behave
--   gmod-math.lua    ) exactly like the engine's.
--
-- Realm flags (SERVER/CLIENT) and the __host_* bridge functions are injected by
-- run-harness.ps1 before these files run.
--
-- Excluded from glua analysis (.luarc.json ignoreGlobs): redefining the whole
-- GMod API here pollutes the analyzer's shared workspace type model and would
-- flag the real addon code. The harness runs under MoonSharp, not glua_ls.

local rawset, setmetatable, getmetatable = rawset, setmetatable, getmetatable
local tostring, tonumber, ipairs, pairs = tostring, tonumber, ipairs, pairs
local sformat, sgmatch = string.format, string.gmatch

-- Bridge functions injected as globals by run-harness.ps1 before this file runs.
-- Pulled off _G with type signatures so the analyzer treats them as known.
---@type fun(pattern: string, pathid: string, kind: string): string
__host_findfiles = _G.__host_findfiles
---@type fun(path: string, pathid?: string): string?
__host_readfile = _G.__host_readfile
---@type fun(message: string)
__host_print = _G.__host_print

local function noop() end

-- A namespace table whose unknown members resolve (once, memoized) to a no-op
-- function. Engine library globals are built from this so `lib.Whatever(...)` is
-- harmless when Whatever is never defined.
local function namespace(seed)
    return setmetatable(seed or {}, {
        __index = function(t, k)
            local f = function() end
            rawset(t, k, f)
            return f
        end,
    })
end

-- Harness-side capture of things the engine would normally own. Parts register
-- as scripted entities; recording those lets a caller enumerate them (and is a
-- coverage signal that the content actually loaded).
__HARNESS = { sents = {} }

-- == output =================================================================

local function joinargs(...)
    local n = select('#', ...)
    local parts = {}
    for i = 1, n do parts[i] = tostring((select(i, ...))) end
    return table.concat(parts, '\t')
end

function print(...) __host_print(joinargs(...)) end
function Msg(...) __host_print(joinargs(...)) end
function MsgN(...) __host_print(joinargs(...)) end
function MsgC(...) __host_print(joinargs(...)) end
function ErrorNoHalt(...) __host_print('[ErrorNoHalt] ' .. joinargs(...)) end
function ErrorNoHaltWithStack(...) __host_print('[Error] ' .. joinargs(...)) end

-- == entities / metatables ==================================================

-- A null entity: present (not nil) but never valid, like GMod's NULL.
NULL = setmetatable({}, {
    __index = function() return noop end,
    __tostring = function() return '[NULL Entity]' end,
})
GAMEMODE = namespace({})
GM = GAMEMODE

-- Engine type metatables. Addons fetch these to hang methods off Panel/Entity/
-- etc.; returning a stable table per name lets those definitions take.
local _metatables = {}
function FindMetaTable(name)
    local mt = _metatables[name]
    if not mt then
        mt = {}
        mt.__index = mt
        mt.MetaName = name
        _metatables[name] = mt
    end
    return mt
end
function RegisterMetaTable(name, tbl) _metatables[name] = tbl end

-- == base helpers ===========================================================

function Either(c, a, b) if c then return a else return b end end
function Format(...) return sformat(...) end
function CurTime() return 0 end
function RealTime() return 0 end
function SysTime() return 0 end
function FrameTime() return 0 end
function RealFrameTime() return 0 end
function UnPredictedCurTime() return 0 end
function IsFirstTimePredicted() return true end
function ScrW() return 1920 end
function ScrH() return 1080 end
function ScreenScale(s) return s end
function LocalPlayer() return NULL end
function SortedPairs(t) return pairs(t) end
function SortedPairsByValue(t) return pairs(t) end
function SortedPairsByMemberValue(t) return pairs(t) end
function RandomPairs(t) return pairs(t) end

-- == config / convars =======================================================

local function makeConVar(default)
    local value = default
    local methods
    methods = {
        GetBool = function() return tobool(value) end,
        GetInt = function() return math.floor(tonumber(value) or 0) end,
        GetFloat = function() return tonumber(value) or 0 end,
        GetString = function() return tostring(value) end,
        GetDefault = function() return tostring(default) end,
        GetName = function() return '' end,
        GetHelpText = function() return '' end,
        SetValue = function(_, v) value = v end,
        IsValid = function() return true end,
    }
    return setmetatable({}, { __index = function(_, k) return methods[k] or noop end })
end

function CreateConVar(name, default) return makeConVar(default) end
function CreateClientConVar(name, default) return makeConVar(default) end
function GetConVar() return makeConVar(nil) end
function GetConVar_Internal() return makeConVar(nil) end
function GetConVarString() return '' end
function GetConVarNumber() return 0 end
function RunConsoleCommand() end

-- == loading ================================================================

function AddCSLuaFile() end
function require() end

function CompileString(code, identifier, handleError)
    local fn, err = load(code, identifier or 'CompileString')
    if not fn and handleError ~= false then error(err) end
    return fn or err
end

function CompileFile(path)
    local src = __host_readfile(path, 'LUA')
    if not src then return nil end
    return load(src, '@' .. path)
end

function RunString(code, identifier)
    local fn = load(code, identifier or 'RunString')
    if fn then return fn() end
end
RunStringEx = RunString

-- Tracks the file currently being included so debug.getinfo can report a
-- meaningful short_src (the addon uses it to attribute/dedupe registrations).
local _source_stack = {}

function include(path)
    local src = __host_readfile(path, 'LUA')
    if not src then error('include: file not found: ' .. tostring(path)) end
    local fn, err = load(src, '@' .. path)
    if not fn then error('include: ' .. tostring(err)) end
    _source_stack[#_source_stack + 1] = path
    local function finish(...)
        _source_stack[#_source_stack] = nil
        return ...
    end
    return finish(fn())
end

-- MoonSharp's debug.getinfo doesn't populate short_src; back it with the
-- include stack so callers that key off the calling file behave.
debug = debug or {}
function debug.getinfo()
    local src = _source_stack[#_source_stack] or 'harness'
    return {
        short_src = src,
        source = '@' .. src,
        currentline = -1,
        what = 'Lua',
        linedefined = -1,
        lastlinedefined = -1,
        nups = 0,
    }
end
debug.traceback = debug.traceback or function(msg) return msg or '' end
debug.getmetatable = debug.getmetatable or getmetatable
debug.setmetatable = debug.setmetatable or setmetatable

-- == bit / jit ==============================================================

-- bit32 (MoonSharp provides it; fetched via rawget so the LuaJIT-configured
-- analyzer doesn't flag the 5.2-only global) gives GMod's bit.* the same names.
bit = rawget(_G, 'bit32') or namespace({})
if bit.rol == nil then bit.rol = bit.lrotate or noop end
if bit.ror == nil then bit.ror = bit.rrotate or noop end
if bit.tobit == nil then bit.tobit = function(x) return x end end
if bit.tohex == nil then bit.tohex = function(x) return sformat('%x', x or 0) end end

jit = {
    version = 'LuaJIT 2.0.4 (harness)',
    version_num = 20004,
    os = 'Windows',
    arch = 'x64',
    status = function() return false end,
    on = noop,
    off = noop,
}

-- == file ===================================================================

file = namespace({
    Find = function(pattern, pathid)
        local files, dirs = {}, {}
        local fstr = __host_findfiles(pattern, pathid or 'GAME', 'f')
        local dstr = __host_findfiles(pattern, pathid or 'GAME', 'd')
        local i = 1
        for name in sgmatch(fstr, '[^\n]+') do files[i] = name; i = i + 1 end
        i = 1
        for name in sgmatch(dstr, '[^\n]+') do dirs[i] = name; i = i + 1 end
        return files, dirs
    end,
    Read = function(path, pathid) return __host_readfile(path, pathid or 'DATA') end,
    Exists = function(path, pathid) return __host_readfile(path, pathid or 'GAME') ~= nil end,
    IsDir = function() return false end,
    CreateDir = noop,
    Write = noop,
    Append = noop,
    Delete = noop,
    Size = function() return 0 end,
    Time = function() return 0 end,
    Open = function() return nil end,
})

-- == hook / timer / concommand =============================================

hook = namespace({
    Add = noop,
    Remove = noop,
    Run = noop,
    Call = noop,
    GetTable = function() return {} end,
})

timer = namespace({
    Create = noop,
    Simple = noop,
    Adjust = noop,
    Remove = noop,
    Exists = function() return false end,
    Start = noop,
    Stop = noop,
    Pause = noop,
    UnPause = noop,
})

concommand = namespace({ Add = noop, Remove = noop })
cvars = namespace({ AddChangeCallback = noop, RemoveChangeCallback = noop })

-- == list (real store; spawnmenu/registry lookups depend on it) =============

local _lists = {}
list = namespace({
    Set = function(name, key, value)
        _lists[name] = _lists[name] or {}
        _lists[name][key] = value
    end,
    Add = function(name, value)
        _lists[name] = _lists[name] or {}
        _lists[name][#_lists[name] + 1] = value
    end,
    Get = function(name) return _lists[name] or {} end,
    GetForEdit = function(name)
        _lists[name] = _lists[name] or {}
        return _lists[name]
    end,
})

-- == permissive engine namespaces ===========================================

for _, name in ipairs({
    'render', 'surface', 'draw', 'cam', 'mesh', 'matrix', 'util', 'net', 'sound',
    'ents', 'player', 'team', 'game', 'engine', 'gui', 'input', 'vgui', 'derma',
    'spawnmenu', 'controlpanel', 'properties', 'numpad', 'scripted_ents',
    'weapons', 'killicon', 'halo', 'matproxy', 'dragndrop', 'cookie',
    'achievements', 'gmod', 'motionsensor', 'navmesh', 'physenv', 'constraint',
    'undo', 'cleanup', 'duplicator', 'resource', 'usermessage', 'umsg',
    'debugoverlay', 'effects', 'ai', 'ai_task', 'ai_schedule', 'presets',
    'search', 'notification', 'chat', 'markup', 'http', 'steamworks', 'system',
    'language', 'menubar', 'frame_blur', 'baseclass', 'widgets', 'serverlist',
    'GWEN',
}) do
    if _G[name] == nil then _G[name] = namespace({}) end
end

-- A few namespace members need a non-nil return at load time. tobool comes from
-- gmod-types.lua; wrap it so this doesn't depend on file load order.
util.AddNetworkString = noop
util.PrecacheModel = noop
util.PrecacheSound = noop
util.tobool = function(v) return tobool(v) end
scripted_ents.Register = function(t, name) __HARNESS.sents[name] = t or true end
weapons.Register = noop
language.Add = noop
engine.ActiveGamemode = function() return 'sandbox' end
game.SinglePlayer = function() return false end
game.MaxPlayers = function() return 1 end
baseclass.Get = function() return {} end
baseclass.Set = noop
