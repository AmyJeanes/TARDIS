-- Control

if SERVER then
    util.AddNetworkString("TARDIS-Control")
end

local controls={}

function TARDIS:AddControl(control)
    if CLIENT or (SERVER and (not control.clientonly)) then
        controls[control.id] = table.Copy(control)
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
        ext:CallCommonHook("TardisControlUsed", control_id, ply, part)
    end
end

net.Receive("TARDIS-Control", function(_,ply)
    TARDIS:Control(net.ReadString(), ply)
end)

TARDIS:LoadFolder("controls")