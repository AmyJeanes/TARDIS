-- Artron Inhibitor by Nova Astral, an edit of the Time Distortion Generator by parar020100 and JEREDEK

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")


function ENT:Initialize()
    self:SetModel("models/props_lab/reciever01b.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    self:SetName("ArtronInhibitor")
    self:SetColor(Color(255, 255, 255, 255))
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()

    self.Radius = 1000
    self.EntMaxHealth = 100
    self.EntHealth = self.EntMaxHealth


    if phys:IsValid() then
        phys:Wake()
    end

    if WireLib then
        local inNames = {"Activate","Radius"}
        local inTypes = {"NORMAL","NORMAL"}

        WireLib.CreateSpecialInputs( self,inNames,inTypes)
        Wire_CreateOutputs(self,{"Active","Radius","Health"})

        Wire_TriggerOutput(self,"Radius",self.Radius)
        Wire_TriggerOutput(self,"Health",self.EntHealth)
    end
end

function ENT:TriggerWire(tname,value)
    if WireLib then
        Wire_TriggerOutput(self,tname,value)
    end
end

function ENT:GetRadius()
    return self.Radius
end

function ENT:SetRadius(radius)
    self.Radius = math.Clamp(radius,0,2048)
    self:TriggerWire("Radius",self.Radius)
    return self.Radius
end

function ENT:Repair(repair)
    if self.EntHealth >= 0 then
        local hp = self.EntHealth + repair

        if self.Broken == true and hp >= 0 then
            self:SetColor(Color(255, 255, 255, self:GetColor().a))
            self.Broken = false
        end

        self.EntHealth = math.Clamp(hp,0,self.EntMaxHealth)
        self:TriggerWire("Health",self.EntHealth)
    end
end

function ENT:TriggerInput(iname, value)
    if iname == "Activate" then
        if self.Broken then return end

        if value >= 1 and self:GetEnabled() == false then
            self:TurnOn(true)
        else
            self:TurnOn(false)
        end
    elseif iname == "Radius" then
        self:SetRadius(value)
    end
end

function ENT:TurnOn(active)
    if self.Broken then return end

    local phys = self:GetPhysicsObject()

    if active and self.FlyTime == nil then
        self:SetColor(Color(0, 50, 255, self:GetColor().a))
        phys:SetAngleVelocity(Vector(20, -20, -10))
        phys:EnableGravity(false)
        phys:SetVelocity(Vector(0, 0, 15))

        self:TriggerWire("Active",0.5)

        sound.Play("drmatt/tardis/seq_ok.wav", self:GetPos())

        if IsValid(self.LastActivator) then
            TARDIS:Message(self.LastActivator, "ArtronInhibitor.Starting")
        end

        self.FlyTime = CurTime()
        self.ArtronTick = CurTime()
    elseif self.On == true then
        self.FlyTime = nil
        self.ArtronTick = nil

        self.On = false
        self:SetEnabled(false)
        self:TriggerWire("Active",0)
        self:SetColor(Color(255, 255, 255, self:GetColor().a))

        phys:EnableGravity(true)

        sound.Play("drmatt/tardis/seq_bad.wav", self:GetPos())

        if IsValid(self.LastActivator) then
            TARDIS:Message(self.LastActivator, "ArtronInhibitor.Disabled")
        end

        local effect_data = EffectData()
        effect_data:SetOrigin(self:GetPos())
        util.Effect("cball_explode", effect_data)
    end
end

function ENT:Use(ply)
    if self.Broken then return end

    self.LastActivator = ply

    if self:GetEnabled() then
        self:TurnOn(false)
    else
        self:TurnOn(true)
    end
end

function ENT:Think()
    if self.Broken then return end

    if self.On then
        local phys = self:GetPhysicsObject()
        if phys:IsMotionEnabled() then
            phys:SetAngleVelocity(Vector(180, -200, -190))
            phys:AddVelocity(-0.2 * phys:GetVelocity())
        end
    end

    if self.FlyTime ~= nil and CurTime() - self.FlyTime > 3 then
        self.FlyTime = nil
        self.On = true
        self:SetEnabled(true)

        TARDIS:Message(self.LastActivator, "ArtronInhibitor.Enabled")
        self.LastActivator = nil

        self:GetPhysicsObject():SetVelocity(Vector(0, 0, 0))
        self:SetColor(Color(255, 166, 0, self:GetColor().a))
        self:TriggerWire("Active",1)

        sound.Play("drmatt/tardis/power_on.wav", self:GetPos())
    end

    if self.ArtronTick ~= nil and CurTime() - self.ArtronTick > 3 then
        self.ArtronTick = CurTime()
        for i,v in ipairs(ents.FindByClass("gmod_tardis")) do
            if v:GetPos():Distance(self:GetPos()) <= self.Radius then
                v:AddArtron(-2)
            end
        end

        for i,v in ipairs(ents.FindByClass("gmod_tardis_interior")) do
            if v:GetPos():Distance(self:GetPos()) <= self.Radius then
                v.exterior:AddArtron(-2)
            end
        end
    end
end

function ENT:Break()
    self.On = false
    self.Broken = true
    self.FlyTime = nil
    self.ArtronTick = nil

    self:SetEnabled(false)
    self:SetColor(Color(100, 100, 100, self:GetColor().a))
    self:GetPhysicsObject():EnableGravity(true)

    self:TriggerWire("Active",0)

    local effect_data = EffectData()
    effect_data:SetOrigin(self:GetPos())
    effect_data:SetMagnitude(10)
    util.Effect("Explosion", effect_data)
end

function ENT:OnTakeDamage(damage)
    if self.Broken then return end

    local dmg = damage:GetDamage()

    self.EntHealth = math.Clamp(self.EntHealth - dmg,0,self.EntMaxHealth)

    self:TriggerWire("Health",self.EntHealth)

    if self.EntHealth <= 0 then
        self:Break()
    end
end
