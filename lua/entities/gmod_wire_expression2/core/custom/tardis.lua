E2Lib.RegisterExtension("tardis", true)

local function getTardis(ent)
    if not IsValid(ent) then return end
    local class = ent:GetClass()
    if class == "gmod_tardis" or class == "sent_tardis" then
        return ent
    elseif class == "sent_tardis_interior" and IsValid(ent.tardis) then
        return ent.tardis
    elseif (class == "gmod_tardis_interior" or ent.Base == "gmod_tardis_part") and IsValid(ent.exterior) then
        return ent.exterior
    elseif ent:IsPlayer() and IsValid(ent.tardis) then
        return ent.tardis.exterior or ent.tardis
    else
        return NULL
    end
end

local function HandleE2(ent, type, name, e2, ...)
    local tardis = getTardis(ent)
    if IsValid(tardis) then
        if type == "Setter" and tardis:CheckSecurity(e2.player) == false then
            TARDIS:ErrorMessage(e2.player,"Expression2.Security.UseDenied")
        else
            return tardis:HandleE2(name, e2, ...)
        end
    else
        error(TARDIS:GetPhrase("Expression2.Error"),0)
    end
end

e2function entity entity:tardisGet()
    return getTardis(this)
end

--[[
    ╔═══════════════════╗
    ║Setters and actions║
    ╚═══════════════════╝
]]

--Teleport

e2function number entity:tardisDemat(vector pos, angle rot)
    return HandleE2(this, "Setter", "Demat", self, pos, rot)
end

e2function number entity:tardisDemat(vector pos)
    return HandleE2(this, "Setter", "Demat", self, pos)
end

e2function number entity:tardisFastDemat()
    return HandleE2(this, "Setter", "FastDemat", self)
end

e2function number entity:tardisMaterialise()
    return HandleE2(this, "Setter", "Mat", self)
end

e2function number entity:tardisSetDestination(vector pos, angle ang)
    return HandleE2(this, "Setter", "SetDestination", self, pos, ang)
end

e2function number entity:tardisSetDestination(vector pos)
    return HandleE2(this, "Setter", "SetDestination", self, pos)
end

e2function number entity:tardisFastReturn()
    return HandleE2(this, "Setter", "FastReturn", self)
end

e2function number entity:tardisLongflight()
    return HandleE2(this, "Setter", "Longflight", self)
end

e2function number entity:tardisLongflight(on)
    return HandleE2(this, "Setter", "SetLongflight", self, on)
end

e2function number entity:tardisHADS()
    return HandleE2(this, "Setter", "HADS", self)
end

e2function number entity:tardisHADS(on)
    return HandleE2(this, "Setter", "SetHADS", self, on)
end

--Flight

e2function number entity:tardisFlightmode(normal on)
    return HandleE2(this, "Setter", "Flightmode", self, on)
end

e2function number entity:tardisFlightmode()
    return HandleE2(this, "Setter", "Flightmode", self)
end

e2function number entity:tardisPhyslock()
    return HandleE2(this, "Setter", "Physlock", self)
end

e2function number entity:tardisPhyslock(on)
    return HandleE2(this, "Setter", "SetPhyslock", self, on)
end

e2function number entity:tardisSpinmode(number spinmode)
    return HandleE2(this, "Setter", "SetSpinmode", self, spinmode)
end

e2function number entity:tardisTrack(entity ent)
    return HandleE2(this, "Setter", "Track", self, ent)
end

--Security

e2function number entity:tardisLock()
    return HandleE2(this, "Setter", "Lock", self)
end

e2function number entity:tardisLock(on)
    return HandleE2(this, "Setter", "SetLock", self, on)
end

e2function number entity:tardisIsomorph()
    return HandleE2(this, "Setter", "Isomorph", self)
end

e2function number entity:tardisIsomorph(on)
    return HandleE2(this, "Setter", "SetIsomorph", self, on)
end

--Extra

e2function number entity:tardisPower()
    return HandleE2(this, "Setter", "Power", self)
end

e2function number entity:tardisPower(on)
    return HandleE2(this, "Setter", "SetPower", self, on)
end

e2function number entity:tardisSelfrepair()
    return HandleE2(this, "Setter", "Selfrepair", self)
end

e2function number entity:tardisSelfrepair(on)
    return HandleE2(this, "Setter", "SetSelfrepair", self, on)
