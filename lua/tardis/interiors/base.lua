-- Base

local T = {}
T.Base = true
T.BaseMerged = true
T.Name = "Base"
T.ID = "base"
T.Interior = {
    Model = "models/drmatt/tardis/interior.mdl",
    ExitDistance = 600,
    Size = {},
    Portal = {
        pos = Vector(-1,-353.5,136),
        ang = Angle(0,90,0),
        width = 60,
        height = 91
    },
    Fallback = {
        pos = Vector(0,-330,95),
        ang = Angle(0,90,0)
    },
    Sounds = {
        Damage = {
            Crash = "jeredek/tardis/damage_collision.wav",
            BigCrash = "jeredek/tardis/damage_bigcollision.wav",
            Explosion = "jeredek/tardis/damage_explode.wav",
            Death = "jeredek/tardis/damage_death.wav",
            Artron = "p00gie/tardis/force_artron.wav",
        },
        Teleport = {}, -- uses exterior sounds if not specified
        Power = {
            On = "drmatt/tardis/power_on.wav",
            Off = "drmatt/tardis/power_off.wav"
        },
        SequenceOK = "drmatt/tardis/seq_ok.wav",
        SequenceFail = "drmatt/tardis/seq_bad.wav",
        Cloister = "drmatt/tardis/cloisterbell_loop.wav",
        Lock = "drmatt/tardis/lock_int.wav",
        Unlock = "p00gie/tardis/base/door_unlock.wav",
    },
    Tips = {},
    CustomTips = {},
    PartTips = {},
    TipSettings = {
        style = "white_on_grey",
        view_range_min = 70,
        view_range_max = 100,
    },
    LightOverride = {
        basebrightness = 0.3, --Base interior brightness when power is on.
        nopowerbrightness = 0.05, --Interior brightness with no power. Should always be darker than basebrightness.
        transitionspeed = 1, --Speed of the light transition.
    },
    ScreenDistance = 500,
    ScreensEnabled = true
}
T.Exterior = {
    Model = "models/drmatt/tardis/exterior/exterior.mdl",
    ExcludedSkins = {},
    Mass = 5000,
    DoorAnimationTime = 0.5,
    ScannerOffset = Vector(22,0,50),
    PhaseMaterial = "models/drmatt/tardis/exterior/phase_noise.vmt",
    Portal = {
        pos = Vector(26,0,51.65),
        ang = Angle(0,0,0),
        width = 44,
        height = 91
    },
    Fallback = {
        pos = Vector(60,0,5),
        ang = Angle(0,0,0)
    },
    Light = {
        enabled = true,
        pos = Vector(0,0,122),
        color = Color(255,255,255),
        dynamicpos = Vector(0,0,130),
        dynamicbrightness = 2,
        dynamicsize = 300
    },
    ProjectedLight = {
        --color = Color(r,g,b), --Base color. Will use main interior light if not set.
        --warncolor = Color(r,g,b), --Warning color. Will use main interior warn color if not set.
        brightness = 0.1, --Light's brightness
        --vertfov = 90,
        --horizfov = 90, --vertical and horizontal field of view of the light. Will default to portal height and width.
        farz = 750, --FarZ property of the light. Determines how far the light projects.]]
        offset = Vector(-21,0,51.1), --Offset from box origin
        texture = "effects/flashlight/square", --Texture the projected light will use. You can get these from the Lamp tool.
        baselightmix = 0, --How much the base light affects the projected light. 0 = none, 1 = full.
    },
    Sounds = {
        Teleport = {
            demat = "p00gie/tardis/base/demat.wav",
            demat_damaged = "drmatt/tardis/demat_damaged.wav",
            demat_fast = "p00gie/tardis/base/demat.wav",
            demat_hads = "p00gie/tardis/base/demat_hads.wav",
            demat_fail = "drmatt/tardis/demat_fail.wav",
            mat = "p00gie/tardis/base/mat.wav",
            mat_damaged = "jeredek/tardis/mat_damaged.wav",
            mat_fail = "p00gie/tardis/mat_fail.wav",
            mat_fast = "p00gie/tardis/base/mat_fast.wav",
            mat_damaged_fast = "p00gie/tardis/base/mat_damaged_fast.wav",
            fullflight = "p00gie/tardis/base/full.wav",
            fullflight_damaged = "drmatt/tardis/full_damaged.wav",
            interrupt = "p00gie/tardis/base/repairfinish.wav",
        },
        RepairFinish = "p00gie/tardis/base/repairfinish.wav",
        Lock = "drmatt/tardis/lock.wav",
        Unlock = "p00gie/tardis/base/door_unlock_ext.wav",
        Spawn = "p00gie/tardis/base/repairfinish.wav",
        Delete = "p00gie/tardis/base/tardis_delete.wav",
        Door = {
            enabled = true,
            open = "drmatt/tardis/door_open.wav",
            close = "drmatt/tardis/door_close.wav",
            locked = "drmatt/tardis/door_locked.wav"
        },
        FlightLoop = "drmatt/tardis/flight_loop.wav",
        FlightLoopDamaged = "drmatt/tardis/flight_loop_damaged.wav",
        FlightLoopBroken = "p00gie/tardis/flight_loop_broken.wav",
        FlightLand = "p00gie/tardis/base/tardis_landing.wav",
        FlightFall = "p00gie/tardis/fall.wav",
        BrokenFlightTurn = {
            "p00gie/tardis/flight_turn_1.wav",
            "p00gie/tardis/flight_turn_2.wav",
            "p00gie/tardis/flight_turn_3.wav",
        },
        BrokenFlightExplosion = "p00gie/tardis/flight_turn_explosion.wav",
        BrokenFlightEnable = "p00gie/tardis/flight_broken_start.wav",
        BrokenFlightDisable = "p00gie/tardis/flight_broken_stop.wav",
        Cloak = "drmatt/tardis/phase_enable.wav",
        CloakOff = "drmatt/tardis/phase_disable.wav",
        Hum = nil,
        Chameleon = "drmatt/tardis/chameleon_circuit.wav",
    },
    Chameleon = {
        AnimTime = 4,
    },
    Parts = {
        vortex = {
            model = "models/doctorwho1200/toyota/2013timevortex.mdl",
            pos = Vector(0,0,50),
            ang = Angle(0,0,0),
            scale = 10
        }
    },
    Teleport = {
        SequenceSpeed = 0.77,
        SequenceSpeedWarning = 0.6,
        SequenceSpeedFast = 0.935,
        SequenceSpeedHads = 1.8,
        SequenceSpeedWarnFast = 0.97,
        PrematDelayFast = 1.9,
        PrematDelay = 8.5,
        DematSequence = {
            200,
            100,
            150,
            50,
            100,
            0
        },
        MatSequence = {
            50,
            150,
            100,
            200,
            150,
            255
        },
        HadsDematSequence = {
            100,
            200,
            0
        },
    }
}
T.Timings = {
    DematInterrupt = 1,
    DematFail = 4,
    MatFail = 8,
}

TARDIS:AddInterior(T)

local E = TARDIS:CopyTable(T.Exterior)
E.ID = "base"
E.Base = true
E.Name = "Base"
E.Category = "Exteriors.Categories.PoliceBoxes"
-- to prevent it generating other empty categories

E.Light.enabled = false

TARDIS:AddExterior(E)