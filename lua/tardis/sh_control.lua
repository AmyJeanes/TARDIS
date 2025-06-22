-- Control

if SERVER then
    util.AddNetworkString("TARDIS-Control")
end

local controls={}
local control_moves = {}
local controlling_via_part = false

function TARDIS:AddControl(control)
    if CLIENT or (SERVER and (not control.clientonly)) then
        local copy = table.Copy(control)
        controls[control.id] = copy
        TARDIS:RegisterControlMoves(copy)
    end
end

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

function TARDIS:CallControlMove(ent, hook, ...)
    if not controlling_via_part and control_moves[hook] then
        for id, func in pairs(control_moves[hook]) do
            if ent.controlparts and ent.controlparts[id] then
                for _, part in pairs(ent.controlparts[id]) do
                    if not part.NoAutoMove and (func == true or func(ent, part, ...)) then
                        TARDIS:TogglePart(part)
                    end
                end
            end
        end
    end
end

function TARDIS:RemoveControl(id)
    controls[id]=nil
end

function TARDIS:GetControls()
    return controls
end

function TARDIS:GetControl(id, ent)
    if ent and ent.metadata.CustomControls and ent.metadata.CustomControls[id] then
        return ent.metadata.CustomControls[id]
    end

    if controls[id] then
        return controls[id]
    end
end

function TARDIS:Control(control_id, ply, part)
    if CLIENT then ply = LocalPlayer() end
    if not ply:IsPlayer() then return end

    local ext = ply:GetTardisData("exterior")
    local control = TARDIS:GetControl(control_id, ext)

    if control and IsValid(ext) then
        local int = ply:GetTardisData("interior")
        if ext:CallCommonHook("CanUseTardisControl", control, ply, part) == false then
            return
        end
        if IsValid(part) then
            controlling_via_part = true
        end
        local res_ext, res_int
        local cl_serv_ok = (CLIENT and not control.serveronly) or (SERVER and not control.clientonly)
        if cl_serv_ok and control.ext_func then
            res_ext = control.ext_func(ext, ply, part)
        end
        if cl_serv_ok and control.int_func and IsValid(int) then
            res_int = control.int_func(int, ply, part)
        end
        if CLIENT and (res_ext ~= false) and (res_int ~= false) and (not control.clientonly) then
            net.Start("TARDIS-Control")
                net.WriteString(control_id)
            net.SendToServer()
        end
        controlling_via_part = false
        ext:CallCommonHook("TardisControlUsed", control_id, ply, part)
    end
end

net.Receive("TARDIS-Control", function(_,ply)
    TARDIS:Control(net.ReadString(), ply)
end)

TARDIS:LoadFolder("controls")