end

e2function number entity:tardisPhase()
    return HandleE2(this, "Setter", "Phase", self)
end

e2function number entity:tardisPhase(on)
    return HandleE2(this, "Setter", "SetPhase", self, on)
end

e2function number entity:tardisDoor(number open)
    return HandleE2(this, "Setter", "SetDoors", self, open)
end

e2function number entity:tardisDoor()
    return HandleE2(this, "Setter", "ToggleDoors", self)
end

e2function number entity:tardisHandbrake(on)
    return HandleE2(this, "Setter", "SetBrake", self, on)
end

e2function number entity:tardisHandbrake()
    return HandleE2(this, "Setter", "ToggleBrake", self)
end

e2function number entity:tardisRemoveArtronEnergy(number energy)
    return HandleE2(this, "Setter", "RemoveArtron", self, energy)
end

e2function number entity:tardisShields()
    return HandleE2(this, "Setter", "ToggleShield", self)
end

e2function number entity:tardisShields(number on)
    return HandleE2(this, "Setter", "SetShield", self, on)
end

--[[
    ╔════════════╗
    ║Data getters║
    ╚════════════╝
]]

e2function string entity:tardisGetData(string id)
    return tostring(this:GetData(id,false))
end

--Teleport

e2function number entity:tardisMoving()
    return HandleE2(this, "Getter", "GetMoving", self)
end

e2function number entity:tardisInVortex()
    return HandleE2(this, "Getter", "GetInVortex", self)
end

e2function number entity:tardisLongflighted()
    return HandleE2(this, "Getter", "GetLongflight", self)
end

e2function vector entity:tardisLastPos()
    return HandleE2(this, "Getter", "LastPos", self)
end

e2function angle entity:tardisLastAng()
    return HandleE2(this, "Getter", "LastAng", self)
end

e2function number entity:tardisIsHADS()
    return HandleE2(this, "Getter", "GetHADS", self)
end

--Flight

e2function number entity:tardisFlying()
    return HandleE2(this, "Getter", "GetFlying", self)
end

e2function entity entity:tardisPilot()
    return HandleE2(this, "Getter", "GetPilot", self)
end

e2function number entity:tardisSpinmode()
    return HandleE2(this, "Setter", "GetSpinmode", self)
end

e2function entity entity:tardisTracking()
    return HandleE2(this, "Getter", "GetTracking", self)
end

e2function number entity:tardisPhyslocked()
    return HandleE2(this, "Getter", "GetPhyslocked", self)
end

--Health

e2function number entity:tardisHealth()
    return HandleE2(this, "Getter", "GetHealth", self)
end

e2function number entity:tardisSelfrepairing()
    return HandleE2(this, "Getter", "GetSelfrepairing", self)
end

e2function number entity:tardisSelfrepairTime()
    return HandleE2(this, "Getter", "GetRepairTime", self)
end

--Security

e2function number entity:tardisIsomorphic()
    return HandleE2(this, "Getter", "GetIsomorphic", self)
end

e2function number entity:tardisLocked()
    return HandleE2(this, "Getter", "GetLocked", self)
end

--Extra

e2function number entity:tardisVisible()
    return HandleE2(this, "Getter", "GetVisible", self)
end

e2function number entity:tardisPowered()
    return HandleE2(this, "Getter", "GetPowered", self)
end

e2function number entity:tardisOpened()
    return HandleE2(this, "Getter", "GetDoors", self)
end

e2function number entity:tardisBraking()
    return HandleE2(this, "Getter", "GetBrake", self)
end

e2function number entity:tardisArtronEnergy()
    return HandleE2(this, "Getter", "GetArtron", self)
end

e2function number entity:tardisMaxArtronEnergy()
    return HandleE2(this, "Getter", "GetMaxArtron", self)
end

e2function number entity:tardisShieldsOn()
    return HandleE2(this, "Getter", "GetShieldsOn", self)
end

e2function number entity:tardisShieldsLevel()
    return HandleE2(this, "Getter", "GetShieldsLevel", self)
end

e2function number entity:tardisShieldsPercent()
    return HandleE2(this, "Getter", "GetShieldsPercent", self)
end

e2function number entity:tardisShieldsMax()
    return HandleE2(this, "Getter", "GetShieldMax", self)
end