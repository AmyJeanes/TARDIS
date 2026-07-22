---@meta
-- Local annotation overrides for gaps in the provisioned GLua annotations.

-- The annotations model stock Lua's 3-arg debug.getinfo(thread, f, what); GMod's
-- takes (funcOrStackLevel, fields) - a stack-level number is how TARDIS uses it.
---@diagnostic disable-next-line: duplicate-set-field
---@param funcOrStackLevel function|integer
---@param fields? string
---@return debuglib.DebugInfo
function debug.getinfo(funcOrStackLevel, fields) end

-- MatProxyData.bind's second argument is typed as the material NAME string
-- upstream (faithfully scraped from wiki prose), but the engine passes the
-- IMaterial itself - the wiki's own example calls SetVector on it. The ent
-- argument is also nil for world materials. Re-declare with the real types.
---@diagnostic disable-next-line: duplicate-set-field
---@param matProxyData { name: string, init: (fun(self: table, mat: IMaterial, values: table)), bind: fun(self: table, mat: IMaterial, ent: Entity?) }
function matproxy.Add(matProxyData) end

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

