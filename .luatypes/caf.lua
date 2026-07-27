---@meta

-- Type annotations only - never executed. The declarations below define real
-- globals and library functions with empty bodies, so loading this file at
-- runtime would replace working functions with stubs rather than declare them.
-- It lives outside lua/ so the game cannot reach it; this is the backstop.
error("caf.lua contains type annotations only and must never be executed")

-- CAF — Custom Addon Framework (legacy Spacebuild dependency, not commonly installed).
-- Stub kept since CAF isn't a sibling addon.

---@class CAF
CAF = {}

---@param name string
---@return any?
function CAF.GetAddon(name) end