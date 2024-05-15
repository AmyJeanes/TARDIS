local PART = {}
PART.ID = "default_doorframe"
PART.Model = "models/molda/toyota_int/doorframe.mdl"
PART.AutoSetup = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_floor"
PART.Model = "models/molda/toyota_int/floor.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.ShouldTakeDamage = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_walls"
PART.Model = "models/molda/toyota_int/walls.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.ShouldTakeDamage = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_entry"
PART.Model = "models/molda/toyota_int/entry.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.ShouldTakeDamage = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_pillars"
PART.Model = "models/molda/toyota_int/pillars.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.ShouldTakeDamage = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_roof"
PART.Model = "models/molda/toyota_int/roof.mdl"
PART.AutoSetup = true
PART.ShouldTakeDamage = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_rings"
PART.Model = "models/molda/toyota_int/rings.mdl"
PART.AutoSetup = true
PART.Animate = true
PART.ClientThinkOverride = true
PART.AnimateOptions = {
    Type = "travel",
    Speed = 0.075
}
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_cables1"
PART.Model = "models/molda/toyota_int/cables1.mdl"
PART.AutoSetup = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_cables2"
PART.Model = "models/molda/toyota_int/cables2.mdl"
PART.AutoSetup = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_cables3"
PART.Model = "models/molda/toyota_int/cables3.mdl"
PART.AutoSetup = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_chairs"
PART.Model = "models/molda/toyota_int/chairs.mdl"
PART.AutoSetup = true
PART.Collision = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_casing"
PART.Model = "models/molda/toyota_int/casing.mdl"
PART.AutoSetup = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_console"
PART.Model = "models/molda/toyota_int/console.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.ShouldTakeDamage = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_side_details1"
PART.Model = "models/molda/toyota_int/side_details1.mdl"
PART.AutoSetup = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_side_details2"
PART.Model = "models/molda/toyota_int/side_details2.mdl"
PART.AutoSetup = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_toplights"
PART.Model = "models/molda/toyota_int/toplights.mdl"
PART.AutoSetup = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_roundels1"
PART.Model = "models/molda/toyota_int/roundels1.mdl"
PART.AutoSetup = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_roundels2"
PART.Model = "models/molda/toyota_int/roundels2.mdl"
PART.AutoSetup = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_bulbs"
PART.Model = "models/molda/toyota_int/bulbs.mdl"
PART.AutoSetup = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_ticks"
PART.Model = "models/molda/toyota_int/ticks.mdl"
PART.AutoSetup = true
PART.ShouldTakeDamage = false
PART.Animate = true
PART.AnimateOptions = {
    Type = "idle",
    Speed = 0.5,
    NoPowerFreeze = true,
}
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_intdoors"
PART.Model = "models/molda/toyota_int/slidedoors2.mdl"
PART.AutoSetup = true
PART.Animate = true
PART.Collision = true
PART.ShouldTakeDamage = true
PART.AnimateSpeed = 1
PART.Sound = "p00gie/tardis/default/intdoors_open.ogg"

if SERVER then
    function PART:Use(ply)
        self:SetCollide(self:GetOn())

        if not self:GetOn() then
            self.interior:Timer(self.ID, 5, function(int)
                self:SetOn(false)
                self:SetCollide(true)
                if self.SoundOff then
                    self:EmitSound(self.SoundOff)
                elseif self.Sound then
                    self:EmitSound(self.Sound)
                end
            end)
        else
            self.interior:CancelTimer(self.ID)
        end
    end
end

TARDIS:AddPart(PART)

PART.Model = "models/molda/toyota_int/slidedoors3.mdl"
PART.ID = "default_corridor_doors"
PART.ShouldTakeDamage = true
TARDIS:AddPart(PART)

PART.ID = "default_top_doors_1"
PART.Model = "models/molda/toyota_int/slidedoors1.mdl"
PART.ShouldTakeDamage = true
PART.Sound = nil
PART.SoundOn = "p00gie/tardis/default/topdoor_open.ogg"
PART.SoundOff = "p00gie/tardis/default/topdoor_close.ogg"
PART.AnimateSpeed = 0.8
TARDIS:AddPart(PART)


PART.ID = "default_top_doors_2"
PART.ShouldTakeDamage = true
TARDIS:AddPart(PART)

PART.Use = nil
PART.Animate = false
PART.AnimateSpeed = nil
PART.SoundOn = nil
PART.SoundOff = nil
PART.SoundPos = nil

PART.ID = "default_intdoors_static"
PART.Model = "models/molda/toyota_int/slidedoors2.mdl"
PART.ShouldTakeDamage = true
TARDIS:AddPart(PART)

PART.ID = "default_corridor_doors_static"
PART.Model = "models/molda/toyota_int/slidedoors3.mdl"
PART.ShouldTakeDamage = true
TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_rotor"
PART.Model = "models/molda/toyota_int/rotor.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.UseTransparencyFix = true
PART.ClientThinkOverride = true
PART.ShouldTakeDamage = true
PART.Animate = true

function PART:Initialize()
    self:SetBodygroup(3,1)
end

PART.AnimateOptions = {
    Type = "travel",
    Speed = 0.075,
    ReturnAfterStop = false,
    NoPowerFreeze = true,
    PoseParameter = "rings",
}

PART.ExtraAnimations = {
    piston = {
        Type = "travel",
        Speed = 0.5,
        ReturnAfterStop = true,
        NoPowerFreeze = true,
        PoseParameter = "piston",
    }
}

TARDIS:AddPart(PART)

local PART={}
PART.ID = "default_corridors"
PART.Model = "models/molda/toyota_int/corridor_version2.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.ShouldTakeDamage = true
TARDIS:AddPart(PART)