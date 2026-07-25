---@meta

-- Type annotations only - never executed. The declarations below define real
-- globals and library functions with empty bodies, so loading this file at
-- runtime would replace working functions with stubs rather than declare them.
-- It lives outside lua/ so the game cannot reach it; this is the backstop.
error("glua_overrides.lua contains type annotations only and must never be executed")

-- Local annotation overrides for gaps in the provisioned GLua annotations.

-- The annotations model stock Lua's 3-arg debug.getinfo(thread, f, what); GMod's
-- takes (funcOrStackLevel, fields) - a stack-level number is how TARDIS uses it.
---@param funcOrStackLevel function|integer
---@param fields? string
---@return debuglib.DebugInfo
function debug.getinfo(funcOrStackLevel, fields) end

-- g_ContextMenu's runtime type. The stub in _globals.lua types it as nil
-- and the analyzer's structural inference resolves to PANEL — neither
-- knows about :Open() / :Close() which the sandbox gamemode adds. Cast
-- locals to this class to call those.
---@class ContextMenuPanel : Panel
---@field Open fun(self: ContextMenuPanel)
---@field Close fun(self: ContextMenuPanel)
---@field IsOpen fun(self: ContextMenuPanel): boolean

-- Internal panels exposed as fields rather than getters in GMod's source.
---@class DNumSlider
---@field Label DLabel

---@class DCollapsibleCategory
---@field Container Panel

-- Panel fields set by our 3D2D vgui wrapper (cl_3d2dvgui.lua's Paint3D2D
-- attaches the active orientation back onto the panel so it can be read
-- after the render loop in IsPointingPanel and friends).
---@class Panel
---@field Origin Vector
---@field Scale number
---@field Angle Angle
---@field Normal Vector

-- Stock engine entities with no annotation entry, reached through ents.Create or
-- FindByClass. Without these the analyzer auto-creates the class and warns.
---@class sky_camera : Entity
---@class env_explosion : Entity
---@class env_smokestack : Entity
---@class env_rotorwash_emitter : Entity
