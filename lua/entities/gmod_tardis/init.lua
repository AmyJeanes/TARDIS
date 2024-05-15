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

if not TARDIS.DoorsFound then
    function ENT:SpawnFunction(ply,...)
        if not scripted_ents.GetStored(self.Base) then
            TARDIS:ErrorMessage(ply, "Common.DoorsNotInstalled")
            ply:SendLua('TARDIS:ShowDoorsPopup()')
            return
        end
    end
end

ENT:AddHook("CustomData", "metadata", function(self, customData)
    if customData.metadataID then
        self.metadataID = customData.metadataID
    end
end)

function ENT:Initialize()
    if IsValid(self:GetCreator()) then
        self.exterior = self
        self.metadata=TARDIS:CreateInteriorMetadata(self.metadataID, self)
        self.Model=self.metadata.Exterior.Model
        self.Portal=self.metadata.Exterior.Portal
        self.Fallback=self.metadata.Exterior.Fallback
        self.BaseClass.Initialize(self)
    end
end

function ENT:PhysicsCollide(colData, collider)
    self:CallHook("PhysicsCollide", colData, collider)
end
function ENT:OnTakeDamage(dmginfo)
    if self:CallHook("ShouldTakeDamage",dmginfo)==false then return end
    self:CallHook("OnTakeDamage", dmginfo)
end

duplicator.RegisterEntityClass("gmod_tardis", function(ply, data)
    local ent = duplicator.GenericDuplicatorFunction(ply, data)
    ent:SetCreator(ply)
    ent:Initialize()
    return ent
end, "Data")