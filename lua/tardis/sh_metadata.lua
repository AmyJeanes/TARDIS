-- Interiors

CreateConVar("tardis2_selected_interior", "", {FCVAR_REPLICATED}, "TARDIS - selected interior to spawn when not using the spawnmenu")

---@class tardis_metadata
---@field Interior tardis_interior_metadata
---@field Exterior tardis_exterior_metadata
---@field ExteriorOriginal tardis_exterior_metadata?
---@field ID string
---@field Name string?
---@field Base string|boolean
---@field BaseMerged boolean?
---@field Templates table<string, tardis_interior_template|false>?
---@field TemplatesMergeOrder string[]?
---@field Timings tardis_timings
---@field Versions tardis_versions?
---@field IsVersionOf string?
---@field CustomHooks table<string, tardis_custom_hook>?
---@field CustomControls table<string, tardis_custom_control>?
---@field CustomSettings table<string, tardis_custom_setting>?
---@field SyncExteriorBodygroupToDoors boolean?
---@field EnableClassicDoors boolean?
---@field Hidden boolean?

---@class tardis_interior_metadata
---@field Model string?
---@field ExitDistance number?
---@field Size tardis_box
---@field Portal tardis_interior_portal
---@field Fallback tardis_interior_fallback
---@field Sounds tardis_interior_sound_metadata
---@field IdleSound tardis_sound_entry[]?
---@field Tips table[]?
---@field CustomTips tardis_custom_tip[]?
---@field PartTips table<string, tardis_part_tip>?
---@field TipSettings tardis_tip_settings
---@field LightOverride tardis_light_override
---@field Light tardis_interior_light?
---@field Lights table<string, tardis_interior_light_state>?
---@field ScreensEnabled boolean?
---@field UseFullName boolean
---@field Screens tardis_screen[]?
---@field Parts table<string, table|false>
---@field Controls table<string, string>?
---@field TextureSets table<string, tardis_texture_set>
---@field CustomPortals table<string, doors_custom_portal>?
---@field FalseWorlds table<string, worldportals_false_world>?
---@field FalseWorldWindows table<string, tardis_false_world_window>?
---@field ExitBox tardis_box?
---@field UI_Theme string?
---@field MatProxy tardis_matproxy?
---@field FloorLevel number?
---@field IntDoorAnimationTime number?
---@field CustomHooks { [1]: string|table<string, boolean>, [2]: function }[]?
---@field RequireLightOverride boolean?
---@field RequireHighModelDetail boolean?
---@field BreakdownEffectPos Vector?
---@field Sequences string?
---@field PortalNoCollide boolean?
---@field RoundThings Vector[]?
---@field Scanners tardis_scanner[]?
---@field Lamps tardis_lamp[]?
---@field Seats tardis_seat[]?

---@class tardis_exterior_metadata
---@field Model string?
---@field Mass number?
---@field ExcludedSkins integer[]?
---@field WinterSkins integer[]?
---@field DoorAnimationTime number
---@field ScannerOffset Vector
---@field PhaseMaterial string?
---@field Portal tardis_exterior_portal
---@field Fallback tardis_exterior_fallback
---@field Light tardis_exterior_light
---@field ProjectedLight tardis_projected_light
---@field Sounds tardis_exterior_sound_metadata
---@field Chameleon tardis_chameleon
---@field LockedDoor tardis_locked_door
---@field Parts table<string, table|false>
---@field Controls table<string, string>?
---@field Teleport tardis_teleport
---@field TextureSets table<string, tardis_texture_set>
---@field CustomHooks { [1]: string|table<string, boolean>, [2]: function }[]?
---@field UseLegacyDoors boolean?
---@field PortalNoCollide boolean?
---@field ID string?
---@field Base string|boolean|nil
---@field Name string?
---@field Category string?

---@class tardis_interior_portal
---@field pos Vector
---@field ang Angle
---@field width number
---@field height number
---@field thickness number?
---@field inverted boolean?

---@class tardis_exterior_portal
---@field pos Vector
---@field ang Angle
---@field width number
---@field height number
---@field model string?
---@field model_offset tardis_model_offset
---@field thickness number?
---@field inverted boolean?

---@class tardis_box
---@field Min Vector
---@field Max Vector

---@class tardis_interior_fallback
---@field pos Vector
---@field ang Angle

---@class tardis_exterior_fallback
---@field pos Vector
---@field ang Angle

---@class tardis_exterior_light
---@field enabled boolean?
---@field pos Vector?
---@field color Color?
---@field dynamicpos Vector?
---@field dynamicbrightness number?
---@field dynamicsize number

