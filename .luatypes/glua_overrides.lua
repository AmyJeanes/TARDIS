---@meta

-- glua-api-snippets declares enum aliases (MASK, COLLISION_GROUP, _USE, etc.) as
-- string-literal unions for autocomplete, but the corresponding MASK_*, COLLISION_GROUP_*,
-- *_USE constants are plain integers at runtime. Re-declare the aliases as `integer` so
-- assignments like `Trace.mask = MASK_NPCWORLDSTATIC` type-check.

---@alias MASK integer
---@alias COLLISION_GROUP integer
---@alias _USE integer
---@alias DMG integer
---@alias RT_SIZE integer
---@alias MATERIAL_RT_DEPTH integer
---@alias CREATERENDERTARGETFLAGS integer
---@alias BOX integer

-- glua-api-snippets types debug.getinfo's first param as `function`, but the
-- runtime accepts a stack-level number too (and that's how TARDIS uses it).
---@param funcOrStackLevel function|integer
---@param fields? string
---@param _function? function
---@return DebugInfo
function debug.getinfo(funcOrStackLevel, fields, _function) end
