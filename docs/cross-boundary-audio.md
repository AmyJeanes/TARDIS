# Cross-boundary audio - design and plan

Phase 3 of the sound rework ([#382](https://github.com/AmyJeanes/TARDIS/issues/382)). The mechanism lands in
the **Doors** addon (`lua/doors/libraries/sh_sound.lua`); this document is the plan, so it may name TARDIS.
Doors' own code and docs stay consumer-agnostic - generic interior / exterior / portal vocabulary only.

Status: **the resolver is built and tuned.** Done and on the `sound-rework` branch: managed BASS channels,
the central hub, looping with mid-file handover, all 13 loop call sites migrated onto it, and then steps
1-3 below - the resolver itself, the consumer volume scalar, and the deletion of the hand-built leak.
What remains is the exterior-hum dedup, alternates, and virtualisation.

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

Every "leak" feature therefore has to be hand-built to compensate. `cl_externalhum.lua` plays a **second,
independent copy** of each interior idle hum from the exterior, so that standing outside sounds right.
Measured live, the two copies drift: interior instance at `t=3.371` against leak copy at `t=2.133`, 1.24s
apart, on the same file. Crossing the threshold hands you a different copy at a different point in the loop.

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

Once interior sounds genuinely leak out, a paired exterior sound would play on top of the leaked interior
one. Three cases, in order of specificity:

| Case | Behaviour |
|---|---|
| **Same asset** on both sides | One channel, gain = combination of both resolved gains |
| **Different assets, declared alternates** | Crossfade between them. No phase guarantee - see below |
| **Different assets, not declared** | Independent - they sum. This is the default; no primitive needed |

"Sum" is just what you get by *not* declaring the link. Declaring it **is** the assertion "these are one
logical sound, blend don't add" - and that is the primitive's only guarantee.

Same-asset collapses to one channel rather than a crossfade because there is no timbre to blend between -
that gets perfect sync for free (it is one sound, it cannot drift) and no extra machinery.

Equality must be **scoped to one interior/exterior pair**. Two separate TARDISes humming the same file are
genuinely two sounds and must still sum.

The link is a *pair* relation and must not be folded into `tag`. `tag` is a stop-category at a deliberately
coarser granularity - `"flight"` covers 9 call sites including three mutually exclusive exterior variants -
and tags can coincide without meaning anything (`"damage"` covers 5 independent one-shots). Fusing them
means never being able to stop at one granularity and blend at another.

### 4. Drop the exterior hum when it duplicates an interior hum

Generalises the existing hand-written check in `cl_externalhum.lua`:

```lua
if snd.path ~= hum_sound_path and not self.LeakedInteriorHums[k] then
```

Evidence - scan of all 275 registered interiors, resolving through `Base` chains:

| | count |
|---|---|
| exterior hum **and** interior idle | 22 |
| **exterior-hum-only** | **0** |
| interior-idle-only | 247 |

Of the 22, **13 share the asset** (`hartnelltardis` x5 variants, `ruth` x2, `tuat` x2,
`backroomstardisint` - about four distinct TARDISes) and 9 use different files, so those 9 just sum.

The zero settles it: no interior anywhere relies on the exterior hum alone, so dropping it where it
duplicates can never leave a TARDIS silent outside.

**Known consequence:** for those 13, the exterior hum currently plays at full volume *regardless of door
state*. Leakage is quieter and door-dependent, so a shut TARDIS will be noticeably quieter outside than it
is today. Judged more correct, but it is a real audible change and it lands entirely on the closed-door
coefficient.

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

With the resolver this stops being hum-specific - it is cross-boundary audio in general. The **mechanism**
belongs in Doors; the **user option** stays TARDIS-side, with Doors taking a scalar (or callback) from the
consumer. Keeps Doors consumer-agnostic and keeps one slider in the TARDIS menu.

The existing `interior_hum_leakage_volume` is the model to follow, and the setting to generalise - it stops
being hum-specific and becomes the leak volume for all cross-boundary audio. **Carry existing values across
on rename** rather than resetting to the default; anyone who changed it did so deliberately.

A solid default matters more than the knob. Tune it in a rig first, then expose it.

**Tune the closed-door coefficient early and by ear.** 247 of 275 interiors have no exterior hum at all, so
leakage is the *only* way they are ever heard from outside - it is the dominant path for ~90% of TARDISes,
not an edge case.

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
  Verified live with one TARDIS parked inside another.

## Open questions

- How the blend factor is exposed. It replaces today's **binary occupancy check** with a continuous value,
  and a few call sites currently branch on occupancy - they need auditing.
- Whether the alternates link is declared in metadata or inferred from the interior/exterior counterpart
  fields (which are already paired by construction), and what the API looks like. It must not be `tag`.
- **The leak setting is now misnamed.** `interior_hum_leakage` / `interior_hum_leakage_volume` drive
  `GetCrossBoundaryVolume`, which covers everything crossing a doorway in either direction - the flight
  loop heard from inside included, not just hums. Renaming means carrying existing values across rather
  than resetting to the default; anyone who changed it did so deliberately.
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
4. **Exterior hum dedup** (decision 4).
5. **Alternates** - same-asset collapse, then declared pairs with a gain-only crossfade.

   **This one is now urgent rather than nice-to-have.** The resolver made leakage symmetric, so the
   *exterior* flight loop is newly audible from inside, on top of the interior's own - 105 interiors
   have a distinct loop on each side, and they now sum where previously the exterior one was inaudible
   across the void. That is decision 3's undeclared-pair default doing exactly what it says, applied to
   a pair that should have been declared. Flying is the case to listen to first.
6. **Virtualisation** on top of the resolver's perceived distance.

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
hum entries found **24 above 1** - `tuat`, `dwebradley`, `ruth`, `nova`, `artonym`, `wooden`,
`slickwine*` at 10, and `witsetardis` / `sellingrope` / `silence` / `spaceshit` at **50**. Source stores
channel volume as a byte and caps it at full scale, so an author who wrote 10 heard exactly the same as
1 and had no reason to notice. A managed channel amplifies instead, which made those interiors 20-34 dB
too loud until the library started reproducing the cap. Worth remembering before trusting any authored
number in an interior definition: the engine has been quietly correcting content for years, and each
place the port replaces the engine has to correct it too.

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
  the blend dives to the noise floor and climbs back over the transition time. Capture the step in dB
  at the instant it happens and heal that instead; see decision 1.
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
- **Phase-syncing paired interior/exterior loops.** 33 of 38 measurable pairs have mismatched lengths (see
  decision 5); there is no shared timeline to align to. Crossfade gains only.
- **A TARDIS-side wrapper over `Doors:PlaySound`.** Rejected twice; see decision 8. Consumer-specific
  inputs are per-entity or per-config, so they belong in provider hooks.
- **Overloading `tag` as the alternates link.** It is a stop-category at a coarser granularity, and tags
  coincide without meaning anything.
