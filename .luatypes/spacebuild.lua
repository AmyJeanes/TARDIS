---@meta

-- Type annotations only - never executed. The declarations below define real
-- globals and library functions with empty bodies, so loading this file at
-- runtime would replace working functions with stubs rather than declare them.
-- It lives outside lua/ so the game cannot reach it; this is the backstop.
error("spacebuild.lua contains type annotations only and must never be executed")

-- Spacebuild resource environment (legacy SB3 dependency, not a sibling addon).
-- Covers only the env-entity surface TARDIS touches in sv_spacebuild.lua.

---@class sb_environment_air
---@field o2 number
---@field o2per number
---@field co2 number
---@field co2per number
---@field n number
---@field nper number
---@field h number
---@field hper number
---@field empty number
---@field emptyper number
---@field max number

---@class sb_environment
---@field gravity number
---@field atmosphere number
---@field pressure number
---@field temperature number
---@field air sb_environment_air

---@class sb_resource_environment : Entity
---@field sbenvironment sb_environment?
---@field OnEnvironment function
---@field CreateEnvironment fun(self: sb_resource_environment, ent: Entity, radius: number)
---@field UpdateEnvironment fun(self: sb_resource_environment, filter: any, gravity: number, atmosphere: number, pressure: number, temperature: number, o2per: number, co2per: number, nper: number, hper: number)
---@field UpdateGravity fun(self: sb_resource_environment, ent: Entity)
---@field GetVolume fun(self: sb_resource_environment): number
---@field GetGravity fun(self: sb_resource_environment): number
---@field GetAtmosphere fun(self: sb_resource_environment): number
---@field GetPressure fun(self: sb_resource_environment): number
---@field GetTemperature fun(self: sb_resource_environment): number
---@field GetO2Percentage fun(self: sb_resource_environment): number
---@field GetCO2Percentage fun(self: sb_resource_environment): number
---@field GetNPercentage fun(self: sb_resource_environment): number
---@field GetHPercentage fun(self: sb_resource_environment): number
---@field GetEmptyAirPercentage fun(self: sb_resource_environment): number

-- The spacebuild environment SENT we spawn by classname.
---@class base_cube_environment : Entity

-- The simpler base environment SENT definition whose methods the cube env
-- borrows (scripted_ents.Get returns the definition table, not an entity).
---@class base_sb_environment
---@field OnEnvironment function
---@field GetTemperature function