---@meta

-- glua-api-snippets types enum-parameter functions (Panel:Dock, SetCollisionGroup,
-- GetRenderTargetEx, ...) and the Trace.mask field with strict literal-union aliases
-- (DOCK, COLLISION_GROUP, MASK, ...) but types the matching constants as plain `integer`,
-- so passing them trips param-type-mismatch / assign-type-mismatch. Re-type each constant
-- we use as its alias so call sites match. Add a line here when a new strictly-typed enum
-- constant gets used - the LSP flags it the moment it does.
---@type DOCK
FILL = 1
---@type DOCK
LEFT = 2
---@type DOCK
RIGHT = 3
---@type DOCK
TOP = 4
---@type DOCK
BOTTOM = 5
---@type COLLISION_GROUP
COLLISION_GROUP_NONE = 0
---@type COLLISION_GROUP
COLLISION_GROUP_DEBRIS = 1
---@type COLLISION_GROUP
COLLISION_GROUP_IN_VEHICLE = 10
---@type DMG
DMG_BLAST = 64
---@type DMG
DMG_BURN = 8
---@type DMG
DMG_SLOWBURN = 2097152
---@type DMG
DMG_DIRECT = 268435456
---@type MASK
MASK_NPCWORLDSTATIC = 131083
---@type MASK
MASK_PLAYERSOLID = 33636363
---@type RT_SIZE
RT_SIZE_LITERAL = 8
---@type MATERIAL_RT_DEPTH
MATERIAL_RT_DEPTH_SEPARATE = 1
---@type CREATERENDERTARGETFLAGS
CREATERENDERTARGETFLAGS_UNFILTERABLE_OK = 4
---@type EF
EF_BONEMERGE = 1

-- glua-api-snippets types debug.getinfo's first param as `function`, but the
-- runtime accepts a stack-level number too (and that's how TARDIS uses it).
---@param funcOrStackLevel function|integer
---@param fields? string
---@param _function? function
---@return DebugInfo
function debug.getinfo(funcOrStackLevel, fields, _function) end

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

---@class DListView
---@field OnRowSelected fun(self: DListView, lineID: integer, line: DListView_Line)
---@field OnRowSelectionRemoved fun(self: DListView, lineID: integer, line: DListView_Line)
---@field DoDoubleClick fun(self: DListView, lineID: integer, line: DListView_Line)

---@class DCheckBoxLabel
---@field OnChange fun(self: DCheckBoxLabel, value: boolean)

-- glua-api-snippets declares panel hook signatures on PANEL, while
-- vgui.Create returns Panel descendants. Mirror common hook fields here
-- so ad-hoc instance overrides infer their arguments.
---@class Panel
---@field PerformLayout fun(self: Panel, width: number, height: number)?

-- Panel fields set by our 3D2D vgui wrapper (cl_3d2dvgui.lua's Paint3D2D
-- attaches the active orientation back onto the panel so it can be read
-- after the render loop in IsPointingPanel and friends).
---@class Panel
---@field Origin Vector
---@field Scale number
---@field Angle Angle
---@field Normal Vector

