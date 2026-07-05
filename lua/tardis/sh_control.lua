-- Control

if SERVER then
    util.AddNetworkString("TARDIS-Control")
end

---@class tardis_control
---@field id string
---@field ext_func (fun(self: gmod_tardis, ply: Player, part: gmod_tardis_part?, complete: fun(ent: gmod_tardis)): boolean?)?
---@field int_func (fun(self: gmod_tardis_interior, ply: Player, part: gmod_tardis_part?, complete: fun(ent: gmod_tardis_interior)): boolean?)?
---@field serveronly boolean?
---@field clientonly boolean?
---@field power_independent boolean
---@field bypass_isomorphic boolean?
---@field bypass_console_toggle boolean?
---@field tip_text string?
---@field moves table<string, true|fun(self: gmod_tardis|gmod_tardis_interior, part: gmod_tardis_part, ...): boolean?>?
---@field screen_button tardis_screen_button|false?

---@class tardis_screen_button
---@field mmenu boolean?
---@field virt_console boolean?
---@field popup_only boolean?
---@field id string?
---@field toggle boolean?
---@field frame_type integer[]?
---@field text string?
---@field pressed_state_data string|string[]?
---@field pressed_state_from_interior boolean?
---@field order integer?

---@type table<string, tardis_control>
local controls={}
local control_moves = {}

-- Functionally identical to {} but gives proper type checking for controls
---@api
---@return tardis_control
function TARDIS:NewControl()
    return {}
end

---@api
---@param control table
function TARDIS:AddControl(control)
    if CLIENT or (SERVER and (not control.clientonly)) then
        ---@type tardis_control
        local copy = table.Copy(control)
        controls[control.id] = copy
        TARDIS:RegisterControlMoves(copy)
    end
end

---@param control tardis_control
function TARDIS:RegisterControlMoves(control)
    for k,v in pairs(control_moves) do
        if v[control.id] then
            control_moves[k][control.id] = nil
        end
    end
    if control.moves then
        for hook, val in pairs(control.moves) do
            control_moves[hook] = control_moves[hook] or {}
            control_moves[hook][control.id] = val
        end
    end
end

function TARDIS:GetControlMoves()
    return control_moves
end

---@param ent gmod_tardis|gmod_tardis_interior
---@param hook string
function TARDIS:CallControlMove(ent, hook, ...)
    if control_moves[hook] then
        for id, func in pairs(control_moves[hook]) do
            local control_parts = ent.controlparts and ent.controlparts[id]
            if control_parts and ent.controlpartsactive and not ent.controlpartsactive[id] then
                for _, part in pairs(control_parts) do
                    if not part.NoAutoMove and (func == true or func(ent, part, ...)) then
                        TARDIS:TogglePart(part)
                    end
                end
            end
        end
    end
end

---@api
---@param id string
function TARDIS:RemoveControl(id)
    controls[id]=nil
end

---@api
function TARDIS:GetControls()
    return controls
end

---@api
---@param id string
---@param ent (gmod_tardis|gmod_tardis_interior)?
---@return tardis_control?
function TARDIS:GetControl(id, ent)
    if ent and ent.metadata.CustomControls and ent.metadata.CustomControls[id] then
        return ent.metadata.CustomControls[id]
    end

    if controls[id] then
        return controls[id]
    end
end

---@api
---@param control_id string
---@param ply Player
---@param part gmod_tardis_part?
function TARDIS:Control(control_id, ply, part)
    if CLIENT then ply = LocalPlayer() end
    if not ply:IsPlayer() then return end

    local ext = ply:GetTardisExterior()
    local control = TARDIS:GetControl(control_id, ext)

    if control and IsValid(ext) then
        local int = ply:GetTardisInterior()
        if ext:CallCommonHook("CanUseTardisControl", control, ply, part) == false then
            return
        end
        if not ext.controlpartsactive then
            ext.controlpartsactive = {}
        end
        if IsValid(int) and not int.controlpartsactive then
            int.controlpartsactive = ext.controlpartsactive
        end
        if IsValid(part) then
            ext.controlpartsactive[control_id] = part
        end
        local async_complete = function(ent)
            if ent.controlpartsactive then
                ent.controlpartsactive[control_id] = false
            end
        end
        local use_async_ext, use_async_int
        local cl_serv_ok = (CLIENT and not control.serveronly) or (SERVER and not control.clientonly)
        if cl_serv_ok and control.ext_func then
            use_async_ext = control.ext_func(ext, ply, part, async_complete)
        end
        if cl_serv_ok and control.int_func and IsValid(int) then
            use_async_int = control.int_func(int, ply, part, async_complete)
        end
        if CLIENT and not control.clientonly then
            net.Start("TARDIS-Control")
                net.WriteString(control_id)
            net.SendToServer()
        end
        if not use_async_ext and not use_async_int then
            ext.controlpartsactive[control_id] = false
        end
        ext:CallCommonHook("TardisControlUsed", control_id, ply, part)
    end
end

net.Receive("TARDIS-Control", function(_,ply)
    TARDIS:Control(net.ReadString(), ply)
end)

TARDIS:LoadFolder("controls")