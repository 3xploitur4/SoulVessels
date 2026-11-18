# Soul Vessels — Art Generation Brief (Chapter I)

A description of every character, monster, stage and boss in Chapter I, written for generating
final art. Each entry has the lore that matters for the look, a visual description, colours, the
details the game needs, and a ready-to-use prompt. It follows the three concept sheets in
`docs/design/concept-art/` and the design bible; where they differ, the sheets win.

---

## 1. The shared style (put this in every prompt)

> Dark fantasy, hand-painted 2D game art with clean dark ink outlines, cel-style shading with soft
> painterly gradients, muted desaturated base colours with a few strong glowing accents,
> high-contrast silhouette readable on a small phone screen, Hollow Knight / Darkest Dungeon / Blasphemous
> mood but its own style, no text, no watermark.

**World mood.** Vael-Sora was a marble city built around a well of soul-light, sunk underground
300 years ago in one night. Everything is old, drowned, cracked and quiet, lit by soul-light
(cool blue-white), fungus glow (teal and violet) and the odd ember (orange). Gold means royal
or sacred; crimson means danger.

**Colour rules the game depends on.** Keep these free for gameplay signals; do not paint them
as large areas on characters:
- **Gold flash**: an attack you can parry.
- **Crimson**: an attack you can't block.
- **Violet or cyan glow**: magic and projectiles.
- **Orange-veined cracked stone**: a wall Darius can break.

---

## 2. What the game needs from the files

**Characters and monsters (sprites).**
- Full body, one figure per image, nothing cropped. Feet visible for anything that stands.
- **Side-on three-quarter view, facing right.** The game mirrors it to face left.
- Plain flat background, either transparent PNG or solid slate grey `#3a3f4a` (the colour of the
  current sheets, which the slicer removes).
- Neutral standing pose with arms and weapon clear of the body. A held weapon must not overlap the
  torso or legs, because the game cuts the figure into parts (arms, legs, weapon, head) and
  animates them.
- At least 1024 px tall per figure (the current sprites are about 470 px, which is why they look soft).
- Same light on every figure: key light from upper left, soft cool rim light from behind.
- **Optional extra poses** (a big upgrade to the animation). Use the same character, scale and
  view as the neutral pose:
  - weapon raised (wind-up);
  - mid-strike;
  - running;
  - hit or recoiling;
  - kneeling or fallen.

**Stages (backdrops).**
- Very wide (about 3:1, for example 3072 × 1024).
- No characters and no UI.
- **Must tile left to right.** The left and right edges should join, or at least be dark and
  plain enough to mirror.
- **Keep the lower third quiet.** The playable floor sits in front of it, so detail and bright
  spots go in the middle and top.
- Painted as the far background: hazy, slightly darker and less saturated than the characters.

**Sizes in the world** (keep proportions consistent across images):

| Who | Height |
| --- | --- |
| Nyra | 1.69 m |
| Seris | 1.73 m |
| Ilyr | 1.80 m |
| Caelan | 1.88 m |
| Darius | 1.94 m |
| Branded Warden | 2.6 m |
| The Guardian Below | 4.4 m |
| The Abyssal Leviathan | about 6.5 m of rising neck and body |

---

## 3. The Intruder (the player's soul)

**Who.** A bodiless soul that wakes in the ruins and enters the bodies of fallen warriors. The
last chapter reveals it is the soul of the last Architect, so its shape is the small bright sigil
on the Architects' orders.

**Look.**
- A small floating wisp about head-sized: a teardrop of white-blue soul-light with a brighter core.
- Two or three trailing tendrils, like a candle flame stretched by motion.
- A faint inner pattern like a simple sigil: one ring and a vertical stroke.
- No face; the core pulses like a heartbeat.

**Colours.** White core `#f4fbff`, pale blue `#9fd8ff`, edge fading to transparent.

**Prompt.**
> A small floating soul wisp, a teardrop of white-blue light with a brighter pulsing core and two
> trailing tendrils, a faint simple ring-and-line sigil inside, no face, glowing softly, on a plain
> dark slate background, [shared style]

---

## 4. The five Vessels (playable)

### Caelan — The Knight

**Who.** The queen's sworn knight, who died guarding a sealed door. He is noble, tired and loyal,
and the first body the Intruder takes.

