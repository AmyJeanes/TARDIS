local T = {
    Exterior = {
        Model="models/artixc/exteriors/sidrat.mdl",
        Mass=5000,
        Portal={
            pos=Vector(29.75, 0, 46.5),
            ang=Angle(0,0,0),
            width=25,
            height=87,
            thickness = 25,
            inverted = true,
        },
        Fallback={
            pos=Vector(44,0,7),
            ang=Angle(0,0,0)
        },
        Light={
            enabled=false,
        },
        Sounds={
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
        },
        Parts={
            door={
                model="models/artixc/exteriors/sidrat_door.mdl",
                posoffset=Vector(-29.85,0,-46.45),
                angoffset=Angle(0,0,0),
            },
        }
    },
    Interior = {
        Parts={
            door={
                model="models/artixc/exteriors/sidrat_door.mdl",
                posoffset=Vector(29.85,0,-46.45),
            },
        }
    },
}

TARDIS:AddInteriorTemplate("exterior_sidrat", T)


local E = TARDIS:CopyTable(T.Exterior)
E.ID = "sidrat"
E.Base = "base"
E.Name = "Exteriors.SIDRAT"
E.Category = "Exteriors.Categories.TTCapsules"

TARDIS:AddExterior(E)



local T = {
    Exterior = {
        Model="models/artixc/exteriors/mk1.mdl",
        Mass=5000,
        Portal={
            pos=Vector(30, 0, 46.73),
            ang=Angle(0,0,0),
            width=40,
            height=92,
            thickness = 25,
            inverted = true,
        },
        Fallback={
            pos=Vector(44,0,7),
            ang=Angle(0,0,0)
        },
        Light={
            enabled=false,
        },
        Sounds={
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
        },
        Parts={
            door={
                model="models/artixc/exteriors/mk1_door.mdl",
                posoffset=Vector(-30.05,0,-46.45),
                angoffset=Angle(0,0,0),
            },
        },
        ScannerOffset = Vector(30,0,50),
    },
    Interior = {
        Parts={
            door={
                model="models/artixc/exteriors/mk1_door.mdl",
                posoffset=Vector(30.05,0,-46.45),
                use_exit_point_offset = true,
            },
        }
    },
}

TARDIS:AddInteriorTemplate("exterior_ttcapsule_type40", T)


local E = TARDIS:CopyTable(T.Exterior)
E.ID = "ttcapsule_type40"
E.Base = "base"
E.Name = "Exteriors.TTCapsuleType40"
E.Category = "Exteriors.Categories.TTCapsules"

TARDIS:AddExterior(E)



local T = {
    Exterior = {
        Model="models/artixc/exteriors/mk2.mdl",
        Mass=5000,
        Portal={
            pos=Vector(28, 0, 57.1),
            ang=Angle(0,0,0),
            width=40,
            height=96,
            thickness = 25,
            inverted = true,
        },
        Fallback={
            pos=Vector(44,0,7),
            ang=Angle(0,0,0)
        },
        Light={
            enabled=false,
        },
        Sounds={
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
        },
        Parts={
            door={
                model="models/artixc/exteriors/mk2_door.mdl",
                posoffset=Vector(-27.95,0,-56.2),
                angoffset=Angle(0,0,0),
            },
        }
    },
    Interior = {
        Parts={
            door={
                model="models/artixc/exteriors/mk2_door.mdl",
                posoffset=Vector(27.95,0,-56.2),
                use_exit_point_offset = true,
            },
        }
    },
}

TARDIS:AddInteriorTemplate("exterior_ttcapsule_type50", T)

local E = TARDIS:CopyTable(T.Exterior)
E.ID = "ttcapsule_type50"
E.Base = "base"
E.Name = "Exteriors.TTCapsuleType50"
E.Category = "Exteriors.Categories.TTCapsules"

TARDIS:AddExterior(E)



local T = {
    Exterior = {
        Model="models/artixc/exteriors/mk3.mdl",
        Mass=5000,
        Portal={
            pos=Vector(18.85, 0, 52.6),
            ang=Angle(0,0,0),
            width=26,
            height=87,
            thickness = 25,
            inverted = true,
        },
        Fallback={
            pos=Vector(44,0,7),
            ang=Angle(0,0,0)
        },
        Light={
            enabled=false,
        },
        Sounds={
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
        },
        Parts={
            door={
                model="models/artixc/exteriors/mk3_door.mdl",
                posoffset=Vector(-5,12.54,-43.55),
                angoffset=Angle(0,0,0),
            },
        }
    },
    Interior = {
        Parts={
            door={
                model="models/artixc/exteriors/mk3_door.mdl",
                posoffset=Vector(5,-12.54,-43.55),
                use_exit_point_offset = true,
            },
        }
    },
}

TARDIS:AddInteriorTemplate("exterior_ttcapsule_type55", T)
TARDIS:AddInteriorTemplate("ttcapsule", T)

local E = TARDIS:CopyTable(T.Exterior)
E.ID = "ttcapsule_type55"
E.Base = "base"
E.Name = "Exteriors.TTCapsuleType55"
E.Category = "Exteriors.Categories.TTCapsules"

TARDIS:AddExterior(E)

