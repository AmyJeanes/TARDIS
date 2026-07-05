-- SIDRAT template
local E = TARDIS:NewExterior()
E.Model="models/artixc/exteriors/sidrat.mdl"
E.Mass=5000
E.Portal={
    pos=Vector(29.75, 0, 46.5),
    ang=Angle(0,0,0),
    width=25,
    height=87,
    thickness = 25,
    inverted = true,
}
E.Fallback={
    pos=Vector(44,0,7),
    ang=Angle(0,0,0)
}
E.Light={
    enabled=false,
}
E.Sounds={
    Teleport={
        demat="vtalanov98/hellbentext/demat.wav",
        mat="vtalanov98/hellbentext/mat.wav"
    },
    Lock="vtalanov98/hellbentext/lock.wav",
    Door={
        enabled=true,
        open="vtalanov98/hellbentext/doorext_open.wav",
        close="vtalanov98/hellbentext/doorext_close.wav",
    },
    FlightLoop="vtalanov98/hellbentext/flight_loop.wav",
}
E.Parts={
    door={
        model="models/artixc/exteriors/sidrat_door.mdl",
        posoffset=Vector(-29.85,0,-46.45),
        angoffset=Angle(0,0,0),
    },
}

TARDIS:AddInteriorTemplate("exterior_sidrat", TARDIS:NewInteriorTemplate({
    Exterior = TARDIS:CopyTable(E),
    Interior = {
        Parts={
            door={
                model="models/artixc/exteriors/sidrat_door.mdl",
                posoffset=Vector(29.85,0,-46.45),
            },
        }
    },
}))

-- SIDRAT exterior
E.ID = "sidrat"
E.Base = "base"
E.Name = "Exteriors.SIDRAT"
E.Category = "Exteriors.Categories.TTCapsules"

TARDIS:AddExterior(E)



-- Type 40 template
E = TARDIS:NewExterior()
E.Model="models/artixc/exteriors/mk1.mdl"
E.Mass=5000
E.Portal={
    pos=Vector(30, 0, 46.73),
    ang=Angle(0,0,0),
    width=40,
    height=92,
    thickness = 25,
    inverted = true,
}
E.Fallback={
    pos=Vector(44,0,7),
    ang=Angle(0,0,0)
}
E.Light={
    enabled=false,
}
E.Sounds={
    Teleport={
        demat="vtalanov98/hellbentext/demat.wav",
        mat="vtalanov98/hellbentext/mat.wav"
    },
    Lock="vtalanov98/hellbentext/lock.wav",
    Door={
        enabled=true,
        open="vtalanov98/hellbentext/doorext_open.wav",
        close="vtalanov98/hellbentext/doorext_close.wav",
    },
    FlightLoop="vtalanov98/hellbentext/flight_loop.wav",
}
E.Parts={
    door={
        model="models/artixc/exteriors/mk1_door.mdl",
        posoffset=Vector(-30.05,0,-46.45),
        angoffset=Angle(0,0,0),
    },
}
E.ScannerOffset = Vector(30,0,50)

TARDIS:AddInteriorTemplate("exterior_ttcapsule_type40", TARDIS:NewInteriorTemplate({
    Exterior = TARDIS:CopyTable(E),
    Interior = {
        Parts={
            door={
                model="models/artixc/exteriors/mk1_door.mdl",
                posoffset=Vector(30.05,0,-46.45),
                use_exit_point_offset = true,
            },
        }
    },
}))

-- Type 40 exterior
E.ID = "ttcapsule_type40"
E.Base = "base"
E.Name = "Exteriors.TTCapsuleType40"
E.Category = "Exteriors.Categories.TTCapsules"

TARDIS:AddExterior(E)



-- Type 50 template
E = TARDIS:NewExterior()
E.Model="models/artixc/exteriors/mk2.mdl"
E.Mass=5000
E.Portal={
    pos=Vector(28, 0, 57.1),
    ang=Angle(0,0,0),
    width=40,
    height=96,
    thickness = 25,
    inverted = true,
}
E.Fallback={
    pos=Vector(44,0,7),
    ang=Angle(0,0,0)
}
E.Light={
    enabled=false,
}
E.Sounds={
    Teleport={
        demat="vtalanov98/hellbentext/demat.wav",
        mat="vtalanov98/hellbentext/mat.wav"
    },
    Lock="vtalanov98/hellbentext/lock.wav",
    Door={
        enabled=true,
        open="vtalanov98/hellbentext/doorext_open.wav",
        close="vtalanov98/hellbentext/doorext_close.wav",
    },
    FlightLoop="vtalanov98/hellbentext/flight_loop.wav",
}
E.Parts={
    door={
        model="models/artixc/exteriors/mk2_door.mdl",
        posoffset=Vector(-27.95,0,-56.2),
        angoffset=Angle(0,0,0),
    },
}

TARDIS:AddInteriorTemplate("exterior_ttcapsule_type50", TARDIS:NewInteriorTemplate({
    Exterior = TARDIS:CopyTable(E),
    Interior = {
        Parts={
            door={
                model="models/artixc/exteriors/mk2_door.mdl",
                posoffset=Vector(27.95,0,-56.2),
                use_exit_point_offset = true,
            },
        }
    },
}))

-- Type 50 exterior
E.ID = "ttcapsule_type50"
E.Base = "base"
E.Name = "Exteriors.TTCapsuleType50"
E.Category = "Exteriors.Categories.TTCapsules"

TARDIS:AddExterior(E)



-- Type 55 template
E = TARDIS:NewExterior()
E.Model="models/artixc/exteriors/mk3.mdl"
E.Mass=5000
E.Portal={
    pos=Vector(18.85, 0, 52.6),
    ang=Angle(0,0,0),
    width=26,
    height=87,
    thickness = 25,
    inverted = true,
}
E.Fallback={
    pos=Vector(44,0,7),
    ang=Angle(0,0,0)
}
E.Light={
    enabled=false,
}
E.Sounds={
    Teleport={
        demat="vtalanov98/hellbentext/demat.wav",
        mat="vtalanov98/hellbentext/mat.wav"
    },
    Lock="vtalanov98/hellbentext/lock.wav",
    Door={
        enabled=true,
        open="vtalanov98/hellbentext/doorext_open.wav",
        close="vtalanov98/hellbentext/doorext_close.wav",
    },
    FlightLoop="vtalanov98/hellbentext/flight_loop.wav",
}
E.Parts={
    door={
        model="models/artixc/exteriors/mk3_door.mdl",
        posoffset=Vector(-5,12.54,-43.55),
        angoffset=Angle(0,0,0),
    },
}

local ttcapsule_template = TARDIS:NewInteriorTemplate({
    Exterior = TARDIS:CopyTable(E),
    Interior = {
        Parts={
            door={
                model="models/artixc/exteriors/mk3_door.mdl",
                posoffset=Vector(5,-12.54,-43.55),
                use_exit_point_offset = true,
            },
        }
    },
})
TARDIS:AddInteriorTemplate("exterior_ttcapsule_type55", ttcapsule_template)
TARDIS:AddInteriorTemplate("ttcapsule", ttcapsule_template)

-- Type 55 exterior
E.ID = "ttcapsule_type55"
E.Base = "base"
E.Name = "Exteriors.TTCapsuleType55"
E.Category = "Exteriors.Categories.TTCapsules"

TARDIS:AddExterior(E)