**Build.** 1.88 m, broad and muscular, a soldier's stance. Square jaw, short brown hair, scar
through the left eyebrow, stubble.

**Armour.**
- Weathered navy and dark-steel plate armour, dented and scratched.
- A heavy left pauldron, larger than the right.
- A torn deep-blue cape, ragged at the hem.
- Brown leather belts and straps.

**Weapons.**
- First: a plain straight longsword in the right hand and a tall kite shield in the left (dark
  steel with a worn blue field).
- Second: a two-handed Greatsword, broad and long and slightly notched, with no shield.

**Colours.** Navy `#2a3550`, dark steel `#4a5262`, cape blue `#2f4f8a`, leather brown `#5a3e2b`.

**Detail.** A faint gold glow along the shield rim when blocking (the game adds it).

**Prompt.**
> Caelan, a tired noble knight, 1.88 m, muscular, short brown hair, scar through left eyebrow,
> weathered navy and dark-steel plate armour with an oversized left pauldron, torn deep-blue cape,
> brown leather straps, straight longsword in right hand held low and clear of the body, tall dark
> steel kite shield on left arm, full body, side three-quarter view facing right, neutral ready
> stance, [shared style]

*Greatsword variant:* same, but no shield, and a broad notched two-handed greatsword resting on
the right shoulder.

### Nyra — The Wanderer

**Who.** A smuggler who mapped escape routes while the city sank, found strangled by roots. She is
quick, wry and wary.

**Build.** 1.69 m, slim and athletic. Auburn hair in a high ponytail, amber eyes, a small tattoo
behind the ear, a confident half-smile.

**Armour.**
- Asymmetrical charcoal and violet leather armour, a fitted vest and bracers.
- A hooded cloak, hood down, deep purple inside.

**Weapons.**
- First: two curved daggers held reverse-grip, and a few throwing knives on the belt.
- Second: Venom Blades, short straight blades with a green-black sheen and dripping venom.

**Colours.** Charcoal `#2b2b33`, violet `#5b3f7a`, auburn `#a0462a`, amber eyes `#e0a040`.

**Prompt.**
> Nyra, an agile rogue woman, 1.69 m, slim athletic build, auburn hair in a high ponytail, amber
> eyes, small tattoo behind her ear, asymmetrical charcoal and violet leather armour, hooded cloak
> with deep purple lining, two curved daggers held reverse-grip and away from the body, throwing
> knives on her belt, full body, side three-quarter view facing right, light on her feet, [shared
> style]

*Venom variant:* swap the daggers for short straight blades with a green-black venom sheen and
faint green drips.

### Seris — The Arcanist

**Who.** The court arcanist, who sealed herself in crystal and is the only partly-living Vessel.
She knows what the Intruder is and keeps the secret. Graceful, sad and precise.

**Build.** 1.73 m, slender and graceful. Long straight silver-white hair, pale lavender eyes,
glowing rune lines on the left forearm.

**Clothing.**
- Long ivory robes with midnight-blue panels and gold trim.
- A high collar and a gold waist sash.

**Weapons.**
- First: a tall dark staff topped with a pale blue crystal, and a gold-edged spellbook in the other hand.
- Second: Floating Focus, the staff gone, three or four crystal shards orbiting her open hand.

**Colours.** Ivory `#e8e0c8`, midnight blue `#1e2a4a`, gold `#c9a24a`, crystal blue `#9fd8ff`.

**Prompt.**
> Seris, a graceful sorceress, 1.73 m, long straight silver-white hair, pale lavender eyes, glowing
> pale-blue rune lines on her left forearm, long ivory robes with midnight-blue panels and gold
> trim, high collar, tall dark staff topped with a glowing pale-blue crystal held upright beside
> her, gold-edged spellbook in the other hand, full body, side three-quarter view facing right,
> [shared style]

*Floating Focus variant:* no staff; three or four glowing crystal shards orbit her raised open hand.

### Darius — The Survivor

**Who.** He came down from the surface 20 years ago to find his lost expedition and never left.
He is huge, hard, suspicious of the Intruder and quietly grieving.

**Build.** 1.94 m, massive and barrel-chested, shaved head, heavy brow. His left eye is damaged,
with a scar across it and a clouded eye. He wears a permanent scowl.

