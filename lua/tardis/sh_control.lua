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
    if control_moves[hook] then
        for id, func in pairs(control_moves[hook]) do
            if ent.controlparts and ent.controlparts[id] and ent.controlpartsactive and not ent.controlpartsactive[id] then
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