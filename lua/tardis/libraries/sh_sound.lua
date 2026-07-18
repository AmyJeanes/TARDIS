-- Every sound the addon plays goes through TARDIS:PlaySound. Callers describe the sound and where it
-- comes from; this picks how to play it - a normal engine sound, or a managed BASS channel for the ones
-- that have to survive the listener jumping across the interior void (opts.resumable).
--
-- Managed BASS channels. Source culls an EmitSound one-shot when the listener jumps far - e.g. toggling
-- the exterior view, or a portal teleport across the interior void - and can't resume it. A BASS channel
-- isn't spatialised by Source, so it plays through the jump. A resumable sound also returns a handle, so
-- callers stop the exact sound on interrupt instead of guessing paths with Entity:StopSound.
--
-- A positioned managed sound is spatialised by hand on a 2D stereo channel to match Source's positioned
-- EmitSound: the volume tracks Source's own distance gain each frame, plus its occlusion rolloff when a
-- world brush blocks the path (map geometry only, like the engine - the interior's floor is an entity, so
-- it doesn't muffle), and a port of Source's speaker spatialiser (spatialize() below) reproduces its exact
-- left/right per-side gain - the azimuth pan and the centre/rear volume envelope - via SetVolume + SetPan,
-- so it tracks the view like the original. Doppler isn't emulated (Source only applies it to CHAR_DOPPLER
-- soundscripts).