**Armour.**
- Patched, mismatched gear: rust-iron plates, thick leather, and salvaged machine parts such as
  rivets, a gear-plate on the chest and riveted bracers.
- Dark brown and faded orange throughout.

**Weapons.**
- First: a heavy two-handed warhammer with a long haft and a blocky iron head, held low in the right hand.
- Second: Improvised Heavy, a crude hammer made of basalt cores lashed to a haft with chain, with
  orange cracks glowing in the stone.

**Colours.** Rust `#8a4a22`, faded orange `#c0672a`, dark leather `#3a2a1e`, iron `#5a5a5a`.

**Prompt.**
> Darius, a massive grizzled survivor, 1.94 m, barrel chest, shaved head, scarred clouded left eye,
> scowling, patched mismatched armour of rust-iron plates, thick leather and salvaged machine parts
> with rivets and a gear plate on the chest, dark brown and faded orange, heavy long-hafted
> warhammer with a blocky iron head held low in his right hand clear of his legs, full body, side
> three-quarter view facing right, [shared style]

*Improvised Heavy variant:* the hammer head is two chained basalt cores with glowing orange cracks.

### Ilyr — The Unwritten

**Who.** A being from outside the world's "writing". He is not quite real, and he wakes at the end
of Chapter I. He is eerie, calm and unsettling.

**Build.** 1.80 m, lean, with unnatural poise: too still, slightly floating on his toes. Long pale
silver hair, pointed ears, glowing pale-blue eyes, grey-white skin with thin glowing cracks like
broken porcelain.

**Clothing.**
- White, black and pale-gold layered garments with sharp angles.
- Cloth fragments float detached around him, like torn pages.

**Weapon.** A thin, glass-like dimensional blade that looks half there, its edge flickering.

**Colours.** White `#f2f0ea`, black `#141418`, pale gold `#d8c48a`, crack glow `#bfe6ff`.

**Prompt.**
> Ilyr, an eerie otherworldly figure, 1.80 m, lean, unnaturally still and poised on his toes, long
> pale silver hair, pointed ears, glowing pale-blue eyes, pale grey skin with thin glowing cracks like
> broken porcelain, sharp layered white, black and pale-gold clothing, torn fragments of cloth
> floating detached around him, a thin glass-like flickering blade in his right hand, full body,
> side three-quarter view facing right, [shared style]

---

## 5. Common and elite monsters

### Echo Crawler (common, Zones 1-4)

**Look.**
- A stone spider the size of a large dog, built of slate-grey stone plates.
- Eight thin jointed legs.
- Green glowing spine-sacs along its back, which flare before it lunges (its tell).
- Small green eyes.

**Colours.** Slate `#5a6068`, glow green `#5cff8a`.

**Prompt.**
> A stone spider monster the size of a large dog, slate-grey stone plates, eight thin jointed legs,
> a row of glowing green sacs along its back, small green eyes, side view facing right, low
> crouched stance, [shared style]

### Subterranean Watcher (common)

**Look.**
- A floating porcelain-white sphere about 1 m across, with a hairline seam around it.
- One large cyan lens-eye.
- It hovers above a soft round shadow.
- The eye charges before it fires a laser beam (its tell).

**Colours.** Porcelain `#e8eef2`, cyan `#3fe0ff`.

**Prompt.**
> A floating porcelain-white sphere sentinel with a hairline seam and one large glowing cyan lens
> eye, smooth and ancient, hovering, side view with the eye facing right, [shared style]

### Calcified Husk (common, Zone 2)

**Look.**
- A human corpse turned to pale fungal stone, standing like a statue to ambush.
- Mushrooms and glowing yellow-green fungus grow from its head and shoulders.
- Roots wrap its legs.
- It puffs spores before it snares (its tell).

**Colours.** Bone-grey `#8a9080`, moss `#6a7a3a`, glow `#c8e85a`.

**Prompt.**
> A calcified fungal corpse monster, a human figure turned to pale grey-green stone, mushrooms and
> glowing yellow-green fungus sprouting from head and shoulders, roots wrapped around its legs,
> hunched statue pose, side view facing right, [shared style]

### Fungal Stalker (common, Zone 2; no painting yet)

**Look.**
- A thin, long-limbed fungal predator that hangs upside down from cave ceilings.
- Its body is a ribbed violet stalk with a drooping mushroom-cap "head", gills underneath, and two
  pale glowing eye-spots.
