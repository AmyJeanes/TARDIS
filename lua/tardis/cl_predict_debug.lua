-- Temporary TARDIS predict-teleport debug HUD. Toggle with
-- `tardis_debug_predict 1`. Companion to the world-portals
-- worldportals_debug_predict overlay. Remove once the high-ping
-- entry artifacts are diagnosed.

CreateClientConVar("tardis_debug_predict", "0", true, false,
    "Show TARDIS predicted-teleport debug overlay", 0, 1)

TARDIS_PredictDebug = TARDIS_PredictDebug or { events = {}, max = 30 }
TARDIS_PredictDebug.max = 120

function TARDIS_PredictDebug:Log(label, data)
    if not GetConVar("tardis_debug_predict"):GetBool() then return end
    table.insert(self.events, 1, {
        frame = FrameNumber(),
        time  = SysTime(),
        label = label,
        data  = data,
    })
    while #self.events > self.max do table.remove(self.events) end
end

local function entStr(e)
    if not IsValid(e) then return tostring(e) end
    return string.format("%s[%d]", e:GetClass(), e:EntIndex())
end

local function fb(b)
    if b == nil then return "nil" end
    return tostring(b)
end

-- Per-portal state for stuck-inside detection. Indexed by entIndex.
local portalState = {}
local function getPortalState(portal)
    local i = portal:EntIndex()
    portalState[i] = portalState[i] or {}
    return portalState[i]
end

-- Last time a WorldPortals_Teleport broadcast arrived for LocalPlayer.
-- Populated by the wp.RecordNetTeleport chain below.
local lastNetTpTime

-- Chain wp.RecordNetTeleport so we can see when the server's swept test
-- caught a teleport the client's predict missed. The broadcast hits cl_init.lua's
-- net.Receive, which for ent==LocalPlayer skips the SetPos (assumes predict
-- already did it) and only stamps RecordNetTeleport. So this firing without
-- a preceding wp-teleport(client) event in the log means: predict missed,
-- server did the teleport, your GetPos will catch up on the next snapshot,
-- and crucially nobody called SetEyeAngles — your view stays at the entry
-- orientation. That's the "facing the wall" / "walked back out" bug.
if wp and wp.RecordNetTeleport and not wp._tardisDebugChained then
    local orig = wp.RecordNetTeleport
    wp.RecordNetTeleport = function(pos)
        orig(pos)
        lastNetTpTime = SysTime()
        if GetConVar("tardis_debug_predict"):GetBool() then
            local ply = LocalPlayer()
            local cur = IsValid(ply) and ply:GetPos() or vector_origin
            local netOrig = IsValid(ply) and ply:GetNetworkOrigin() or vector_origin
            local ea = IsValid(ply) and ply:EyeAngles() or angle_zero
            TARDIS_PredictDebug:Log("net WorldPortals_Teleport (server-driven)",
                string.format("target=(%.0f,%.0f,%.0f) GetPos=(%.0f,%.0f,%.0f) NetOrigin=(%.0f,%.0f,%.0f) eyeAng=(%.1f,%.1f,%.1f)",
                    pos.x, pos.y, pos.z,
                    cur.x, cur.y, cur.z,
                    netOrig.x, netOrig.y, netOrig.z,
                    ea.p, ea.y, ea.r))
        end
    end
    wp._tardisDebugChained = true
end

