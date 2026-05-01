
-- Default gears
local PART={}
PART.ID = "default_gears1"
PART.Model = "models/molda/toyota_int/gears1.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.ShouldTakeDamage = false

PART.SoundLoop = "p00gie/tardis/default/steeringmech_loop.wav"
PART.SoundLoopVolume = 0.5

PART.Animate = true
PART.AnimateOptions = {
    Type = "perpetual_use",
    Speed = 1.2,
    StopAnywhere = true,
    SpeedOverrideFunc = function(self, a, target, do_reset)
        if do_reset and (a.pos < 0.2 or a.pos > 0.8) then
            return a.speed * 3
        end
        return a.speed
    end,
}

if CLIENT then
    PART.Use = function(self, ply)
        self.animation.stop_anywhere = LocalPlayer():KeyDown(IN_WALK)
    end
end

TARDIS:AddPart(PART)

PART.ID = "default_gears2"
PART.Model = "models/molda/toyota_int/gears2.mdl"
PART.AnimateOptions.Speed = 1.5
TARDIS:AddPart(PART)

PART.ID = "default_gears3"
PART.Model = "models/molda/toyota_int/gears3.mdl"
PART.AnimateOptions.Speed = 0.9
TARDIS:AddPart(PART)

-- Default handbrake
PART = {}
PART.ID = "default_handbrake"
PART.Model = "models/molda/toyota_int/handbrake.mdl"
PART.SoundOn = "p00gie/tardis/default/handbrake_on.ogg"
PART.SoundOff = "p00gie/tardis/default/handbrake_off.ogg"
PART.AutoSetup = true
PART.Collision = true
PART.ShouldTakeDamage = false

PART.EnabledOnStart = true

PART.Animate = true
PART.AnimateOptions = {
    Type = "toggle",
    Speed = 1.2,
}

TARDIS:AddPart(PART)

-- Default throttle
PART = {}
PART.ID = "default_throttle"
PART.Model = "models/molda/toyota_int/throttle.mdl"
PART.SoundOn = "p00gie/tardis/default/throttle_on.ogg"
PART.SoundOff = "p00gie/tardis/default/throttle_off.ogg"
PART.AutoSetup = true
PART.Collision = true
PART.ShouldTakeDamage = false
PART.Animate = true
PART.AnimateSpeed = 3
TARDIS:AddPart(PART)

-- Default keyboard
PART = {}
PART.ID = "default_keyboard"
PART.Model = "models/molda/toyota_int/keyboard.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.ShouldTakeDamage = false
PART.SoundOn = "p00gie/tardis/default/keyboard_2014.ogg"
PART.SoundOff = "p00gie/tardis/default/keyboard_2015.ogg"
PART.SoundNoPower = "p00gie/tardis/default/keyboard.ogg"

TARDIS:AddPart(PART)

-- Default telepathic circuit
PART = {}
PART.ID = "default_telepathic"
PART.Model = "models/molda/toyota_int/telepathic.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.ShouldTakeDamage = false
PART.SoundOn = "p00gie/tardis/default/telepathic_on.ogg"
PART.SoundOff = "p00gie/tardis/default/telepathic_off.ogg"

function PART:Use(ply)
    local last_d_exit = ply:GetTardisData("destination_last_exit")

    if last_d_exit and self.Control == "destination" and CurTime() - last_d_exit < 1 then return end

    if CLIENT then
        self:SetData("destination_last_toggle", RealTime(), true)
    end

    if SERVER then
        TARDIS:Control(self.Control, ply, self)
    end
end

TARDIS:AddPart(PART)

-- Default side lever 1
PART = {}
PART.ID = "default_side_lever1"
PART.Model = "models/molda/toyota_int/sidelever1.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.ShouldTakeDamage = false
PART.Animate = true
PART.AnimateSpeed = 3
PART.SoundOn = "p00gie/tardis/default/slider_2_on.ogg"
PART.SoundOff = "p00gie/tardis/default/slider_off.ogg"
PART.SoundNoPower = "p00gie/tardis/default/slider_off.ogg"
TARDIS:AddPart(PART)

