---@meta

-- Type annotations only - never executed. The declarations below define real
-- globals and library functions with empty bodies, so loading this file at
-- runtime would replace working functions with stubs rather than declare them.
-- It lives outside lua/ so the game cannot reach it; this is the backstop.
error("wire.lua contains type annotations only and must never be executed")

-- Wiremod's port helpers take an untyped `ent`, so the analyzer back-infers it
-- from every addon that calls them. Declare the entity argument here instead.

---@param ent Entity
---@param names table
---@param types table?
---@param descs table?
function WireLib.CreateSpecialInputs(ent, names, types, descs) end

---@param ent Entity
---@param names table
---@param types table?
---@param descs table?
function WireLib.CreateSpecialOutputs(ent, names, types, descs) end

---@param ent Entity
---@param names table
---@param descs table?
function WireLib.CreateOutputs(ent, names, descs) end

---@param ent Entity
---@param oname string
---@param value any
---@param iter table?
---@param force boolean?
function WireLib.TriggerOutput(ent, oname, value, iter, force) end

---@param ent Entity
---@param names table
---@param descs table?
function Wire_CreateOutputs(ent, names, descs) end

---@param ent Entity
---@param oname string
---@param value any
---@param iter table?
---@param force boolean?
function Wire_TriggerOutput(ent, oname, value, iter, force) end