-- Log every client-side wp-teleport so we can see whether the world-portals
-- predicted SetupMove path is firing at all on TARDIS entry, regardless of
-- whether the per-entity PostTeleportPortal chain reaches our predict hook.
hook.Add("wp-teleport", "TARDIS_PredictDebugLog", function(portal, ent, newpos, newang)
    if ent ~= LocalPlayer() then return end
    if IsValid(portal) then
        getPortalState(portal).lastTpTime = SysTime()
        local exit = portal.GetExit and portal:GetExit() or nil
        if IsValid(exit) then getPortalState(exit).lastTpTime = SysTime() end
    end
    local parent = IsValid(portal) and portal:GetParent() or nil
    local exit = IsValid(portal) and portal.GetExit and portal:GetExit() or nil
    local portalAng = IsValid(portal) and portal:GetAngles() or angle_zero
    local exitAng = IsValid(exit) and exit:GetAngles() or angle_zero
    local curEye = IsValid(ent) and ent:EyeAngles() or angle_zero
    TARDIS_PredictDebug:Log("wp-teleport(client)",
        string.format("portal=%s parent=%s newpos=(%.0f,%.0f,%.0f) newang=(%.1f,%.1f,%.1f) preEye=(%.1f,%.1f,%.1f) portalAng=(%.1f,%.1f,%.1f) exitAng=(%.1f,%.1f,%.1f)",
            tostring(portal), entStr(parent),
            newpos and newpos.x or 0, newpos and newpos.y or 0, newpos and newpos.z or 0,
            newang and newang.p or 0, newang and newang.y or 0, newang and newang.r or 0,
            curEye.p, curEye.y, curEye.r,
            portalAng.p, portalAng.y, portalAng.r,
            exitAng.p, exitAng.y, exitAng.r))
end)

