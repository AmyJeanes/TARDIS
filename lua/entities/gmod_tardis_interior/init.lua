AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

ENT:AddHook("PlayerInitialize", "interior", function(self)
    net.WriteString(self.metadata.ID)

    net.WriteBool(self.templates ~= nil)
    if self.templates ~= nil then
        net.WriteString(TARDIS.von.serialize(self.templates))
    end
end)

ENT:AddHook("PostPlayerInitialize", "senddata", function(self,ply)
    self:SendData(ply)
end)

ENT:AddHook("PostInitialize", "save_interior_position", function(self,ply)
    self:SetData("interior_saved_pos", self:GetPos())
    self:SetData("interior_saved_map", game.GetMap())
end)

ENT:AddHook("SetupPosition", "restore_position", function(self,pos)
    local saved_pos = self:GetData("interior_saved_pos")
    if not saved_pos then return end

    if game.GetMap() ~= self:GetData("interior_saved_map") then return end

    local td={
        mins=self.mins or self:OBBMins(),
        maxs=self.maxs or self:OBBMaxs(),
        start=saved_pos,
        endpos=saved_pos,
        filter = function(ent)
            if ent.TardisInterior then return true end
            return false
        end
    }

    if not util.TraceHull(td).Hit and
        self:CallHook("AllowInteriorPos",nil,saved_pos,td.mins,td.maxs)~=false
    then
        return saved_pos
    end

    return pos
end)

ENT:AddHook("ShouldRemoveProp", "restore", function(self,prop)
    if prop:IsVehicle() then
        return true
    end
    if not IsValid(self.exterior) and not self.exterior_deleted and not prop.TardisPart then
        return false
    end
end)

function ENT:Initialize()
    if not IsValid(self.exterior) then
        self:Remove()
        return
    end

    self.interior = self
    if self.spacecheck then
        self.metadata=TARDIS:CreateInteriorMetadata(self.exterior.metadataID, self)
        self.Model=self.metadata.Interior.Model
        self.Fallback=self.metadata.Interior.Fallback
        self.Portal=self.metadata.Interior.Portal
        self.CustomPortals=self.metadata.Interior.CustomPortals
        if self.metadata.Interior.ExitBox then
            self.ExitBox=self.metadata.Interior.ExitBox
        else
            self.ExitDistance=self.metadata.Interior.ExitDistance
        end
        self.mins=self.metadata.Interior.Size.Min
        self.maxs=self.metadata.Interior.Size.Max
    end
    self.BaseClass.Initialize(self)
end

function ENT:OnTakeDamage(dmginfo)
    if self:CallHook("ShouldTakeDamage",dmginfo)==false then return end
    self:CallHook("OnTakeDamage", dmginfo)
end