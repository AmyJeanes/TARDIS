ENT:AddHook("OnTakeDamage", "Health", function(self, dmginfo)
    if dmginfo:GetDamage() <= 0 then return end
    local newhealth = self.exterior:GetHealth() - (dmginfo:GetDamage()/2)
    self.exterior:ChangeHealth(newhealth)
end)

---@api
---@param magnitude number?
function ENT:Explode(magnitude)
    local force = 60
    if magnitude ~= nil then
        force = tostring(magnitude)
    end
    local explode = ents.Create("env_explosion")
    -- Creation only fails on edict exhaustion, where spawning is already broken.
    ---@cast explode Entity

    local console = self:GetPart("console")
    if console and IsValid(console) then
        explode:SetPos(console:GetPos())
    else
        explode:SetPos( self:LocalToWorld(Vector(0,0,0)) )
    end

    explode:SetOwner( self )
    explode:Spawn()
    explode:SetKeyValue("iMagnitude", force)
    explode:Fire("Explode", 0, 0 )
end

ENT:AddHook("OnHealthChange", "health", function(self, newhealth, oldhealth)
    if newhealth > oldhealth then return end
    local hp = (oldhealth - newhealth) / 10
    local door = self:GetPart("door")
    if door and IsValid(door) then
        sound.Play("Default.ImpactSoft",door:GetPos())
    end
    util.ScreenShake(self:GetPos(),math.Clamp(hp,0,16),5,0.5,700)
end)

ENT:AddHook("OnHealthDepleted", "interior-death", function(self)
    util.ScreenShake(self:GetPos(), 10, 10, 1, 10)
    self:Explode(80)
end)

ENT:AddHook("ShouldTakeDamage", "DamageOff", function(self, dmginfo)
    if not TARDIS:GetSetting("health-enabled") then return false end
end)

ENT:AddHook("ShouldTakeDamage", "fire", function(self, dmginfo)
    if TARDIS:IsFireDamage(dmginfo) then return false end
end)
