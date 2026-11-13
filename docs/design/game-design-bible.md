[SYSTEM DIRECTIVE: FULL GAME PRODUCTION SPECIFICATION — FABLE 5.2]
Generate a complete, playable 2.5D Dark Fantasy Action-RPG for Android based on the following Master Game Design Bible. Enforce strict mechanical consistency, adaptive multi-stem audio integration, high-contrast mobile combat readability, and 60 FPS Android optimization.

======================================================================
1. CORE CONCEPT, ENGINE & ANDROID TECHNICAL SPECS
======================================================================
- Genre: 2.5D Side-Scrolling Dark Fantasy Action-RPG (Metroidvania-lite interconnected zones, skill-based real-time combat, instant mid-combat character switching).
- Platform & Performance: Android (ARM64). Target locked 60 FPS, dynamic resolution scaling, memory footprint under 1.8 GB RAM, object-pooled VFX, texture atlasing, and compressed OGG Vorbis audio streams.
- Controls:
  * Touch UI: Dynamic floating left virtual joystick; right-side ergonomic button arc (Primary Attack, Jump, Air-Dash/Dodge with 0.25s i-frames, Ability 1, Ability 2, Soul Synchronization Ultimate) + top-right 3-Vessel Quick-Swap radial wheel.
  * Gamepad: Full native Bluetooth controller support (auto-hides touch UI on input).
- Combat Telegraphing Standard (Color-Coded for Mobile Clarity):
  * Gold Flash + Metallic Chime = Parryable attack.
  * Crimson Flash + Low Boom = Unblockable attack (must dodge/jump).
  * Violet/Cyan Glow + Harmonic Ring = Magical/dimensional projectile.

======================================================================
2. NARRATIVE PREMISE & SOUL SYNCHRONIZATION MECHANIC
======================================================================
- Premise: The player controls "The Intruder," a mysterious bodiless soul awakening inside a fallen underground civilization. To survive and uncover the truth behind the world's collapse and the god-like "Architects," the Intruder inhabits fallen warriors ("Vessels"), inheriting their memories, weapons, and combat styles.
- Vessel Switching: Equip up to 3 Vessels simultaneously; swap mid-combat (1.5s cooldown) to trigger a unique "Resonance Strike."
- Soul Synchronization (Ultimate Mechanic): Building trust with Vessels and filling the Soul Gauge allows each Vessel to briefly override control for a signature ultimate intervention.

======================================================================
3. THE FIVE PRINCIPAL VESSELS (PLAYABLE CHARACTERS)
======================================================================
1) CAELAN — The Knight (Defensive / Balanced)
   - Appearance: 1.88m, muscular, scarred left brow, weathered navy/dark-steel plate armor, torn blue cape, heavy left pauldron.
   - Weapons: Longsword + Shield (unlocks Greatsword via progression).
   - Abilities: Royal Guard (block), Counterstrike (perfect parry counter), Iron Resolve (damage reduction), King's Judgment (sword shockwave), Final Stand (defensive AoE).
   - Soul Sync: Automatically intercepts and blocks a lethal blow when affinity is high.

2) NYRA — The Wanderer (Fast / Agile Assassin)
   - Appearance: 1.69m, slim athletic build, auburn hair tied back, amber eyes, behind-ear tattoo, asymmetrical charcoal/violet leather armor, hooded cloak.
   - Weapons: Dual Curved Daggers + Throwing Knives (unlocks Poison/Elemental Short Blades).
   - Abilities: Shadowstep (teleport dash), Backstab (bonus rear crit damage), Phantom Blades (spectral daggers), Vanishing Act (brief stealth), Dance of Shadows (multi-target slash frenzy).
   - Soul Sync: Auto-evades an otherwise unavoidable attack with a shadow counter.

3) SERIS — The Arcanist (Ranged / Elemental & Aether Magic)
   - Appearance: 1.73m, graceful, long silver-white hair, pale lavender eyes, glowing runes on left forearm, ivory/midnight-blue/gold robes, crystal-tipped staff.
   - Weapons: Arcane Staff + Spellbook (unlocks Floating Magical Focus).
   - Abilities: Arcane Bolt (ranged projectile), Frost Binding (slow/freeze), Aether Shield (absorbs projectiles), Rift Step (short dimensional blink), Cataclysm (elemental AoE).
   - Soul Sync: Fuses her magic with the Intruder's soul energy for amplified dimensional spells.

