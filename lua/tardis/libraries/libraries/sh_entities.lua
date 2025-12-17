local exts = {}
local ints = {}
local extsbycreator = {}
local intsbycreator = {}

local function updateexts()
    if not Doors or not Doors.Exteriors then return end
    exts = {}
    extsbycreator = {}
    for ent,_ in pairs(Doors.Exteriors) do
        if not IsValid(ent) or not ent.TardisExterior then return end
        table.insert(exts, ent)
        local creator=ent:GetCreator()
        if not extsbycreator[creator] then extsbycreator[creator]={} end
        table.insert(extsbycreator[creator], ent)
    end
end

local function updateints()
    if not Doors or not Doors.Interiors then return end
    ints = {}
    intsbycreator = {}
    for ent,_ in pairs(Doors.Interiors) do
        if not IsValid(ent) or not ent.TardisInterior then return end
        table.insert(ints, ent)
        local creator=ent:GetCreator()
        if not intsbycreator[creator] then intsbycreator[creator]={} end
        table.insert(intsbycreator[creator], ent)
    end
end

updateexts()
updateints()

hook.Add("Doors-ExteriorAdded", "TARDIS_UpdateExteriors", updateexts)
hook.Add("Doors-ExteriorRemoved", "TARDIS_UpdateExteriors", updateexts)

hook.Add("Doors-InteriorAdded", "TARDIS_UpdateInteriors", updateints)
hook.Add("Doors-InteriorRemoved", "TARDIS_UpdateInteriors", updateints)

function TARDIS:GetExteriorEnts(ply)
    if ply then
        return extsbycreator[ply] or {}
    end
    return exts
end

function TARDIS:GetInteriorEnts(ply)
    if ply then
        return intsbycreator[ply] or {}
    end
    return ints
end

function TARDIS:GetExteriorEnt(ply)
    return (CLIENT and LocalPlayer() or ply):GetTardisData("exterior")
end

function TARDIS:GetInteriorEnt(ply)
    return (CLIENT and LocalPlayer() or ply):GetTardisData("interior")
end
