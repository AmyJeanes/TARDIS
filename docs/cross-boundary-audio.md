# Cross-boundary audio - design and plan

Phase 3 of the sound rework ([#382](https://github.com/AmyJeanes/TARDIS/issues/382)). The mechanism lands in
the **Doors** addon (`lua/doors/libraries/sh_sound.lua`); this document is the plan, so it may name TARDIS.
Doors' own code and docs stay consumer-agnostic - generic interior / exterior / portal vocabulary only.

Status: **design agreed, not yet built.** Phases 1 and 2 (managed BASS channels, the central hub, looping
with mid-file handover) are done and on the `sound-rework` branch of both repos.

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

When listener and emitter are in different spaces, the sound is resolved **through the doorway in two
stages**:

1. **Source -> doorway**: how much energy reaches the opening.
2. **Doorway -> listener**: re-radiate from the doorway as a new point source.

Attenuating twice is what makes 500 units outside much quieter than 500 units inside, and it puts the
perceived *direction* at the doorway, which is what you would actually hear. A single transformed position
gets the direction right but not the falloff.

**Constraint:** the aperture term must approach 1 as the listener approaches the mouth. Standing in the
doorway must sound nearly like standing inside; over-attenuating there is the failure mode to listen for.

## Decisions

### 1. Door state is acoustic; portal culling is not

A **closed door** is a fact about the world - deterministic, same for every player, real attenuation. Door
open/closed becomes an *aperture coefficient* rather than a switch: open is mostly transmitted, closed is
heavily attenuated but **non-zero**. Sound leaks through a shut door, just quietly and over a shorter range.

A portal **culled client-side for performance** is a rendering optimisation. Two players in the same spot
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
| **Different assets, declared a pair** | Group: crossfade, phase-aligned |
| **Different assets, not declared** | Independent - they sum. This is the default; no primitive needed |

"Sum" is just what you get by *not* grouping. Declaring a group **is** the assertion "these are one logical
sound, blend don't add". The group primitive therefore carries exactly two guarantees, only where asked
for: blend instead of sum, and phase-align while blending.

Same-asset collapses to one channel rather than a crossfade because there is no timbre to blend between -
that gets perfect sync for free (it is one sound, it cannot drift) and no group machinery.

Equality must be **scoped to one interior/exterior pair**. Two separate TARDISes humming the same file are
genuinely two sounds and must still sum.

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

### 5. Sync: phase when audible, not identical rates

The interior and exterior flight loops already pitch-shift on the **identical** curve - same 95..110 range,
same divisor, and the interior reads velocity off `self.exterior`, so it is literally the same number:

```lua
-- cl_flight.lua (interior)
local p = 95 + math.Clamp(self.exterior:GetVelocity():Length()/250, 0, 15)
-- sh_flight.lua (exterior)
local p = math.Clamp(self:GetVelocity():Length()/250, 0, 15)   -- then 95 + p, or +doppler clamped 80..120
```

The only divergence is the **doppler** term on the exterior. That must not be forced onto the interior:
inside the TARDIS you move *with* it, so there is no relative motion and physically no doppler. Matching it
would trade a sync bug for an acoustics bug.

It does not need to be. Doppler is only significant when the listener has real relative motion to the
exterior - exactly when the interior member is inaudible. Where sync matters (at the threshold, both
audible) you are effectively co-located with the exterior and doppler is ~0.

So: **each member takes its own correct rate, and the inaudible member is silently re-asserted against the
clock master.** When the blend factor starts to rise, snap the quieter member to the master's position - it
is inaudible at that instant, so the snap is free, and by the time it can be heard it is in phase. Drift
while apart becomes a non-problem rather than something to prevent.

This weaker invariant - *phase when audible*, not identical rates forever - is what makes the group
primitive tractable. It only works under the crossfade policy; a summed pair has no silent moment to snap in.

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

The existing `interior_hum_leakage_volume` is the model to follow, and probably the setting to generalise.

**Tune the closed-door coefficient early and by ear.** 247 of 275 interiors have no exterior hum at all, so
leakage is the *only* way they are ever heard from outside - it is the dominant path for ~90% of TARDISes,
not an edge case.

## Open questions

- The exact aperture curve and its coefficients (open vs closed), and how doorway size feeds in. Ear-tuning
  job; reuse the rig pattern from the loop work.
- How the blend factor is exposed. It replaces today's **binary occupancy check** with a continuous value,
  and a few call sites currently branch on occupancy - they need auditing.
- Whether path distance is transformed straight-line or true path-through-the-mouth.
- Whether groups are declared in metadata or inferred, and what the API looks like.

## Implementation order

1. **Resolver core** in Doors: `sourcePos` resolves through the doorway transform, two-stage aperture,
   symmetric in both directions, independent of the portal entity.
2. **Consumer scalar** so the aperture/leak volume is driven by a TARDIS setting.
3. **Delete `cl_externalhum.lua`'s hand-built leak** - the second copy and its `LeakedInteriorHums` table.
   Leaking becomes a property of the geometry rather than a maintained feature.
4. **Exterior hum dedup** (decision 4).
5. **Groups** - same-asset collapse, then declared pairs with crossfade + silent re-sync.
6. **Virtualisation** on top of the resolver's perceived distance.

## Testing

Mid-file loop markers are rare - a full scan of all 275 interiors (721 readable wavs) found **three**:

| Interior | Asset | Marker | Notes |
|---|---|---|---|
| `rtd60` | `uriel/rtd2/.../hum_thebridge.wav` | 2.0221s / 10.99s | The real test case |
| `type35` | `jorj/type35/type35hum.wav` | 0.1625s / 22.27s | Edge case - only just over the 0.15s crossfade |
| `baker_1975` | `liam.T/baker/flight_loop.wav` | 0.0029s / 3.60s | Under threshold, stays a whole-file loop |

`rtd60` is the one to test with: its idle hum is audible both inside and (via leakage) outside, so it
exercises the resolver on both sides of the same sound.

Note the file the tuning rig used, `FuzzyLeo/fuzzyscrap/beee/loudflight.wav`, is referenced by **no
interior** - an orphan asset picked purely because it had a marker.

## Do not re-attempt

- **Lua-timed loop-point correction.** GMod exposes no loop-region API, the observable position is not the
  audible one, and these files open with near-silent fade-ins. Solved by trimming the body to `data/` and
  letting BASS loop it whole-file, with the intro crossfading in.
- **Keying cross-boundary audio off the portal entity.** It is a client-side perf optimisation; making audio
  depend on it means two players in the same spot hear different things.
- **Culling on world distance.** That is the original bug.
- **Writing a channel's volume from anywhere but `applyGain`.** A caller's volume is the pre-distance one;
  writing it straight to the channel plays far-off sounds at full volume.
