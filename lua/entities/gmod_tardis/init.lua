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
    ---@param ply Player
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
        self:CallHook("PreMetadataInitialize", self.metadataID)
        self.metadata=TARDIS:CreateInteriorMetadata(self.metadataID, self)
        self.Model=self.metadata.Exterior.Model
        self.Portal=self.metadata.Exterior.Portal
        self.Fallback=self.metadata.Exterior.Fallback
        -- glua_ls upstream: undeclared base-method self -- https://github.com/Pollux12/gmod-glua-ls/issues/51
        ---@diagnostic disable-next-line: infer-unknown
        self.BaseClass.Initialize(self)
    end
end

---@param colData CollisionData
---@param collider Entity
function ENT:PhysicsCollide(colData, collider)
    self:CallHook("PhysicsCollide", colData, collider)
end
---@param dmginfo CTakeDamageInfo
function ENT:OnTakeDamage(dmginfo)
    if self:CallHook("ShouldTakeDamage",dmginfo)==false then return end
    self:CallHook("OnTakeDamage", dmginfo)
end

-- Not our constraints - GMod copies them in from the TARDIS being duplicated, and they still point at it
---@param data table
function ENT:OnEntityCopyTableFinish(data)
    data.Constraints = nil
end

duplicator.RegisterEntityClass("gmod_tardis", function(ply, data)
    -- The generic pass runs pre-spawn, so withhold skin and bodygroups from it and set them below -
    -- the hooks they fire need a TARDIS that already has its metadata
    local generic = {}
    for k, v in pairs(data) do generic[k] = v end
    generic.Skin, generic.BodyG = nil, nil

    local ent = duplicator.GenericDuplicatorFunction(ply, generic)
    if not IsValid(ent) then return end

    ent:SetCreator(ply)
    ent:Initialize()

    if data.Skin then ent:SetSkin(data.Skin) end
    for id, value in pairs(data.BodyG or {}) do
        ent:SetBodygroup(id, value)
    end
    return ent
end, "Data")