-- Default side lever 2
PART = {}
PART.ID = "default_side_lever2"
PART.Model = "models/molda/toyota_int/sidelever2.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.ShouldTakeDamage = false
PART.Animate = true
PART.AnimateSpeed = 3
PART.SoundOn = "p00gie/tardis/default/slider_on.ogg"
PART.SoundOff = "p00gie/tardis/default/slider_off.ogg"
PART.SoundNoPower = "p00gie/tardis/default/slider_off.ogg"
TARDIS:AddPart(PART)

-- Default side dial
PART = {}
PART.ID = "default_side_dial"
PART.Model = "models/molda/toyota_int/side_dial.mdl"
PART.AutoSetup = true
TARDIS:AddPart(PART)


-- Default throttle lights
PART = {}
PART.ID = "default_throttle_lights"
PART.Model = "models/molda/toyota_int/throttle_lights.mdl"
PART.AutoSetup = true
TARDIS:AddPart(PART)

-- Default side speakers
PART = {}
PART.ID = "default_side_speakers"
PART.Model = "models/molda/toyota_int/side_speakers.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.ShouldTakeDamage = false
TARDIS:AddPart(PART)


------------------------------
-- ported from Toyota addon --
------------------------------

-- Default bouncy lever
PART = {}
PART.ID = "default_bouncy_lever"
PART.Model = "models/cem/toyota_contr/bouncy_lever.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 3
PART.Sound = "p00gie/tardis/default/levers.ogg"
TARDIS:AddPart(PART)

-- Default buttons 1 and 2
PART = {}
PART.Model = "models/cem/toyota_contr/button.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 6

PART.ID = "default_button_1"
PART.EnabledOnStart = true
PART.Sound = "p00gie/tardis/default/balls.ogg"
PART.AnimateSpeed = 10
TARDIS:AddPart(PART)

PART.ID = "default_button_2"
PART.EnabledOnStart = true
PART.Sound = "p00gie/tardis/default/balls.ogg"
PART.AnimateSpeed = 10
TARDIS:AddPart(PART)

-- Default buttons
PART = {}
PART.ID = "default_buttons"
PART.Model = "models/cem/toyota_contr/buttons.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 1
PART.SoundOn = "p00gie/tardis/default/buttons_on.ogg"
PART.SoundOff = "p00gie/tardis/default/buttons.ogg"
PART.SoundNoPower = "p00gie/tardis/default/buttons.ogg"
TARDIS:AddPart(PART)

-- Default crank
PART = {}
PART.ID = "default_crank"
PART.Model = "models/cem/toyota_contr/crank.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true

PART.SoundLoop = "p00gie/tardis/default/crank_loop.wav"
PART.SoundStop = "p00gie/tardis/default/crank_beep.ogg"

PART.AnimateOptions = {
    Type = "perpetual_use",
    Speed = 1.2
}

TARDIS:AddPart(PART)

-- Default crank 2
PART = {}
PART.ID = "default_crank2"
PART.Model = "models/cem/toyota_contr/crank2.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.Sound = "p00gie/tardis/default/crank.ogg"

PART.AnimateOptions = {
    Type = "perpetual_use",
    Speed = 0.65,
}

TARDIS:AddPart(PART)

-- Default crank 3
PART = {}
PART.ID = "default_crank3"
PART.Model = "models/cem/toyota_contr/crank3.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 0.75
PART.Sound = "p00gie/tardis/default/crank.ogg"
TARDIS:AddPart(PART)

-- Default crank 4
PART = {}
PART.ID = "default_crank4"
PART.Model = "models/cem/toyota_contr/crank4.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.Sound = "p00gie/tardis/default/crank2.ogg"
TARDIS:AddPart(PART)

-- Default crank 5
PART = {}
PART.ID = "default_crank5"
PART.Model = "models/cem/toyota_contr/crank5.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 1.1
PART.Sound = "p00gie/tardis/default/crank.ogg"
TARDIS:AddPart(PART)

