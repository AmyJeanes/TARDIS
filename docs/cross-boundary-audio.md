# Cross-boundary audio - design and plan

Phase 3 of the sound rework ([#382](https://github.com/AmyJeanes/TARDIS/issues/382)). The mechanism lands in
the **Doors** addon (`lua/doors/libraries/sh_sound.lua`); this document is the plan, so it may name TARDIS.
Doors' own code and docs stay consumer-agnostic - generic interior / exterior / portal vocabulary only.

Status: **the resolver is built and tuned; counterpart handling is designed but not built.** Done and on
the `sound-rework` branch: managed BASS channels, the central hub, looping with mid-file handover, all 13
loop call sites migrated onto it, and then steps 1-3 below - the resolver itself, the consumer volume
scalar, and the deletion of the hand-built leak.

**Decision 9 is built and ear-tested** (2026-07-19): the listener resolves from the camera, and a view
change cuts in 40ms where a move still glides in 500ms.

What remains: counterpart pairs (decision 3, which absorbs the old exterior-hum dedup step), the settings
rename (decision 10), and virtualisation. Decisions 3, 9 and 10 were settled on 2026-07-19 and are the
current design of record - where an earlier section disagrees with them, they win.

The tuned numbers live in `Doors.SoundTuningDefaults` (`sh_sound.lua`), reached by ear against a real
interior hum through `doors_debug_sound`:

```lua
closed  = 0.250   -- fully open is 1 by construction
curve   = 1.00
falloff = 25.00   -- dB per 1000u, per halving of the doorway below 16384 square units
aim     = 0.50
```

`curve` landing on exactly 1 is worth noting: the aperture is plain linear in how open the door is, so
the sound tracks the animation with no shaping at all. The exponent stays a setting because it costs
nothing and the next consumer's door may not be a hinged pair.

## Why

A managed sound's perceived position is currently just its emitter's world position. Interiors live
thousands of units away in the void, so a sound inside the interior computes as inaudible from outside the
door - and vice versa. Nothing about the doorway enters the calculation.

Every "leak" feature therefore had to be hand-built to compensate. `cl_externalhum.lua` played a **second,
independent copy** of each interior idle hum from the exterior, so that standing outside sounded right.
Measured live, the two copies drifted: interior instance at `t=3.371` against leak copy at `t=2.133`, 1.24s
apart, on the same file. Crossing the threshold handed you a different copy at a different point in the loop.
That file is now deleted outright (decision 4), along with the exterior hum field itself.

## The model

Everything positional in the library flows through one function, `sourcePos(handle)` - distance gain, pan,
and occlusion all derive from its return. **The resolver is a change to that one function.** Every
downstream behaviour (the `SND_GetGainFromMult` port, the speaker envelope, the omni rule) keeps working
untouched.

When listener and emitter are in different spaces, the sound's **perceived position** is the doorway on
the listener's side - that is the `sourcePos` change, and it gets pan and occlusion right for free. Its
**level** is a separate matter, and is the ordinary engine falloff over the whole distance the sound
travels (source to mouth, plus mouth to listener), with the doorway then taking away in two ways:

1. **Aperture** - a flat gain. Exactly **1 when fully open**; below 1 as the door shuts, never 0.
2. **Extra falloff past the mouth** - dB per 1000 units, for each halving of the doorway below the
   size at which size stops mattering. **Exactly 0 at the mouth**, whatever it is set to, and 0 for a
   large enough opening.
3. **Directivity** - a doorway throws its sound out of the opening, so standing round the back of one
   is much quieter than standing the same distance in front. **Exactly 1 head-on**, and forced to 1 at
   the mouth itself, where the direction is meaningless.

All three vanish at the mouth with the door open, which is the invariant the model rests on: standing
in an open doorway is *identical* to standing in the room, not merely close to it. So there is no
coefficient for the open case to get wrong - it is 1 by construction, not by tuning.

**Falloff is one slider, not two.** It was briefly split into a base amount plus a size-dependent
amount, which was a mistake: the base is "attenuation even for an infinitely large opening", which
must be zero, so its only real function was to let one knob detune the other. `strength * halvings`
answers the whole question - given this doorway, what does it cost a sound coming through it - and is
correctly zero for an opening big enough to be just a hole. The size at which that happens is a
constant rather than a second slider; it is the same degree of freedom wearing a different hat
(`strength * (log2 NEUTRAL - log2 area)`), but it is pinned by a physical question instead of a dial.

**Attenuating each leg separately is wrong, and was tried first.** It reads as the physical answer -
energy reaches the opening, then re-radiates - but Source's gain curve compresses everything above 0.5,
so two short legs both sit in the flat part and together lose *less* than one long leg. Measured against
free field at the same total distance, a doorway made things **louder by up to 3.7 dB**, and the sign of
the error flipped with distance (louder to ~850u, quieter beyond), so it could not even be corrected
with a constant. Free field over the true path, then subtract, is predictable and monotonic.

## Decisions

### 1. Door state is acoustic; portal culling is not

A **closed door** is a fact about the world - deterministic, same for every player, real attenuation. Door
open/closed becomes an *aperture coefficient* rather than a switch: open is mostly transmitted, closed is
heavily attenuated but **non-zero**. Sound leaks through a shut door, just quietly and over a shorter range.

**Ride the door animation.** The coefficient tracks a continuous 0..1 openness, so the audio ramps in step
with what you see. TARDIS already animates `DoorPos` toward `DoorTarget` over `DoorAnimationTime`, and 190
of 275 interiors sit on the 0.5s base default:

```
0.000s x1 (portal)   0.250s x8    0.500s x190   0.700s x9    1.000s+ x5
0.200s x2            0.450s x5    0.600s x38    0.800s x7    2.000s x2
```

Free win: `LockedDoor.AnimPos` is a partially-open locked-door rattle, so an ajar door leaks proportionally
with no extra code.

**But floor the transition time.** Two independent things can change the aperture term discontinuously:

1. **Door openness** - gradual for 274 interiors, but `portal` is `DoorAnimationTime = 0` on both sides,
   genuinely instant.
2. **The listener changing space** - teleported in or out, or the exterior view toggle, where the door
   state does not change at all and the animation contributes nothing.

These need **two different mechanisms**, not one - trying to cover both with a single blend is what
broke it first time round.

1. **Openness is rate-limited** so it cannot traverse 0..1 faster than the floor. Everything derived
   from it inherits the limit. `portal` is then not a special case - it is just where the animation
   contributes nothing and the floor does all the work.
2. **A space change is captured as a dB step and healed to nothing** over the same floor. It cannot be
   done by blending the in-space and cross-boundary gains, because **each is only valid in its own
   space**: the instant you step out, the in-space term is measuring the emitter's world position
   across the void, so blending from it blends from silence. Observed as a dive to the noise floor and
   a climb back over exactly the floor time, on a crossing that should have been seamless. Capturing
   the step instead means a seamless crossing stays seamless - measured at -0.03 dB one unit out,
   -0.38 dB at sixty - while a real teleport still glides.

Neither rate-limits the **total gain**. That would smear ordinary distance changes and make walking
past a doorway lag behind you. The discontinuity risk is the topology changing, not distance.

**The floor is not a tunable** - it is tied to the fade-to-black on an Alt+E teleport
(`parts/door.lua`'s `ScreenFade(SCREENFADE.IN, color_black, 1, 0)`), which is the case it exists for,
so the sound finishes settling as the screen clears. Tying it to the visual rather than picking a
number by ear means the two stay together if the fade is ever changed.

Shipped at **half** that fade, 0.5s. A full 1.0s felt slow: the fade is linear from full black, so it
reads as over around its midpoint, and matching its nominal length left the audio still settling well
after the picture had arrived. It is a constant in `sh_sound.lua` rather than a slider - the panel
never offered it, because it is answered by the visual and not by ear.

**Openness is never a call-site parameter.** It is read per-frame inside the gain path, which already
recomputes distance, pan and occlusion for every channel every frame. Passing it in would be impossible
anyway - the value is stale 200ms into the sound. Call sites are unchanged by all of this:

```lua
Doors:PlaySound({ path = v.path, ent = self, loop = true, volume = v.volume or 1 })
```

That states *what* and *from where*; everything about the listener, the doorway between them, and how open
it is, is derived. This is also why decision 8 holds - there is no per-call data for a wrapper to carry.

**API consequence:** `DoorPos` lives on a TARDIS part (`gmod_tardis_part`, ID `door`), which Doors cannot
read without breaking consumer-agnosticism. Doors must *ask* for openness - a 0..1 the consumer supplies,
falling back to the boolean open/closed if unimplemented. Same shape as the leak-volume scalar in decision 7.

Doors can already traverse the relationship in its own vocabulary - the links are on its own base entities
(`gmod_door_exterior.interior`, `gmod_door_interior.exterior`) - so the consumer supplies openness and
nothing else.

**Portal culling, by contrast, must be inaudible.** A portal culled client-side for performance is a
rendering optimisation, not a fact about the world. Two players in the same spot
must not hear different things because one has portals turned down. So the resolver must **never read the
portal entity** - derive from the doorway's own transform (position + angle), which exists regardless. The
perf setting then has no audible effect at all and there is nothing to fade.

Fading is only needed for an *explicit* user toggle of cross-boundary audio, which is a separate switch.

### 2. Symmetric from the start

Written as "map between two spaces", not "map interior to exterior". Exterior sounds leaking inward (the
flight loop being the obvious case) is then the same code path with the arguments swapped. Cheap now,
awkward to retrofit.

### 3. The grouping ladder

**The default inverted on 2026-07-19, after listening.** This section originally had unpaired sounds
summing, with blending as the opt-in. It is the other way round.

| Case | Behaviour |
|---|---|
| **Counterpart pair** - an interior sound with an exterior equivalent, or vice versa | Only the listener's side is audible; crossing fades between them. **The default** |
| **Counterpart pair, declared independent** | They sum. The opt-out |
| **No counterpart** | Leaks as it does now. Nothing to collide with |

Why blend is the default: an interior hum and an exterior hum are not two sources. They are one object's
sound authored twice, for two vantage points - one for how the ship reads in the console room, one for how
it reads standing next to the box. Summing them is not realism, it is counting the ship twice. So there is
no framing in which sum is the sensible default, and the opt-out is for the rarer ship whose author really
did write two different things and wants both (the 2020 Jodie interior is the example that prompted this).

**Similarity is the real predicate and nothing can measure it**, so the default has to assume it. Two files
that are merely *similar* - the common case by far - sound like flanging or like a bug when summed, and no
code can tell "similar" from "deliberately different" by inspection. The only safe assumption is that any
counterpart pair will sound wrong played together unless the author says otherwise. Extension authors who
want both opt in; unmaintained content gets the good behaviour for free, which is the constraint that
decides this whole area.

Same-asset is no longer a separate rung. It gets identical treatment, so detecting it buys nothing - it
survives only as an explanation of *severity*: a file summed against itself is comb filtering, the harshest
version of the artefact. It is also structural rather than rare, because `cl_flight.lua:30` falls back to
`sounds_ext.FlightLoop` when an interior declares no loop of its own, and `base.lua:125` puts a flight loop
on the *exterior* section only. Roughly 170 of 275 interiors take that fallback and play the exterior's
exact file inside, at a different volume and out of phase with it.

Scoping is now free. Pairing is a counterpart relation within one interior/exterior pair by construction,
so two separate TARDISes humming the same file were never at risk of being fused.

The link is a *pair* relation and must not be folded into `tag`. `tag` is a stop-category at a deliberately
coarser granularity - `"flight"` covers 9 call sites including three mutually exclusive exterior variants -
and tags can coincide without meaning anything (`"damage"` covers 5 independent one-shots). Fusing them
means never being able to stop at one granularity and blend at another.

#### The counterpart inventory

Audited 2026-07-19 across every play site. **Every pair below is currently both-audible** - none is gated
by occupancy, view, or mutually exclusive settings. Where two settings exist (`flight-internalsound` and
`flight-externalsound`) they are independent and both default true.

| Pair | Played at | Kind | Note |
|---|---|---|---|
| `Teleport` (demat/mat/fullflight/fail/interrupt) | `sh_tp_main.lua:325-427`, `sh_tp_interrupt.lua:135`, `sh_tp_failed.lua:196` | one-shot | The set that motivated start-together alignment |
| `FlightLoop` / `Damaged` / `Broken` | int `cl_flight.lua:11-43`, ext `sh_flight.lua:568-590` | **loop** | The flying doubles |
| ~~`Idle` (int) / `Hum` (ext)~~ | `cl_idlesound.lua:17` | **loop** | No longer a pair - the exterior half is deleted (decision 4) |
| `Door` (open/close) | `sh_doors.lua:362-382` | one-shot | Whole sub-table falls back at once |
| `Door.locked` | `parts/door.lua:77-87` | one-shot | Always plays the *exterior* asset on **both** sides, so it is identical by construction - the opt-out can never apply |
| `Lock` / `Unlock` | `sh_lock.lua:110-124` | one-shot | |
| `Chameleon` | `sh_chameleon.lua:55-65` | one-shot | |
| `FlightLand` / `FlightFall` | `sh_falling.lua:134-165` | one-shot | |

Not pairs: `Teleport.demat_fail_loop` / `_stop` are interior-only (no exterior counterpart declared).

**The `int.X or ext.X` fallback is on nearly all of them** - Teleport, Door, Lock/Unlock, Chameleon,
FlightLand/Fall and the FlightLoop trio all resolve the interior asset as "the interior's own, else the
exterior's". So identical-asset is what an interior gets *by default* across the whole inventory, not just
for flight. Decision 3's note that this is structural rather than rare understates it.

**This restores an intent that already existed.** `sh_tp_main.lua:316` explains the two-copy pattern as
relying on distance: "only the copy near the current POV is audible - the same falloff and near/far
crossfade Source gave them". That was true while the far copy sat across an unbridgeable void. The
resolver made leakage symmetric and so made the far copy audible, which is what turned a working
assumption into the doubling. The mechanism here is that intent made explicit rather than emergent.

**Two schema faults found in passing**, both worth fixing regardless of this work:

- `Interior.Sounds.FlightLoop` / `FlightLoopDamaged` / `FlightLoopBroken` are **read in code**
  (`cl_flight.lua:18,26,30`) and **set by content** (`default.lua:108`) but are **not declared** on
  `tardis_interior_sound_metadata`. Since those annotations are the wiki, interior authors have no
  documentation that they can override the flight loop at all - the very field at the centre of the
  doubling.
- `Interior.Sounds.Hum` (`sh_metadata.lua:264`) is declared but **never read anywhere**. The interior's
  hum-equivalent is `Idle`. Dead schema.

#### How the exception is declared

Settled 2026-07-20. A sound field accepts **either a path or a table**, matching the `SequenceSpeed*`
precedent (`sh_metadata.lua:234`) - scalar for the default, table for control. The table is the existing
`tardis_sound_entry`, which `Idle` and `Hum` already use, so the two loop pairs get this for free.

```lua
FlightLoop = { path = "jodie/tardis/flight_int.wav", through_doors = 0.6 },
```

`through_doors` is **a number, not a flag**. Absent, the system decides - decision 3's rule, so a pair
swaps and an unpaired sound leaks. Set, the author overrides with a level.

Naming a boolean was tried at length and every candidate failed, which turned out to be a symptom rather
than a naming problem: a flag asks the author to *categorise* ("is this distinct? is it a pair? does it
leak?"), and that is a judgement about the very predicate decision 3 admits is fuzzy. Rejected in order -
`play_both` describes the mechanism and describes it wrongly, since both members always play and only
audibility changes; `leak` reads as something every author would want (everything already leaks - the flag
really means "leak *despite* being a pair") and re-adopts the vocabulary decision 10 is retiring;
`standalone` inverts on reading, sounding like "play this one alone"; `distinct` was the best of them but
still asks for a classification.

A number asks instead how much of the sound should be heard from outside, which an author can answer by
ear. It is also strictly more expressive: the Jodie case does not just get "both play", it gets both at a
level that sounds right, which is likely the difference between summing working and merely happening.
`0` becomes meaningful too - seal an *unpaired* sound in, which no boolean could express. And it joins the
knob family from decision 10 rather than being a one-off concept, sharing vocabulary with the player's
`sound_through_doors`.

Also considered and rejected: an enum naming the relationship (`counterpart = "distinct"`) - more surface,
and it still demands the classification; and one blanket flag per interior - tempting because a bespoke
interior is characterised by bespoke audio, but an interior with its own flight loop still inherits Door,
Lock and Chameleon from base as identical assets, so a blanket flag would mark those distinct and double
them. It fails in the direction that reintroduces the bug.

**Both members play throughout; only audibility changes.** They start together where the event allows it,
which is what makes a mid-sound swap safe for one-shots: a demat heard from inside and the same demat heard
from outside stay time-aligned for their whole length, so crossing halfway through selects between two
synchronised renderings rather than splicing two recordings at an arbitrary join. Loops need no such care -
they have no meaningful position, which is decision 5. One mechanism covers both. The cost is a channel per
pair whether or not the far side is ever heard, which is the first real argument for virtualisation
(decision 6).

### 4. The exterior hum is deleted, not deduplicated

Settled 2026-07-20, replacing a plan to drop it only where it duplicated an interior hum. The field
`Exterior.Sounds.Hum`, its `external_hum` setting, and `cl_externalhum.lua` are gone.

**The scan, of all 275 registered interiors.** 128 set an interior hum; 13 set an exterior one; none set an
exterior hum without an interior one, so removing it can never leave a TARDIS silent outside. Of the 13,
only 4 name the same file as their own interior hum - but heard side by side, **11 of the 13 are the same
sound rendered quieter**, including every one that names a separate file. Only `trakenclock` and
`assassinclock` are genuinely different material: a clock face ticking, which is the shell's own voice and
not the interior at any volume.

**So the same-asset predicate is dead.** It catches 4 of the 11, and nothing else measurable separates a
re-exported copy from a distinct sound. Only ears did. Do not rebuild it - a heuristic here either silences
a clock or leaves a duplicate, and there is no third outcome.

**Why deleting beats keeping it for the two.** Both members were already declared a counterpart pair, so
standing outside suppressed the interior hum in favour of the exterior one. For all 13 that meant opening
the door did nothing: a static quiet hum from the shell instead of the interior swelling through the
doorway. The field was not merely redundant, it stood in front of the feature that replaces it - and it did
that for 11 interiors whose authors only ever wanted "the hum, but quieter from outside", which is now what
the doorway produces by itself.

Keeping the field for two interiors means keeping a whole authoring concept, a player setting and a module
alive to serve content that would be better expressed as an exterior-owned ambient sound with
`through_doors` set - which is decision 3's mechanism, not this one's. If that need is confirmed it comes
back under a field that means what it says, rather than one named for a hum.

**Known consequence, accepted.** `trakenclock` and `assassinclock` lose their ticks. Both are from
[Torrent's Classic TARDIS Pack](https://steamcommunity.com/sharedfiles/filedetails/?id=2931571340)
(`2931571340`), whose author has been contacted; the deletion stands unless he says otherwise. Every other
affected interior gains the door-dependent swell it never had.

The interior side keeps its `Idle` sounds and loses only its `pair`/`through_doors` arguments, which
addressed a counterpart that no longer exists - a pair of one is inert (`#group < 2`), and
`through_doors` exists only to override pair suppression.

### 5. No phase sync - the content has no phase to align

**Investigated and dropped.** The plan was for paired members to share a clock: nominate a master, and
silently re-assert the inaudible member against it when the blend factor starts to rise, so they are in
phase by the time both can be heard.

The content does not support it. Of the 105 interiors with a distinct interior *and* exterior `FlightLoop`,
38 pairs are measurable and **33 have mismatched lengths**, most of them wildly:

```
1.72s vs 54.62s   drmatt/tardis/flight_loop.wav | FuzzyLeo/.../BBC_TARDIS_Flying_Loop.wav
1.70s vs 50.76s   minibox/torrent/flightloop.wav | minibox/torrent/flightloopint.wav
1.72s vs 37.09s   drmatt/tardis/flight_loop.wav | FuzzyLeo/.../coral_inflight.wav
6.43s vs 56.37s   torrentcoolydude/flight_loop.wav | torrentcoolydude/flight_loopint.wav
1.72s vs  1.59s   drmatt/tardis/flight_loop.wav | p00gie/tardis/default/flight_loop.wav
```

`drmatt/tardis/flight_loop.wav` (1.72s) is the near-universal exterior loop, paired against interiors from
1.59s to 56s. A 1.72s loop against a 37.09s one wraps 21 times per interior cycle, so "the same position"
means nothing. These are not two mixes of one performance - they are independent ambiences that both happen
to mean "flying". There is no phase relationship to preserve because there never was one.

So crossfading blends **gains only**, and needs no alignment. Phase sync would be a future opt-in for a
genuinely same-performance pair; none exist in current content, and even the 5 length matches are more
likely coincidence than intent.

Related and still true: the two flight loops already pitch-shift on the **identical** curve (same 95..110
range, same divisor, and the interior reads velocity off `self.exterior` - literally the same number). The
only divergence is the exterior's **doppler** term, which must *not* be forced onto the interior: inside
the TARDIS you move with it, so there is physically no doppler. With sync dropped there is no reason to.

### 6. Virtualise at distance rather than destroy

A managed channel currently plays forever, at negligible volume, however far away. Culling is wanted - but
**destroying fights the ownership pattern**: loops poll `if not self.flightsound then start it`, so a
library-side stop is recreated by the owner's next Think, giving create/destroy every frame at range.

So **virtualise**: keep the handle (the owner sees it and does not recreate), free the BASS channel, reload
on return. The SP-pause watcher already parks and unparks channels this way. Culling stays entirely inside
the library; no call site learns about distance.

The trigger must be **perceived** distance from the resolver, never world distance - culling on world
distance would re-break the original bug. Needs hysteresis (a gain floor sustained for N seconds, unpark
nearer than you park) so it does not chatter at the boundary. Restart-at-0 on return is fine: at that gain
it is inaudible either way.

### 7. Where the user setting lives

**Half superseded by decision 10.** Where the setting lives - TARDIS-side, mechanism in Doors - still
holds. What the player gets does not: it is a bool, not a slider, and the amounts moved to the interior.

With the resolver this stops being hum-specific - it is cross-boundary audio in general. The **mechanism**
belongs in Doors; the **user option** stays TARDIS-side, with Doors taking a scalar (or callback) from the
consumer. Keeps Doors consumer-agnostic and keeps one slider in the TARDIS menu.

The existing `interior_hum_leakage_volume` is the model to follow, and the setting to generalise - it stops
being hum-specific and becomes the leak volume for all cross-boundary audio. **Carry existing values across
on rename** rather than resetting to the default; anyone who changed it did so deliberately.

A solid default matters more than the knob. Tune it in a rig first, then expose it.

**Tune the closed-door coefficient early and by ear.** No interior has an exterior hum any more
(decision 4), so leakage is the *only* way any of them is ever heard from outside - it is the sole path for
every TARDIS, not an edge case.

### 8. Consumer-specific logic goes in provider hooks, not a TARDIS wrapper

Re-examined when the resolver introduced two consumer-specific inputs (door openness, leak volume) and
rejected again, more firmly.

Both inputs are **per-entity or per-config, not per-call**. A wrapper wraps a call site; wrapping 68 of them
to supply information no individual call knows about is the wrong axis. Instead:

- **Openness**: Doors already owns `gmod_door_exterior`, which the consumer's exterior extends. It is a
  virtual method on an inheritance relationship that already exists - base returns 0/1 from the boolean,
  the consumer overrides it. No wrapper, no call-site changes.
- **Leak volume**: one registration at load.

The job previously imagined for a wrapper - folding in the master `sound` gate - does not survive contact
with how that gate is actually used. 25 gate sites across 15 files against 68 play sites, and:

- The master gate is almost never alone; it is ANDed with a per-feature setting (`teleport-sound`,
  `doorsounds-enabled`, `locksound-enabled`, ...) that must stay at the call site anyway. The `if` remains
  either way.
- It gates more than playing: stopping a loop (`sh_repair.lua`), a predicate feeding a Think
  (`ShouldPlayFlightSounds`), and non-`PlaySound` audio (`sh_music.lua`). A play-wrapper reaches none of
  those, so consolidating there splits gating across two conventions.
- Some sounds **deliberately bypass** the master gate (damage, explosions). A wrapper applying it
  universally would be a silent behaviour change.

A wrapper would add a layer while eliminating none of the existing checks.

### 9. The listener is the camera, not the body

`resolve()` measures everything from `EyePos()` - path distance (`sh_sound.lua:528`, `:553`), directivity
(`:570`), the occlusion trace (`:805`) - but decides *which side of the boundary you are on* from
`ply.doori` (`:535`), which is the player's body. Those disagree whenever a view mode moves the camera
away from the body, and the result is incoherent: distances measured from one place, space classified from
another.

This is not a corner case, it is the piloting view. TARDIS third person routes through `SetOutsideView`
(`sh_thirdperson.lua:68`) and anchors the camera to the **exterior**, not to the player -
`self:LocalToWorld(Vector(0,0,60))` traced back 90 to 500 units (`:29`, `:87`). So flying in third person
means the resolver measures from a camera at least 90 units outside the box while classifying the listener
as standing in the console room.

Keying the side off the listener fixes it and puts us back in step with the engine, whose own sound
listener follows the view - `ply.doori` was the odd one out.

No hysteresis needed. The camera is anchored to the exterior at a 90-unit minimum, so it cannot hover on
the boundary and flap between spaces.

**But the transition is not one mechanism.** This section first claimed that changing view should be
smoothed by the same glide as walking, "one mechanism for every way the listener can change side". Built
and heard, that is wrong: the camera cuts instantly and the sound arrives half a second later, so the
glide reads as the sound lagging the picture rather than as anything being smoothed. A move has travel for
a glide to cover; a cut has none.

So a view change gets a 40ms ramp instead of the 0.5s glide - short enough to read as a cut, long enough
that the gain step (0.62 to 0.03 through a shut door, measured) does not click.

Classifying the two is subtler than it looks, and two obvious tests both fail:

- **Comparing the camera's space to its body's.** They agree again the instant the view switches back, so
  returning to first person would read as a move.
- **Looking for a jump in position.** Walking through a portal teleports the camera exactly as far as any
  cut does.

What does separate them is a change in *whether the two agree at all*: true when a view is switched in
either direction, false when walking, where camera and body cross together. That also makes it robust to
the two updating a frame apart.

### 10. Players get a switch; authors get the numbers

Settled 2026-07-19, and it supersedes the "how much leaks" half of decision 7.

The player-facing setting is a **bool**, `sound_through_doors` - plainly named, because "cross-boundary
audio" is our vocabulary and not a player's. Every *amount* is content, owned by the interior. TARDIS
already works this way almost everywhere: it gates sounds on and off and leaves their volume to the
interior, so this is the existing precedent rather than a new pattern.

That puts the whole weight on the default. If most extensions never set these - and many are unmaintained -
the shipped default *is* the experience for the overwhelming majority, so it wants tuning as the product,
not as a fallback.

**Three knobs for authors, not four.** The four tuning values are not the same kind of thing:

- **`volume`** (overall scalar) and **`closed`** (how much passes through a *shut* door) and **`falloff`**
  (how fast it dies with distance) are *content*. A wooden police box and a sealed blast door genuinely
  differ, and a cathedral carries sound differently from a cupboard. Exposed.
- **`curve`** (how aperture responds to the door opening) and **`aim`** (directivity) are *physics*. They
  should not vary per ship, and they are precisely the two an author cannot hear in isolation or reason
  about. Locked global. Adding a knob later is easy; un-shipping one that content already sets is not.

**Relative multipliers, not absolute values.** With absolutes, every retune of the global default strands
every interior that set an explicit number in the old world - the unset majority moves and the customisers,
who are exactly the maintained extensions, get left behind. With multipliers everyone moves together and a
ship authored as "leakier than standard" stays that way, which is what the author meant: they are
expressing character against a norm, not taking physical measurements. Nobody knows what 25 dB per 1000u
per halving sounds like. Clamp to a sane range so a broken extension cannot set 1000.

**The size derivation is the default, and the knob scales it.** Falloff already varies per interior
automatically, from doorway area against `SIZE_NEUTRAL` - free, automatic, and right for unmaintained
content. The author knob multiplies that rather than replacing it, for the case where the geometry lies: a
wide doorway into a small sealed room, or a narrow one into a cathedral.

**Per direction**, which is the first deliberate break of decision 2's symmetry. Genuinely asymmetric in
the fiction as well as the physics: a TARDIS interior is meant to be sealed from the world, while the world
is meant to be plainly audible from just inside an open door. `res.inside` already says which way a sound
is travelling, so the hook can simply take it. One asymmetry, not two number sets free to drift apart.

Since the three knobs plus a direction no longer fit in a single returned scalar, `GetCrossBoundaryVolume`
becomes a profile-returning hook, where absent fields mean "use the global default" so unmaintained content
costs nothing. TARDIS-side, a module reads the interior metadata, applies the player bool, and hands Doors
the profile. That is the one place a consumer-side wrapper is justified, and it does not contradict
decision 8: it wraps *configuration*, which is per-entity, not call sites.

**Migration** (done 2026-07-20, `sound-through-doors`). Only the switch carries: once amounts are content
there is nowhere for a customised volume to go, so the slider is simply removed. The one exception is a
volume of **0**, which said the same thing as switching it off and would otherwise hand back a sound the
player had silenced - it migrates to `sound_through_doors = false`.

Unlike `sh_icons.lua:405`, the old keys are **not** cleared. Moving between beta and release is a normal
thing for this addon's users to do, and leaving `interior_hum_leakage` in place means release keeps a
working setting while beta uses the new one. A few dead keys is the cost.

That flow also turned up a latent data-loss bug worth knowing about, now fixed: `SaveSettings` used to skip
any key with no registered `SettingsData`, and `LoadSettings` saves immediately on load - so booting a build
that did not know a setting **erased it from disk at once**. Every rename the addon has ever shipped lost
its migrated value for anyone who went beta -> release -> beta, silently. Unknown keys are now written back
untouched.

This was briefly blocked and no longer is. Migrations used to gate on a version comparison, which meant a
migration written here would never have run for beta users - `2026.1.0` was already published to the beta
item, so their stored version already equalled any gate we could author. That was fixed on `main` (issue
#1151): `AddMigration(name, date, func)` now takes an ISO `YYYY-MM-DD` authoring date, records each
migration in `tardis/migrations_{sv,cl}.txt` as it succeeds, and retries a failure on next load instead of
skipping it forever. Use the date signature; there is no version to reason about.

## Settled while building

- **The aperture curve and its coefficients.** Tuned by ear; the numbers are at the top of this file.
  Most of it settled by construction rather than by ear: **open is 1** because every doorway term
  vanishes at the mouth, and **size feeds the falloff, not the gain** (see Do not re-attempt).
- **Resolving an arbitrary emitter to its space.** `spaceOf` walks the parent chain: an interior emits
  from itself, and anything a consumer builds onto either side is parented to it (TARDIS parts at
  `sh_parts.lua:792`). An exterior stands in the world unless parked inside another interior, which
  Doors already tracks as `insideof`. Only an unparented emitter or a fixed `pos` falls through to a
  containment scan over `Doors:GetInteriors()`, which is why that comes last. Not cached: the walk is
  two hops for every real case, and an emitter can change space at any time.
- **Which boundary a sound is resolved through**, once both listener and emitter can be in interiors.
  Always the **sound's own** interior when it has one, because a sound radiates out through the doorway
  of the space it is in; only a sound already in the open world uses the listener's doorway instead.
  That rule also gets nesting right for free - a shell parked inside another interior has its far
  doorway genuinely opening into the room the listener is standing in, so the second leg is a real short
  distance rather than a void crossing.
- **The exterior's doorway transform client-side.** Doors now networks both sides' geometry at player
  init (`sh_portals.lua`) and answers from it through `GetDoorway()`, so the resolver never reads a
  consumer's metadata. A consumer only overrides `GetDoorway` if its doorway *changes* - Safe-Space
  does, since its portals are resizable.
- **Path distance is the true path through the mouth**, not a straight line: emitter to the nearest
  point on its own doorway, plus the listener's doorway to the listener.
- **Which space the listener is in** is `ply.doori`, not `LocalPlayerInside()`. Interiors nest, so the
  latter is true all the way up the chain - it answers "somewhere within" rather than "which space".
  Verified live with one TARDIS parked inside another. **Superseded by decision 9** - the right answer is
  the space containing the *camera*, not the body; `ply.doori` remains correct only while the two agree.

## Open questions

- How the blend factor is exposed. It replaces today's **binary occupancy check** with a continuous value,
  and a few call sites currently branch on occupancy - they need auditing.
- **How far to widen the union.** `through_doors` is settled, but not which fields accept the table form.
  The top-level pair fields (the `FlightLoop` trio, `FlightLand`, `FlightFall`, `Lock`, `Unlock`,
  `Chameleon`) are cheap - `Idle` and `Hum` are already entries. The nested ones are not: `Teleport` has
  ~15 sub-fields and `Door` has three, each inside its own class. Doing only the cheap ones leaves the
  schema mixed, which is what the table form was meant to end.
- **Turning a string field into a table changes override semantics**, from replace to `table.Merge`'s deep
  merge - so an interior overriding only `path` would inherit a parent's `through_doors`. Not live today
  (no base sound field is a table, and the two that can be, `Idle` and `Hum`, are unset in base) but it
  arrives with interior-to-interior inheritance. This project already hit exactly this: the teleport
  sequences are swapped to `*Saved` in `PreMergeExteriorMetadata` to stop the deep merge. Watch for it
  rather than pre-building the same workaround.
- **Only managed channels cross.** The engine cannot reposition a sound already in flight, so a plain
  `EmitSound` still stops dead at the boundary. Everything long is already managed, so what this leaves
  out is one-shots - which is the "capturing arbitrary sounds" section below.

## Implementation order

0. ~~**Tuning rig** for the aperture curve and minimum transition time, before the defaults get baked
   in.~~ **Built** - see Testing.
1. ~~**Resolver core** in Doors: `sourcePos` resolves through the doorway transform, two-stage aperture,
   symmetric in both directions, independent of the portal entity.~~ **Built** - `resolve()` in
   `sh_sound.lua`, computed once per frame per handle and left on it for the panel to read.
2. ~~**Consumer scalar** so the aperture/leak volume is driven by a TARDIS setting.~~ **Built** -
   `gmod_door_exterior:GetCrossBoundaryVolume()`, the same provider-hook shape as `GetDoorOpenness`.
3. ~~**Delete `cl_externalhum.lua`'s hand-built leak** - the second copy and its `LeakedInteriorHums`
   table.~~ **Done**, along with `cl_idlesound.lua`'s `PlayerEnter` ramp, which existed only to hand
   over from that copy. Leaking is a property of the geometry now.
4. ~~**Exterior hum dedup**~~ **Done** - deleted the feature outright instead; see decision 4.
5. **Counterpart pairs** - one side audible at a time, fading across the boundary. **Design settled
   2026-07-19; see decision 3.** The rungs below are the reasoning that got there, kept because the
   default reversed twice on the way.

   **This one is now urgent rather than nice-to-have.** The resolver made leakage symmetric, so the
   *exterior* flight loop is newly audible from inside, on top of the interior's own - 105 interiors
   have a distinct loop on each side, and they now sum where previously the exterior one was inaudible
   across the void. That is decision 3's undeclared-pair default doing exactly what it says, applied to
   a pair that should have been declared. Flying is the case to listen to first.

   **Judged live, and the split is not where the plan assumed.** Summing sounds *good* where the two
   loops are genuinely different material - the 2020 Jodie interior was called out as working really
   nicely - and bad where they are similar loops running out of phase, which reads as flanging or as a
   mistake rather than as two sources. So the thing that needs declaring is not "these are a pair" so
   much as "these are the same idea twice". Two consequences worth carrying into the design:
   - Inferring the link from the interior/exterior counterpart fields would catch the Jodie case too
     and make it worse, so inference alone is not enough - or the default has to be *sum*, with the
     crossfade opted into per pair.
   - Similarity is the actual predicate and nothing currently measures it. Same asset is the trivially
     detectable end of it (13 interiors, step 4); "different file, same idea" is the common case and
     may just have to be authored.

   **Resolved: assume it, do not detect it.** Similarity being unmeasurable is not a reason to fall back
   to summing - it is the reason the *default* has to be blend. Any counterpart pair is assumed to sound
   wrong played together unless the author declares otherwise, so inference is right after all: it decides
   the default, and the opt-out handles Jodie. The earlier objection only held while inference was the
   sole mechanism. Detecting same-asset was then dropped too, since it earns nothing once both branches
   behave identically.

   **Step 4 no longer overlaps this.** The plan was for `Idle` / `Hum` to be the general rule's easiest
   pair, but the exterior half turned out to be a quieter copy of the interior one in 11 of 13 cases and
   was deleted rather than paired (decision 4). Interior idle hums now have no counterpart at all and
   simply leak.
6. **Virtualisation** on top of the resolver's perceived distance. Promoted from "can wait" - decision 3
   keeps both members of every pair playing whether or not the far side is audible.

## Which addon this belongs in

Doors, for now. The question is worth asking because a portal is what makes two distant places
acoustically adjacent, and that sounds like world-portals' job - but only half of it is.

- **Crossing a portal** is a geometric transform between two linked frames, and would generalise to
  any portal pair. That half is world-portals-shaped.
- **A doorway as an acoustic aperture** is not. Openness, aperture, directivity and above all *which
  space the listener is in* are all Doors concepts: `doori`, `DoorInterior`, a door's animation
  position. world-portals has no notion of a listener being inside anything.

There is also a constraint pushing the other way: this must **never read the portal entity** (see
decision 1), because it is client-side perf-culled and two players in the same spot must not hear
different things. The model uses the doorway descriptor instead, which exists whether or not a portal
is spawned. Putting the mechanism in world-portals would sit it right beside the one object it is
forbidden to depend on.

**The trigger to revisit:** when sound needs to cross a portal that is not a Doors doorway. Until
then, a world-portals layer would have exactly one consumer.

## Later: capturing arbitrary sounds, not just declared ones

Everything above moves *declared* sounds across the boundary - an interior's hum, a flight loop. The
obvious next step is to capture **any** sound occurring in one space and re-radiate it through the
doorway: footsteps and voices heard from outside a TARDIS, a firefight outside heard from within.

That is what would make this pay off for the other Doors consumer. Safe-Space ships no sounds of its
own today, so nothing there currently exercises any of this - but its doorways are user-resizable up
to 5000 a side, which is precisely where the size term stops being marginal. Measured at influence
0.5: 7.46 dB/1000u at its smallest mouth against **0.07** at its largest, i.e. an opening that big
attenuates nothing and the sound carries out as though the doorway were not there. That falls out of
the model rather than being special-cased, which is a good sign for it.

The enabling mechanism already exists: the client-side `EntityEmitSound` hook exposes `SoundName`,
`Volume`, `SoundLevel` and `Entity` for every sound before it plays, and returning false suppresses
it. So a sound emitted in the space you are *not* in could be swallowed and replayed as a managed
channel through the resolver. Known risks: every footstep becomes a candidate, so it needs a filter
rather than a blanket capture; the per-sound cost is real; and one-shots are short enough that the
managed channel's async load latency may be audible where a loop's is not.

## Testing

### The tuning panel

`doors_debug_sound`, a Doors debug module that ships (`lua/doors/libraries/cl_debug_sound.lua`). It
lives in the context menu, so holding C adjusts and releasing C walks. Everything keeps updating either
way - it is driven by a global Think hook rather than by the panel - which is what makes it usable while
moving, and moving is how falloff is judged.

**It is a viewer, not a prototype.** The model lives in `sh_sound.lua` and leaves its per-frame result
on each handle as `handle.res`; the panel only reads that, so what it shows is exactly what is playing.
Its sliders write `Doors.SoundTuning` live and every managed sound picks that up on its next frame, so
the numbers get judged against a real interior hum rather than a test tone. The list is
`Doors.ActiveManagedSounds`, and picking a row points the readouts, the plot and the world marker at
that sound. A test sound is there for when nothing else is playing; its SNDLVL and volume sliders are
the only ones that touch a handle directly, and they grey out unless it is the one in focus.

It started life as a prototype that owned a real handle's `pos`/`base` and cleared its `level`, which is
what let the model be developed before it existed anywhere. Once the model shipped, keeping that would
have meant two implementations drifting apart.

Holding the door part-open is done by overriding `GetDoorOpenness` on that one exterior instance and
clearing it on close, rather than by adding a debug path to the library. The doorway-size knob is gone
with it: a Safe-Space doorway is resizable over four orders of magnitude, so size is better exercised
with real geometry than with a faked number.

**Everything is measured from the sound, along the path it actually travels** - straight when you share
a space, out to the mouth and on to you when you do not. This is the one decision that makes the panel
readable, and it was got wrong twice first:

- **Ratios drift; use absolute levels.** Judging the resolved gain against the same path length folded
  straight seems reasonable and is not. The resolved path is attenuated twice with one leg fixed, so
  in the far field it decays *slower* than a single attenuation over the sum, and the ratio climbs as
  you walk away - in either direction, on either side. Measured inside: +0.08 dB at the mouth drifting
  to +2.6 dB 300u in, none of which is about the doorway. The panel now shows what you actually hear
  in dB, plus what the doorway costs (`20*log10(aperture)`), which holds still while you move because
  it depends only on the tuning.
- **Distance from the doorway means opposite things on the two sides.** Inside, walking to the door is
  walking *away* from a sound in the middle of the room. An axis keyed to the doorway therefore runs
  backwards on one side of it. Keyed to the sound, it is monotonic everywhere.

So the graph is one continuous curve of level against distance from the emitter: plain falloff up to
the doorway, the through-the-doorway falloff beyond it, and a faint line continuing the undoored
falloff for comparison. The step down at the doorway line *is* the aperture, and the widening gap to
the faint line is the extra attenuation - both tunables visible at once. dB up the side, since linear
gain squashes everything interesting into the bottom pixel. Verified monotonic across the boundary:
`-0.0 / -0.4 / -3.3 / -6.0` in the room, a -0.5 dB step, then `-6.6 / -8.2 / -16.9 / -21.7` outside.

A plot draws gain against distance for both paths, so the falloff tightening is visible rather than
walked, and a world marker sits on the sound's **true origin** - not the doorway the model resolves it
to, which across a boundary is a different room. It draws inside portal passes, so from outside it shows
through the doorway, sitting where the sound really is.

### Content

Mid-file loop markers are rare - a full scan of all 275 interiors (721 readable wavs) found **three**:

| Interior | Asset | Marker | Notes |
|---|---|---|---|
| `rtd60` | `uriel/rtd2/.../hum_thebridge.wav` | 2.0221s / 10.99s | The real test case |
| `type35` | `jorj/type35/type35hum.wav` | 0.1625s / 22.27s | Edge case - only just over the 0.15s crossfade |
| `baker_1975` | `liam.T/baker/flight_loop.wav` | 0.0029s / 3.60s | Under threshold, stays a whole-file loop |

**Mouth sizes**, measured across all 275 interiors (the smaller of each pair of portals):

| min | p5 | p25 | p50 | p75 | p95 | max |
|---|---|---|---|---|---|---|
| 1360 | 2280 | 3563 | **3864** | 4141 | 4759 | 12420 |

`Diamond` is the smallest, `gnome` the largest - 9.1x apart, but p5 to p95 is only about 2x, so mouth
size barely separates the common case and mostly distinguishes the two tails. Worth knowing before
spending long tuning the size term: across 90% of content it does very little.

**The reference size must not ship as a Doors constant.** It would be a TARDIS fact baked into a
consumer-agnostic addon - and it is not needed anyway, because it is algebraically redundant with the
tilt: `tilt = falloff * (ref/area)^n`, so scaling `ref` by *k* multiplies every tilt by *k^n*, exactly
cancelled by dividing `falloff` by the same. Only **n** and the tilt at some anchor carry meaning. The
median above is a tuning anchor for the rig, nothing more.

That also makes **n the one number that generalises across consumers** - Safe-Space is the other Doors
consumer and populates the same `Portal` dimensions, so it gets this for free, at whatever sizes its
own doorways happen to be. Which is an argument for not over-fitting n to TARDIS's narrow spread.

**Interior volumes above 1 are common and were always being clamped.** A scan of 137 registered idle and
hum entries found **24 above 1** - TUAT, DW Exp. Bradley, RUTH, NOVA, Artonym's, Wooden and both
SlickWine TARDISes at 10, and Witse Tardis / The Silence's Time-Ship / `sellingrope` / `spaceshit` at
**50**. `CSoundPatch::ChangeVolume` caps its target at 1 before anything else touches it and `PlayEx`
routes through the same call ([soundenvelope.cpp:417](https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/soundenvelope.cpp)),
so an author who wrote 10 heard exactly what 1 gives and had no reason to notice. A managed channel
amplifies instead, which made those interiors 20-34 dB too loud until the library reproduced the cap.

Note *where* it caps: the caller's volume, not the result after distance attenuation. Capping the result
instead would make an over-1 volume carry roughly ten times as far rather than do nothing, which is a
completely different behaviour - and the plausible one, which is why it was worth checking rather than
assuming. Confirmed both ways: no audible difference between volume 1 and 10 on the same emitter 1200u
out, where the distance gain is about 0.1 and an uncapped 10 would have been ~19 dB louder.

Worth remembering before trusting any authored number in an interior definition: the engine has been
quietly correcting content for years, and each place the port replaces the engine has to correct it too.

`rtd60` is the one to test with: its idle hum is audible both inside and (via leakage) outside, so it
exercises the resolver on both sides of the same sound.

The panel's own test sounds are `p00gie/tardis/default/hum.wav` and `drmatt/tardis/flight_loop.wav`,
picked as two long loops that were to hand. They are the only TARDIS-specific thing in a Doors module,
and deliberately so: any other path can be typed into the box, and nothing there reads a consumer's
content.

## Do not re-attempt

- **Lua-timed loop-point correction.** GMod exposes no loop-region API, the observable position is not the
  audible one, and these files open with near-silent fade-ins. Solved by trimming the body to `data/` and
  letting BASS loop it whole-file, with the intro crossfading in.
- **Keying cross-boundary audio off the portal entity.** It is a client-side perf optimisation; making audio
  depend on it means two players in the same spot hear different things.
- **Culling on world distance.** That is the original bug.
- **Assuming an authored volume is already in range.** The engine caps volume at full scale, so content
  carries values like 10 and 50 that have never once been heard as written. Anywhere the library
  replaces an engine behaviour, check whether that behaviour was silently correcting the input.
- **Deriving which way a doorway faces from its geometry.** Pointing the normal away from the middle
  of the entity the doorway sits in looks more robust than trusting the authored angle, and is worse
  in both directions. A free-standing doorframe has its mouth essentially at its own centre, so there
  is no "away" to find - measured on a Safe-Space frame the test came out at exactly 0.000 and decided
  the facing on a rounding error. On an interior it gets the answer backwards and points the normal
  out through the wall. Use `Portal.ang`'s forward: it already points into the space you stand in to
  use the doorway, out into the world for an exterior and into the room for an interior.
- **Treating a doorway as a point.** Harmless at TARDIS scale (a 50x92 door's corner is 52 units from
  its centre) and badly wrong beyond it: a Safe-Space doorway may be 5000 a side, where the corner is
  3536 units out, so a centre-based distance calls you far away while you stand in the opening. Use
  the nearest point on the doorway rectangle - clamp into it in the doorway's own space.
- **Attenuating each leg of the path separately.** The intuitive two-stage reading, and wrong against
  Source's own gain curve - see The model. It made a doorway *increase* level by up to 3.7 dB, with the
  error changing sign at ~850u.
- **Feeding doorway size into the aperture gain.** Size belongs in the falloff, not the flat gain: a
  gain term shifts the whole curve including the mouth, which breaks the one invariant that matters
  (an open doorway costs nothing). A small mouth should make the sound *carry less far*, not be quieter
  where you stand in it.
- **Crossfading the in-space gain against the cross-boundary one** to smooth a space change. Each term
  is only valid in its own space, so the moment you cross, one of them is measuring across the void -
  the blend dives to the noise floor and climbs back over the transition time. Glide from the level the
  sound was already at instead; see decision 1.
- **Holding that glide as a fixed dB step captured once.** The obvious way to write it, and it shipped
  briefly and hurt: crossing a doorway *moves the listener*, so the gain it was calibrated against is
  gone by the very next frame and the offset multiplies whatever replaced it. Measured over 12
  crossings, the exterior flight loop reached a x922 multiplier and a channel volume of **323** against
  a ceiling of 1 - about 50 dB into a hard clip, which is heard as a burst of noise rather than as
  something loud, and is genuinely painful. Re-measure the ratio against the *current* gain every frame
  so the result is an interpolation between two attenuations and cannot leave that range. The
  multiplier itself then looks absurd (750,000x is normal when the raw gain has collapsed toward zero)
  and that is fine - the product is what is bounded, not the ratio.
- **Trusting a probe that never saw the event.** The first attempt at measuring this reported a peak
  multiplier of x1.00 and a peak volume of 0.49, which reads as complete exoneration and was nothing of
  the sort: zero crossings happened in its window. Count the *triggering event* alongside the symptom,
  or a quiet result is indistinguishable from a clean one.
- **Raising SNDLVL to tighten falloff.** It does the opposite - a higher sound level travels *further*
  (75 -> 85 took a 600u reading from -11.4 dB to -1.2 dB). Extra attenuation is applied as its own dB
  term, not by moving the level.
- **Writing a channel's volume from anywhere but `applyGain`.** A caller's volume is the pre-distance one;
  writing it straight to the channel plays far-off sounds at full volume.
- **Resolving through the listener's boundary when the sound has one of its own.** It looks symmetric
  and breaks nesting: a shell parked inside another interior has a sound two doorways from a listener
  outside, and only the sound's own doorway leads anywhere real. Its far side then opens into whatever
  room the shell is standing in, which is the answer either way.
- **Calling `sourcePos` more than once a frame.** It is not a getter - it carries the pin-on-teleport
  and attach handovers, which must happen exactly once. `resolve()` caches on `FrameNumber()` for that
  reason as much as for cost, and everything downstream reads its result rather than re-deriving.
- **Caching anything view-derived on `FrameNumber()` alone.** `EyePos()` is not stable across a frame:
  crossing a doorway teleports the camera *between* two of the same frame's `resolve` calls, measured
  directly - one call saw the camera inside and the next two saw it outside, same frame number. The
  listener-space cache was keyed on the frame, so the sounds resolved after the teleport were told the
  listener was still in the room they had just left. Listener and sound then read as sharing a space,
  which takes the doorway out of the path and measures the sound straight to its own room thousands of
  units away - one frame of silence, which the glide then starts from, so a crossfade plays only its
  second half. Key such a cache on the values it was computed from (camera and body), not on the frame.
  Note the body is *not* the culprit: `ply.doori` had already cleared on the first call.
- **Diagnosing this class of bug from a neighbouring hook.** Six consecutive wrong diagnoses here, each
  from deriving what a value "must have been" out of quantities sampled in a `Think` probe beside the
  code. It resolved on the first look at the values *where they are computed*. Where a per-frame cache
  or hook ordering is in play, an outside sampler cannot tell a stale read from a fresh one - log inside
  the function, and A/B the fix by reverting only it and re-running the same automated repro.
- **Phase-syncing paired interior/exterior loops.** 33 of 38 measurable pairs have mismatched lengths (see
  decision 5); there is no shared timeline to align to. Crossfade gains only.
- **A TARDIS-side wrapper over `Doors:PlaySound`.** Rejected twice; see decision 8. Consumer-specific
  inputs are per-entity or per-config, so they belong in provider hooks.
- **Overloading `tag` as the alternates link.** It is a stop-category at a coarser granularity, and tags
  coincide without meaning anything.
