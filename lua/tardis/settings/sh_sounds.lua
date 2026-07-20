local SETTING_SECTION = "SoundsAndMusic"

if CLIENT then
    -- Developers should respect this setting before playing any sounds
    TARDIS:AddSetting({
        id = "sound",
        type = "bool",
        value = true,

        class="local",

        option = true,
        subsection = "Sounds",
        section = SETTING_SECTION,
        name = "All",
    })

    TARDIS:AddSetting({
        id="spawn_delete_sound",
        type="bool",
        value=true,

        class="local",

        option=true,
        section=SETTING_SECTION,
        subsection="Sounds",
        name="SpawnDelete",
    })

    TARDIS:AddSetting({
        id = "cloaksound-enabled",
        type = "bool",
        value = true,

        class="local",

        option = true,
        section = SETTING_SECTION,
        subsection="Sounds",
        name = "Cloak",
    })

    TARDIS:AddSetting({
        id="doorsounds-enabled",
        type="bool",
        value=true,

        class="local",

        option=true,
        section=SETTING_SECTION,
        subsection="Sounds",
        name="Door",
    })

    TARDIS:AddSetting({
        id="flight-externalsound",
        type="bool",
        value=true,

        class="local",

        option=true,
        section=SETTING_SECTION,
        subsection="Sounds",
        name="FlightExternal",
    })

    TARDIS:AddSetting({
        id="locksound-enabled",
        type="bool",
        value=true,

        class="local",

        option=true,
        section=SETTING_SECTION,
        subsection="Sounds",
        name="Lock",
    })

    TARDIS:AddSetting({
        id="teleport-sound",
        type="bool",
        value=true,

        class="local",

        option=true,
        section=SETTING_SECTION,
        subsection="Sounds",
        name="Teleport",
    })

    TARDIS:AddSetting({
        id="cloistersound",
        type="bool",
        value=true,

        class="local",

        option=true,
        section=SETTING_SECTION,
        subsection="Sounds",
        name="CloisterBells",
    })

    TARDIS:AddSetting({
        id="flight-internalsound",
        type="bool",
        value=true,

        class="local",

        option=true,
        section=SETTING_SECTION,
        subsection="Sounds",
        name="FlightInternal",
    })

    TARDIS:AddSetting({
        id="idlesounds",
        type="bool",
        value=true,

        class="local",

        option=true,
        section=SETTING_SECTION,
        subsection="Sounds",
        name="Idle",
    })
    
    TARDIS:AddSetting({
        id="sound_through_doors",
        type="bool",
        value=true,

        class="local",

        option=true,
        section=SETTING_SECTION,
        subsection="Sounds",
        name="SoundThroughDoors",
    })

    -- Replaces interior_hum_leakage, which was only ever about the hum, and its volume, which is now
    -- content: an interior owns how much of it carries, the way it already owns every other sound's
    -- volume. The old keys are deliberately left in place rather than cleared, so a player moving
    -- between beta and release keeps working settings on both.
    TARDIS:AddMigration("sound-through-doors", "2026-07-20", function(self)
        local enabled = self.LocalSettings["interior_hum_leakage"]
        -- Muting it through the volume said the same thing as switching it off, so carry that across
        -- rather than handing them back a sound they had silenced.
        if enabled == false or self.LocalSettings["interior_hum_leakage_volume"] == 0 then
            self:SetSetting("sound_through_doors", false)
        end
    end)
end

TARDIS:AddSetting({
    id="music-enabled",
    type="bool",
    value=true,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Music",
    name="Enabled",
})

TARDIS:AddSetting({
    id="music-volume",
    type="number",
    value=100,
    min=0,
    max=1500,
    round_func = function(x)
        if x > 1000 then return (x - x % 250) end
        if x > 300 then return (x - x % 100) end
        if x > 50 then return (x - x % 10) end
        return (x - x % 5)
    end,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Music",
    name="Volume",
})

TARDIS:AddSetting({
    id="music-exit",
    type="bool",
    value=true,

    class="networked",

    option=true,
    section=SETTING_SECTION,
    subsection="Music",
    name="StopOnExit",
})