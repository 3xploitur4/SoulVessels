# Soul Vessels — Design Addendum v1 (Chapter I)

Nov 13, 2026 · Online copy: https://claude.ai/artifact/RSA5fXj2ZHCMcgCHoxH8iY

## Purpose and tech stack

This addendum fills every gap and fixes every contradiction in the Master Game Design Bible (`docs/design/game-design-bible.md`). Where the two disagree, this addendum wins. "Soul Vessels" is a working title only.

**Engine: Godot 4.7.2 with GDScript, exported to Android (ARM64).** It's free and light on mobile. It also has built-in adaptive-music nodes (AudioStreamInteractive, AudioStreamSynchronized) that match the 5-layer stem design.

**Rendering approach (2.5D):** 3D environments with real lights and fog, in a side-on camera with parallax depth layers. Characters start as procedural low-poly placeholders built in-engine, then get swapped for final art. Final character art is an open asset task (see Production milestones).

**Performance budget:** 60 FPS on a mid-range 2022 phone (Snapdragon 778 class), under 1.8 GB RAM, Mobile renderer, at most 3 dynamic lights per screen, pooled VFX, and OGG Vorbis stems at 128 kbps.

## Resolved contradictions

| Bible issue | Resolution |
| --- | --- |
| Calcified Husk is "escaped via Ilyr teleport", but Ilyr isn't playable in Chapter I | Any Vessel escapes the root-snare by dodging during the 1.0s telegraph, or by mashing to break free (6 taps). Nyra's Shadowstep and Seris's Rift Step break it instantly. In Chapter II, Ilyr's Distortion gives full immunity. |
| Echo Crawler is "weak to Darius AoE" but Darius only arrives in Zone 4 | Crawlers take +50% damage from every AoE. Darius's AoE kills them instantly. Zone 4 sends Crawler swarms in groups of 8. |
| Branded Warden needs Darius or Nyra; the first Warden appears before either is unlocked | The first Warden (Zone 1 set-piece) can be beaten with Caelan's Counterstrike: perfect parry, then 2s of guard break. Darius and Nyra counters stay as faster options. |
| "Luminous Resin" vs "Luminous Root Resin" | Named **Luminous Root Resin** everywhere. |
| Tarnished Censer Core is an Elite drop but listed as Epic | Split: **Tarnished Censer Shard** (Rare, Choir Prelate drop) and **Censer Core** (Epic, crafted from 3 shards at a Soul Altar). |
| Weeping Sovereign is called a "Mini-Boss" but gets an Epic loot package | Renamed **Zone Boss**. "Mini-Boss" now means elite set-pieces, such as the first Warden. |
| Some Soul Syncs are passive (Caelan, Nyra), others active (Darius); unclear what the Ultimate button does | Each Vessel has both: an automatic **Sync Guard** and a button-triggered **Sync Ultimate**. |
| "Ultimate Sync Awakening" vs "Soul Synchronization Overdrive" | Same thing: **Overdrive**. Unlocked by the Pure Soul Matrix from the Leviathan; chains two Vessels' Ultimates in one activation. |

## Core combat systems