---@class tardis_interior_light_state
---@field enabled boolean?
---@field color Color?
---@field pos Vector?
---@field brightness number?
---@field falloff number?
---@field warn_color Color?
---@field warn_pos Vector?
---@field warn_brightness number?
---@field warn_falloff number?
---@field nopower boolean?
---@field off_color Color?
---@field off_pos Vector?
---@field off_brightness number?
---@field off_falloff number?
---@field off_warn_color Color?
---@field off_warn_pos Vector?
---@field off_warn_brightness number?
---@field off_warn_falloff number?
---@field states table<string, tardis_interior_light_state>?

---@class tardis_interior_light : tardis_interior_light_state
---@field NoLO tardis_interior_light_state?
---@field NoExtra tardis_interior_light_state?
---@field NoExtraNoLO tardis_interior_light_state?

---@class tardis_light_override
---@field basebrightness number
---@field nopowerbrightness number
---@field transitionspeed number
---@field basebrightnessRGB Vector|number[]|nil

---@class tardis_projected_light
---@field brightness number?
---@field farz number?
---@field offset Vector?
---@field texture string?
---@field baselightmix number
---@field color Color?
---@field warncolor Color?
---@field vertfov number?
---@field horizfov number?

---@class tardis_chameleon
---@field AnimTime number
---@field Enable boolean?

---@class tardis_locked_door
---@field AnimPos number
---@field AnimTime number

---@class tardis_tip_settings
---@field style string?
---@field view_range_min number
---@field view_range_max number
---@field TextOverrides table<string, string>?

---@class tardis_timings
---@field DematAbortState number
---@field DematFail number
---@field MatFail number
---@field TakeOffState number
---@field ParkingState number

---@class tardis_teleport
---@field SequenceSpeed number|{ Demat: number, Mat: number }
---@field SequenceSpeedWarning number|{ Demat: number, Mat: number }
---@field SequenceSpeedFast number|{ Demat: number, Mat: number }
---@field SequenceSpeedHads number|{ Demat: number, Mat: number }
---@field SequenceSpeedWarnFast number|{ Demat: number, Mat: number }
---@field DematInterruptSpeed number
---@field PrematDelayFast number
---@field PrematDelay number
---@field DematSequence number[]
---@field MatSequence number[]
---@field HadsDematSequence number[]
---@field DematSequenceSaved number[]?
---@field MatSequenceSaved number[]?
---@field HadsDematSequenceSaved number[]?
---@field DematSequenceDelays number[]?
---@field DematFastSequenceDelays number[]?
---@field DematHadsSequenceDelays number[]?
---@field MatSequenceDelays number[]?
---@field MatFastSequenceDelays number[]?

---@class tardis_interior_sound_metadata
---@field Damage tardis_sound_damage
---@field Teleport tardis_interior_sound_teleport
---@field Power tardis_sound_power
---@field SequenceOK string?
---@field SequenceFail string?
---@field Cloister string?
---@field Lock string?
---@field Unlock string?
---@field Idle tardis_sound_entry[]?
---@field Hum string?

---@class tardis_exterior_sound_metadata
---@field Teleport tardis_exterior_sound_teleport
---@field Door tardis_sound_door
---@field RepairFinish string?
---@field RepairLoop string?
---@field Lock string?
---@field Unlock string?
---@field Spawn string?
---@field Delete string?
---@field FlightLoop string?
---@field FlightLoopDamaged string?
---@field FlightLoopBroken string?
---@field FlightLand string?
---@field FlightFall string?
---@field BrokenFlightTurn string[]?
---@field BrokenFlightExplosion string?
---@field BrokenFlightEnable string?
---@field BrokenFlightDisable string?
---@field Cloak string?
---@field CloakOff string?
---@field Chameleon string?
---@field Hum tardis_sound_entry?

---@class tardis_sound_damage
---@field Crash string?
---@field BigCrash string?
---@field Explosion string?
---@field Death string?
---@field Artron string?

---@class tardis_sound_door
---@field enabled boolean?
---@field open string?
---@field close string?
---@field locked string?

---@class tardis_sound_power
---@field On string?
---@field Off string?

---@class tardis_interior_sound_teleport
---@field demat string?
---@field demat_damaged string?
---@field demat_fast string?
---@field demat_hads string?
---@field demat_fail string?
---@field demat_fail_loop string?
---@field demat_fail_loop_stop string?
---@field mat string?
---@field mat_damaged string?
---@field mat_fail string?
---@field mat_fast string?
---@field mat_damaged_fast string?
---@field fullflight string?
---@field fullflight_damaged string?
---@field interrupt string?