-- (Server-side WorldPortals_Teleport broadcast lands at the world-portals
-- net.Receive — see worldportals_debug_predict for the "Last net broadcast"
-- line. Don't override that net handler here, last-wins would break it.)

-- Client-side enter/exit tracking. Watch ply.door / ply.doori / tardis.interior
-- state transitions and log the instant they flip, so we can read off the
-- exact frame each piece of state landed and which path set it (predict vs
-- net broadcast vs nothing at all).
local prevDoor, prevDori, prevTI, prevTE, prevTO
hook.Add("Think", "TARDIS_PredictDebug_StateWatch", function()
    if not GetConVar("tardis_debug_predict"):GetBool() then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local door, dori = ply.door, ply.doori
    local ti = ply:GetTardisData("interior")
    local te = ply:GetTardisData("exterior")
    local to = ply:GetTardisData("outside")
    if door ~= prevDoor then
        TARDIS_PredictDebug:Log("ply.door change",
            string.format("%s -> %s", entStr(prevDoor), entStr(door)))
        prevDoor = door
    end
    if dori ~= prevDori then
        TARDIS_PredictDebug:Log("ply.doori change",
            string.format("%s -> %s", entStr(prevDori), entStr(dori)))
        prevDori = dori
    end
    if ti ~= prevTI then
        TARDIS_PredictDebug:Log("tardis.interior change",
            string.format("%s -> %s", entStr(prevTI), entStr(ti)))
        prevTI = ti
    end
    if te ~= prevTE then
        TARDIS_PredictDebug:Log("tardis.exterior change",
            string.format("%s -> %s", entStr(prevTE), entStr(te)))
        prevTE = te
    end
    if to ~= prevTO then
        TARDIS_PredictDebug:Log("tardis.outside change",
            string.format("%s -> %s", fb(prevTO), fb(to)))
        prevTO = to
    end
end)

-- Stuck-inside-portal detection. At high ping the predict swept test
-- sometimes misses on TARDIS entry — especially when the exterior is parked
-- on a slight slope — and the player ends up wedged inside the portal
-- volume with the 3D portal wrapped around them. That wedged state
-- correlates with the entry-angle bug; logging it lets us see the pattern.
-- Fires when LocalPlayer is behind a TARDIS portal's plane AND inside its
-- bbox AND no wp-teleport for that portal (or its exit) fired recently.
hook.Add("Think", "TARDIS_PredictDebug_StuckWatch", function()
    if not GetConVar("tardis_debug_predict"):GetBool() then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local eye = ply:EyePos()
    local now = SysTime()
    local frame = FrameNumber()

    for _, portal in ipairs(ents.FindByClass("linked_portal_door")) do
        local parent = portal:GetParent()
        if not (IsValid(parent) and (parent.TardisExterior or parent.TardisInterior)) then goto cont end
        if portal:GetPos():Distance(eye) > 800 then goto cont end

        local s = getPortalState(portal)
        local fwd = portal:GetForward()
        local pos = portal:GetPos()
        local distNow = (eye - pos):Dot(fwd)
        local localEye = portal:WorldToLocal(eye)
        local mins, maxs = portal:GetCollisionBounds()
        local inBox = localEye.y >= mins.y and localEye.y <= maxs.y
                  and localEye.z >= mins.z and localEye.z <= maxs.z

        local recentTp = s.lastTpTime and (now - s.lastTpTime) < 0.3
        local stuck = distNow <= 0 and inBox and not recentTp

        if stuck and not s.stuckSince then
            s.stuckSince = now
            s.stuckEntryAng = ply:EyeAngles()
            s.stuckEntryPos = ply:GetPos()
            s.stuckSampleAng = s.stuckEntryAng
            s.stuckSampleFrame = frame
            local a = s.stuckEntryAng
            TARDIS_PredictDebug:Log("STUCK BEGIN",
                string.format("portal=%d prevDist=%s dist=%.2f localEye y=%.1f z=%.1f bbox y=[%.1f,%.1f] z=[%.1f,%.1f] vel=%.0f ang=(%.1f,%.1f,%.1f) door=%s doori=%s",
                    portal:EntIndex(),
                    s.prevDistNow and string.format("%.2f", s.prevDistNow) or "nil",
                    distNow, localEye.y, localEye.z,
                    mins.y, maxs.y, mins.z, maxs.z,
                    ply:GetVelocity():Length(),
                    a.p, a.y, a.r,
                    entStr(ply.door), entStr(ply.doori)))
        elseif stuck and s.stuckSince then
            if frame - (s.stuckSampleFrame or 0) >= 3 then
                local cur = ply:EyeAngles()
                local dp = math.abs(cur.p - s.stuckSampleAng.p)
                local dy = math.abs(math.AngleDifference(cur.y, s.stuckSampleAng.y))
                local dr = math.abs(cur.r - s.stuckSampleAng.r)
                if dp + dy + dr > 0.5 then
                    TARDIS_PredictDebug:Log("STUCK ang drift",
                        string.format("+%.3fs portal=%d (%.1f,%.1f,%.1f) -> (%.1f,%.1f,%.1f) vel=%.0f",
                            now - s.stuckSince, portal:EntIndex(),
                            s.stuckSampleAng.p, s.stuckSampleAng.y, s.stuckSampleAng.r,
                            cur.p, cur.y, cur.r, ply:GetVelocity():Length()))
                    s.stuckSampleAng = cur
                end
                s.stuckSampleFrame = frame
            end
        elseif not stuck and s.stuckSince then
            local cur = ply:EyeAngles()
            local netTpRecent = lastNetTpTime and (now - lastNetTpTime) < 0.5
            TARDIS_PredictDebug:Log("STUCK END",
                string.format("portal=%d after %.3fs dist=%.2f predictTp=%s netTp=%s entryAng=(%.1f,%.1f,%.1f) endAng=(%.1f,%.1f,%.1f)",
                    portal:EntIndex(), now - s.stuckSince, distNow,
                    fb(recentTp), fb(netTpRecent),
                    s.stuckEntryAng.p, s.stuckEntryAng.y, s.stuckEntryAng.r,
                    cur.p, cur.y, cur.r))
            s.stuckSince = nil
            s.stuckEntryAng = nil
            s.stuckEntryPos = nil
            s.stuckSampleAng = nil
            s.stuckSampleFrame = nil
        end

        s.prevDistNow = distNow
        ::cont::
    end
end)

-- Predict-lerp shift window timeline. The world-portals predict path arms
-- wp.predictedPos at SetupMove time; the shift window masks engine GetPos
-- drift by parking the view at NetOrigin. If the server's swept test
-- missed the same crossing the client's caught, the post-teleport
-- snapshot never arrives, NetOrigin stays at oldPos, the sanity guard
-- skips the shift, and prediction-error correction drifts GetPos back
-- toward oldPos ("kicked back outside"). This watcher logs arm/disarm
-- transitions, sanity FAIL/OK transitions, and any big eye-angle or
-- GetPos jumps that happen during the armed window — so a single
-- "weird" frame can be traced backward across its event log.
local prevPredictedPos, prevSanity, prevArmedEyeAng, prevArmedGetPos
hook.Add("Think", "TARDIS_PredictDebug_ShiftWatch", function()
    if not GetConVar("tardis_debug_predict"):GetBool() then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local cur = wp and wp.predictedPos or nil
    if cur ~= prevPredictedPos then
        if cur and not prevPredictedPos then
            local old = wp.predictedOldPos
            local ea = ply:EyeAngles()
            local netO = ply:GetNetworkOrigin()
            local p = ply:GetPos()
            TARDIS_PredictDebug:Log("PREDICT-LERP arm",
                string.format("pred=(%.0f,%.0f,%.0f) old=(%.0f,%.0f,%.0f) net=(%.0f,%.0f,%.0f) getPos=(%.0f,%.0f,%.0f) ang=(%.1f,%.1f,%.1f)",
                    cur.x, cur.y, cur.z,
                    old and old.x or 0, old and old.y or 0, old and old.z or 0,
                    netO.x, netO.y, netO.z, p.x, p.y, p.z,
                    ea.p, ea.y, ea.r))
        elseif not cur and prevPredictedPos then
            local ea = ply:EyeAngles()
            local netO = ply:GetNetworkOrigin()
            local p = ply:GetPos()
            TARDIS_PredictDebug:Log("PREDICT-LERP disarm",
                string.format("getPos=(%.0f,%.0f,%.0f) net=(%.0f,%.0f,%.0f) ang=(%.1f,%.1f,%.1f)",
                    p.x, p.y, p.z, netO.x, netO.y, netO.z,
                    ea.p, ea.y, ea.r))
        end
        prevPredictedPos = cur
    end

    if cur then
        local old = wp.predictedOldPos
        local netO = ply:GetNetworkOrigin()
        local pos = ply:GetPos()
        local sanityFail = old and (netO:DistToSqr(cur) >= netO:DistToSqr(old))

        if sanityFail ~= prevSanity then
            TARDIS_PredictDebug:Log("PREDICT-LERP sanity " .. (sanityFail and "FAIL" or "OK"),
                string.format("|net-pred|=%.0f |net-old|=%.0f getPos=(%.0f,%.0f,%.0f) net=(%.0f,%.0f,%.0f)",
                    math.sqrt(netO:DistToSqr(cur)),
                    old and math.sqrt(netO:DistToSqr(old)) or 0,
                    pos.x, pos.y, pos.z, netO.x, netO.y, netO.z))
            prevSanity = sanityFail
        end

        local ea = ply:EyeAngles()
        if prevArmedEyeAng then
            local dp = math.abs(ea.p - prevArmedEyeAng.p)
            local dy = math.abs(math.AngleDifference(ea.y, prevArmedEyeAng.y))
            local dr = math.abs(ea.r - prevArmedEyeAng.r)
            if dp + dy + dr > 5 then
                TARDIS_PredictDebug:Log("ARMED ang jump",
                    string.format("(%.1f,%.1f,%.1f) -> (%.1f,%.1f,%.1f) sanity=%s",
                        prevArmedEyeAng.p, prevArmedEyeAng.y, prevArmedEyeAng.r,
                        ea.p, ea.y, ea.r,
                        sanityFail and "FAIL" or "OK"))
            end
        end
        prevArmedEyeAng = ea

        if prevArmedGetPos then
            local d = pos:DistToSqr(prevArmedGetPos)
            if d > 100*100 then
                TARDIS_PredictDebug:Log("ARMED getPos jump",
                    string.format("%.0fu (%.0f,%.0f,%.0f) -> (%.0f,%.0f,%.0f) sanity=%s",
                        math.sqrt(d),
                        prevArmedGetPos.x, prevArmedGetPos.y, prevArmedGetPos.z,
                        pos.x, pos.y, pos.z,
                        sanityFail and "FAIL" or "OK"))
            end
        end
        prevArmedGetPos = pos
    else
        prevArmedEyeAng = nil
        prevArmedGetPos = nil
        prevSanity = nil
    end
end)

-- Continuous eye-angle watcher. Catches "snap back" changes that happen
-- outside the predict-lerp armed window — the gap between disarm and the
-- next predict, where ARMED ang jump can't see. Hypothesis: predict's
-- cmd:SetViewAngles in SetupMove doesn't propagate to the network packet
-- (cmd is serialized before SetupMove modifications), so the server's
-- m_angEyeAngles stays pre-teleport for the predict cmd, the snapshot
-- ack eventually rolls the client's m_angEyeAngles back, and we end up
-- visually rotated to the pre-entry orientation despite no mouse input.
local prevSnapAng
hook.Add("Think", "TARDIS_PredictDebug_EyeSnap", function()
    if not GetConVar("tardis_debug_predict"):GetBool() then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local cur = ply:EyeAngles()
    if prevSnapAng then
        local dp = math.abs(cur.p - prevSnapAng.p)
        local dy = math.abs(math.AngleDifference(cur.y, prevSnapAng.y))
        local dr = math.abs(cur.r - prevSnapAng.r)
        if dp + dy + dr > 30 then
            local armed = wp and wp.predictedPos and "armed" or "unarmed"
            TARDIS_PredictDebug:Log("EYE snap (" .. armed .. ")",
                string.format("(%.1f,%.1f,%.1f) -> (%.1f,%.1f,%.1f) delta p=%.1f y=%.1f r=%.1f",
                    prevSnapAng.p, prevSnapAng.y, prevSnapAng.r,
                    cur.p, cur.y, cur.r, dp, dy, dr))
        end
    end
    prevSnapAng = cur
end)

hook.Add("HUDPaint", "TARDIS_PredictDebugHUD", function()
    if not GetConVar("tardis_debug_predict"):GetBool() then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local sw = ScrW()
    local x, y = sw - 560, 100
    local lh = 14
    local function line(text, col)
        draw.SimpleText(text, "DermaDefault", x, y, col or color_white,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        y = y + lh
    end

    line(string.format("[TARDIS predict debug] frame=%d  SysTime=%.3f",
        FrameNumber(), SysTime()), Color(120, 220, 255))

    local activeStuck
    for _, portal in ipairs(ents.FindByClass("linked_portal_door")) do
        local s = portalState[portal:EntIndex()]
        if s and s.stuckSince then
            activeStuck = {portal = portal, since = s.stuckSince}
            break
        end
    end
    if activeStuck then
        line(string.format(">>> STUCK INSIDE portal=%s for %.3fs <<<",
            entStr(activeStuck.portal), SysTime() - activeStuck.since),
            Color(255, 90, 90))
    end

    line(string.format("ply.door=%s  ply.doori=%s",
        entStr(ply.door), entStr(ply.doori)))
    line(string.format("tardis.exterior=%s",
        entStr(ply:GetTardisData("exterior"))))
    line(string.format("tardis.interior=%s",
        entStr(ply:GetTardisData("interior"))))
    line(string.format("tardis.outside=%s  tardis.intfallback=%s",
        fb(ply:GetTardisData("outside")), fb(ply:GetTardisData("intfallback"))))

    line("")
    line("Nearby TARDIS-parented portals (<800u):", Color(200, 200, 200))
    local plyEye = ply:EyePos()
    local vel = ply:GetVelocity()
    local frameTime = FrameTime()
    local count = 0
    for _, portal in ipairs(ents.FindByClass("linked_portal_door")) do
        local parent = portal:GetParent()
        if not (IsValid(parent) and (parent.TardisExterior or parent.TardisInterior)) then goto skip end
        local d = portal:GetPos():Distance(plyEye)
        if d > 800 then goto skip end
        count = count + 1
        local fwd = portal:GetForward()
        local pos = portal:GetPos()
        local distNow = (plyEye - pos):Dot(fwd)
        local nextEye = plyEye + vel * frameTime
        local distNext = (nextEye - pos):Dot(fwd)
        local localEye = portal:WorldToLocal(nextEye)
        local mins, maxs = portal:GetCollisionBounds()
        local inY = localEye.y >= mins.y and localEye.y <= maxs.y
        local inZ = localEye.z >= mins.z and localEye.z <= maxs.z
        local crossing = distNow > 0 and distNext <= 0
        local crossCol = crossing and Color(255, 200, 120) or color_white
        line(string.format("  [%d] parent=%s d=%.1f thick=%d inv=%s",
            portal:EntIndex(), entStr(parent), d,
            portal:GetThickness(), fb(portal:GetInverted())), crossCol)
        line(string.format("    distNow=%6.2f distNext=%6.2f velFwd=%6.2f open=%s tp=%s",
            distNow, distNext, vel:Dot(fwd),
            fb(portal:GetOpen()), fb(portal:GetEnableTeleport())), crossCol)
        line(string.format("    localEyeNext y=%6.2f z=%6.2f  inY=%s inZ=%s  CROSSING=%s",
            localEye.y, localEye.z, fb(inY), fb(inZ), fb(crossing)), crossCol)
        -- TARDIS veto evaluation (replicates predicates used by the
        -- ShouldTeleportPortal / CanPlayerEnter / CanPlayerExit chain).
        local ext = parent.TardisExterior and parent or parent.exterior
        local doorOpen = IsValid(ext) and ext.DoorOpen and ext:DoorOpen() or false
        local locked = IsValid(ext) and ext.Locked and ext:Locked() or false
        local demat = IsValid(ext) and ext:GetData("teleport") or false
        local vortex = IsValid(ext) and ext:GetData("vortex") or false
        local redec = IsValid(ext) and ext:GetData("redecorate") or false
        local tracking = IsValid(ext) and ext:GetTracking() or nil
        local trackingHits = IsValid(tracking) and tracking == ply
        line(string.format("    veto: doorOpen=%s locked=%s demat=%s vortex=%s redec=%s tracking=%s",
            fb(doorOpen), fb(locked), fb(demat), fb(vortex), fb(redec),
            fb(trackingHits)), crossCol)
        ::skip::
    end
    if count == 0 then line("  (none in range)", Color(160, 160, 160)) end

    line("")
    -- Pick the interior we care about: the one ply is "in" via TardisData,
    -- else the one whose exterior is ply.door, else the nearest tardis interior.
    local int = ply:GetTardisData("interior")
    if not IsValid(int) and IsValid(ply.door) and ply.door.TardisExterior then
        int = ply.door.interior
    end
    if not IsValid(int) then
        local nearestDist
        for _, e in ipairs(ents.FindByClass("gmod_tardis_interior")) do
            local d = e:GetPos():Distance(plyEye)
            if not nearestDist or d < nearestDist then int, nearestDist = e, d end
        end
        if IsValid(int) then
            line(string.format("(no current TARDIS interior; nearest = %s)",
                entStr(int)), Color(200, 200, 160))
        end
    end

    if IsValid(int) then
        local extKey = ply:GetTardisData("interior") == int
        local outside = ply:GetTardisData("outside")
        local propsExt = int.props and int.props[int.exterior] or nil
        local containsDoor = int.contains and int.contains[ply.door] or nil
        local drawing = wp and wp.drawing
        local hideA = not extKey
        local hideB = outside and (propsExt == nil)
        local hide = (hideA or hideB) and not drawing and not containsDoor
        local col = hide and Color(255, 130, 130) or Color(150, 230, 150)
        line(string.format("Interior %s ShouldDraw inputs:", entStr(int)), col)
        line(string.format("  GetTardisData(\"interior\") == self : %s", fb(extKey)), col)
        line(string.format("  GetTardisData(\"outside\")          : %s", fb(outside)), col)
        line(string.format("  props[exterior]==nil               : %s (props.ext=%s)",
            fb(propsExt == nil), tostring(propsExt)), col)
        line(string.format("  wp.drawing                         : %s", fb(drawing)), col)
        line(string.format("  contains[ply.door]                 : %s (door=%s)",
            fb(containsDoor), entStr(ply.door)), col)
        line(string.format("  -> ShouldDraw returns              : %s",
            hide and "FALSE (HIDE)" or "nil (SHOW)"), col)
    end

    line("")
    line("---- Events (newest first) ----", Color(200, 200, 200))
    local now = SysTime()
    for i, e in ipairs(TARDIS_PredictDebug.events) do
        if i > 22 then break end
        local age = now - e.time
        line(string.format("  [%d] %5.3fs ago  %s%s",
            e.frame, age, e.label, e.data and ("  " .. e.data) or ""),
            Color(220, 220, 220))
    end
end)