Four meters: **HP, Stamina, Posture, Soul Gauge**. HP is shared (the Intruder's soul dies, not the Vessel). Stamina and Posture are per Vessel.

**HP.** Soul pool starts at 300. Each Vessel in the active loadout adds a passive HP bonus. Each Soul Core node bought with Lesser Soul Shards adds +15.

**Stamina (per Vessel, 100 max).** Dodge 20, air-dash 25, light attack 0, heavy/charged attack 15, blocking 10 per hit. Regen 40/s after 0.6s without spending. At 0 stamina a Vessel is Exhausted: no dodge for 1.5s. Swapping out is the main escape.

**Dodge and parry timing.**
- Dodge: 0.25s i-frames inside a 0.45s roll, 0.15s cancel window into an attack.
- Parry: block within 0.18s of a Gold-flash hit. Perfect parry restores 15 stamina and deals 35 posture damage.
- Story difficulty widens both windows (see Difficulty).

**Posture.** Every enemy has a Posture bar that fills from hits and parries. Full bar = 2.5s stagger, then a **Riposte** (Attack button prompt) for 2x damage. Drains 10/s after 2s without being hit. Darius deals 2–3x posture damage. Player Vessels have a hidden Posture of 100: blocking heavy blows fills it; a full bar opens a 1s guard-break.

**Damage formula.**

```
Damage = ATK × MotionValue × 100 / (100 + DEF) × Crit × Element × Backstab
```

Crit 1.5x (base 5% chance, Nyra 20%). Weakness 1.5x, resisted element 0.5x. Backstab 1.3x, or 2.5x for Nyra.

**Elements and status effects** (build-up meter triggers the status when full):

| Element | Status | Effect | Main sources |
| --- | --- | --- | --- |
| Physical | Stagger | Posture damage x1.2 | Caelan, Darius |
| Frost | Chill → Freeze | -30% move speed; at full build-up frozen 2s and +25% damage taken | Seris, Frost coating |
| Venom | Poison | 2% max HP per second for 6s | Nyra, Venom coating |
| Aether | Unravel | -20% DEF for 5s; strips Choir Prelate buffs | Seris, Ilyr |
| Ember | Burn | 15 damage/s for 4s; breaks fungal armor | Ember coating, Sovereign P3 |

**Telegraphs (accessible: colour + shape + sound).**
- Gold flash + metallic chime + **ring** icon = parryable.
- Crimson flash + low boom + **X** icon = unblockable.
- Violet/cyan glow + harmonic ring + **diamond** icon = magic projectile.

Enemy-specific tells (green spine-sac, cyan charge) always run alongside these standard cues.

## Vessel switching, Resonance and Soul Sync

Each Vessel has one Resonance Strike on swap-in, one automatic Sync Guard, and one button Sync Ultimate. Pair flavour comes from **Echo Bonuses**: extra effects when the incoming Vessel hits a status effect the outgoing Vessel applied.

**Swapping.** Tap a portrait on the radial wheel, or LB/RB on gamepad. 1.5s global cooldown, 0.2s swap with i-frames (a well-timed swap doubles as a dodge). Inactive Vessels regen stamina at 2x.

**Resonance Strikes.**

| Incoming Vessel | Resonance Strike | Echo Bonus |
| --- | --- | --- |
| Caelan | **Oathbreaker Lunge**: shield-bash dash, 60 posture damage | vs Frozen: shatters ice for 3x posture damage |
| Nyra | **Severing Arrival**: teleports behind nearest enemy, guaranteed backstab | vs Staggered: guaranteed crit |
| Seris | **Aether Burst**: 3m radial blast, knockback, Aether build-up | vs Poisoned: poison spreads to every enemy hit |
| Darius | **Meteor Drop**: ground slam, 90 posture damage, 3m AoE | vs Unraveled: armor shattered at once |
| Ilyr | **Dislocation**: swaps places with target enemy | Copies the outgoing Vessel's Resonance Strike at 50% |

**Soul Gauge (shared, 300 max = 3 bars).** +2 per hit landed, +10 per perfect parry or perfect dodge (within 0.1s of the hit), +8 per connecting Resonance Strike, +5 per kill, +1 per 10 damage taken. Drains 1/s outside combat.

**Sync Guard (automatic).** Costs 1 bar, needs Affinity 2+, once per 90s per Vessel. Inactive Vessels can trigger theirs too (free swap-in).
- Caelan: intercepts a lethal blow and blocks it.
- Nyra: auto-evades an unavoidable attack and counters with a shadow strike.
- Seris: Aether Shield absorbs a magic projectile that would deal 25%+ max HP.
- Darius: survives at 1 HP and gains 3s of Last Survivor at maximum.
- Ilyr: rewinds the player 2 seconds when grabbed.

**Sync Ultimate (button, 2 bars, Affinity 3+).** The Vessel takes control for 3–5s:
- Caelan: **Final Stand**, 6m defensive AoE; 50% damage reduction, enemies knocked down.
- Nyra: **Dance of Shadows**, 12 auto-targeted slashes over 3s.
- Seris: **Cataclysm Fused**, dimensional meteor storm (Aether + Frost).
- Darius: **Worldbreaker Override**, charged strike that breaks all posture on screen.
- Ilyr: **Absolute Rupture**, implosion that pulls enemies together and remixes the arena for 8s.

**Overdrive (3 bars, after the Leviathan).** Chains two Ultimates back to back with a combined finisher.

**Affinity (trust), 0–5 per Vessel.** XP from time active in combat, kills, perfect parries/dodges; reading that Vessel's Lore Fragments at a Soul Altar gives +1 level each.

| Level | Unlocks |
| --- | --- |
| 1 | Vessel memory flashback (lore) |
| 2 | Sync Guard |
| 3 | Sync Ultimate, +5% Vessel stats |
| 4 | Echo Bonus +50% |
| 5 | Signature passive, alternate cape/colour |

## Vessel stats and ability kits

**Base stats (Affinity 0, no upgrades)**

| Vessel | HP bonus | ATK | DEF | Move (m/s) | Attack speed | Posture dmg | Role |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Caelan | +120 | 40 | 30 | 6.0 | 1.0x | 1.2x | Defense, parry |
| Nyra | +40 | 32 | 12 | 7.5 | 1.6x | 0.6x | Burst, backstab |
| Seris | +60 | 45 (magic) | 15 | 5.8 | 0.9x | 0.5x | Range, control |
| Darius | +160 | 60 | 35 | 5.2 | 0.6x | 2.5x | Break, AoE |
| Ilyr | +80 | 48 | 20 | 6.5 | 1.1x | 1.0x | Disruption |

**Ability mapping and cooldowns**

| Vessel | Primary | Ability 1 | Ability 2 | Dodge | Passive | Ultimate |
| --- | --- | --- | --- | --- | --- | --- |
| Caelan | 4-hit longsword combo | **Royal Guard** (hold to block 100% frontal; perfect block triggers **Counterstrike**) | **King's Judgment**: 8m ground shockwave, 6s cd | Roll | **Iron Resolve**: -15% damage taken, -30% while blocking | **Final Stand** |
| Nyra | 6-hit dagger flurry | **Shadowstep**: 6m teleport dash, 3s cd; hold for **Vanishing Act** (2s stealth, 12s cd) | **Phantom Blades**: 5 spectral knives, 5s cd | Short flip (15 stamina) | **Backstab**: 2.5x rear damage | **Dance of Shadows** |
| Seris | **Arcane Bolt**: 3-shot ranged chain, 20m | **Frost Binding**: 4m ice field, 60% Frost build-up, 8s cd | **Aether Shield**: 3s projectile barrier, 10s cd | **Rift Step**: 5m blink | +10% spell damage per enemy within 10m (max +30%) | **Cataclysm** |
| Darius | 3-hit hammer swings, hyper-armor | **Crushing Blow**: shatters shields/armor, 150 posture, 7s cd | **Groundbreaker**: 5m seismic slam, 9s cd | Shoulder charge (knockback) | **Unbreakable** (hyper-armor) + **Last Survivor** (+1% dmg per 2% HP missing, max +50%) | **Worldbreaker** |
| Ilyr | Dimensional blade, 4 hits | **Fracture**: spatial tear, 3s DoT, 6s cd | **Distortion**: pull/push enemy 6m, 8s cd | **Null Space**: blink that erases projectiles | **Echo**: every 5th attack repeats at 70% | **Absolute Rupture** |

**Weapon unlocks and Affinity 5 passives**

| Vessel | Second weapon (unlock) | Affinity 5 passive |
| --- | --- | --- |
| Caelan | Greatsword (Guardian Below): no shield, 1.5x posture, parry with blade | **Sworn Shield**: perfect parry reflects magic projectiles |
| Nyra | Venom/Elemental Short Blades (Weapon Schematic from a Warden) | **Ghost Step**: Shadowstep resets on backstab kill |
| Seris | Floating Focus (Deep-Realm Rune): cast while moving at full speed | **Spellweave**: every 3rd Arcane Bolt copies last spell |
| Darius | Improvised Heavy (Polished Basalt Cores): random elemental slam | **Unkillable**: Sync Guard cooldown 45s |
| Ilyr | Reality Constructs (Chapter II) | **Unwritten**: Echo every 3rd attack |

## Enemy and boss stats

Tuning targets: common enemy dies in 3–5 hits with no upgrades, elite ~25s, boss 3–5 min on Normal.

| Enemy | Tier | HP | ATK | Posture | Weak / resists | Behaviour | First zone |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Echo Crawler | Common | 90 | 18 | 40 | Weak AoE (+50%), Frost | Groups of 3–8; 0.6s green spine-sac flare, then 4m lunge | 1 |
| Subterranean Watcher | Common | 120 | 30 (beam) | 50 | Weak Aether (grounded 4s); parried beam reflects | Hovers 4m up; 1.2s cyan charge, 1.5s sweeping beam | 1 |
| Calcified Husk | Common | 160 | 22 | 70 | Weak Ember; resists Venom | Statue disguise; 1.0s spore puff, root-snare 2.5s | 2 |
| Branded Warden | Elite | 900 | 55 | 220 | Shield blocks 80% frontal; weak from behind and to Crushing Blow | Gold halberd thrust (parryable); crimson shield charge (unblockable) | 1 (set-piece), 3–4 |
| Choir Prelate | Elite | 700 | 40 (orbs) | 160 | Weak Aether (Unravel strips buffs) | Golden aura: allies within 8m +30% ATK/DEF; teleports when approached | 3 |
| Fungal Stalker (new) | Common | 140 | 26 | 60 | Weak Ember | Ceiling ambusher for vertical sections | 2 |
| Drowned Courtier (new) | Common | 110 | 24 | 50 | Weak Frost (freezes in water) | Swims, surfaces with gold-flash slash | 3 |

| Boss | HP | Posture | Phases | Stagger rule | Arena |
| --- | --- | --- | --- | --- | --- |
| The Weeping Sovereign | 4,500 | 500 | 60% / 25% | Each full posture break: 4s vulnerable, 2x damage | Throne hall 30m; water rises 1.5m in P2 (Frost freezes it into platforms) |
| The Guardian Below | 8,000 | 900 | 65% / 30% | Posture only on fists (P1–P2) and core (P3) | Elevator 24m; tilts 15° in P2, rocks slide every 6s |
| The Abyssal Leviathan | 12,000 | 1,200 | 65% / 30% | 12 eyes, 300 HP each; every 3 destroyed = 5s stagger | Shoreline 40m, scrolling |

Phase changes: 1.5s invulnerable transition synced to the next 4-bar musical boundary (audio may shift it by up to 1s). Each boss phase has at least 2 parryable, 2 unblockable and 1 magic attack.

## Progression, upgrades and loot

**Soul Essence** is the currency: dropped by every kill, lost on death (see Soul Echo). All upgrades happen at Soul Altars.

| Track | Paid with | Effect | Chapter I size |
| --- | --- | --- | --- |
| Soul Core (shared) | Lesser Soul Shards (1/node) | +15 max HP, +5% stamina regen, +10 Soul Gauge cap, +1 flask charge, etc. | 20 nodes, ~14 reachable |
| Vessel Ability Ranks | Standard Soul Shards (1/2/3 per rank) | Rank 2: +20% power; rank 3: a modifier (e.g. King's Judgment travels along walls) | 4 abilities × 3 ranks per Vessel |
| Sync Passives | Greater Soul Shards (1 each) | 1 slot per Vessel, choose 1 of 3 (e.g. Caelan: Sync Guard also heals 20%) | 3 options per Vessel |
| Weapon reforging | Essence + materials | +0→+5, +8% ATK per level; +3 adds a coating slot | below |

| Level | Essence | Materials |
| --- | --- | --- |
| +1 | 300 | 3 Crude Stone/Iron |
| +2 | 700 | 6 Crude Stone/Iron |
| +3 | 1,500 | 2 Polished Basalt Core or Luminous Root Resin |
| +4 | 3,000 | 4 Polished Basalt Core + 1 Censer Core |
| +5 | 6,000 | 1 Sovereign's Crown Fragment or Heart of the Guardian |

| Rarity | Normal | Elite | Zone Boss | Major Boss | Examples |
| --- | --- | --- | --- | --- | --- |
| Common | 70% | 20% | — | — | Lesser Soul Shard, Crude Stone/Iron, Faded Parchment |
| Rare | 25% | 65% | — | — | Standard Soul Shard, Polished Basalt Core, Luminous Root Resin, Tarnished Censer Shard, Echoing Relic, Elemental Coating |
| Epic | 5% | 15% | 100% | 100% | Greater Soul Shard, Censer Core (crafted), Sovereign's Crown Fragment, Deep-Realm Rune, Weapon Schematic |
| Legendary | — | — | — | 100% | Pure Soul Matrix, Heart of the Guardian, Abyssal Scale, Primeval Truth |

Rarity odds per drop; normal enemies drop something 35% of the time, elites 100%; bosses always drop their full list. Pity rule: 15 elite kills without an Epic guarantees the next.

**Healing.** Soul Flask, 3 charges (up to 6 via Soul Core), 40% max HP over 0.8s each, refilled at altars.

## Level design

4 zones, 62 rooms, 7 Soul Altars. Critical path ~4–5 h, completion ~7 h. Each Vessel opens a gate type, so earlier zones gain shortcuts and secrets.

| Gate | Looks like | Opened by | From |
| --- | --- | --- | --- |
| Shield ward | Golden statue firing a steady beam | Caelan blocks and deflects the beam onto a receiver crystal | Zone 1 |
| Shadow veil | 6m+ gap or black mist curtain | Nyra's Shadowstep | Zone 2 (+4 Zone 1 secrets) |
| Light-rune door | Dark rune circle | Seris's Arcane Bolt (puzzles) | Zone 3 (+3 secrets in Zones 1–2) |
| Cracked masonry | Orange-veined wall/floor | Darius's Crushing Blow or Groundbreaker | Zone 4 (+5 secrets in Zones 1–3) |
| Rift scar | Shimmering tear in the air | Ilyr only — opens in Chapter II | Zones 2–4 (tease) |

| Zone | Rooms | Altars | Vessel unlocked | New mechanic | Bosses / set-pieces | Music |
| --- | --- | --- | --- | --- | --- | --- |
| 1 — Whispering Cavern | 14 | 2 | Caelan (room 2) | Attack, dodge, parry tutorial | Branded Warden set-piece (Mini-Boss) | Track 01 (70 BPM) |
| 2 — Luminous Mycelium Forest | 16 | 2 | Nyra (room 8, freed from roots) | Swap tutorial, vertical climbing, bounce mushrooms, wall-jump | Husk ambush gauntlet | Track 03 |
| 3 — Sunken Palace | 18 | 2 | Seris (room 4, frozen in crystal) | Water levels, light-rune puzzles | The Weeping Sovereign (Zone Boss) | Track 05 |
| 4 — Sealed Rift & Starless Shore | 14 | 1 + boss checkpoints | Darius (room 3) | Darkness (light radius), sliding floors | Guardian Below; Abyssal Leviathan; Ilyr's awakening | Tracks 10, 12, 13 |

**Light-rune puzzles (Zone 3, 6 total):** 1) Sequence — light runes in mural order (3, 4, then 5). 2) Reflection — bounce a Watcher beam or Arcane Bolt off rotatable mirror-shields (Caelan can carry one). 3) Tide — freeze the water surface with Frost Binding at the right height, light the rune from the ice. The final puzzle opens the throne room and combines all three.

