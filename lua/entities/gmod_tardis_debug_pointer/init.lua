-- TARDIS debug pointer
-- Creators: Brundoob, Parar020100 and RyanM2711

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

function ENT:Initialize()

    self:SetModel(self.model or "models/brundoob/precision.mdl" )
    self:SetModelScale(self.scale or 1)

    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_NONE )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetCollisionGroup( COLLISION_GROUP_WORLD )
    self:SetUnFreezable(true)

    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if (phys:IsValid()) then
        phys:EnableMotion(false)
        phys:Wake()
    end

    local ply = self:GetCreator()
    if IsValid(ply) and not IsValid(ply.last_used_tardis_debug_pointer) then
        ply.last_used_tardis_debug_pointer = self
    end
end

function ENT:Use( activator, caller )
    if activator:GetTardisData("interior") then
        local pos,ang = TARDIS:GetLocalPos(self, activator)
        local decimals = 3
        local text =   "  pos = Vector("..math.Round(pos.x,decimals)..", "..math.Round(pos.y,decimals)..", "..math.Round(pos.z,decimals).."),"
        text = text .. "  ang = Angle("..math.Round(ang.p,decimals)..", "..math.Round(ang.y,decimals)..", "..math.Round(ang.r,decimals)..")"
        activator:ChatPrint(" \nCurrent pointer position:")
        activator:ChatPrint(text)
    end
    activator.last_used_tardis_debug_pointer = self
    return
end

function ENT:Think()
end