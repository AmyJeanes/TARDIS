SWEP.PrintName = "TARDIS Hands"
SWEP.Slot = 0
SWEP.SlotPos = 0
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Author = "Dr. Matt"

SWEP.Weight = 0
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Spawnable = false
SWEP.AdminSpawnable = false

SWEP.ViewModel = ""
SWEP.WorldModel = ""
SWEP.HoldType = "normal"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

function SWEP:DrawWorldModel()
    return false
end

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)
    self.Weapon:DrawShadow(false)
end


function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end