---@class tardis_exterior_sound_teleport
---@field demat string?
---@field demat_damaged string?
---@field demat_fast string?
---@field demat_hads string?
---@field demat_fail string?
---@field demat_fail_loop string?
---@field demat_fail_loop_stop string?
---@field mat string?
---@field mat_damaged string?
---@field mat_fail string?
---@field mat_fast string?
---@field mat_damaged_fast string?
---@field fullflight string?
---@field fullflight_damaged string?
---@field interrupt string?

---@class tardis_version_entry
---@field id string
---@field name string?
---@field classic_doors_id string?
---@field double_doors_id string?

---@class tardis_versions
---@field main tardis_version_entry?
---@field other tardis_version_entry[]?
---@field randomize boolean?
---@field custom table<string, table>?
---@field list_all table?
---@field list_original table?
---@field allow_custom boolean?
---@field randomize_custom boolean?

---@class tardis_model_offset
---@field pos Vector
---@field ang Angle

---@class tardis_sound_entry
---@field path string
---@field volume number?

---@class tardis_matproxy
---@field Color1 Color
---@field Color2 Color
---@field Color3 Color
---@field VortexColor Color?

---@class tardis_seat
---@field pos Vector
---@field ang Angle

---@class tardis_screen
---@field pos Vector
---@field ang Angle
---@field width number
---@field height number
---@field gui_rows number?
---@field power_off_black boolean?

---@class tardis_scanner
---@field part string?
---@field mat string
---@field width number
---@field height number
---@field ang Angle
---@field fov number

---@class tardis_custom_tip
---@field pos Vector
---@field right boolean?
---@field down boolean?
---@field part string?

---@class tardis_part_tip
---@field pos Vector?
---@field right boolean?
---@field down boolean?

---@class tardis_lamp
---@field pos Vector
---@field color Color
---@field texture string?
---@field fov number?
---@field distance number?
---@field brightness number?
---@field ang Angle?
---@field shadows boolean?
---@field states table<string, tardis_lamp>?
---@field warn tardis_lamp?
---@field off tardis_lamp?
---@field off_warn tardis_lamp?

---@class tardis_interior_template
---@field override boolean?
---@field condition function?

---@class tardis_custom_control
---@field int_func function
---@field power_independent boolean?
---@field screen_button boolean?
---@field tip_text string?

---@class tardis_custom_setting
---@field text string?
---@field value_type string?
---@field value any
---@field options table<string, string>?

---@class tardis_custom_hook
---@field inthooks table<string, boolean>?
---@field exthooks table<string, boolean>?
---@field func function

---@class tardis_texture_set
---@field prefix string?
---@field base string?
---@field [integer] { [1]: string, [2]: integer, [3]: string }

---@class tardis_false_world_window : doors_portal_side
---@field falseworld string?

function TARDIS:LoadInteriors()
    if TARDIS.InteriorsLoading then return end

    ---@type table<string, tardis_metadata>
    TARDIS.Metadata = {}
    ---@type table<string, tardis_metadata>
    TARDIS.MetadataRaw = {}
    ---@type table<string, tardis_metadata>
    TARDIS.MetadataTemplates = {}
    ---@type table<string, tardis_versions>
    TARDIS.MetadataVersions = {}
    ---@type table<string, table<string, table>>
    TARDIS.MetadataCustomVersions = {}

    ---@type table<string, tardis_exterior_metadata>
    TARDIS.ExteriorsMetadata = {}
    ---@type table<string, table>
    TARDIS.ExteriorsMetadataRaw = {}
    TARDIS.ExteriorCategories = {}

    TARDIS.ImportedExteriors = {}

    TARDIS.IntCustomSettings = {}
    TARDIS.IntUpdatesPerTemplate = {}

    TARDIS.InteriorsLoading = true
    TARDIS:LoadFolder("metadata")
    TARDIS:LoadFolder("interiors/templates", nil, true)
    TARDIS:LoadFolder("interiors", nil, true)
    TARDIS:LoadFolder("interiors/exteriors", nil, true)
    TARDIS:LoadFolder("interiors/versions", nil, true)
    TARDIS.InteriorsLoading = nil

    hook.Call("TARDIS_MetadataLoaded", GAMEMODE)
    hook.Call("TARDIS_PostMetadataLoaded", GAMEMODE)
end