**Soul Altars:** full heal + flask refill, respawn ordinary enemies (not killed elites), save, change 3-Vessel loadout, upgrades, Lore playback, Censer Core crafting. Fast travel once all 7 are lit.

## Death, saving, difficulty and accessibility

Respawn at last rested altar. Carried Soul Essence stays as a **Soul Echo** where you died; touch it to recover. Die again first and it's lost. Shards, items and Affinity are never lost.

Saving: autosave at altars, zone entry, after bosses; 3 slots; suspend-save when the Android app is backgrounded.

| Difficulty | Enemy damage | Parry/dodge windows | Soul Echo | Notes |
| --- | --- | --- | --- | --- |
| Story | 50% | +80% | Never lost | Auto-swap suggestion prompts |
| Normal | 100% | Standard | Lost on 2nd death | Intended |
| Abyssal | 140% | -20% | Lost on 2nd death | Extra attack per combo; unlocks after Chapter I |

Accessibility: shape + sound on every telegraph; colour-blind palettes (deuteranopia, protanopia, tritanopia); hold-to-toggle for block and charge; screen shake 0–100%; remappable touch layout with size/opacity sliders; left-handed mirror layout; subtitles with speaker colours; haptics toggle.

## Narrative

Chapter I's reveal: the Architects didn't build this civilisation — they buried it on purpose to seal something away. Seeded, revealed only in the final chapter: the Intruder is the soul of the last Architect.