-- Default crank 6
PART = {}
PART.ID = "default_crank6"
PART.Model = "models/cem/toyota_contr/crank6.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 1.1
PART.Sound = "p00gie/tardis/default/crank.ogg"
TARDIS:AddPart(PART)

-- Default ducks
PART = {}
PART.ID = "default_ducks"
PART.Model = "models/cem/toyota_contr/ducks.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.SoundOn = "p00gie/tardis/default/ducks_on.ogg"
PART.SoundOff = "p00gie/tardis/default/ducks_off.ogg"
TARDIS:AddPart(PART)

-- Default flippers
PART = {}
PART.ID = "default_flippers"
PART.Model = "models/cem/toyota_contr/flippers.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 1
PART.Sound = "p00gie/tardis/default/flippers.ogg"
TARDIS:AddPart(PART)

-- Default fiddle 1
PART = {}
PART.ID = "default_fiddle1"
PART.Model = "models/cem/toyota_contr/fiddle1.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 3
PART.Sound = "p00gie/tardis/default/levers.ogg"
TARDIS:AddPart(PART)

-- Default fiddle 2
PART = {}
PART.ID = "default_fiddle2"
PART.Model = "models/cem/toyota_contr/fiddle2.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 3
PART.Sound = "p00gie/tardis/default/levers.ogg"
TARDIS:AddPart(PART)

-- Default flat switches
PART = {}
PART.Model = "models/cem/toyota_contr/flat_switch.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 5
PART.Sound = "p00gie/tardis/default/switch.ogg"

for i = 1,6 do
    PART.ID = "default_flat_switch_" .. i
    TARDIS:AddPart(PART)
end

-- Default handle 1
PART = {}
PART.ID = "default_handle1"
PART.Model = "models/cem/toyota_contr/handle1.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 3
PART.Sound = "p00gie/tardis/default/levers.ogg"
TARDIS:AddPart(PART)

-- Default handle 2
PART = {}
PART.ID = "default_handle2"
PART.Model = "models/cem/toyota_contr/handle2.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 3
PART.Sound = "p00gie/tardis/default/levers.ogg"
TARDIS:AddPart(PART)

-- Default key
PART = {}
PART.ID = "default_key"
PART.Model = "models/cem/toyota_contr/key.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 8
PART.SoundOn = "p00gie/tardis/default/key.ogg"
PART.SoundOff = "p00gie/tardis/default/buttons.ogg"
PART.SoundNoPower = "p00gie/tardis/default/buttons.ogg"
TARDIS:AddPart(PART)

-- Default red levers
PART = {}
PART.Model = "models/cem/toyota_contr/red_lever.mdl"
PART.SoundOn = "p00gie/tardis/default/red_lever_on.ogg"
PART.SoundOff = "p00gie/tardis/default/red_lever_off.ogg"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 3

PART.ID = "default_red_lever_1"
TARDIS:AddPart(PART)
PART.ID = "default_red_lever_2"
TARDIS:AddPart(PART)

-- Default thick lever
PART = {}
PART.ID = "default_thick_lever"
PART.Model = "models/cem/toyota_contr/thick_lever.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 5
PART.Sound = "p00gie/tardis/default/lever5.ogg"
TARDIS:AddPart(PART)

for i = 1,5 do
    -- Default colored lever
    PART = {}
    PART.ID = "default_colored_lever_" .. i
    PART.Model = "models/cem/toyota_contr/colored_lever_" .. i .. ".mdl"

    PART.SoundOn = "p00gie/tardis/default/colored_lever_" .. i .. ".ogg"
    PART.SoundOff = "p00gie/tardis/default/colored_lever_off.ogg"
    PART.SoundOnNoPower = "p00gie/tardis/default/colored_lever_1.ogg"
    PART.SoundOffNoPower = "p00gie/tardis/default/colored_lever_off.ogg"

    PART.AutoSetup = true
    PART.Collision = true
    PART.Animate = true
    PART.AnimateSpeed = 3

    TARDIS:AddPart(PART)
end

-- Default phone
PART = {}
PART.ID = "default_phone"
PART.Model = "models/molda/toyota_int/phone.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.Sound = "p00gie/tardis/default/phone.ogg"
PART.SoundNoPower = false
TARDIS:AddPart(PART)