4) DARIUS — The Survivor (Heavy / Posture-Breaking Bruiser)
   - Appearance: 1.94m, massive physique, damaged left eye, rugged patched armor of rust-iron, leather, and salvaged machinery in dark brown/faded orange.
   - Weapons: Heavy Warhammer + Massive Axe (unlocks Improvised Heavy Weapons).
   - Abilities: Crushing Blow (shatters enemy shields/armor), Groundbreaker (seismic AoE slam), Unbreakable (poise/damage resistance), Last Survivor (damage scales up as HP drops), Worldbreaker (charged shockwave).
   - Soul Sync: Overrides movement to unleash a devastating armor-shattering strike.

5) ILYR — The Unwritten (Dimensional / Unpredictable Reality-Bender)
   - Appearance: 1.80m, lean unnatural poise, long pale silver hair, glowing pale-blue eyes, luminous skin fractures, white/black/pale-gold attire with floating cloth fragments.
   - Weapons: Dimensional Blade + Floating Fragments (unlocks Reality Constructs).
   - Abilities: Fracture (damaging spatial tear), Distortion (repositions enemies), Echo (duplicates previous attack), Null Space (erases enemy projectiles), Absolute Rupture (dimensional implosion).
   - Soul Sync: Temporarily warps arena geometry and enemy positions.

======================================================================
4. ADAPTIVE SOUNDTRACK & LEITMOTIF SYSTEM
======================================================================
- Musical Direction: Original dark fantasy orchestral score blended with ambient synths, solo folk/chamber instruments, choir, and electronic distortion in later chapters.
- Protagonist Leitmotif: A simple, innocent solo piano melody that dynamically transforms based on the active Vessel:
  * Caelan: Noble strings & French horns.
  * Nyra: Fast plucked strings & light percussion.
  * Seris: Ethereal piano & choir.
  * Darius: Heavy cello & deep drums.
  * Ilyr: Reversed piano textures, dissonant strings, odd meters.
  * Final Boss ("Track 14 — The End of Everything"): All five variations merge into one climax.
- Adaptive 5-Layer Stem Engine (sync transitions to 4-bar boundaries):
  * Layer 1 (Exploration): Soft piano + environmental ambience (e.g., "Track 01 — Beneath the Forgotten", 70 BPM).
  * Layer 2 (Alert): Subtle rhythmic pulse when enemies detect the player.
  * Layer 3 (Combat): Driving strings & percussion ("Track 06 — Echoes of War").
  * Layer 4 (Elite): Aggressive low brass & staccato cellos.
  * Layer 5 (Boss 3-Phase Architecture): Phase 1 (Restrained motif) -> Phase 2 (Full orchestra + choir) -> Phase 3 (Maximum tempo/intensity desperation).

======================================================================
5. CHAPTER I WORLD, LEVEL FLOW, ENEMIES & BOSSES ("THE SUNKEN FOUNDATIONS")
======================================================================
- Structure: 4 interconnected zones with Soul Altar checkpoints (heal, swap 3-Vessel loadout, upgrade gear, invest Soul Shards, play Lore Fragments):
  1) Zone 1 — The Whispering Cavern (Collapsed marble aqueducts; unlocks Caelan; teaches combat/parries).
  2) Zone 2 — The Luminous Mycelium Forest (Bioluminescent fungal chasms; unlocks Nyra; vertical platforming).
  3) Zone 3 — The Sunken Palace (Flooded subterranean halls; unlocks Seris; light-rune puzzles + Boss 1).
  4) Zone 4 — The Sealed Rift & Starless Shore (Underground ocean chasm; unlocks Darius + teases Ilyr; Bosses 2 & 3).

- Ordinary & Elite Enemies:
  * Echo Crawler (Common): Swarming slate-gray stone arachnids; green spine-sac flare telegraph (0.6s) before lunge. Weak to Darius AoE. Drops: Crude Stone, Lesser Soul Shards.
  * Subterranean Watcher (Common): Hovering porcelain sphere with cyan laser; 1.2s charge telegraph. Grounded by Seris magic; beam reflectable by Caelan. Drops: Faded Parchment, Lesser Soul Shards.
  * Calcified Husk (Common): Statue-disguised fungal ambushers; 1.0s spore telegraph before root-snare. Escaped via Ilyr teleport. Drops: Luminous Root Resin, Lesser Soul Shards.
  * Branded Warden (Elite): 2.6m corroded iron royal guard with tower shield + halberd; shield blocks 80% frontal damage until shattered by Darius or flanked by Nyra. Drops: Polished Basalt Core, Standard Soul Shards, Weapon Schematics.
  * Choir Prelate (Elite): Floating headless priest buffing allies with golden aura; interruptible via Seris Rift Step + Frost Binding. Drops: Tarnished Censer Core, Standard Soul Shards, Deep-Realm Rune.