**World.** The kingdom of **Vael-Sora**, a marble city around a well of soul-light called the Foundation. The **Architects** "wrote" reality into stable form. 300 years ago they sank Vael-Sora in one night (the Descent). Souls stayed bound to bodies, which is why fallen warriors can become Vessels.

1. **Awakening (Zone 1).** The Intruder wakes as a wisp. A voice in the walls — the **Weeping Sovereign** — calls it "thief". It enters Caelan, the queen's sworn knight who died guarding a sealed door.
2. **The Forest (Zone 2).** Nyra, a smuggler who mapped escape routes during the Descent, is found strangled by roots. Her memories show the Architects' Wardens herding citizens downward.
3. **The Palace (Zone 3).** Seris, the court arcanist, sealed herself in crystal; the only partly-living Vessel. She knows what the Intruder is and hides it. The Sovereign is Caelan's queen, mad with grief; beating her lets Caelan say goodbye (+1 Affinity).
4. **The Rift (Zone 4).** Darius came from the surface 20 years ago seeking his lost expedition. He distrusts the Intruder (Affinity XP -25% until the Leviathan). The Guardian Below guards the elevator to the Starless Shore.
5. **Finale.** The Leviathan is the Foundation's jailer. Its death tears the rift open.
6. **Ilyr's awakening.** A **playable 90-second segment**: the Intruder briefly inhabits Ilyr, fighting "erased" echoes of the other four Vessels. Ilyr: "You've worn this face before." Cut to black. Ilyr joins in Chapter II.