- Long hooked forelimbs.
- Thread-like mycelium strands hang from it.

**Colours.** Violet `#4a2f6a`, cap pink-violet `#9a5ac8`, eye-spots `#e0f0ff`.

**Prompt.**
> A lanky fungal predator monster that hangs upside-down from a cave ceiling, ribbed violet stalk
> body, drooping violet mushroom cap for a head with gills underneath, two pale glowing eye spots,
> long hooked forelimbs, thin mycelium threads hanging, side view facing right, [shared style]
> (Also make an upright version, dropping to the ground.)

### Drowned Courtier (common, Zone 3; no painting yet)

**Who.** A noble of the sunken court, drowned and still waiting for the queen.

**Look.**
- A thin, waterlogged noble in ruined court finery: a high lace collar, a tattered teal-and-gold
  doublet, a sash.
- Pale blue-grey skin, hair floating as if underwater, empty glowing white eyes.
- A slim rapier.
- Gold glints on the blade before it slashes.

**Colours.** Teal `#2f6a72`, tarnished gold `#a8883a`, skin `#9ab0b8`.

**Prompt.**
> A drowned court noble, thin and waterlogged, pale blue-grey skin, hair drifting as if underwater,
> empty glowing white eyes, ruined teal and tarnished gold court finery with a high lace collar,
> holding a slim rapier, side view facing right, [shared style]

### Branded Warden (elite, Zones 1, 3, 4)

**Who.** A royal guard of the Architects who herded citizens down during the Descent.

**Look.**
- 2.6 m, an armoured giant in corroded iron plate with a full great helm and a small crown-like crest.
- A glowing orange brand on the chest.
- A huge rounded tower shield on the left arm, covering most of the body.
- A gold-headed halberd in the right hand.
- A torn brown tabard.

**Colours.** Corroded iron `#6a6460`, brand `#ff7a3a`, halberd gold `#c9a24a`.

**Prompt.**
> A towering armoured royal guard, 2.6 m, corroded iron plate armour, full great helm with a small
> crown crest, a glowing orange brand on the chest, huge tower shield on the left arm, gold-headed
> halberd held upright in the right hand, torn brown tabard, side view facing right, [shared
> style]

### Choir Prelate (elite, Zone 3)

**Look.**
- A floating headless priest: empty ochre-and-gold vestments hold the shape of a body with no head
  or legs.
- A gold-trimmed stole with a cross-like sigil.
- One ghostly grey-blue hand swings a smoking brass censer.
- A golden aura when it empowers allies.

**Colours.** Ochre `#a8823a`, gold `#d8b04a`, ghost hand `#a0b0c0`.

**Prompt.**
> A floating headless priest, empty ochre and gold vestments holding the shape of a body with no
> head and no legs, gold-trimmed stole with a sacred sigil, one pale ghostly hand swinging a smoking
> brass censer, a faint golden aura, side view facing right, [shared style]

### Erased Echoes (the Ilyr segment)

The four Vessels as they look when reality "unwrites" them:
- The same figures, drained to near-white, as if overexposed.
- Edges break into horizontal glitch slices.
- Faint scan-line flicker, an afterimage offset to one side, and hollow glowing eyes.

Easiest route: generate each Vessel's art with this prompt added.
> ...drained to pale near-white, edges breaking into horizontal glitch slices, faint afterimage
> offset, hollow glowing eyes, unstable and half-erased

---

## 6. The bosses

### The Weeping Sovereign (Zone 3 throne hall)

**Who.** Caelan's queen, mad with grief, drowned on her throne for 300 years. Tragic, not evil.

**Look.**
- A tall gaunt queen in a ragged midnight-blue and violet gown, tattered and floating at the hem.
- A tall pale-blue crystal crown.
- Long white hair, pale blue skin.
- Glowing tears run down her face and freeze into crystal on her cheeks.
- Crystal shards grow from her shoulders.
- She holds two swords burning with blue spirit flame (the flames grow in phase 3).

**Phases to illustrate.**
1. Crowned and weeping, crystal tears.
2. Arms raised as spectral courtiers rise and water floods the hall.
3. She drops her crown, hair wild, two blue-flame sabres crossed.

