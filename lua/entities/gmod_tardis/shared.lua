-- TARDIS

---@class gmod_tardis : gmod_door_exterior
---@field BaseClass gmod_door_exterior
---@field timers table<string, table>
---@field parts table<string, gmod_tardis_part>
---@field controlparts table<string, table<string, gmod_tardis_part>>?
---@field metadataID string
---@field effect_pos Vector
---@field metadata tardis_metadata
---@field interior gmod_tardis_interior?
---@field pilot Player?
---@field occupants table<Player, true>
---@field LeakedInteriorHums table<any, CSoundPatch>
---@field environment sb_resource_environment?
---@field environment_old sb_resource_environment?
---@field music IGModAudioChannel?

ENT.Base="gmod_door_exterior"
ENT.Spawnable=false
ENT.PrintName="TARDIS"
ENT.Category="Doctor Who - TARDIS"
ENT.TardisExterior=true
ENT.Interior="gmod_tardis_interior"

if TARDIS_OVERRIDES and TARDIS_OVERRIDES.MainCategory then
    ENT.Category = TARDIS_OVERRIDES.MainCategory
end


local class=string.sub(ENT.Folder,string.find(ENT.Folder, "/[^/]*$")+1) -- only works if in a folder

local hooks={}

-- Hook system for modules
---@api
---@param func fun(self: gmod_tardis, ...)
---@param name string
---@param id string
-- >>> GENERATED hook overloads - do not edit; regen: scripts/generate-hook-types.ps1 >>>
---@overload fun(self: gmod_tardis, name: "AlphaTranslucentChanged", id: string, func: fun(self: gmod_tardis, arg1: boolean, ...))
---@overload fun(self: gmod_tardis, name: "ArtronDepleted", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "CanChangeDestination", id: string, func: fun(self: gmod_tardis, pos: Vector?, ang: Angle?, ...))
---@overload fun(self: gmod_tardis, name: "CanChangeExterior", id: string, func: fun(self: gmod_tardis, target: any, arg2: boolean, ...))
---@overload fun(self: gmod_tardis, name: "CanChangePilot", id: string, func: fun(self: gmod_tardis, ply: Player, ...))
---@overload fun(self: gmod_tardis, name: "CanDemat", id: string, func: fun(self: gmod_tardis, force: boolean?, arg2: boolean, ...))
---@overload fun(self: gmod_tardis, name: "CanIncreaseArtron", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "CanLock", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "CanMat", id: string, func: fun(self: gmod_tardis, pos: Vector?, ang: Angle?, arg3: boolean, ...))
---@overload fun(self: gmod_tardis, name: "CanPlayerEnterDoor", id: string, func: fun(self: gmod_tardis, ply: Player, ...))
---@overload fun(self: gmod_tardis, name: "CanPlayerExitDoor", id: string, func: fun(self: gmod_tardis, ply: Player, ...))
---@overload fun(self: gmod_tardis, name: "CanRepair", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "CanToggleCloak", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "CanToggleDoor", id: string, func: fun(self: gmod_tardis, doorstate: boolean, ...))
---@overload fun(self: gmod_tardis, name: "CanToggleFastRemat", id: string, func: fun(self: gmod_tardis, force: boolean?, ...))
---@overload fun(self: gmod_tardis, name: "CanToggleHandbrake", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "CanTogglePower", id: string, func: fun(self: gmod_tardis, on: boolean, ...))
---@overload fun(self: gmod_tardis, name: "CanToggleRedecoration", id: string, func: fun(self: gmod_tardis, on: boolean, ...))
---@overload fun(self: gmod_tardis, name: "CanToggleShields", id: string, func: fun(self: gmod_tardis, on: boolean, ...))
---@overload fun(self: gmod_tardis, name: "CanTrack", id: string, func: fun(self: gmod_tardis, ent: any, ply: any, ...))
---@overload fun(self: gmod_tardis, name: "CanTriggerHads", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "CanTurnOffFlight", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "CanTurnOffFloat", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "CanTurnOffPhyslock", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "CanTurnOnFlight", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "CanTurnOnFloat", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "CanTurnOnPhyslock", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "CanUsePart", id: string, func: fun(self: gmod_tardis, arg1: gmod_tardis_part, a: Entity, ...))
---@overload fun(self: gmod_tardis, name: "CanUseTardisControl", id: string, func: fun(self: gmod_tardis, control: tardis_control, ply: Player, part: gmod_tardis_part, ...))
---@overload fun(self: gmod_tardis, name: "ChameleonAnimationFinished", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ChameleonAnimationStarted", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "CloakAnimationFinished", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "CloakAnimationStarted", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "CloakToggled", id: string, func: fun(self: gmod_tardis, on: boolean, ...))
---@overload fun(self: gmod_tardis, name: "DataChanged", id: string, func: fun(self: gmod_tardis, key: string, value: any, ...))
---@overload fun(self: gmod_tardis, name: "DataLoaded", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "DematFailed", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "DematFailStopped", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "DematInterrupted", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "DematStart", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "Destination", id: string, func: fun(self: gmod_tardis, ply: Player, arg2: boolean, ...))
---@overload fun(self: gmod_tardis, name: "DestinationChanged", id: string, func: fun(self: gmod_tardis, pos: Vector?, ang: Angle?, ...))
---@overload fun(self: gmod_tardis, name: "DestinationOverride", id: string, func: fun(self: gmod_tardis, pos: Vector?, ang: Angle?, ...))
---@overload fun(self: gmod_tardis, name: "DoorLockToggled", id: string, func: fun(self: gmod_tardis, locked: boolean, ...))
---@overload fun(self: gmod_tardis, name: "ExteriorChanged", id: string, func: fun(self: gmod_tardis, id: any, ...))
---@overload fun(self: gmod_tardis, name: "FailedPhyslockEnable", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "FastDemat", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "FastRematToggled", id: string, func: fun(self: gmod_tardis, on: boolean, ...))
---@overload fun(self: gmod_tardis, name: "FastReturnTriggered", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "FlightControl", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "FlightInterrupted", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "FlightToggled", id: string, func: fun(self: gmod_tardis, on: boolean, ...))
---@overload fun(self: gmod_tardis, name: "FloatToggled", id: string, func: fun(self: gmod_tardis, on: boolean, ...))
---@overload fun(self: gmod_tardis, name: "ForceDematStart", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "HadsToggled", id: string, func: fun(self: gmod_tardis, on: boolean, ...))
---@overload fun(self: gmod_tardis, name: "HADSTrigger", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "HandbrakeToggled", id: string, func: fun(self: gmod_tardis, on: boolean, ...))
---@overload fun(self: gmod_tardis, name: "HandleE2", id: string, func: fun(self: gmod_tardis, cmd: string, arg2: any, ...))
---@overload fun(self: gmod_tardis, name: "HandleNoMat", id: string, func: fun(self: gmod_tardis, pos: Vector?, ang: Angle?, callback: any, ...))
---@overload fun(self: gmod_tardis, name: "HealthWarningToggled", id: string, func: fun(self: gmod_tardis, on: boolean, ...))
---@overload fun(self: gmod_tardis, name: "InterruptTeleport", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "IsTravelling", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "LanguageChanged", id: string, func: fun(self: gmod_tardis, langCode: any, oldLangCode: string, ...))
---@overload fun(self: gmod_tardis, name: "LockedUse", id: string, func: fun(self: gmod_tardis, ply: Player, ...))
---@overload fun(self: gmod_tardis, name: "MatFailed", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "MatFailStopped", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "MatStart", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "MigrateData", id: string, func: fun(self: gmod_tardis, parent: any, ...))
---@overload fun(self: gmod_tardis, name: "NewVersion", id: string, func: fun(self: gmod_tardis, newVersion: tardis_version, newVersionStr: string, oldVersion: tardis_version, oldVersionStr: string, ...))
---@overload fun(self: gmod_tardis, name: "OnHealthChange", id: string, func: fun(self: gmod_tardis, new_health: number, old_health: integer, ...))
---@overload fun(self: gmod_tardis, name: "OnHealthDepleted", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "OnTakeDamage", id: string, func: fun(self: gmod_tardis, dmginfo: CTakeDamageInfo, ...))
---@overload fun(self: gmod_tardis, name: "OnWireInput", id: string, func: fun(self: gmod_tardis, name: string, value: any, ...))
---@overload fun(self: gmod_tardis, name: "Outside", id: string, func: fun(self: gmod_tardis, ply: Player, enabled: true, ...))
---@overload fun(self: gmod_tardis, name: "Outside-PosAng", id: string, func: fun(self: gmod_tardis, ply: Player, pos: Vector, ang: Angle, ...))
---@overload fun(self: gmod_tardis, name: "Outside-StartCommand", id: string, func: fun(self: gmod_tardis, ply: Player, cmd: CUserCmd, ...))
---@overload fun(self: gmod_tardis, name: "PartBodygroupChanged", id: string, func: fun(self: gmod_tardis, ent: gmod_tardis_part, bodygroup: number, value: number, ...))
---@overload fun(self: gmod_tardis, name: "PartUsed", id: string, func: fun(self: gmod_tardis, arg1: gmod_tardis_part, a: Entity, ...))
---@overload fun(self: gmod_tardis, name: "PhysicsCollide", id: string, func: fun(self: gmod_tardis, colData: CollisionData, collider: Entity, ...))
---@overload fun(self: gmod_tardis, name: "PhyslockToggled", id: string, func: fun(self: gmod_tardis, on: boolean, ...))
---@overload fun(self: gmod_tardis, name: "PilotChanged", id: string, func: fun(self: gmod_tardis, arg1: any, ply: Player, ...))
---@overload fun(self: gmod_tardis, name: "PostDrawPart", id: string, func: fun(self: gmod_tardis, arg1: gmod_tardis_part, ...))
---@overload fun(self: gmod_tardis, name: "PowerToggled", id: string, func: fun(self: gmod_tardis, on: boolean, ...))
---@overload fun(self: gmod_tardis, name: "PreDrawPart", id: string, func: fun(self: gmod_tardis, arg1: gmod_tardis_part, ...))
---@overload fun(self: gmod_tardis, name: "PreMatStart", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "PreMetadataInitialize", id: string, func: fun(self: gmod_tardis, arg1: string, ...))
---@overload fun(self: gmod_tardis, name: "PreTeleportPositionChange", id: string, func: fun(self: gmod_tardis, pos: Vector, ang: Angle, phys_enable: boolean, ...))
---@overload fun(self: gmod_tardis, name: "RandomDestinationSet", id: string, func: fun(self: gmod_tardis, randomLocation: Vector, ...))
---@overload fun(self: gmod_tardis, name: "RandomizeTips", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "RedecorateToggled", id: string, func: fun(self: gmod_tardis, on: true, ...))
---@overload fun(self: gmod_tardis, name: "RepairCancelled", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "RepairFinished", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "RepairStarted", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "RepairToggled", id: string, func: fun(self: gmod_tardis, on: boolean, ...))
---@overload fun(self: gmod_tardis, name: "SecurityToggled", id: string, func: fun(self: gmod_tardis, on: boolean, ...))
---@overload fun(self: gmod_tardis, name: "SettingChanged", id: string, func: fun(self: gmod_tardis, id: string, value: any, old_value: any, ply: Player, ...))
---@overload fun(self: gmod_tardis, name: "SetupMMenuButtons", id: string, func: fun(self: gmod_tardis, screen: TardisScreen, frame: Panel, layout: HexagonalLayout, ...))
---@overload fun(self: gmod_tardis, name: "SetupVirtualConsole", id: string, func: fun(self: gmod_tardis, screen: TardisScreen, frame: tardis_screen_frame, layout: HexagonalLayout, ...))
---@overload fun(self: gmod_tardis, name: "ShieldsToggled", id: string, func: fun(self: gmod_tardis, on: boolean, ...))
---@overload fun(self: gmod_tardis, name: "ShouldAllowFalling", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldDraw", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldDrawPart", id: string, func: fun(self: gmod_tardis, arg1: gmod_tardis_part, ...))
---@overload fun(self: gmod_tardis, name: "ShouldDrawPhaseAnimation", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldDrawProjectedLight", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldDrawShadow", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldEmitDoorSound", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldFailDemat", id: string, func: fun(self: gmod_tardis, force: boolean?, ...))
---@overload fun(self: gmod_tardis, name: "ShouldFailMat", id: string, func: fun(self: gmod_tardis, pos: Vector?, ang: Angle?, ...))
---@overload fun(self: gmod_tardis, name: "ShouldForceDemat", id: string, func: fun(self: gmod_tardis, pos: Vector?, ang: Angle?, ...))
---@overload fun(self: gmod_tardis, name: "ShouldNotAllowFalling", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldNotDrawProjectedLight", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldNotPlayLandingSound", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldNotPulseLight", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldNotRenderPortal", id: string, func: fun(self: gmod_tardis, arg1: gmod_tardis_interior, portal: linked_portal_door, exit: linked_portal_door, origin: Vector, ...))
---@overload fun(self: gmod_tardis, name: "ShouldPlayDematSound", id: string, func: fun(self: gmod_tardis, arg1: boolean, ...))
---@overload fun(self: gmod_tardis, name: "ShouldPlayLandingSound", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldPlayMatSound", id: string, func: fun(self: gmod_tardis, arg1: boolean, ...))
---@overload fun(self: gmod_tardis, name: "ShouldPulseLight", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldRegenShields", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldStartFire", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldStartSmoke", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldStopFire", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldStopSmoke", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldTakeDamage", id: string, func: fun(self: gmod_tardis, dmginfo: CTakeDamageInfo, ...))
---@overload fun(self: gmod_tardis, name: "ShouldTurnOffFlightPhysics", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldTurnOffFlightSound", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldTurnOffFloatPhysics", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldTurnOffLight", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldTurnOffRotorwash", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldTurnOnLight", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldTurnOnRotorwash", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldUpdateArtron", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldVortexIgnoreZ", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "ShouldWarningBeEnabled", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "SpinChanged", id: string, func: fun(self: gmod_tardis, arg1: integer, ...))
---@overload fun(self: gmod_tardis, name: "StopDemat", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "StopMat", id: string, func: fun(self: gmod_tardis, ...))
---@overload fun(self: gmod_tardis, name: "TardisControlUsed", id: string, func: fun(self: gmod_tardis, control_id: string, ply: Player, part: gmod_tardis_part, ...))
---@overload fun(self: gmod_tardis, name: "TeleportPositionChanged", id: string, func: fun(self: gmod_tardis, pos: Vector, ang: Angle, phys_enable: boolean, ...))
---@overload fun(self: gmod_tardis, name: "ThirdPerson", id: string, func: fun(self: gmod_tardis, ply: Player, arg2: boolean, ...))
---@overload fun(self: gmod_tardis, name: "ToggleDoor", id: string, func: fun(self: gmod_tardis, arg1: boolean, ...))
---@overload fun(self: gmod_tardis, name: "ToggleDoorReal", id: string, func: fun(self: gmod_tardis, doorstate: boolean, ...))
---@overload fun(self: gmod_tardis, name: "VortexEnabled", id: string, func: fun(self: gmod_tardis, pilot: Player, ...))
---@overload fun(self: gmod_tardis, name: "WarningToggled", id: string, func: fun(self: gmod_tardis, on: boolean, ...))
-- <<< END GENERATED hook overloads <<<
function ENT:AddHook(name,id,func)
    if not (hooks[name]) then hooks[name]={} end
    if hooks[name][id] then error("Duplicate hook ID '"..id.."' for '"..name.."' hook",2) end
    if type(id)==func or not func then error("Invalid parameters - need name, id and func",2) end
    hooks[name][id]=func
end

---@api
---@param name string
---@param id string
function ENT:RemoveHook(name,id)
    if hooks[name] and hooks[name][id] then
        hooks[name][id]=nil
    end
end

function ENT:GetHooksTable()
    return hooks
end

---@param listInteriorHooks boolean?
function ENT:ListHooks(listInteriorHooks)
    print("[Exterior]"..(SERVER and "[Server]" or "[Client]"))
    for h in pairs(hooks) do
        print(h)
    end
    if listInteriorHooks and IsValid(self.interior) then self.interior:ListHooks() end
end

---@api
---@param name string
---@return any
function ENT:CallCommonHook(name, ...)
    local a,b,c,d,e,f

    a,b,c,d,e,f = self:CallHook(name, ...)
    if a~=nil then
        return a,b,c,d,e,f
    end

    if IsValid(self.interior) then
        a,b,c,d,e,f = self.interior:CallHook(name, ...)
        if a~=nil then
            return a,b,c,d,e,f
        end
    end
end

---@api
---@param name string
---@return any
function ENT:CallHook(name,...)
    local a,b,c,d,e,f
    a,b,c,d,e,f=self.BaseClass.CallHook(self,name,...)
    if a~=nil then
        return a,b,c,d,e,f
    end
    if hooks[name] then
        for _,v in pairs(hooks[name]) do
            a,b,c,d,e,f = v(self,...)
            if a~=nil then
                return a,b,c,d,e,f
            end
        end
    end
    if self.metadata and self.metadata.Exterior and self.metadata.Exterior.CustomHooks then
        for _,body in pairs(self.metadata.Exterior.CustomHooks) do
            if body and istable(body) and ((body[1] == name) or (istable(body[1]) and body[1][name])) then
                local func = body[2]
                a,b,c,d,e,f = func(self, ...)
                if a~=nil then
                    return a,b,c,d,e,f
                end
            end
        end
    end
    if self.metadata and self.metadata.CustomHooks then
        for _,body in pairs(self.metadata.CustomHooks) do
            if body and istable(body) and body.exthooks and body.exthooks[name] then
                a,b,c,d,e,f = body.func(self, self.interior, ...)
                if a~=nil then
                    return a,b,c,d,e,f
                end
            end
        end
    end
    if SERVER then
        TARDIS:CallControlMove(self, name, ...)
    end
end

---@api
---@param folder string
---@param addonly boolean?
---@param noprefix boolean?
function ENT:LoadFolder(folder,addonly,noprefix)
    folder="entities/"..class.."/"..folder.."/"
    local modules = file.Find(folder.."*.lua","LUA")
    for _, plugin in ipairs(modules) do
        if noprefix then
            if SERVER then
                AddCSLuaFile(folder..plugin)
            end
            if not addonly then
                include(folder..plugin)
            end
        else
            local prefix = string.Left( plugin, string.find( plugin, "_" ) - 1 )
            if (CLIENT and (prefix=="sh" or prefix=="cl")) then
                if not addonly then
                    include(folder..plugin)
                end
            elseif (SERVER) then
                if (prefix=="sv" or prefix=="sh") and (not addonly) then
                    include(folder..plugin)
                end
                if (prefix=="sh" or prefix=="cl") then
                    AddCSLuaFile(folder..plugin)
                end
            end
        end
    end
end

ENT:LoadFolder("modules/libraries")

if SERVER then
    ---@api
    ---@param name string
    function ENT:CallClientHook(name, ...)
        self:SendMessage("client_hook", {name, ...})
    end
    ---@api
    ---@param name string
    function ENT:CallClientCommonHook(name, ...)
        self:SendMessage("client_common_hook", {name, ...})
    end
else
    ENT:OnMessage("client_hook", function(self, data, ply)
        self:CallHook(unpack(data))
    end)
    ENT:OnMessage("client_common_hook", function(self, data, ply)
        self:CallCommonHook(unpack(data))
    end)
end


ENT:LoadFolder("modules")
