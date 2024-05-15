local SETTING_SECTION = "Global"

CONVAR_FLAGS = {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}

TARDIS:AddSetting({
    id="health-enabled",
    type="bool",
    value=true,

    class="global",
    convar = {
        name = "tardis2_damage",
        flags = CONVAR_FLAGS,
        desc = "TARDIS - Damage enabled (1 enables, 0 disables)",
    },

    option = true,
    section=SETTING_SECTION,
    name="EnableHealth",
})

TARDIS:AddSetting({
    id="health_max",
    type="integer",
    value=3000,
    min=1,
    max=30000,
    round_func = function(x)
        if x < 50 then return x end
        if x < 500 then return (x - x % 10) end
        if x < 2000 then return (x - x % 100) end
        return (x - x % 500)
    end,

    class="global",
    convar = {
        name = "tardis2_maxhealth",
        flags = CONVAR_FLAGS,
        desc = "TARDIS - Maximum health",
    },

    option = true,
    section=SETTING_SECTION,
    name="MaxHealth",
})

if SERVER then
    TARDIS:AddMigration("health-changed", "2023.8.0", function(self)
        local oldHealthMax = self.GlobalSettings["health-max"]
        if oldHealthMax then
            self:SetSetting("health_max", oldHealthMax * 3)
        end
    end)
end

TARDIS:AddSetting({
    id="health_to_shields_ratio",
    type="number",
    value=0.2,
    min=0.05,
    max=0.95,
    round_func = function(x)
        return x - ((x * 100) % 5) * 0.01
    end,

    class="global",
    convar = {
        name = "tardis2_health_to_shields_ratio",
        flags = CONVAR_FLAGS,
        desc = "TARDIS - the ratio of max health to max shields",
    },

    option = true,
    section=SETTING_SECTION,
    name="HealthToShieldsRatio",
})

TARDIS:AddSetting({
    id="long_repair",
    type="bool",
    value=true,

    class="global",
    convar = {
        name = "tardis2_long_repair",
        flags = CONVAR_FLAGS,
        desc = "TARDIS - Whether max repair time is 60 seconds instead of 15",
    },

    option = true,
    section=SETTING_SECTION,
    name="WaitLongForRepair",
})

TARDIS:AddSetting({
    id="artron_energy",
    type="bool",
    value=true,

    class="global",
    convar = {
        name = "tardis2_artron_energy",
        flags = CONVAR_FLAGS,
        desc = "TARDIS - Whether artron energy is enabled",
    },

    option = true,
    section=SETTING_SECTION,
    subsection="ArtronEnergy",
    name="ArtronEnergyEnabled",
})

TARDIS:AddSetting({
    id="artron_energy_start",
    type="list",
    value=0.25,
    get_values_func = function()
        return {
            { "0%", 0.0 },
            { "25%", 0.25 },
            { "50%", 0.5 },
            { "75%", 0.75 },
            { "100%", 1.0 },
        }
    end,

    class="global",
    convar = {
        name = "tardis2_artron_energy_start",
        flags = CONVAR_FLAGS,
        desc = "TARDIS - Initial amount of artron energy",
    },

    option=true,
    section=SETTING_SECTION,
    subsection="ArtronEnergy",
    name="ArtronEnergyStart",
})

TARDIS:AddSetting({
    id="artron_energy_max",
    type="integer",
    value=100,
    min=25,
    max=400,
    round_func = function(x)
        if x > 200 then return (x - x % 100) end
        if x > 100 then return (x - x % 50) end
        return (x - x % 25)
    end,

    class="global",
    convar = {
        name = "tardis2_artron_energy_max",
        flags = CONVAR_FLAGS,
        desc = "TARDIS - Max amount of artron energy",
    },

    option = true,
    section=SETTING_SECTION,
    subsection="ArtronEnergy",
    name="ArtronEnergyMax",
})

TARDIS:AddSetting({
    id="artron_energy_charge_frequency",
    type="integer",
    value=5,
    min=2,
    max=10,

    class="global",
    convar = {
        name = "tardis2_artron_energy_charge_frequency",
        flags = CONVAR_FLAGS,
        desc = "TARDIS - How often does the charging of artron energy happen without handbrake",
    },

    option = true,
    section=SETTING_SECTION,
    subsection="ArtronEnergy",
    name="ArtronEnergyChargeFrequency",
})

TARDIS:AddSetting({
    id="admin_security_bypass",
    type="bool",
    value=false,

    class="global",
    convar = {
        name = "tardis2_admin_security_bypass",
        flags = CONVAR_FLAGS,
        desc = "TARDIS - Admins bypass security (1 enables, 0 disables)",
    },

    option = true,
    section=SETTING_SECTION,
    name="AdminSecurityBypass",
})

TARDIS:AddSetting({
    id="boost-speed",
    type="number",
    value=2.5,
    min=1.0,
    max=8.0,
    round_func = function(x)
        return (x - x % 0.5)
    end,

    class="global",
    convar = {
        name = "tardis2_boost_speed",
        flags = CONVAR_FLAGS,
        desc = "TARDIS - Boost Speed",
    },

    option = true,
    section=SETTING_SECTION,
    name="BoostSpeed",
})