function TARDIS:PreMergeExteriorMetadata(ext_m)
    if ext_m and ext_m.Teleport then
        if ext_m.Teleport.HadsDematSequence then
            ext_m.Teleport.HadsDematSequenceSaved = table.Copy(ext_m.Teleport.HadsDematSequence)
        end

        if ext_m.Teleport.DematSequence then
            ext_m.Teleport.DematSequenceSaved = table.Copy(ext_m.Teleport.DematSequence)
        end

        if ext_m.Teleport.MatSequence then
            ext_m.Teleport.MatSequenceSaved = table.Copy(ext_m.Teleport.MatSequence)
        end
    end
end

function TARDIS:PostMergeExteriorMetadata(ext_m)
    if ext_m and ext_m.Teleport then
        if ext_m.Teleport.DematSequenceSaved then
            ext_m.Teleport.DematSequence = ext_m.Teleport.DematSequenceSaved
            ext_m.Teleport.DematSequenceSaved = nil
        end

        if ext_m.Teleport.MatSequenceSaved then
            ext_m.Teleport.MatSequence = ext_m.Teleport.MatSequenceSaved
            ext_m.Teleport.MatSequenceSaved = nil
        end

        if ext_m.Teleport.HadsDematSequenceSaved then
            ext_m.Teleport.HadsDematSequence = ext_m.Teleport.HadsDematSequenceSaved
            ext_m.Teleport.HadsDematSequenceSaved = nil
        end
    end
end

---@return tardis_metadata
function TARDIS:MergeMetadata(base, t)
    ---@type tardis_metadata
    local copy=table.Copy(base) -- table.Copy returns a bare table, dropping the class
    self:PreMergeExteriorMetadata(t.Exterior)
    table.Merge(copy,t)
    self:PostMergeExteriorMetadata(copy.Exterior)
    return copy
end

function TARDIS:ClearMetadata(id)
    self.Metadata[id] = nil
    for k,v in pairs(self.MetadataRaw) do
        if v.Base == id then
            self:ClearMetadata(k)
        end
    end
end

function TARDIS:ValidateMetadata(t)
    if t.Interior then
        if t.Interior.Size and (t.Interior.Size.Min or t.Interior.Size.Max) then
            if not t.Interior.Size.Min then
                return "Interior.Size.Min not set"
            end

            if not t.Interior.Size.Max then
                return "Interior.Size.Max not set"
            end

            if t.Interior.Size.Min.x >= t.Interior.Size.Max.x then
                return "Interior.Size.Min.x >= Maxs.x"
            end

            if t.Interior.Size.Min.y >= t.Interior.Size.Max.y then
                return "Interior.Size.Min.y >= Maxs.y"
            end

            if t.Interior.Size.Min.z >= t.Interior.Size.Max.z then
                return "Interior.Size.Min.z >= Maxs.z"
            end
        end

        if t.Interior.ExitBox and (t.Interior.ExitBox.Min or t.Interior.ExitBox.Max) then
            if not t.Interior.ExitBox.Min then
                return "Interior.ExitBox.Min not set"
            end

            if not t.Interior.ExitBox.Max then
                return "Interior.ExitBox.Max not set"
            end

            if t.Interior.ExitDistance then
                return "Interior.ExitDistance cannot be used with Interior.ExitBox"
            end

            if t.Interior.ExitBox.Min.x >= t.Interior.ExitBox.Max.x then
                return "Interior.ExitBox.Min.x >= Maxs.x"
            end

            if t.Interior.ExitBox.Min.y >= t.Interior.ExitBox.Max.y then
                return "Interior.ExitBox.Min.y >= Maxs.y"
            end

            if t.Interior.ExitBox.Min.z >= t.Interior.ExitBox.Max.z then
                return "Interior.ExitBox.Min.z >= Maxs.z"
            end
        end
    end
end

function TARDIS:SetupFalseWorlds(int_id)
    if not (wp and wp.addfalseworld) then return end

    local t = self.MetadataRaw[int_id]
    if not (t and t.Interior) then return end

    local locals = t.Interior.FalseWorlds
    if locals then
        for k, world in pairs(locals) do
            local fw_id = "tardis_" .. tostring(int_id) .. "_" .. tostring(k)
            local copy = table.Copy(world)
            copy.id = fw_id
            wp.addfalseworld(copy)
        end
    end

    if t.Interior.FalseWorldWindows then
        for _, entry in pairs(t.Interior.FalseWorldWindows) do
            local name = entry.falseworld
            if name and locals and locals[name] then
                entry.falseworld = "tardis_" .. tostring(int_id) .. "_" .. tostring(name)
            end
        end
    end
