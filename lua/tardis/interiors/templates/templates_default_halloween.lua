local HALLOWEEN_STATE_DISABLED = 0
local HALLOWEEN_STATE_KNOCKING = 1
local HALLOWEEN_STATE_CORRIDOR_CHECK = 2
local HALLOWEEN_STATE_CORRIDOR_SOUNDS = 3
local HALLOWEEN_STATE_WARNING = 4
local HALLOWEEN_STATE_COMPLETE = 5

local HALLOWEEN_TIME_BEFORE_FIRST_KNOCK_MIN = 20
local HALLOWEEN_TIME_BEFORE_FIRST_KNOCK_MAX = 30

local HALLOWEEN_TIME_BETWEEN_KNOCKS_MIN = 10
local HALLOWEEN_TIME_BETWEEN_KNOCKS_MAX = 20

local HALLOWEEN_DOOR_OPENS_BEFORE_CORRIDOR_CHECK = 2

local HALLOWEEN_TIME_BEFORE_CORRIDOR_SOUNDS_MIN = 10
local HALLOWEEN_TIME_BEFORE_CORRIDOR_SOUNDS_MAX = 15

local HALLOWEEN_TIME_RETRY_CORRIDOR_CHECK_MIN = 5
local HALLOWEEN_TIME_RETRY_CORRIDOR_CHECK_MAX = 10

local HALLOWEEN_USE_LOOPED_SOUND_CHANCE = 0

local HALLOWEEN_TIME_BETWEEN_NON_LOOPED_SOUNDS_MIN = 2
local HALLOWEEN_TIME_BETWEEN_NON_LOOPED_SOUNDS_MAX = 5

local HALLOWEEN_LOOPED_SOUNDS = {
    {"ambient/voices/crying_loop1.wav", 75},
    {"ambient/gas/steam_loop1.wav", 65},
}

local HALLOWEEN_NON_LOOPED_SOUNDS = {
    {"vehicles/crane/crane_creak3.wav", 75},
    {"vehicles/crane/crane_creak4.wav", 75},
    {"physics/metal/metal_large_debris1.wav", 80},
    {"ambient/materials/creaking.wav", 80},
    {"ambient/materials/rustypipes1.wav", 90},
    {"ambient/materials/rustypipes2.wav", 90},
    {"ambient/materials/rustypipes3.wav", 80},
    {"ambient/materials/shipgroan1.wav", 85},
    {"ambient/materials/shipgroan2.wav", 80},
    {"ambient/materials/shipgroan3.wav", 75},
    {"ambient/materials/shipgroan4.wav", 80},
}

local HALLOWEEN_DEBUG = false
local HALLOWEEN_DEBUG_TIMINGS = false
if HALLOWEEN_DEBUG_TIMINGS then
    HALLOWEEN_TIME_BEFORE_FIRST_KNOCK_MIN = 1
    HALLOWEEN_TIME_BEFORE_FIRST_KNOCK_MAX = 1

    HALLOWEEN_TIME_BETWEEN_KNOCKS_MIN = 1
    HALLOWEEN_TIME_BETWEEN_KNOCKS_MAX = 1

    HALLOWEEN_TIME_BEFORE_CORRIDOR_SOUNDS_MIN = 1
    HALLOWEEN_TIME_BEFORE_CORRIDOR_SOUNDS_MAX = 1

    HALLOWEEN_TIME_RETRY_CORRIDOR_CHECK_MIN = 1
    HALLOWEEN_TIME_RETRY_CORRIDOR_CHECK_MAX = 1

    HALLOWEEN_TIME_BETWEEN_NON_LOOPED_SOUNDS_MIN = 0
    HALLOWEEN_TIME_BETWEEN_NON_LOOPED_SOUNDS_MAX = 0
end

local function debug_print(...)
    if HALLOWEEN_DEBUG then
        print("Halloween event:", ...)
    end
end

local function can_be_outside(ext)
    local isteleporting = ext:IsTeleporting()
    local invortex = ext:IsInVortex()
    local speed = ext:GetVelocity():Length()
    local dooropen = ext:DoorOpen()
    local anythirdperson = false
    local anyoccupants = false
    for k,v in pairs(ext.occupants) do
        if k:GetTardisData("thirdperson") or k:GetTardisData("destination") then
            anythirdperson = true
            anyoccupants = true
            break
        else
            anyoccupants = true
        end
    end
    if anyoccupants and not isteleporting and not invortex and speed < 90 and not dooropen and not anythirdperson then
        return true
    else
        return false
    end