Lore: 24 Faded Parchments, 10 Echoing Relics (text + musical sting, no voice acting in v1), 5 Vessel Memories, 1 Primeval Truth — **"The Descent Was Not a Fall"**: an Architect's order to sink Vael-Sora "to contain the Unwritten", signed with a sigil shaped like the Intruder's own wisp.

## Audio implementation

Each zone track = **shared intensity stems** + **one lead stem per Vessel** (the leitmotif). Swapping crossfades only the lead stem in 1 beat. Intensity changes wait for the next 4-bar boundary.

| Stem | Plays | Content |
| --- | --- | --- |
| Bed | Always | Ambience + soft piano pad (Layer 1) |
| Pulse | Alert+ | Rhythmic pulse (Layer 2) |
| Combat | Combat+ | Driving strings + percussion (Layer 3) |
| Elite | Elite alive | Low brass, staccato cellos (Layer 4) |
| Lead ×5 | Always, active Vessel only | Caelan horns/strings; Nyra plucked + light percussion; Seris ethereal piano + choir; Darius cello + drums; Ilyr reversed piano, 7/8 |

Godot: zone stems in AudioStreamSynchronized; a MusicDirector tracks the beat clock and schedules volume changes on 4-bar boundaries; bosses use AudioStreamInteractive with three phase clips. States: Explore→Alert (spotted), Alert→Combat (first damage), Combat→Elite (elite within 15m), calm-down after 6s with no aggro.