end

-- wp may not have loaded yet during interior metadata load, so setup all false worlds after world init
hook.Add("InitPostEntity", "TARDIS_FalseWorlds", function()
    if not (wp and wp.addfalseworld) then return end
    for int_id in pairs(TARDIS.MetadataRaw) do
        TARDIS:SetupFalseWorlds(int_id)
    end
end)

-- Functionally identical to T = {} but gives proper type checking for interiors
---@api
---@return tardis_metadata
function TARDIS:NewInterior()
    return {}
end

---@api
---@param interior table
function TARDIS:AddInterior(interior)
    interior = table.Copy(interior)

    local id = interior.ID

    self.MetadataRaw[id] = interior

    local error = self:ValidateMetadata(interior)
    if error then
        ErrorNoHalt("TARDIS: Error in interior '"..id.."' metadata: "..error.."\n")
        return
    end

    self:ClearMetadata(id)

    -- setting up the stuff we need before spawning, e.g. in spawnmenu
    self:SetupVersions(id)
    self:AddSpawnmenuInterior(id)
    self:SetupTemplateUpdates(id)
    self:SetupCustomSettings(id)
    self:SetupFalseWorlds(id)

    if self.ImportedExteriors and self.ImportedExteriors[id] then
        self:ImportExterior(id, self.ImportedExteriors[id])
    end
end

function TARDIS:SetupMetadata(id)
    if self.Metadata[id] then return end
    ---@type table?
    local t = self.MetadataRaw[id]
    if not t then return end

    local base = t.Base

    if base == true then
        self.Metadata[id] = t
        return
    end

    self:SetupMetadata(base)

    local m_base = self.Metadata[base]
    if not m_base then return end

    self.Metadata[id] = self:MergeMetadata(m_base, t)
    self.Metadata[id].Versions = nil -- we don't want those mixing up anywhere
end

---@return tardis_metadata
function TARDIS:CreateInteriorMetadata(id, ent)
    if ent then
        if ent.TardisExterior and ent.interior and ent.interior.metadata then
            if ent.interior.templates then
                ent.templates = ent.interior.templates
            end
            return ent.interior.metadata
        end
        if ent.TardisInterior and ent.exterior and ent.exterior.metadata then
            if ent.exterior.templates then
                ent.templates = ent.exterior.templates
            end
            return ent.exterior.metadata
        end
    end

    if id == nil then
        local cv_id = GetConVar("tardis2_selected_interior"):GetString()
        if cv_id ~= "" then
            id = cv_id
        end
    end

    self:SetupMetadata(id)

    local raw = self.Metadata[id]
    if raw == nil or raw.BaseMerged ~= true then
        return self:CreateInteriorMetadata("default", ent)
    end

    local metadata = TARDIS:CopyTable(raw)

    metadata = TARDIS:MergeTemplates(metadata, ent)

    metadata.Interior.TextureSets = TARDIS:GetMergedTextureSets(metadata.Interior.TextureSets)
    metadata.Exterior.TextureSets = TARDIS:GetMergedTextureSets(metadata.Exterior.TextureSets)

    local lightOverridebaseBrightnessRGB = metadata.Interior.LightOverride.basebrightnessRGB
    if lightOverridebaseBrightnessRGB and type(lightOverridebaseBrightnessRGB) == "table" then
        metadata.Interior.LightOverride.basebrightnessRGB = Vector(lightOverridebaseBrightnessRGB[1], lightOverridebaseBrightnessRGB[2], lightOverridebaseBrightnessRGB[3])
        print("[TARDIS] WARNING: Interior '"..id.."' metadata: Exterior.LightOverride.basebrightnessRGB should be a Vector not a table\n")
    end

    return metadata
end

---@api
function TARDIS:GetInteriors()
    return self.MetadataRaw
end

---@api
---@param id string
---@return tardis_metadata?
function TARDIS:GetInterior(id)
    return self.Metadata[id] or self.MetadataRaw[id]
end

---@api
---@param metadata tardis_metadata
---@return string
function TARDIS:GetTARDISName(metadata)
    local namekey = metadata.Name
    if not namekey then return TARDIS:GetPhrase("Common.TARDIS") end
    local name = TARDIS:GetPhrase(namekey)
    if metadata.Interior and metadata.Interior.UseFullName == false then return name end
    return TARDIS:GetPhrase("Common.TARDIS") .. " (" .. name .. ")"
end

TARDIS:LoadInteriors()