-- Default red flick cover
PART = {}
PART.ID = "default_red_flick_cover"
PART.Model = "models/cem/toyota_contr/red_flick_cover.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.Sound = "p00gie/tardis/default/levers.ogg"
if SERVER then
    function PART:Use(ply)
        if not self:GetOn() then
            self:SetCollide(false, true)
        end
    end
end
TARDIS:AddPart(PART)

-- Default red flick switch
PART = {}
PART.ID = "default_red_flick_switch"
PART.Model = "models/cem/toyota_contr/red_flick_switch.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 6
PART.Sound = "p00gie/tardis/default/switch.ogg"
if SERVER then
    function PART:Use(ply)
        local cover = self.interior:GetPart("default_red_flick_cover")
        if not IsValid(cover) then return end

        if cover:GetOn() then
            TARDIS:Control(self.Control, ply, self)
            self.interior:Timer("default_redflickswitch_cover", 0.3, function()
                cover:SetOn(false)
                cover:SetPoseParameter("switch", 0)
                cover:SetCollide(true)
            end)
        end
    end
end
TARDIS:AddPart(PART)

-- Default sliders
PART = {}
PART.ID = "default_sliders"
PART.Model = "models/cem/toyota_contr/sliders.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.SoundOn = "p00gie/tardis/default/sliders.ogg"
PART.SoundOff = "p00gie/tardis/default/sliders_off.ogg"
PART.AnimateSpeed = 1
PART.SoundNoPower = "p00gie/tardis/default/sliders_off.ogg"
TARDIS:AddPart(PART)

-- Default small switches
PART = {}
PART.Model = "models/cem/toyota_contr/small_switch.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 4
PART.Sound = "p00gie/tardis/default/switch.ogg"

for i = 1,18 do
    PART.ID = "default_small_switch_" .. i
    TARDIS:AddPart(PART)
end

-- Default spin A switches
PART = {}
PART.Model = "models/cem/toyota_contr/spin_a.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true

PART.AnimateOptions = {
    Type = "perpetual_use",
    Speed = 3,
}

PART.Sound = "p00gie/tardis/default/switch2.ogg"

for i = 1,5 do
    PART.ID = "default_spin_a_" .. i
    TARDIS:AddPart(PART)
end

-- Default spin B switches
PART = {}
PART.Model = "models/cem/toyota_contr/spin_b.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 2
PART.Sound = "p00gie/tardis/default/switch2.ogg"

for i = 1,4 do
    PART.ID = "default_spin_b_" .. i
    TARDIS:AddPart(PART)
end

-- Default spin big
PART = {}
PART.ID = "default_spin_big"
PART.Model = "models/cem/toyota_contr/spin_big.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.Sound = "p00gie/tardis/default/crank2.ogg"
TARDIS:AddPart(PART)

-- Default spin crank
PART = {}
PART.ID = "default_spin_crank"
PART.Model = "models/cem/toyota_contr/spin_crank.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.Sound = "p00gie/tardis/default/crank2.ogg"
TARDIS:AddPart(PART)

-- Default spin switch
PART = {}
PART.ID = "default_spin_switch"
PART.Model = "models/cem/toyota_contr/spin_switch.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.Sound = "p00gie/tardis/default/crank2.ogg"
TARDIS:AddPart(PART)

-- Default switch
PART = {}
PART.ID = "default_switch"
PART.Model = "models/cem/toyota_contr/switch.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.SoundOn = "p00gie/tardis/default/switch_on.ogg"
PART.SoundOff = "p00gie/tardis/default/switch.ogg"
PART.SoundNoPower = "p00gie/tardis/default/switch.ogg"
TARDIS:AddPart(PART)

-- Default switch 2
PART = {}
PART.ID = "default_switch2"
PART.Model = "models/cem/toyota_contr/switch2.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.Sound = "p00gie/tardis/default/switch.ogg"
TARDIS:AddPart(PART)

