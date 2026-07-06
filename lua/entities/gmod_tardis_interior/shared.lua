-- TARDIS Interior

---@class gmod_tardis_interior : gmod_door_interior
---@field BaseClass gmod_door_interior
---@field timers table<string, table>
---@field parts table<string, gmod_tardis_part>
---@field controlparts table<string, table<string, gmod_tardis_part>>?
---@field roundthings table<integer, integer>
---@field owner Player?
---@field metadata tardis_metadata
---@field exterior gmod_tardis
---@field tips tardis_tip[]
---@field idlesounds table<any, CSoundPatch>
---@field dematfailsound CSoundPatch?
---@field spacebuild_env sb_resource_environment?
---@field light_data tardis_interior_light_data?
---@field lamps_data table<string, tardis_lamp_complete>?

ENT.Base="gmod_door_interior"
ENT.TardisInterior=true
ENT.Exterior="gmod_tardis"

local class=string.sub(ENT.Folder,string.find(ENT.Folder, "/[^/]*$")+1) -- only works if in a folder

local hooks={}

-- Hook system for modules
---@api
---@param name string
---@param id string
---@param func fun(self: gmod_tardis_interior, ...)
-- >>> GENERATED hook overloads - do not edit; regen: scripts/generate-hook-types.ps1 >>>
---@overload fun(self: gmod_tardis_interior, name: "AllowInteriorPos", id: string, func: fun(self: gmod_tardis_interior, arg1: any, saved_pos: any, arg3: any, arg4: any, ...))
---@overload fun(self: gmod_tardis_interior, name: "CanChangeDestination", id: string, func: fun(self: gmod_tardis_interior, pos: Vector?, ang: Angle?, ...))
---@overload fun(self: gmod_tardis_interior, name: "CanChangeExterior", id: string, func: fun(self: gmod_tardis_interior, id: (false|string), retry: boolean?, ...))
---@overload fun(self: gmod_tardis_interior, name: "CanEnableScreens", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "CanStartControlSequence", id: string, func: fun(self: gmod_tardis_interior, arg1: string?, ...))
---@overload fun(self: gmod_tardis_interior, name: "CanToggleHandbrake", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "CanTogglePower", id: string, func: fun(self: gmod_tardis_interior, on: boolean, ...))
---@overload fun(self: gmod_tardis_interior, name: "CanToggleRedecoration", id: string, func: fun(self: gmod_tardis_interior, on: boolean, ...))
---@overload fun(self: gmod_tardis_interior, name: "CanToggleScreens", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "CanToggleShields", id: string, func: fun(self: gmod_tardis_interior, on: boolean, ...))
---@overload fun(self: gmod_tardis_interior, name: "CanTurnOffScanner", id: string, func: fun(self: gmod_tardis_interior, id: integer, ...))
---@overload fun(self: gmod_tardis_interior, name: "CanTurnOffScanners", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "CanTurnOnScanner", id: string, func: fun(self: gmod_tardis_interior, id: integer, ...))
---@overload fun(self: gmod_tardis_interior, name: "CanTurnOnScanners", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "CanUsePart", id: string, func: fun(self: gmod_tardis_interior, arg1: gmod_tardis_part, a: any, ...))
---@overload fun(self: gmod_tardis_interior, name: "CanUseTardisControl", id: string, func: fun(self: gmod_tardis_interior, control: tardis_control, ply: Player, part: gmod_tardis_part, ...))
---@overload fun(self: gmod_tardis_interior, name: "ConsoleToggled", id: string, func: fun(self: gmod_tardis_interior, on: boolean, ...))
---@overload fun(self: gmod_tardis_interior, name: "DataLoaded", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "DematFailed", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "DematFailStopped", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "DematInterrupted", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "DematStart", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "DestinationChanged", id: string, func: fun(self: gmod_tardis_interior, pos: Vector?, ang: Angle?, ...))
---@overload fun(self: gmod_tardis_interior, name: "DestinationOverride", id: string, func: fun(self: gmod_tardis_interior, pos: Vector?, ang: Angle?, ...))
---@overload fun(self: gmod_tardis_interior, name: "ExteriorChanged", id: string, func: fun(self: gmod_tardis_interior, id: (false|string), ...))
---@overload fun(self: gmod_tardis_interior, name: "FlightInterrupted", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "FlightToggled", id: string, func: fun(self: gmod_tardis_interior, on: boolean, ...))
---@overload fun(self: gmod_tardis_interior, name: "FloatToggled", id: string, func: fun(self: gmod_tardis_interior, on: boolean, ...))
---@overload fun(self: gmod_tardis_interior, name: "HadsToggled", id: string, func: fun(self: gmod_tardis_interior, on: boolean, ...))
---@overload fun(self: gmod_tardis_interior, name: "HandbrakeControlToggled", id: string, func: fun(self: gmod_tardis_interior, on: boolean, ...))
---@overload fun(self: gmod_tardis_interior, name: "HandbrakeToggled", id: string, func: fun(self: gmod_tardis_interior, on: boolean, ...))
---@overload fun(self: gmod_tardis_interior, name: "HealthWarningToggled", id: string, func: fun(self: gmod_tardis_interior, on: boolean, ...))
---@overload fun(self: gmod_tardis_interior, name: "LanguageChanged", id: string, func: fun(self: gmod_tardis_interior, langCode: any, oldLangCode: any, ...))
---@overload fun(self: gmod_tardis_interior, name: "LightStateChanged", id: string, func: fun(self: gmod_tardis_interior, state: string, ...))
---@overload fun(self: gmod_tardis_interior, name: "MatFailed", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "MatFailStopped", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "NewVersion", id: string, func: fun(self: gmod_tardis_interior, newVersion: tardis_version, newVersionStr: string, oldVersion: tardis_version, oldVersionStr: string, ...))
---@overload fun(self: gmod_tardis_interior, name: "OnHealthChange", id: string, func: fun(self: gmod_tardis_interior, new_health: number, old_health: integer, ...))
---@overload fun(self: gmod_tardis_interior, name: "OnHealthDepleted", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "OnTakeDamage", id: string, func: fun(self: gmod_tardis_interior, dmginfo: CTakeDamageInfo, ...))
---@overload fun(self: gmod_tardis_interior, name: "PartBodygroupChanged", id: string, func: fun(self: gmod_tardis_interior, ent: gmod_tardis_part, bodygroup: any, value: any, ...))
---@overload fun(self: gmod_tardis_interior, name: "PartUsed", id: string, func: fun(self: gmod_tardis_interior, arg1: gmod_tardis_part, a: any, ...))
---@overload fun(self: gmod_tardis_interior, name: "PhyslockToggled", id: string, func: fun(self: gmod_tardis_interior, on: boolean, ...))
---@overload fun(self: gmod_tardis_interior, name: "PostDrawPart", id: string, func: fun(self: gmod_tardis_interior, arg1: gmod_tardis_part, ...))
---@overload fun(self: gmod_tardis_interior, name: "PostScannerRender", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "PostScannersToggled", id: string, func: fun(self: gmod_tardis_interior, state: boolean, ...))
---@overload fun(self: gmod_tardis_interior, name: "PowerToggled", id: string, func: fun(self: gmod_tardis_interior, on: boolean, ...))
---@overload fun(self: gmod_tardis_interior, name: "PreDrawPart", id: string, func: fun(self: gmod_tardis_interior, arg1: gmod_tardis_part, ...))
---@overload fun(self: gmod_tardis_interior, name: "PreMatStart", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "PreScannerRender", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "RandomizeTips", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "RepairCancelled", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "ScannersToggled", id: string, func: fun(self: gmod_tardis_interior, state: boolean, ...))
---@overload fun(self: gmod_tardis_interior, name: "ScannerToggled", id: string, func: fun(self: gmod_tardis_interior, k: any, on: boolean, ...))
---@overload fun(self: gmod_tardis_interior, name: "ScreensToggled", id: string, func: fun(self: gmod_tardis_interior, on: boolean, ...))
---@overload fun(self: gmod_tardis_interior, name: "SettingChanged", id: string, func: fun(self: gmod_tardis_interior, id: string, value: any, old_value: any, ply: Player, ...))
---@overload fun(self: gmod_tardis_interior, name: "SetupMMenuButtons", id: string, func: fun(self: gmod_tardis_interior, screen: TardisScreen, frame: Panel, layout: HexagonalLayout, ...))
---@overload fun(self: gmod_tardis_interior, name: "SetupVirtualConsole", id: string, func: fun(self: gmod_tardis_interior, screen: TardisScreen, frame: tardis_screen_frame, layout: HexagonalLayout, ...))
---@overload fun(self: gmod_tardis_interior, name: "ShieldsToggled", id: string, func: fun(self: gmod_tardis_interior, on: boolean, ...))
---@overload fun(self: gmod_tardis_interior, name: "ShouldDraw", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "ShouldDrawBlackScreen", id: string, func: fun(self: gmod_tardis_interior, arg1: ("pop"|integer|string), ...))
---@overload fun(self: gmod_tardis_interior, name: "ShouldDrawLight", id: string, func: fun(self: gmod_tardis_interior, arg1: any, lt: tardis_interior_light_state_complete, ...))
---@overload fun(self: gmod_tardis_interior, name: "ShouldDrawPart", id: string, func: fun(self: gmod_tardis_interior, arg1: gmod_tardis_part, ...))
---@overload fun(self: gmod_tardis_interior, name: "ShouldDrawScanner", id: string, func: fun(self: gmod_tardis_interior, k: any, ...))
---@overload fun(self: gmod_tardis_interior, name: "ShouldDrawScanners", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "ShouldDrawTips", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "ShouldForceDemat", id: string, func: fun(self: gmod_tardis_interior, pos: Vector?, ang: Angle?, ...))
---@overload fun(self: gmod_tardis_interior, name: "ShouldNotDrawScreen", id: string, func: fun(self: gmod_tardis_interior, arg1: ("pop"|integer|string), ...))
---@overload fun(self: gmod_tardis_interior, name: "ShouldNotRenderPortal", id: string, func: fun(self: gmod_tardis_interior, arg1: gmod_tardis, portal: any, exit: any, origin: any, ...))
---@overload fun(self: gmod_tardis_interior, name: "ShouldRegenShields", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "ShouldTakeDamage", id: string, func: fun(self: gmod_tardis_interior, dmginfo: CTakeDamageInfo, ...))
---@overload fun(self: gmod_tardis_interior, name: "ShouldThink", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "ShouldTurnOffCloisters", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "ShouldTurnOffFlightSound", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "ShouldTurnOnCloisters", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "ShouldWarningBeEnabled", id: string, func: fun(self: gmod_tardis_interior, ...))
---@overload fun(self: gmod_tardis_interior, name: "TardisControlUsed", id: string, func: fun(self: gmod_tardis_interior, control_id: string, ply: Player, part: gmod_tardis_part, ...))
---@overload fun(self: gmod_tardis_interior, name: "TeleportControlToggled", id: string, func: fun(self: gmod_tardis_interior, on: boolean, ...))
---@overload fun(self: gmod_tardis_interior, name: "WarningToggled", id: string, func: fun(self: gmod_tardis_interior, on: boolean, ...))
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

function ENT:ListHooks()
    print("[Interior]"..(SERVER and "[Server]" or "[Client]"))
    for h in pairs(hooks) do
        print(h)
    end
end

---@api
---@param name string
function ENT:CallCommonHook(name, ...)
    return self.exterior:CallCommonHook(name, ...)
end

---@api
---@param name string
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
    if self.metadata and self.metadata.Interior and self.metadata.Interior.CustomHooks then
        for _,body in pairs(self.metadata.Interior.CustomHooks) do
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
            if body and istable(body) and body.inthooks and body.inthooks[name] then
                a,b,c,d,e,f = body.func(self.exterior, self, ...)
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
    ---@param ... any
    function ENT:CallClientHook(name, ...)
        self:SendMessage("client_hook", {name, ...})
    end
    ---@api
    ---@param name string
    ---@param ... any
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
