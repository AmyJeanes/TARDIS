---@class gmod_tardis_part : Entity

ENT.Type = "anim"
if WireLib then
    ENT.Base            = "base_wire_entity"
else
    ENT.Base            = "base_gmodentity"
end
ENT.PrintName       = "TARDIS Part"
ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.Category        = "Doctor Who"
ENT.RenderGroup     = RENDERGROUP_OPAQUE
ENT.TardisPart      = true
ENT.AllowedProperties = {
    ["skin"] = true,
    ["bodygroups"] = true
}

function ENT:Initialize() end

function ENT:SetupDataTables()
    self:NetworkVar("Bool",0,"On")
    self:SetOn(self.EnabledOnStart or false)
end

hook.Add("PhysgunPickup", "tardis-part", function(ply,ent)
    if ent.TardisPart and (not ent.Motion or (ent.StartFrozen and not ent.unfrozen)) then return false end
end)

hook.Add("PlayerUnfrozeObject", "tardis-part", function(ply,ent,phys)
    if ent.TardisPart and (not ent.Motion or (ent.StartFrozen and not ent.unfrozen)) then phys:EnableMotion(false) end
end)

hook.Add("CanProperty", "tardis-part", function(ply,prop,ent)
    if ent.TardisPart and (not ent.AllowedProperties[prop]) then return false end
end)

hook.Add("CanDrive", "tardis-part", function(ply,ent)
    if ent.TardisPart then return false end
end)

function ENT:SetData(k,v,network)
    return IsValid(self.exterior) and self.exterior:SetData(k, v, network)
end

function ENT:GetData(k,default)
    if IsValid(self.exterior) then
        return self.exterior:GetData(k, default)
    else
        return default
    end
end

hook.Add("BodygroupChanged", "tardis_parts", function(ent,bodygroup,value)
    if ent.TardisPart then
        if ent.OnBodygroupChanged then
            ent.OnBodygroupChanged(ent, bodygroup, value)
        end
        if IsValid(ent.parent) then
            ent.parent:CallHook("PartBodygroupChanged", ent, bodygroup, value)
        end
    end
end)

function ENT:SetInvisible(invisible, nofade)
    return self.parent:SetPartInvisible(self.ID, invisible, nofade)
end

function ENT:IsInvisible()
    local inv_parts = self:GetData("invisible_int_parts")

    if not inv_parts or not inv_parts[self.ID] then return false end
    local inv = inv_parts[self.ID]
    return inv.invisible, inv.nofade
end