end

TARDIS:AddInteriorTemplate("default_halloween", {
    Interior = {
        Parts = {
            pumpkin = {
                invisible = true,
                pos = Vector(-281.936279, -0.611328, 93.487305)
            }
        }
    },
    CustomHooks = {
        halloween_init = {
            inthooks = {
                ["Initialize"] = SERVER,
            },
            func = function(ext,int,id)
                if IsValid(int) then
                    -- Disabled -> Knocking
                    ext:SetData("halloween-state", HALLOWEEN_STATE_KNOCKING, true)
                    ext:SetData("halloween-nextknock", CurTime() + math.random(HALLOWEEN_TIME_BEFORE_FIRST_KNOCK_MIN, HALLOWEEN_TIME_BEFORE_FIRST_KNOCK_MAX))
                    ext:SetData("halloween-knocksdooropens", 0)
                else
                    ext:SetData("halloween-state", HALLOWEEN_STATE_DISABLED, true)
                end
            end,
        },
        halloween_toggledoorreal = {
            exthooks = {
                ["ToggleDoorReal"] = SERVER,
            },
            func = function(ext,int,open)
                local state = ext:GetData("halloween-state", HALLOWEEN_STATE_DISABLED)
                if state ~= HALLOWEEN_STATE_KNOCKING then return end
                local hasoccupants = false
                for k,v in pairs(ext.occupants) do
                    hasoccupants = true
                    break
                end
                local canbeoutside = can_be_outside(ext)
                local knocked = ext:GetData("halloween-knocked", false)
                if open and hasoccupants and knocked and canbeoutside then
                    debug_print("Door opened after knocking")
                    ext:SendMessage("halloween-stopknock", {})
                    ext:SetData("halloween-knocked", false)
                    local knocksdooropens = ext:GetData("halloween-knocksdooropens", 0)
                    knocksdooropens = knocksdooropens + 1
                    if knocksdooropens >= HALLOWEEN_DOOR_OPENS_BEFORE_CORRIDOR_CHECK then
                        debug_print("Entered TARDIS interior")
                        ext:SendMessage("halloween-entered", {})
                        if IsValid(int) and IsValid(int:GetPart("default_corridors")) then
                            -- Knocking -> Corridor Check
                            debug_print("Starting corridor checks")
                            ext:SetData("halloween-state", HALLOWEEN_STATE_CORRIDOR_CHECK, true)
                            ext:SetData("halloween-nextcorridorcheck", CurTime() + math.random(HALLOWEEN_TIME_BEFORE_CORRIDOR_SOUNDS_MIN, HALLOWEEN_TIME_BEFORE_CORRIDOR_SOUNDS_MAX))
                        else
                            debug_print("No corridors part, disabling event")
                            -- Knocking -> Disabled
                            ext:SetData("halloween-state", HALLOWEEN_STATE_DISABLED, true)
                        end
                    else
                        debug_print("Door has been opened", knocksdooropens, "times")
                        ext:SetData("halloween-knocksdooropens", knocksdooropens)
                    end
                end
            end,
        },
        halloween_think = {
            inthooks = {
                ["Think"] = SERVER,
            },
            func = function(ext,int,id)
                local state = ext:GetData("halloween-state", HALLOWEEN_STATE_DISABLED)
                local nextknock = ext:GetData("halloween-nextknock", 0)
                if state == HALLOWEEN_STATE_KNOCKING and CurTime() - nextknock > 0 then
                    if can_be_outside(ext) then
                        debug_print("Knocked on door")
                        local snd = math.random(1,6)
                        ext:SendMessage("halloween-knock", {snd})
                        if not ext:GetData("halloween-knocked") then
                            ext:SetData("halloween-knocked", true)
                        end
                    end
                    ext:SetData("halloween-nextknock", CurTime() + math.random(HALLOWEEN_TIME_BETWEEN_KNOCKS_MIN, HALLOWEEN_TIME_BETWEEN_KNOCKS_MAX))
                elseif state == HALLOWEEN_STATE_CORRIDOR_CHECK then
                    local nextcorridorcheck = ext:GetData("halloween-nextcorridorcheck", 0)
                    if CurTime() - nextcorridorcheck > 0 then
                        local mins = int:LocalToWorld(Vector(-506.809, -1200.763, 32.308))
                        local maxs = int:LocalToWorld(Vector(854.176, -669.703, 223.044))

                        local occupantsinbox = false
                        for k,v in pairs(ext.occupants) do
                            local pos = k:GetPos()
                            if pos.x >= mins.x and pos.x <= maxs.x
                            and pos.y >= mins.y and pos.y <= maxs.y
                            and pos.z >= mins.z and pos.z <= maxs.z then
                                occupantsinbox = true
                                break
                            end
                        end

                        local corridor_doors_open = false
                        local corridor_doors_1 = int:GetPart("default_corridor_doors_1")
                        local corridor_doors_2 = int:GetPart("default_corridor_doors_2")
                        if IsValid(corridor_doors_1) and corridor_doors_1:GetOn() then
                            corridor_doors_open = true
                        end
                        if IsValid(corridor_doors_2) and corridor_doors_2:GetOn() then
                            corridor_doors_open = true
                        end

                        if occupantsinbox or corridor_doors_open then
                            debug_print("Occupants detected in corridor area or corridor doors open, retrying corridor check later")
                            ext:SetData("halloween-nextcorridorcheck", CurTime() + math.random(HALLOWEEN_TIME_RETRY_CORRIDOR_CHECK_MIN, HALLOWEEN_TIME_RETRY_CORRIDOR_CHECK_MAX))
                        else
                            -- Corridor Check -> Sounds
                            debug_print("No occupants in corridor area, starting corridor sounds")
                            if math.random() < HALLOWEEN_USE_LOOPED_SOUND_CHANCE then
                                debug_print("Using looped corridor sound")
                                ext:SetData("halloween-loopsound", HALLOWEEN_LOOPED_SOUNDS[math.random(1,#HALLOWEEN_LOOPED_SOUNDS)], true)
                            else
                                debug_print("Using non-looped corridor sounds")
                            end
                            ext:SetData("halloween-state", HALLOWEEN_STATE_CORRIDOR_SOUNDS, true)
                        end
                    end
                elseif state == HALLOWEEN_STATE_CORRIDOR_SOUNDS then
                    local loopsound = ext:GetData("halloween-loopsound", nil)
                    if not loopsound then
                        local nextsoundtime = ext:GetData("halloween-nextcorridorsound", 0)
                        if CurTime() - nextsoundtime > 0 then
                            local sound = assert(HALLOWEEN_NON_LOOPED_SOUNDS[math.random(1,#HALLOWEEN_NON_LOOPED_SOUNDS)])
                            local soundduration = SoundDuration(sound[1])
                            debug_print("Playing non-looped corridor sound: " .. sound[1])
                            ext:SendMessage("halloween-corridorsound", {sound[1], sound[2]})
                            ext:SetData("halloween-nextcorridorsound", CurTime() + soundduration + math.random(HALLOWEEN_TIME_BETWEEN_NON_LOOPED_SOUNDS_MIN, HALLOWEEN_TIME_BETWEEN_NON_LOOPED_SOUNDS_MAX))
                        end
                    end
                    local soundswarning = ext:GetData("halloween-soundswarning", 0)
                    if soundswarning > 0 and CurTime() - soundswarning > 0 then
                        -- Corridor Sounds -> Warning
                        ext:SetData("halloween-state", HALLOWEEN_STATE_WARNING, true)
                        ext:UpdateWarning()
                    end
                elseif state == HALLOWEEN_STATE_WARNING then
                    local warningdoormoving = ext:GetData("halloween-warningdoormoving", 0)
                    if warningdoormoving > 0 then
                        if CurTime() - warningdoormoving > 0 then
                            debug_print("Warning door movement finished")
                            local pumpkin = int:GetPart("pumpkin")
                            if IsValid(pumpkin) then
                                if pumpkin:IsInvisible() then
                                    debug_print("Forcing pumpkin visible after door movement")
                                    pumpkin:SetInvisible(false)
                                end
                            else
                                debug_print("No pumpkin part found")
                            end
                            -- Warning -> Complete
                            ext:SetData("halloween-state", HALLOWEEN_STATE_COMPLETE, true)
                            ext:UpdateWarning()
                            ext:SendMessage("halloween-finishwarning", {})
                        end
                    else
                        local warningnextcheck = ext:GetData("halloween-warningnextcheck", 0)
                        if CurTime() - warningnextcheck > 0 then
                            local pos = int:LocalToWorld(Vector(0,0,225))
                            local allinconsoleroom = true
                            for k,v in pairs(ext.occupants) do
                                local dist = k:GetPos():Distance(pos)
                                if dist > 450 then
                                    allinconsoleroom = false
                                    break
                                end
                            end
                            if not allinconsoleroom then
                                debug_print("Not all occupants in warning area, waiting until next check")
                                ext:SetData("halloween-warningnextcheck", CurTime() + 0.1)
                            else
                                debug_print("All occupants detected in warning area, opening and closing door")
                                ext:SetData("halloween-warningdoormoving", CurTime() + 5) -- fallback in case door callbacks fail
                                ext:OpenDoor(function()
                                    local wait = 0
                                    if ext:DoorOpen() then
                                        wait = ext.metadata.Exterior.DoorAnimationTime
                                    end
                                    ext:Timer("halloween_door_open", wait, function()
                                        local pumpkin = int:GetPart("pumpkin")
                                        if IsValid(pumpkin) then
                                            debug_print("Making pumpkin visible")
                                            pumpkin:SetInvisible(false)
                                        else
                                            debug_print("No pumpkin part found")
                                        end
                                        ext:CloseDoor(function()
                                            debug_print("Doors closed, setting door movement time")
                                            ext:SetData("halloween-warningdoormoving", CurTime())
                                        end)
                                    end)
                                end)
                            end
                        end
                    end
                end
            end,
        },
        halloween_think_client = {
            inthooks = {
                ["Think"] = CLIENT,
            },
            func = function(ext,int,id)
                local state = ext:GetData("halloween-state", HALLOWEEN_STATE_DISABLED)
                if state == HALLOWEEN_STATE_CORRIDOR_SOUNDS then
                    local soundent = int.halloween_corridor_sound_ent
                    if not IsValid(soundent) then
                        debug_print("Creating corridor sound entity")
                        soundent = ents.CreateClientProp("models/props_junk/PopCan01a.mdl")
                        soundent:SetPos(int:LocalToWorld(Vector(190.887, -1104.175, 81.385)))
                        soundent:SetParent(int)
                        soundent:Spawn()
                        soundent:Activate()
                        soundent:SetNoDraw(true)
                        int.halloween_corridor_sound_ent = soundent
                    end
                    local loopsound = ext:GetData("halloween-loopsound", nil)
                    if loopsound then
                        local soundentloopsound = soundent.sound
                        if not soundentloopsound then
                            debug_print("Creating corridor looped sound")
                            soundentloopsound = CreateSound(soundent, loopsound[1])
                            soundentloopsound:SetSoundLevel(loopsound[2])
                            soundent.sound = soundentloopsound
                        end
                        if not soundentloopsound:IsPlaying() then
                            debug_print("Playing corridor looped sound")
                            soundentloopsound:PlayEx(0, 100)
                            soundentloopsound:ChangeVolume(1, 1)
                        end
                    end
                else
                    local soundent = int.halloween_corridor_sound_ent
                    if not IsValid(soundent) then return end
                    if soundent.sound then
                        if not soundent.soundfading then
                            debug_print("Fading out corridor sound")
                            soundent.sound:FadeOut(1)
                            soundent.soundfading = CurTime() + 1
                        elseif CurTime() - soundent.soundfading > 0 then
                            debug_print("Removing faded out corridor sound")
                            soundent.sound:Stop()
                            soundent.sound = nil
                        end
                    else
                        debug_print("Removing corridor sound entity")
                        soundent:Remove()
                        int.halloween_corridor_sound_ent = nil
                    end
                end
            end,
        },
        halloween_part_used = {
            inthooks = {
                ["PartUsed"] = SERVER,
            },
            func = function(ext,int,part,ply)
                local state = ext:GetData("halloween-state", HALLOWEEN_STATE_DISABLED)
                if state ~= HALLOWEEN_STATE_CORRIDOR_SOUNDS then return end
                if part.ID == "default_corridor_doors_1" or part.ID == "default_corridor_doors_2" and part:GetOn() then
                    debug_print("Corridor doors opened, starting warning timer")
                    ext:SetData("halloween-soundswarning", CurTime() + 2)
                end
            end,
        },
        halloween_should_warning_be_enabled = {
            exthooks = {
                ["ShouldWarningBeEnabled"] = SERVER,
            },
            func = function(ext,int)
                local state = ext:GetData("halloween-state", HALLOWEEN_STATE_DISABLED)
                if state == HALLOWEEN_STATE_WARNING then
                    return true
                end
            end,
        },
        halloween_should_think_fast = {
            exthooks = {
                ["ShouldThinkFast"] = SERVER,
            },
            func = function(ext,int)
                local state = ext:GetData("halloween-state", HALLOWEEN_STATE_DISABLED)
                if state == HALLOWEEN_STATE_WARNING then
                    return true
                end
            end,
        },
        halloween_on_remove = {
            inthooks = {
                ["OnRemove"] = SERVER,
            },
            func = function(ext,int,id)
                ext:SendMessage("halloween-stopknock", {})
                ext:SendMessage("halloween-stopcorridorsound", {})
            end,
        },
    },
    CustomMessages = {
        ["halloween-knock"] = function(self, data, ply)
            if not IsValid(self.interior) then return end
            local extdoor = self:GetPart("door")
            local intdoor = self.interior:GetPart("door")
            if IsValid(extdoor) and IsValid(intdoor) then
                local soundnum = data[1]
                local sound = "drmatt/tardis/events/knock" .. soundnum .. ".wav"
                intdoor:EmitSound(sound)
                intdoor.lastknocksound = sound
                intdoor.cancelknock = false
                local lockanim = function()
                    if IsValid(extdoor) and not intdoor.cancelknock then
                        debug_print("Playing lock animation on door")
                        extdoor.LockedAnim = true
                    end
                end
                if soundnum == 6 then
                    debug_print("Hard knock, scheduling lock animations, sound: " .. soundnum)
                    self:Timer("knock_delay", 0.45, lockanim)
                    self:Timer("knock_delay2", 0.83, lockanim)
                    self:Timer("knock_delay3", 1.2, lockanim)
                else
                    debug_print("Soft knock, no lock animation, sound: " .. soundnum)
                end
            end
        end,
        ["halloween-stopknock"] = function(self, data, ply)
            if not IsValid(self.interior) then return end
            local intdoor = self.interior:GetPart("door")
            if IsValid(intdoor) and intdoor.lastknocksound then
                intdoor:StopSound(intdoor.lastknocksound)
                intdoor.cancelknock = true
            end
        end,
        ["halloween-entered"] = function(self, data, ply)
            if not IsValid(self.interior) then return end
            local intdoor = self.interior:GetPart("door")
            if IsValid(intdoor) then
                intdoor:EmitSound("hl1/ambience/des_wind2.wav", 55)
            end
        end,
        ["halloween-corridorsound"] = function(self, data, ply)
            if not IsValid(self.interior) then return end
            local corridors = self.interior:GetPart("default_corridors")
            if IsValid(corridors) then
                local sound = data[1]
                local soundlvl = data[2]
                local soundent = self.interior.halloween_corridor_sound_ent
                if not IsValid(soundent) then
                    debug_print("Client corridor sound entity invalid, not playing sound")
                    return
                end
                if soundent.sound then
                    soundent.sound:Stop()
                    soundent.sound = nil
                end
                soundent.sound = CreateSound(soundent, sound)
                soundent.sound:SetSoundLevel(soundlvl)
                debug_print("Playing corridor sound: " .. sound)
                soundent.sound:Play()
            end
        end,
        ["halloween-stopcorridorsound"] = function(self, data, ply)
            local soundent = self.interior.halloween_corridor_sound_ent
            if IsValid(soundent) then
                if soundent.sound then
                    debug_print("Stopping corridor sound")
                    soundent.sound:Stop()
                    soundent.sound = nil
                end
                debug_print("Removing corridor sound entity")
                soundent:Remove()
                self.interior.halloween_corridor_sound_ent = nil
            end
        end,
        ["halloween-finishwarning"] = function(self, data, ply)
            if not IsValid(self.interior) then return end
            self.interior:EmitSound(self.metadata.Interior.Sounds.Teleport.demat_fail_loop_stop)
        end,
    }
})