**Colours.** Midnight `#1e2550`, violet `#4a3a7a`, ice `#a8e0ff`, flame `#4fb0ff`.

**Prompt.**
> The Weeping Sovereign, a tall gaunt drowned queen, ragged midnight-blue and violet gown floating at
> the hem, tall pale-blue crystal crown, long white hair, pale blue skin, glowing tears freezing into
> crystal on her cheeks, crystal shards on her shoulders, two swords wreathed in blue spirit flame
> held out to the sides, full body, side three-quarter view facing right, tragic and regal, [shared
> style]

### The Guardian Below (Zone 4 elevator)

**Who.** An ancient Architect construct that has kept the great lift for 300 years.

**Look.**
- A 4.4 m humanoid golem of weathered olive-grey stone and bronze-banded plates.
- A small blocky head with a narrow visor slit.
- Massive arms with oversized fists and bronze cuffs.
- A round glowing orange reactor core in the chest, inside a bronze frame.
- Moss and chain fragments hang from it.
- Heavy and slow.

**Phases to illustrate.**
1. Fists raised for a slam, the core dim.
2. Chains snapped and hanging from its arms.
3. Chest plates opened outward, the core blazing and cracks glowing orange all over.

**Colours.** Stone `#6a6e5e`, bronze `#9a6a3a`, core `#ff8a2a`.

**Prompt.**
> The Guardian Below, a 4.4 m ancient stone-and-bronze golem, weathered olive-grey stone plates with
> bronze bands, small blocky head with a narrow visor slit, massive arms with oversized fists and
> bronze cuffs, a round glowing orange reactor core in its chest within a bronze frame, moss and
> broken chains hanging from it, full body, side three-quarter view facing right, heavy stance,
> [shared style]

### The Abyssal Leviathan (Zone 4 Starless Shore)

**Who.** The thing in the black sea that ate Darius's expedition. Its fall tears reality open.

**Look.**
- A colossal sea serpent-dragon rising from black water.
- A long coiling neck and body covered in dark blue-black scales.
- A spined fin crest along its back.
- Swept-back horns, and a wide jaw full of needle teeth.
- **Twelve glowing pale-cyan eyes** clustered on its head and neck. They are its weak points, so
  they must read clearly.
- A curling barbed tail.

**Phases to illustrate.**
1. Rising from the water, mid-roar.
2. In total darkness, only the twelve eyes visible.
3. Rifts torn in the air around it, beams of white light shooting out.

**Colours.** Abyss `#14202e`, scale highlights `#3a5a7a`, eyes `#8ff0ff`.

**Prompt.**
> The Abyssal Leviathan, a colossal sea serpent-dragon rising out of black water, long coiling neck
> and body with dark blue-black scales, spined fin crest down its back, swept-back horns, wide jaw of
> needle teeth, twelve glowing pale-cyan eyes clustered on its head and neck, a curling barbed tail,
> side view facing left toward the player, [shared style]

(It faces **left** in its painting; that is fine. Just say which way it faces.)

---

## 7. The stages (backdrops, one per zone)

### Zone 1 — The Whispering Cavern

**What happened here.** The aqueducts and lower streets of Vael-Sora, collapsed into a cave.

**Look.**
- A vast dark cavern of blue-grey rock with stalactites.
- Ruined white marble aqueduct arches and broken bridges in the middle distance.
- Fallen columns.
- Still teal pools glowing faintly on the floor.
- Pale light shafts falling from cracks above, with dust in the air.

**Mood.** Lonely and quiet.

**Prompt.**
> Wide side-scrolling game background, a vast dark underground cavern of blue-grey rock with
> stalactites, ruined white marble aqueduct arches and broken bridges in the middle distance, fallen
> columns, still teal glowing pools, pale light shafts falling through cracks above with floating
> dust, lonely quiet mood, no characters, horizontally tileable, lower third dark and simple,
> [shared style]

### Zone 2 — The Luminous Mycelium Forest

**Look.**
- Deep chasms filled with giant bioluminescent mushrooms: teal-glowing and violet-glowing caps with
  spotted tops.
- Hanging vines with glowing bulbs.
- Rope-and-plank bridges strung between mushroom stalks.
- Drifting spores and a teal mist far below.

**Mood.** Beautiful, alien and vertical.