| # | Title | Use | Tempo |
| --- | --- | --- | --- |
| 01 | Beneath the Forgotten | Zone 1 | 70 BPM 4/4 |
| 02 | The Intruder (leitmotif, solo piano) | Title, altars | 60 BPM 3/4 |
| 03 | Spore Light | Zone 2 | 84 BPM 6/8 |
| 05 | Drowned Court | Zone 3 | 72 BPM 4/4 |
| 06 | Echoes of War | Shared combat stems | 140 BPM 4/4 |
| 08 | Tears of the Sovereign | Boss 1: solo cello → strings + choir | 76 → 152 BPM |
| 10 | The Guardian Below | Boss 2: war drums, sub-bass brass, male choir | 65 BPM (P3 130) |
| 12 | Starless Shore | Zone 4b | 60 BPM ambient |
| 13 | Leviathan | Boss 3: 5/4 + 7/8 hybrid, distorted cellos, sonar | 96 BPM |
| 14 | The End of Everything | Final boss (all leitmotifs merged); short version in Ilyr's awakening | — |

Until real recordings exist, use synthesised placeholder stems with this exact structure so final audio drops in without code changes. Telegraph SFX: chime / boom / harmonic ring, each under 150ms.

## UI, controls and localisation

HUD in the corners; centre 60% kept clear; touch elements outside notch/gesture safe areas.
- Top-left: HP bar, flask charges, Soul Gauge (3 segments).
- Top-right: 3-Vessel radial swap wheel (stamina ring, swap cooldown, glow when Sync Guard ready).
- Bottom-right: button arc — Attack, Jump, Dodge, Ability 1, Ability 2, Ultimate — with cooldown sweeps.
- Bottom-left: floating joystick (appears where the thumb lands on the left 40%).
- Boss: top boss bar + posture bar.

