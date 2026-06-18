---@meta

-- glua-api-snippets types Trace.mask as the MASK enum union, but the MASK_*
-- constants are plain integers at runtime, so `Trace.mask = MASK_NPCWORLDSTATIC`
-- warns as assign-type-mismatch. Widen the field to accept integer; keep it
-- optional (?) so Trace literals that omit mask don't trip missing-fields.
---@class Trace
---@field mask integer?

-- glua-api-snippets types debug.getinfo's first param as `function`, but the
-- runtime accepts a stack-level number too (and that's how TARDIS uses it).
---@param funcOrStackLevel function|integer
---@param fields? string
---@param _function? function
---@return DebugInfo
function debug.getinfo(funcOrStackLevel, fields, _function) end

-- glua-api-snippets types ColorAlpha's return as `table`, but at runtime it
-- returns a Color (Color(col.r, col.g, col.b, alpha)), so values flowing into
-- Color-typed params (draw.*, render.*) warn. Re-declaring the function doesn't
-- override the library's return type (the stub wins), but adding a Color-returning
-- overload does — same trick as table.insert below.
---@diagnostic disable-next-line: duplicate-set-field
---@overload fun(color: Color, alpha: number): Color
function _G.ColorAlpha(color, alpha) end

-- glua-api-snippets only declares the 3-arg signature of table.insert; without
-- a 2-arg overload, the analyzer flags every `table.insert(t, value)` call as
-- passing a non-number where it expects `position`. Re-declare with both forms.
---@diagnostic disable-next-line: duplicate-set-field
---@overload fun(tbl: table, value: any): integer
---@param tbl table
---@param position integer
---@param value any
---@return integer
function table.insert(tbl, position, value) end

-- DModelPanel internal fields/methods that GMod sets at runtime but
-- glua-api-snippets only exposes via getter/setter pairs. We rely on
-- direct field access in cl_vgui.lua's RT-based DModelPanel3D2D wrapper.
---@class DModelPanel
---@field Entity Entity
---@field vCamPos Vector
---@field vLookatPos Vector
---@field aLookAngle Angle?
---@field colAmbientLight Color
---@field colColor Color
---@field FarZ number
---@field fFOV number
---@field rt_w number
---@field rt_h number
---@field DirectionalLight table<integer, Color?>
function DModelPanel:LayoutEntity(ent) end
function DModelPanel:PostDrawModel(ent) end
function DModelPanel:PreDrawModel(ent) end

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

-- DListView_Line:DoDoubleClick is the row's double-click hook (assigned, not called).
---@class DListView_Line
---@field DoDoubleClick fun(self: DListView_Line)

-- Panel fields set by our 3D2D vgui wrapper (cl_3d2dvgui.lua's Paint3D2D
-- attaches the active orientation back onto the panel so it can be read
-- after the render loop in IsPointingPanel and friends).
---@class Panel
---@field Origin Vector
---@field Scale number
---@field Angle Angle
---@field Normal Vector

