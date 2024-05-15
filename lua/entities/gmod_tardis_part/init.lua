AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

function ENT:OnTakeDamage(dmginfo)
    if not self.ShouldTakeDamage then return end
    if self.parent:CallHook("ShouldTakeDamage",dmginfo)==false then return end
    self.parent:CallHook("OnTakeDamage", dmginfo)
end

function ENT:SetCollide(collide, notrace)
    if collide then
        self:SetCollisionGroup(COLLISION_GROUP_NONE)
    elseif notrace then
        self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    else
        self:SetCollisionGroup(COLLISION_GROUP_WORLD)
    end
end

-- this is deprecated; it's better to use ENT:SetInvisible()
-- some extensions still use color-based part invisibility, so we should not change this
function ENT:SetVisible(visible)
    if visible then
        if self.pre_invis_color then
            self:SetColor(self.pre_invis_color)
            self.pre_invis_color = nil
        else
            self:SetColor(Color(255,255,255,255))
        end
    else
        self.pre_invis_color = (self:GetColor().a ~= 0) and self:GetColor()
        self:SetColor(Color(0,0,0,0))
    end
end