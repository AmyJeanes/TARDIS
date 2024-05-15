-- Helper functions

function TARDIS:GetExteriorEnt(ply)
    return (CLIENT and LocalPlayer() or ply):GetTardisData("exterior")
end

function TARDIS:GetInteriorEnt(ply)
    return (CLIENT and LocalPlayer() or ply):GetTardisData("interior")
end

function TARDIS:Benchmark(name,func)
    local time=SysTime()
    func()
    time=(SysTime()-time)*1000
    cam.Start2D()
        draw.DrawText(name.." took "..time .."ms","DermaLarge",50,1000*math.random(),Color(255,255,255,255),TEXT_ALIGN_LEFT)
    cam.End2D()
end

function TARDIS:GetLocalPos(ent,ply)
    local int=self:GetInteriorEnt(ply)
    if IsValid(int) and IsValid(ent) then
        return int:WorldToLocal(ent:GetPos()),int:WorldToLocalAngles(ent:GetAngles())
    else
        return false
    end
end
concommand.Add("tardis_getlocal",function(ply,cmd,args)
    local decimals=tonumber(args[1])
    local ent=ply:GetEyeTraceNoCursor().Entity
    local pos,ang=TARDIS:GetLocalPos(ent,ply)
    print("Vector("..math.Round(pos.x,decimals)..","..math.Round(pos.y,decimals)..","..math.Round(pos.z,decimals)..")")
    print("Angle("..math.Round(ang.p,decimals)..","..math.Round(ang.y,decimals)..","..math.Round(ang.r,decimals)..")")
end)

-- Thanks world-portals!
function TARDIS:IsBehind( object_pos, plane_pos, plane_forward )
    local vec = object_pos - plane_pos

    if plane_forward:Dot( vec ) < 0 then
        return true
    end
    return false
end

local pp_trace = {
    ["AllSolid"] = false,
    ["Contents"] = bit.bor(CONTENTS_HITBOX,CONTENTS_SOLID),
    ["DispFlags"] = 0,
    ["Entity"] = NULL,
    ["Fraction"] = 1,
    ["FractionLeftSolid"] = 0,
    ["Hit"] = true,
    ["HitBox"] = 0,
    ["HitBoxBone"] = 0,
    ["HitGroup"] = 0,
    ["HitNoDraw"] = false,
    ["HitNonWorld"] = true,
    ["HitNormal"] = Vector(),
    ["HitPos"] = Vector(),
    ["HitSky"] = false,
    ["HitTexture"] = "**studio**",
    ["HitWorld"] = false,
    ["MatType"] = MAT_WOOD,
    ["Normal"] = Vector(),
    ["PhysicsBone"] = 0,
    ["StartPos"] = Vector(),
    ["StartSolid"] = false,
    ["SurfaceFlags"] = SURF_HITBOX,
    ["SurfaceProps"] = 0
}

-- Prop Protection
function TARDIS:CheckPP(ply, ent)
    pp_trace.Entity = ent
    return hook.Call("CanTool", GAMEMODE, ply, pp_trace, "")
end

TARDIS.color_white_vector = Vector(1,1,1)

--[[
local meta=FindMetaTable("Player")
meta.OldSetEyeAngles=meta.OldSetEyeAngles or meta.SetEyeAngles
function meta:SetEyeAngles(...)
    print(...)
    print(debug.traceback())
    self:OldSetEyeAngles(...)
end

hook.Add("HUDPaint", "tardis-debug", function()
    local ply=LocalPlayer()
    local int=TARDIS:GetInteriorEnt(ply)
    if IsValid(int) then
        local portals=int.portals
        local e=ply:EyeAngles()
        local l=portals.interior:WorldToLocalAngles(e)
        local n=portals.exterior:LocalToWorldAngles(l)
        draw.SimpleText(tostring(e), "DermaLarge", 100, 50, Color(86, 104, 86, 255), 0, 0)
        draw.SimpleText(tostring(l), "DermaLarge", 100, 100, Color(86, 104, 86, 255), 0, 0)
        draw.SimpleText(tostring(n), "DermaLarge", 100, 150, Color(86, 104, 86, 255), 0, 0)
    end
end)
]]--