-- Events

local PART = TARDIS:NewPart()
PART.ID = "pumpkin"
PART.AutoSetup = true
PART.Collision = true
PART.ShouldTakeDamage = false
PART.Motion = true
PART.Model = "models/molda/misc/tardis_pumpkin.mdl"
PART.InvisibleCollision = false
PART.InvisibleFade = true
PART.FadeSpeed = 2
PART.AllowThroughPortals = true

if CLIENT then
    ---@param ply Player
    function PART:Use(ply)
        self.exterior:NotifyEvent(false, true)
    end
end

TARDIS:AddPart(PART)