---@class tardis_sound_opts
---@field path string sound path relative to sound/
---@field ent Entity? entity the sound plays from
---@field pos Vector? fixed world position to play from, when there is no entity
---@field offset Vector? local offset from ent for the source position
---@field volume number? max volume 0-1, default 1
---@field level number? SNDLVL for distance falloff, default 75 (EmitSound's default)
---@field resumable boolean? play through a managed BASS channel instead of the engine, so the sound survives the listener jumping across the interior void - a door portal crossing or the exterior view toggle - which culls a normal engine sound. Returns a handle
---@field owner Entity? owner, for group-stop via TARDIS:StopSounds (a resumable sound also stops when its owner is removed)
---@field tag string? group label for TARDIS:StopSounds, e.g. "teleport"
---@field setting string? server only: client setting id each receiving client checks before playing; omit to play for everyone regardless
---@field recipients Player|Player[]? server only: who hears it; omit = everyone
---@field falloff tardis_sound_falloff_point[]? resumable only: custom distance->volume curve, overrides level
---@field pin_on_jump number? resumable only, with ent: the sound pins where the entity vanished from once it moves faster than this (units/second) - a teleporting emitter leaves its tail behind, e.g. the demat echo a bystander hears. A speed, not a distance: interpolation renders a client-side teleport as a short impossibly-fast slide, never a single-frame jump
---@field attach Entity? resumable only, with pos: entity that takes over as the source once it arrives within attach_dist of pos (e.g. the exterior landing on its materialise point)
---@field attach_dist number? resumable only: arrival distance for attach, default 500
---@field update fun(handle: tardis_managed_sound)? resumable only: custom per-frame volume callback (overrides falloff)
---@field on_done fun()? resumable only: called once when the sound finishes on its own

-- The engine's own sound, positioned like the caller asked. Shared by both realms: played on the server
-- it reaches every client by itself, played on a client it is that client's alone.
---@param opts tardis_sound_opts
local function playNative(opts)
    if opts.ent == nil and opts.pos == nil then
        -- no source at all: an interface sound, played flat rather than placed in the world
        if CLIENT then surface.PlaySound(opts.path) end
        return
    end
    local ent = opts.ent
    if IsValid(ent) then
        -- EmitSound takes no offset, so an offset sound plays from that fixed point instead of following
        if opts.offset then
            sound.Play(opts.path, ent:LocalToWorld(opts.offset), opts.level, nil, opts.volume)
        else
            ent:EmitSound(opts.path, opts.level, nil, opts.volume)
        end
    elseif opts.pos then
        sound.Play(opts.path, opts.pos, opts.level, nil, opts.volume)
    end
end

if SERVER then
    util.AddNetworkString("TARDIS-Sound")
    util.AddNetworkString("TARDIS-SoundStop")

    ---@api
    ---@param opts tardis_sound_opts
    function TARDIS:PlaySound(opts)
        -- The engine broadcasts a plain positioned sound by itself, so only send our own message when a
        -- client has to decide or do something first: check a setting, be the only one to hear it, run
        -- the BASS channel (which lives client-side), or play an interface sound, which has no position
        -- for the engine to carry. Fire-and-forget - no handle comes back; stop by group instead.
        local client_decides = opts.resumable or opts.setting or opts.recipients
            or (opts.ent == nil and opts.pos == nil)
        if not client_decides then
            playNative(opts)
            return
        end
        net.Start("TARDIS-Sound")
        net.WriteString(opts.path)
        net.WriteEntity(opts.owner or NULL)
        net.WriteString(opts.tag or "")
        net.WriteFloat(opts.volume or 1)
        net.WriteEntity(opts.ent or NULL)
        -- the entity's position rides along, so a client that doesn't have it still hears the sound
        -- from where it was rather than everywhere at once
        local pos = opts.pos or (IsValid(opts.ent) and opts.ent:GetPos() or nil)
        net.WriteBool(pos ~= nil)
        if pos then net.WriteVector(pos) end
        net.WriteBool(opts.offset ~= nil)
        if opts.offset then net.WriteVector(opts.offset) end
        net.WriteBool(opts.level ~= nil)
        if opts.level then net.WriteUInt(opts.level, 8) end
        net.WriteBool(opts.resumable == true)
        net.WriteString(opts.setting or "")
        if opts.recipients then
            -- the stub types net.Send Player-only; it accepts a Player table too
            net.Send(opts.recipients --[[@as Player]])
        else
            net.Broadcast()
        end
    end

    ---@api
    ---@param owner Entity
    ---@param tag string?
    ---@param recipients Player|Player[]? who to stop it for; omit = all players
    function TARDIS:StopSounds(owner, tag, recipients)
        net.Start("TARDIS-SoundStop")
        net.WriteEntity(owner)
        net.WriteString(tag or "")
        if recipients then
            -- the stub types net.Send Player-only; it accepts a Player table too
            net.Send(recipients --[[@as Player]])
        else
            net.Broadcast()
        end
    end

    return
end

-- Source's exact distance gain, ported from the engine (sound_shared.cpp SND_GetGainFromMult), so the
-- falloff matches EmitSound precisely: inverse-distance from the SNDLVL, plus air/foliage loss and the
-- >0.5 soft-knee compression and the min-gain floor. Reads the same convars the engine does. Validated
-- against snd_show's own channel gains at 150/300/600/1200u (matched to 1 part in 255). The obscured
-- (line-of-sight blocked) loss is applied on top of this by occlusion() below.
local SND_GAIN_COMP_THRESH = 0.5
local SND_GAIN_COMP_EXP_MAX = 2.5
local SND_GAIN_COMP_EXP_MIN = 0.8
local SND_DB_MED = 90
local SND_DB_MAX = 140
local snd_refdb = GetConVar("snd_refdb")
local snd_refdist = GetConVar("snd_refdist")
local snd_foliage_db_loss = GetConVar("snd_foliage_db_loss")
local snd_gain_max = GetConVar("snd_gain_max")
local snd_gain_min = GetConVar("snd_gain_min")

---@param dist number
---@param level number SNDLVL (0 = SNDLVL_NONE, no attenuation)
---@return number
local function sndLevelGain(dist, level)
    if level <= 0 then return 1 end
    local refdb = snd_refdb and snd_refdb:GetFloat() or 60
    local refdist = snd_refdist and snd_refdist:GetFloat() or 36
    local dist_mult = (10 ^ (refdb / 20) / 10 ^ (level / 20)) / refdist
    local foliage = snd_foliage_db_loss and snd_foliage_db_loss:GetFloat() or 4
    local relative_dist = dist * dist_mult * (10 ^ (foliage * (dist / 1200) / 20))
    local gain = relative_dist > 0.1 and (1 / relative_dist) or 10
    if gain > SND_GAIN_COMP_THRESH then
        local power = SND_GAIN_COMP_EXP_MAX
        if level > SND_DB_MED then
            power = SND_GAIN_COMP_EXP_MAX + (level - SND_DB_MED) / (SND_DB_MAX - SND_DB_MED)
                * (SND_GAIN_COMP_EXP_MIN - SND_GAIN_COMP_EXP_MAX)
        end
        local Y = -1 / (SND_GAIN_COMP_THRESH ^ power * (SND_GAIN_COMP_THRESH - 1))
        gain = (1 - 1 / (Y * gain ^ power)) * (snd_gain_max and snd_gain_max:GetFloat() or 1)
    end
    local gmin = snd_gain_min and snd_gain_min:GetFloat() or 0.01
    if gain < gmin then
        gain = gmin * (2 - relative_dist * gmin)
        if gain <= 0 then gain = 0.001 end
    end
    return gain
end

---@class tardis_sound_falloff_point
---@field dist number distance in units
---@field vol number volume multiplier 0-1 at that distance

-- Volume from a custom falloff curve: a list of {dist, vol} points (ascending by dist), linearly
-- interpolated. Flat at the first/last point's volume outside the range. An alternative to the
-- SNDLVL curve for hand-tuned falloff, e.g. {{dist=200,vol=1},{dist=400,vol=0.5},{dist=500,vol=0}}.
---@param dist number
---@param points tardis_sound_falloff_point[]
---@return number
local function curveGain(dist, points)
    local n = #points
    if n == 0 then return 1 end
    if dist <= points[1].dist then return points[1].vol end
    if dist >= points[n].dist then return points[n].vol end
    for i = 1, n - 1 do
        local a, b = points[i], points[i + 1]
        if dist <= b.dist then
            return Lerp((dist - a.dist) / math.max(b.dist - a.dist, 0.001), a.vol, b.vol)
        end
    end
    return points[n].vol
end

---@class tardis_managed_sound
---@field chan IGModAudioChannel? nil while the async load is still in flight
---@field owner Entity?
---@field tag string?
---@field base number caller's max volume (the EmitSound volume equivalent)
---@field volume number current applied volume
---@field ent Entity? source entity for distance falloff (offset applied in its local space)
---@field pos Vector? fixed world source position for falloff (used when ent is not set)
---@field offset Vector? local offset from ent for the source position (like a relative EmitSound pos)
---@field level number? SNDLVL for distance falloff (needs a source: ent or pos)
---@field falloff tardis_sound_falloff_point[]? custom distance->volume curve (needs a source, overrides level)
---@field last_pos Vector? last resolved source position; the pin target when ent teleports or vanishes
---@field pin_on_jump number? see tardis_sound_opts
---@field attach Entity? see tardis_sound_opts
---@field attach_dist number distance from pos at which attach takes over as the source
---@field occ number? smoothed occlusion gain, eased toward the blocked/clear line-of-sight each frame
---@field omni boolean true for a stereo .wav - Source plays it omnidirectional (mono, no pan, unobscured)
---@field sp_paused boolean? true while parked by the SP-pause watcher
---@field stopped boolean
---@field update fun(handle: tardis_managed_sound)?
---@field on_done fun()?
local MANAGED = {}
MANAGED.__index = MANAGED

TARDIS.ActiveManagedSounds = TARDIS.ActiveManagedSounds or {} ---@type tardis_managed_sound[]

---@param handle tardis_managed_sound
local function drop(handle)
    handle.chan = nil
    table.RemoveByValue(TARDIS.ActiveManagedSounds, handle)
end

-- world position the falloff is measured from: ent (+ local offset), or a fixed pos. A followed entity
-- that teleports (pin_on_jump) or is removed leaves the sound pinned at its last position instead of
-- dragging the tail across the map or going global; a pinned sound with an `attach` entity starts
-- following it once it arrives at the pin point.
---@param handle tardis_managed_sound
---@return Vector?
local function sourcePos(handle)
    local ent = handle.ent
    if IsValid(ent) then
        local pos = handle.offset and ent:LocalToWorld(handle.offset) or ent:GetPos()
        local last = handle.last_pos
        local jump = handle.pin_on_jump and handle.pin_on_jump * math.max(FrameTime(), 0.001)
        if jump and last and pos:DistToSqr(last) > jump * jump then
            handle.ent = nil
            handle.pos = last
            return last
        end
        handle.last_pos = pos
        return pos
    end
    local attach = handle.attach
    if attach ~= nil and handle.pos and IsValid(attach)
        and attach:GetPos():DistToSqr(handle.pos) <= handle.attach_dist * handle.attach_dist then
        handle.ent = attach
        handle.attach = nil
    end
    return handle.pos or handle.last_pos
end

-- Source plays a positioned STEREO .wav as CHAR_OMNI (S_SetChannelStereo, snd_dma.cpp): omnidirectional,
-- so it's full mono (no left/right panning), distance-attenuated only, and never occluded. A stereo OGG/MP3
-- is NOT omni (IsStereoWav excludes them) - it spatialises normally. Match that by detecting a stereo .wav
-- from its header (canonical RIFF: channel count is the 16-bit LE at offset 22), cached per path.
-- Channel count from a RIFF/WAVE byte string. Walks the chunk list to find "fmt " rather than assuming
-- the canonical offset, so a WAV with extra chunks (LIST/fact/JUNK) before fmt still reads correctly.
---@param data string
---@return number? channels, nil if not a parseable WAV
local function wavChannels(data)
    if #data < 16 or data:sub(1, 4) ~= "RIFF" or data:sub(9, 12) ~= "WAVE" then return nil end
    local pos = 13 -- first chunk id (byte 13 = file offset 12)
    while pos + 8 <= #data do
        local size = data:byte(pos+4) + data:byte(pos+5)*256 + data:byte(pos+6)*65536 + data:byte(pos+7)*16777216
        if data:sub(pos, pos + 3) == "fmt " and pos + 11 <= #data then
            return data:byte(pos + 10) + data:byte(pos + 11) * 256 -- fmt: audioFormat(2), then channels(2)
        end
        pos = pos + 8 + size + (size % 2) -- chunks are word-aligned
    end
    return nil
end

local stereoWavCache = {}
---@param path string sound path relative to sound/
---@return boolean
local function isStereoWav(path)
    if stereoWavCache[path] == nil then
        local stereo = false
        if string.EndsWith(path:lower(), ".wav") then
            local data = file.Read("sound/" .. path, "GAME")
            -- unreadable .wav (e.g. a mount file.Read can't reach): assume stereo, since almost every
            -- teleport .wav is - so it defaults to omni, matching what Source does with a stereo wav.
            stereo = data == nil or wavChannels(data) == 2
        end
        stereoWavCache[path] = stereo
    end
    return stereoWavCache[path]
end

-- Source's stereo spatialisation, ported from CAudioDeviceBase::SpatializeChannel + GetSpeakerVol
-- (engine/audio/snd_dev_common.cpp). Returns the per-side gains (lf, rf, 0-1) Source applies to a
-- positioned sound's left/right channels: a nonlinear power-1.5 speaker crossfade, quieter rear (rear
-- folded in at 0.75), and a pitch->mono centring for sounds far above/below. Config-dependent -
-- snd_surround_speakers 0 = headphone (gentle), else the 2-speaker 4->2 fold (the usual desktop default).
-- Applied on a stereo channel as SetVolume(gain * max(lf,rf)) + SetPan((rf-lf)/max), this reproduces
-- Source's per-side leftvol/rightvol exactly - matching both the pan and the ~0.646 centre envelope.
local snd_surround = GetConVar("snd_surround_speakers")
local SND_VOLCURVE = 1.5

-- one speaker's contribution (GetSpeakerVol). cspeaker 2 = opposing headphone pair, 4 = the 90-deg
-- surround/stereo speakers; `mono` (0-1) fades the speaker toward the centred distribution target.
---@param yaw number
---@param speakerYaw number
---@param mono number
---@param cspeaker number
---@param rear boolean?
---@return number
local function speakerVol(yaw, speakerYaw, mono, cspeaker, rear)
    local adif = math.abs(yaw - speakerYaw)
    if adif > 180 then adif = 360 - adif end
    local scale
    if cspeaker == 2 then
        scale = 1 - (adif / 180) ^ SND_VOLCURVE
    elseif adif >= 90 then
        scale = 0
    else
        scale = 1 - (adif / 90) ^ SND_VOLCURVE
    end
    local target = (cspeaker ~= 2 and rear) and 0 or 0.9
    return scale + (target - scale) * mono
end

-- Source's left/right per-side gains (0-1) for a source at `pos`, from the yaw/pitch to it. `radius` is
-- the emitter's own size (ent:GetModelRadius(), what Source uses): inside it the sound blends to mono.
---@param pos Vector
---@param radius number source radius in units; 0 = point source (no mono collapse)
---@return number lf
---@return number rf
local function spatialize(pos, radius)
    local dir = pos - EyePos()
    local dist = dir:Length()
    if dist < 1 then return 0.9, 0.9 end
    local ang = dir:Angle()
    local right = EyeAngles():Right()
    local yaw = (ang.yaw - Vector(right.x, right.y, 0):Angle().yaw) % 360
    -- pitch (folded to 0-90 above/below horizontal) collapses toward mono past 45 degrees
    local pitch = ang.pitch
    if pitch < 0 then pitch = pitch + 360 end
    if pitch > 180 then pitch = 360 - pitch end
    if pitch > 90 then pitch = 90 - (pitch - 90) end
    local mono = pitch > 45 and math.Clamp((pitch - 45) / 45, 0, 1) or 0
    -- radius mono collapse: a positioned sound reads as mono once the listener is within the emitter's
    -- radius, ramping from stereo at the rim to full mono at half-radius (so a large interior's demat,
    -- whose origin you stand inside, barely pans - matching Source rather than hard-panning by position).
    if radius > 0 and dist < radius then
        local interval = radius * 0.5
        mono = math.Clamp(mono + 1 - math.max(dist - interval, 0) / interval, 0, 1)
    end
    if snd_surround and snd_surround:GetInt() == 0 then
        return speakerVol(yaw, 180, mono, 2), speakerVol(yaw, 0, mono, 2)
    end
    local rf = speakerVol(yaw, 45, mono, 4)
    local lf = speakerVol(yaw, 135, mono, 4)
    local rr = speakerVol(yaw, 315, mono, 4, true)
    local lr = speakerVol(yaw, 225, mono, 4, true)
    return math.Clamp(lf + lr * 0.75, 0, 1), math.Clamp(rf + rr * 0.75, 0, 1)
end

-- Master SFX volume: BASS channels bypass the `volume` convar that EmitSound obeys, so fold it in for
-- parity - otherwise a lowered SFX slider wouldn't quieten these sounds like it did the old ones.
local volumeConVar = GetConVar("volume")

-- Source only muffles a sound when WORLD geometry blocks the straight path to it: SND_GetGainObscured
-- traces CTraceFilterWorldOnly (map brushes only), so props and other entities never occlude - including
-- an interior's own floor, even though the origin sits below it. So trace world-only (ignore every entity)
-- and ease the gain toward the obscured level when a brush blocks. This muffles the exterior copy behind a
-- real wall like the engine does, and is a no-op inside the geometry-free interior void. (Source softens
-- occlusion over a 4-point radius; a single binary block is close enough and doesn't compound stacked walls.)
local snd_obscured = GetConVar("snd_obscured_gain_dB")
local MASK_BLOCK_AUDIO = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_WINDOW) --[[@as MASK]]
local function ignoreEntities() return false end
---@param handle tardis_managed_sound
---@param pos Vector
---@return number
local function occlusion(handle, pos)
    local blocked = util.TraceLine({ start = EyePos(), endpos = pos, mask = MASK_BLOCK_AUDIO, filter = ignoreEntities }).Hit
    local target = blocked and (snd_obscured and 10 ^ (snd_obscured:GetFloat() / 20) or 0.73) or 1
    if handle.occ == nil then
        handle.occ = target
    else
        handle.occ = Lerp(FrameTime() * 8, handle.occ, target)
    end
    return handle.occ
end

-- Source scales every sound by its mix-group volume (MXR_GetVolFromMixGroup) before mixing. Our BASS
-- channel bypasses the mixer, so fold the group volume in for parity. TARDIS SFX carry no special name or
-- classname, so they fall through Default_Mix's rules to the catch-all "All" group (0.72). GMod exposes no
-- live mixer to Lua and a map's soundscape can pick a different mixer, so this is the default-mix constant
-- rather than a per-frame read - right for the common case, which is what the old EmitSound mostly played at.
local SOURCE_MIXER_GAIN = 0.72

-- volume for this frame: base * distance gain (custom curve or SNDLVL falloff) * occlusion * mixer * master.
-- Omni (stereo-wav) sounds are unattenuated by direction and never obscured, so they skip occlusion.
---@param handle tardis_managed_sound
---@return number
local function targetVolume(handle)
    local gain = 1
    local pos = sourcePos(handle)
    if pos then
        if handle.falloff then
            gain = curveGain(EyePos():Distance(pos), handle.falloff)
        elseif handle.level then
            gain = sndLevelGain(EyePos():Distance(pos), handle.level)
        end
        if not handle.omni then
            gain = gain * occlusion(handle, pos)
        end
    end
    return handle.base * gain * SOURCE_MIXER_GAIN * (volumeConVar and volumeConVar:GetFloat() or 1)
end

local OMNI_ENVELOPE = 0.9   -- GetSpeakerVol's fully-mono target per front speaker (both sides equal)
-- Apply this frame's level and pan to the channel. targetVolume is Source's pre-spatialisation scalar
-- gain; the spatialiser then splits it into the left/right the engine would produce, mapped onto a stereo
-- BASS channel via SetVolume (the louder side) + SetPan (the ratio between them).
---@param handle tardis_managed_sound
---@param chan IGModAudioChannel
local function applyGain(handle, chan)
    local scalar = targetVolume(handle)
    local pos = sourcePos(handle)
    if pos and handle.omni then
        -- CHAR_OMNI: mono, both channels equal, no pan - only the distance gain varies
        handle.volume = scalar * OMNI_ENVELOPE
        chan:SetVolume(handle.volume)
        chan:SetPan(0)
    elseif pos then
        local radius = IsValid(handle.ent) and handle.ent:GetModelRadius() or 0
        local lf, rf = spatialize(pos, radius)
        local m = math.max(lf, rf, 0.0001)
        handle.volume = scalar * m
        chan:SetVolume(handle.volume)
        chan:SetPan((rf - lf) / m)
    else
        handle.volume = scalar
        chan:SetVolume(scalar)
        chan:SetPan(0)
    end
end

function MANAGED:IsValid()
    return IsValid(self.chan)
end

function MANAGED:IsPlaying()
    return IsValid(self.chan) and self.chan:GetState() == GMOD_CHANNEL_PLAYING
end

---@param volume number
function MANAGED:SetVolume(volume)
    self.base = volume
    self.volume = volume
    if IsValid(self.chan) then
        self.chan:SetVolume(volume)
    end
end

function MANAGED:Stop()
    self.stopped = true
    if IsValid(self.chan) then
        self.chan:Stop()
    end
    drop(self)
end

-- EmitSound's default sound level; the SNDLVL_* names aren't Lua globals, so 75
local DEFAULT_SNDLVL = 75

-- SP-pause watcher state (the PreRender hook at the bottom): true while the game is paused.
-- SinglePlayer can't change within a session, so read it once instead of per frame.
local SINGLEPLAYER = game.SinglePlayer()
local sp_paused = false
local last_think_frame = 0

---@param opts tardis_sound_opts
---@return tardis_managed_sound
local function playManaged(opts)
    ---@type tardis_managed_sound
    local handle = setmetatable({
        owner = opts.owner,
        tag = opts.tag,
        base = opts.volume or 1,
        volume = opts.volume or 1,
        ent = opts.ent,
        pos = opts.pos,
        offset = opts.offset,
        level = opts.level or ((opts.ent ~= nil or opts.pos ~= nil) and DEFAULT_SNDLVL or nil),
        falloff = opts.falloff,
        pin_on_jump = opts.pin_on_jump,
        attach = opts.attach,
        attach_dist = opts.attach_dist or 500,
        omni = isStereoWav(opts.path),
        update = opts.update,
        on_done = opts.on_done,
        stopped = false,
    }, MANAGED)
    table.insert(TARDIS.ActiveManagedSounds, handle)

    -- Stereo, like Source: a positioned stereo sound keeps its channels, each scaled by that side's
    -- spatialisation weight (not summed to mono). noblock fully loads so there's no block-stream hitch.
    sound.PlayFile("sound/" .. opts.path, "noblock", function(chan)
        if handle.stopped then
            -- stopped before the load finished (e.g. an interrupt raced the load)
            if IsValid(chan) then chan:Stop() end
        elseif IsValid(chan) then
            handle.chan = chan
            applyGain(handle, chan)
            chan:Play()
            -- the async load can complete mid-pause; start parked so it doesn't play into the pause
            if sp_paused then
                chan:Pause()
                handle.sp_paused = true
            end
        else
            drop(handle)
        end
    end)

    return handle
end

---@api
---@param opts tardis_sound_opts
---@return tardis_managed_sound? handle to a resumable sound, so callers can stop or track that exact sound
function TARDIS:PlaySound(opts)
    if opts.resumable then
        return playManaged(opts)
    end
    playNative(opts)
end

-- Only resumable sounds can be stopped as a group: the engine's own sounds are fire-and-forget once
-- started, so a caller that needs to cut one short stops it through the entity it plays from.
---@api
---@param owner Entity
---@param tag string?
function TARDIS:StopSounds(owner, tag)
    local list = TARDIS.ActiveManagedSounds
    for i = #list, 1, -1 do
        local handle = list[i]
        if handle.owner == owner and (tag == nil or handle.tag == tag) then
            handle:Stop()
        end
    end
end

net.Receive("TARDIS-Sound", function()
    local path = net.ReadString()
    local owner = net.ReadEntity()
    local tag = net.ReadString()
    local volume = net.ReadFloat()
    local ent = net.ReadEntity()
    local pos = net.ReadBool() and net.ReadVector() or nil
    local offset = net.ReadBool() and net.ReadVector() or nil
    local level = net.ReadBool() and net.ReadUInt(8) or nil
    local resumable = net.ReadBool()
    local setting = net.ReadString()
    if setting ~= "" and not TARDIS:GetSetting(setting) then return end
    TARDIS:PlaySound({
        path = path,
        owner = IsValid(owner) and owner or nil,
        tag = tag ~= "" and tag or nil,
        volume = volume,
        ent = IsValid(ent) and ent or nil,
        pos = pos,
        offset = offset,
        level = level,
        resumable = resumable,
    })
end)

net.Receive("TARDIS-SoundStop", function()
    local owner = net.ReadEntity()
    local tag = net.ReadString()
    if not IsValid(owner) then return end
    TARDIS:StopSounds(owner, tag ~= "" and tag or nil)
end)

hook.Add("Think", "tardis_managed_sounds", function()
    last_think_frame = FrameNumber()
    local list = TARDIS.ActiveManagedSounds
    for i = #list, 1, -1 do
        local handle = list[i]
        local chan = handle.chan
        if handle.owner ~= nil and not IsValid(handle.owner) then
            -- owner deleted: stop, like the entity's own EmitSounds would have
            handle:Stop()
        elseif chan ~= nil then
            if not IsValid(chan) or chan:GetState() == GMOD_CHANNEL_STOPPED then
                drop(handle)
                if handle.on_done then handle.on_done() end
            elseif handle.update then
                handle.update(handle)
            else
                applyGain(handle, chan)
            end
        end
    end
end)

-- SP pause parity: native EmitSounds freeze with the engine but BASS plays in real time, so park the
-- channels while the game is paused. No pause hook or getter exists, but render hooks keep running at
-- full frame rate through a pause while Think freezes completely - so render frames passing with no
-- Think detect the transition within ~2 frames. Singleplayer only: in multiplayer a Think stall is net
-- lag, during which native sounds keep playing, so pausing here would create a divergence, not fix one.
hook.Add("PreRender", "tardis_managed_sounds_pause", function()
    if not SINGLEPLAYER or last_think_frame == 0 then return end
    local now_paused = FrameNumber() - last_think_frame >= 2
    if now_paused == sp_paused then return end
    sp_paused = now_paused
    for _, handle in ipairs(TARDIS.ActiveManagedSounds) do
        local chan = handle.chan
        if chan ~= nil and IsValid(chan) then
            if sp_paused and chan:GetState() == GMOD_CHANNEL_PLAYING then
                chan:Pause()
                handle.sp_paused = true
            elseif not sp_paused and handle.sp_paused then
                handle.sp_paused = nil
                -- resume only what we parked and is still parked: Play() on a channel that finished
                -- in the detection window would restart it from the beginning
                if chan:GetState() == GMOD_CHANNEL_PAUSED then
                    chan:Play()
                end
            end
        end
    end
end)
