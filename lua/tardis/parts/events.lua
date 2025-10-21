-- Events

local PART={}
PART.ID = "pumpkin"
PART.AutoSetup = true
PART.Collision = true
PART.ShouldTakeDamage = false
PART.Motion = true
PART.Model = "models/molda/misc/tardis_pumpkin.mdl"
PART.InvisibleCollision = false

if CLIENT then
    function PART:Use(ply)
        self.exterior:NotifyEvent(false, true)
    end
end

TARDIS:AddPart(PART)