| Action | Gamepad |
| --- | --- |
| Move | Left stick |
| Attack / Jump / Dodge | X / A / B |
| Ability 1 / Ability 2 | Y / RT |
| Ultimate | LT + RT |
| Swap prev / next | LB / RB |
| Flask | D-pad up |
| Map / Menu | View / Menu |

Controller input hides touch UI; touch brings it back. Everything remappable. Menus: Title; Pause (Map, Vessels, Inventory, Lore, Settings); Soul Altar (Rest, Loadout, Upgrade, Reforge, Lore, Travel).

Localisation: v1 ships in English; all text through Godot translation tables from day one (French and Arabic RTL later).

## Production milestones

Each milestone ends with an installable Android build; nothing advances until it holds 60 FPS on the target phone.

1. **M0 — Setup.** Done (Godot 4.7.2 portable, JDK 17, Android SDK + cmdline-tools, export templates, studio template, kit). Remaining: create the Godot project and confirm an empty project exports an APK.
2. **M1 — Combat sandbox.** One arena; Caelan and Nyra fully playable with swapping, Resonance Strikes, stamina, posture, parry; Echo Crawler, Watcher, Warden; touch + gamepad; adaptive music with placeholder stems.
3. **M2 — Zones 1–2.** Rooms, Soul Altars, saving, Soul Essence and death, loot, Soul Core tree, Caelan/Nyra gates.
4. **M3 — Zone 3 + Weeping Sovereign.** Seris, light-rune puzzles, water, Choir Prelate, first boss with 3 music phases, reforging.
5. **M4 — Zone 4 + finale.** Darius, Guardian Below, Abyssal Leviathan, darkness lighting, Overdrive, Ilyr's awakening.
6. **M5 — Polish and release candidate.** Performance, accessibility, final art/music, signed APK/AAB.

Open asset decisions: final character art source; final music source; target test phone; release channel (Play Store or direct APK).