**Prompt.**
> Wide side-scrolling game background, a deep underground chasm forest of giant bioluminescent
> mushrooms with teal and violet glowing spotted caps, hanging vines with glowing bulbs, rope and
> plank bridges between mushroom stalks, drifting glowing spores, teal mist in the depths, magical
> alien mood, no characters, horizontally tileable, lower third dark and simple, [shared style]

### Zone 3 — The Sunken Palace

**Look.**
- Flooded palace halls of pale veined marble with tall columns and vaulted ceilings.
- Knee-deep teal water reflecting the light.
- Golden rune circles glowing on the walls.
- Tall stained-glass windows lit from behind in blue and amber.
- A domed throne hall in the far distance.

**Mood.** Drowned grandeur and grief.

**Prompt.**
> Wide side-scrolling game background, flooded underground palace halls, pale veined marble columns
> and vaulted ceilings, still teal water reflecting the light, golden glowing rune circles on the
> walls, tall stained glass windows lit in blue and amber, a domed throne hall in the distance,
> drowned grandeur, melancholy, no characters, horizontally tileable, lower third dark and simple,
> [shared style]

### Zone 4a — The Sealed Rift

**Look.**
- A colossal crack in the world.
- Black basalt cliffs and jagged spires.
- Glowing white-blue rift tears hanging in the air like lightning frozen in place.
- Ruined Architect towers clinging to the cliffs.
- Faint orange veins of heat in the rock.
- The great lift shaft with its chains, lit from below.

**Mood.** Oppressive, ancient, dangerous.

**Prompt.**
> Wide side-scrolling game background, a colossal underground rift, black basalt cliffs and jagged
> spires, glowing white-blue tears in the air like frozen lightning, ruined stone towers clinging
> to the cliffs, faint orange heat veins in the rock, a vast elevator shaft with hanging chains lit
> from below, oppressive and ancient, no characters, horizontally tileable, lower third dark and
> simple, [shared style]

### Zone 4b — The Starless Shore

**Look.**
- A black underground ocean under a rock ceiling so high it looks like a starless night sky.
- A wet slate shore and broken stone piers.
- The wreck of a surface expedition camp: torn tents, ropes, a lantern.
- Black water with slow silver highlights.
- Far rift-lights on the horizon.

**Mood.** Vast, still, dreadful.

**Prompt.**
> Wide side-scrolling game background, a black underground ocean beneath a cavern ceiling so high it
> looks like a starless night sky, wet slate shore, broken stone piers, the ruins of an expedition
> camp with torn tents and ropes, black water with slow silver highlights, faint white rift lights on
> the far horizon, vast still and dreadful, no characters, horizontally tileable, lower third dark
> and simple, [shared style]

### Beyond the Rift (Ilyr's awakening)

**Look.**
- A void that is not quite a place.
- A pale floor of cracked white stone floating in black-blue nothing.
- Fragments of the earlier zones (an aqueduct arch, a mushroom, a palace column) hang broken in the
  distance.
- Thin glowing pale-gold lines like unfinished drawing strokes.

**Prompt.**
> Wide side-scrolling game background, a dreamlike void, a pale cracked white stone floor floating in
> black-blue nothingness, broken fragments of a marble aqueduct arch, a giant mushroom and a palace
> column hanging in the distance, thin glowing pale-gold lines like unfinished sketch strokes,
> unreal and quiet, no characters, horizontally tileable, [shared style]

---

## 8. Small pieces (if you want to go further)

- **Soul Altar:** stepped grey stone with a shallow basin, a blue-white soul flame inside a thin
  gold halo ring.
- **Masonry wall:** dark cracked stone blocks with glowing orange veins in the cracks.
- **Rune door:** a round stone door with a circle of dead runes that light gold when solved.
- **Arena lock bars:** an iron portcullis with ember-red glow.
- **Pickups:**
  - Faded Parchment: a curled yellowed scroll.
  - Echoing Relic: a small glowing keepsake.
  - Soul Shards: blue-white crystal splinters.
- **Vessel face portraits** for the swap wheel: head and shoulders of each Vessel, square, facing
  forward.

---

## 9. When you have the images

Send them, or drop them in `docs/design/concept-art/` and tell me the file names, and I'll:
- cut the figures out;
- set heights and anchors;
- re-rig the parts for animation;
- replace the backdrops;
- re-shoot the same screens so you can compare before and after.
