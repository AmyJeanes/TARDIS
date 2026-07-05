local E = TARDIS:NewExterior()
E.ID = "legacy"
E.Name = "Exteriors.LegacyPoliceBox"
E.Base = "base"
E.Category = "Exteriors.Categories.PoliceBoxes"

E.Parts = {
    door = {
        model = "models/drmatt/tardis/exterior/door.mdl",
        posoffset=Vector(-28,0,-54.6)
    }
}
E.Sounds = {
    Teleport = {
        demat = "drmatt/tardis/demat.wav",
        demat_fast = "drmatt/tardis/demat.wav",
        demat_hads = "p00gie/tardis/demat_hads.wav",
        mat = "drmatt/tardis/mat.wav",
        mat_fast = "p00gie/tardis/mat_fast.wav",
        mat_damaged_fast = "p00gie/tardis/mat_damaged_fast.wav",
        fullflight = "drmatt/tardis/full.wav",
        interrupt = "drmatt/tardis/repairfinish.wav",
    },
    Spawn = "drmatt/tardis/repairfinish.wav",
    RepairFinish = "drmatt/tardis/repairfinish.wav",
    Delete = "p00gie/tardis/tardis_delete.wav",
    FlightLand = "p00gie/tardis/tardis_landing.wav",
}
E.Light = {
    warncolor = Color(255,200,200),
}
E.PhaseMaterial = "models/drmatt/tardis/exterior/phase.vmt"
E.Portal = {
    pos = Vector(28,0,54.6),
    ang = Angle(0,0,0),
    width = 45,
    height = 92,
    thickness = 42,
    inverted = true,
}

TARDIS:AddExterior(E)
