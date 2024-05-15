-- Vortex

local PART={}
PART.ID = "vortex"
PART.Name = "Vortex"
PART.Model = "models/doctorwho1200/toyota/2013timevortex.mdl"
PART.AutoSetup = true
PART.AutoPosition = false
PART.ClientThinkOverride = true
PART.ClientDrawOverride = true
PART.ShouldDrawOverride = true
PART.Collision = false
PART.NoStrictUse = true
PART.CustomAlpha = true
PART.NoShadow = true
PART.NoShadowCopy = true
PART.NoCloak = true
if SERVER then
    function PART:Initialize()
        self:SetSolid(SOLID_NONE)
        self:SetPos(self.exterior:LocalToWorld(self.pos))
        self:SetAngles(self.exterior:LocalToWorldAngles(self.ang))
        self:SetParent(self.exterior)
    end
else
    function PART:PreDraw()
        if self:GetData("vortexalpha",0)>0 then
            self:SetRenderOrigin(self.exterior:LocalToWorld(self.pos))
            self:SetRenderAngles(self:GetData("lockedang"))
        end
    end
end

TARDIS:AddPart(PART)