-- Default toggles
PART = {}
PART.ID = "default_toggles"
PART.Model = "models/cem/toyota_contr/toggles.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 2
PART.SoundOn = "p00gie/tardis/default/toggles_on.ogg"
PART.SoundOff = "p00gie/tardis/default/toggles_off.ogg"
PART.SoundNoPower = "p00gie/tardis/default/toggles.ogg"
function PART:Use(ply)
    TARDIS:Control(self.Control, ply, self)

    local pr = "p00gie/tardis/default/toggles_on"
    self.SoundOn = pr .. (self.exterior:IsTravelling() and ".ogg" or "_2.ogg")
end
TARDIS:AddPart(PART)

-- Default toggles 2
PART = {}
PART.ID = "default_toggles2"
PART.Model = "models/cem/toyota_contr/toggles2.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 1.5
PART.SoundOn = "p00gie/tardis/default/toggles2.ogg"
PART.SoundOff = "p00gie/tardis/default/toggles2_off.ogg"
PART.SoundNoPower = "p00gie/tardis/default/toggles2_off.ogg"
TARDIS:AddPart(PART)

-- Default tumblers
PART = {}
PART.ID = "default_tumblers"
PART.Model = "models/cem/toyota_contr/tumblers.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.AnimateSpeed = 3
PART.SoundOn = "p00gie/tardis/default/tumblers_on.ogg"
PART.SoundOff = "p00gie/tardis/default/tumblers_off.ogg"
PART.SoundNoPower = "p00gie/tardis/default/tumblers_off.ogg"
TARDIS:AddPart(PART)

-- Default balls
PART = {}
PART.ID = "default_balls"
PART.Model = "models/cem/toyota_contr/balls.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Sound = "p00gie/tardis/default/balls.ogg"
TARDIS:AddPart(PART)

-- Default console scanner
PART = {}
PART.ID = "default_console_scanner"
PART.Model = "models/molda/toyota_int/consolescanner.mdl"
PART.AutoSetup = true
PART.Collision = true
TARDIS:AddPart(PART)

-- Default side cranks
PART = {}
PART.Model = "models/cem/toyota_contr/cranks.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.Animate = true
PART.NoStrictUse = true

PART.ID = "default_side_cranks1"
PART.AnimateSpeed = 1.6
PART.Sound = "p00gie/tardis/default/crank.ogg"
TARDIS:AddPart(PART)

PART.ID = "default_side_cranks2"
PART.AnimateSpeed = 0.6
PART.Sound = "p00gie/tardis/default/cranks.ogg"
TARDIS:AddPart(PART)


-- Default side panels
PART = {}
PART.ID = "default_side_panels"
PART.Model = "models/molda/toyota_int/sidepanels.mdl"
PART.AutoSetup = true
PART.Collision = true
TARDIS:AddPart(PART)

-- Default side toggles
PART = {}
PART.Model = "models/molda/toyota_int/side_toggle.mdl"
PART.AutoSetup = true

PART.ID = "default_side_toggles_1"
TARDIS:AddPart(PART)
PART.ID = "default_side_toggles_2"
TARDIS:AddPart(PART)

-- Default sonic dispenser hitbox
PART = {}
PART.ID = "default_sonic_dispenser_hitbox"
PART.Model = "models/molda/toyota_int/hitboxes/sonic_cube.mdl"
PART.AutoSetup = true
PART.Collision = true
PART.NoDraw = true
PART.Sound = "p00gie/tardis/default/sonic_dispenser.ogg"
PART.PowerOffUse = false

if SERVER then
    function PART:Use(ply)
        TARDIS:Control(self.Control, ply, self)

        self:SetData("default_sonic_charger_active", true, true)

        self.interior:Timer(self.ID, 3, function()
            self:SetData("default_sonic_charger_active", false, true)
        end)
    end
end

TARDIS:AddPart(PART)

-- Default door button
PART = {}
PART.ID = "default_door_button"
PART.Model = "models/parar020100/toyota_int/classic_doors_button.mdl"
PART.AutoSetup = true
PART.Collision = true
TARDIS:AddPart(PART)