- Chapter I Bosses (3-Phase Combat & Audio Sync):
  1) Mini-Boss: THE WEEPING SOVEREIGN (Sunken Palace)
     - Music: Melancholic solo cello -> frantic strings & choir.
     - Phases: P1 (100-60%: Crystalline tear projectiles & stamina-draining pools) -> P2 (60-25%: Summons 4 delayed spectral courtiers + rising water) -> P3 (25-0%: Drops crown for frantic blue-flame dual-saber combos).
     - Drops: Sovereign's Crown Fragment (Epic), Greater Soul Shards x2 (Epic), Royal Echo Passive Scroll (Epic).
  2) Gatekeeper Boss: THE GUARDIAN BELOW (The Sealed Rift Elevator)
     - Music: "Track 10 — The Guardian Below" (65 BPM war drums, sub-bass brass, 40-voice male choir).
     - Phases: P1 (100-65%: Seismic fist slams & sweeping chest laser) -> P2 (65-30%: Smashes elevator chains, tilting arena 15 degrees with sliding rocks) -> P3 (30-0%: Exposes glowing reactor core, +40% attack speed, radial shockwaves).
     - Drops: Heart of the Guardian (Legendary), Greater Soul Shards x3 (Epic), Unlocks Caelan's Greatsword.
  3) Chapter Climax Boss: THE ABYSSAL LEVIATHAN (Starless Shore)
     - Music: Polymetric 5/4 & 7/8 electronic/orchestral hybrid with distorted cellos & sonar pulses.
     - Phases: P1 (100-65%: Emerges from black water with tidal tail-whips & lunge bites) -> P2 (65-30%: Plunges arena into darkness; only its 12 glowing eyes are visible before blindside strikes) -> P3 (30-0%: Tears open dimensional rifts firing energy beams + sonic roars).
     - Drops: Pure Soul Matrix (Legendary), Abyssal Scale (Legendary), Primeval Truth I Lore Fragment (Legendary), Unlocks Soul Synchronization Overdrive.

======================================================================
6. LOOT & PROGRESSION ECONOMY (4 RARITIES)
======================================================================
- Common (70% Normal / 20% Elite): Lesser Soul Shards (+1 Base Node), Crude Stone/Iron, Faded Parchment (text lore).
- Rare (25% Normal / 65% Elite): Standard Soul Shards (+1 Ability Rank), Polished Basalt/Luminous Resin, Echoing Relics (voiced logs), Elemental Weapon Coatings.
- Epic (5% Normal / 15% Elite / 100% Boss): Greater Soul Shards (Sync Passives), Sovereign's Crown/Censer Core, Deep-Realm Runes, New Weapon Types.
- Legendary (100% Major Bosses): Pure Soul Matrix (Ultimate Sync Awakening), Heart of Guardian/Abyssal Scale, Primeval Truths (Architect origin lore), Mythic Soul-Sync Abilities.

======================================================================
7. DELIVERABLE INSTRUCTION FOR FABLE 5.2
======================================================================
Build the complete playable Chapter I vertical slice and core progression architecture on Android:
1. Implement all 5 Vessels (with Caelan, Nyra, Seris, and Darius playable across Chapter I and Ilyr's preview awakening in the Chapter I finale) including their full ability kits, Resonance Switch attacks, and Soul Synchronization ultimates.
2. Generate 2.5D environments, parallax lighting, character/enemy models, animations, and color-coded attack telegraphs for all 4 Chapter I zones.
3. Synthesize the adaptive multi-stem OGG Vorbis soundtrack implementing the protagonist's Vessel-morphing piano leitmotif and all 3 Chapter I boss themes.
4. Implement the Soul Altar checkpoint system, 4-rarity loot drops, weapon/skill upgrade menus, and responsive mobile touch + Bluetooth controller inputs.