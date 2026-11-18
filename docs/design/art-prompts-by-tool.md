# Soul Vessels — Concept Art Prompts, Split by AI Tool

One part per tool, so each free tool's daily limit only has to cover its own part. Every tool gets
the same style block, so the parts still match.

**Before you start:** free limits change often. If a tool runs out, finish its part the next day
or move the leftover images to the backup tool named in its section. Each part lists its images
in priority order, so do them top to bottom.

| Part | Tool | Why this tool | Backup |
| --- | --- | --- | --- |
| A. The 5 Vessels + the Intruder (design, parts, poses, turnaround each: about 22 images) | **Google Gemini** (image generation) | Best at keeping the same character across several images and edits ("same character, now running") | ChatGPT |
| B. The 3 bosses (design, parts, poses each: 9 images, plus 6 phase images) | **ChatGPT** (image generation) | Follows long, detailed descriptions best | Gemini |
| C. Monsters (8) | **Leonardo.ai** | Many images per day, a "transparent background" option, good for game assets | Microsoft Copilot / Bing Image Creator |
| D. Stage backgrounds (6) | **Ideogram** | Lets you pick very wide aspect ratios (3:1) | Leonardo.ai (custom size) |
| E. Props, items, portraits | **Microsoft Copilot / Bing Image Creator** | Free, quick, fine for small objects | Leonardo.ai |

**For Leonardo, Ideogram and Bing:** their prompt box is short, so paste **one image prompt at a
time**. Each one already includes the short style line. Gemini and ChatGPT take the long prompts
as they are.

---

## What every character needs for smooth animation

The game is a side-scroller: a character facing left is the right-facing art mirrored, so **one
facing direction is enough**. Smooth motion comes from three sheets per character, in this order
of importance:

1. **The design:** one clean full-body image facing right. Every other sheet must match it exactly.
2. **The parts sheet** (the most useful for animation). The same character taken apart and laid out
   flat with gaps between the pieces:
   - head, torso, pelvis;
   - upper arm, forearm and hand for each arm;
   - thigh, shin and foot for each leg;
   - the weapon, the shield, and loose cloth such as the cape.

   Each piece is drawn whole, including the parts normally hidden (the shoulder under the
   pauldron, the hip under the cape). The game rotates these pieces, so no hidden area may be left
   blank.
3. **The pose sheet.** The same character, scale and view in key poses, one row:
   - idle;
   - two run poses (left leg forward, right leg forward);
   - jump; fall;
   - attack wind-up; attack strike; follow-through;
   - block or dodge;
   - hit recoil; kneel or death;
   - one pose per special ability.

   The game blends between these drawings instead of bending one picture.
4. **The turnaround** (reference only): front, three-quarter, side and back in one row. It keeps the
   character consistent while the AI makes the other sheets.

Lopsided details (Caelan's shield and big pauldron, Darius's scarred left eye) swap sides when the
art is mirrored. That's normal in 2D games. If one bothers you, ask the AI for that piece facing
left and I'll swap it in.

**Tips that help the AI stay consistent:**
- Make the design first, then **upload it as the reference image** for each sheet, or say "same
  character as the previous image" in the same chat.
- Keep the background plain dark slate (`#3a3f4a`) and the light from the upper left on every sheet.
- Regenerate any sheet where the outfit, colours or proportions drift from the design.

---

## The style block (already inside every prompt below)

**Long version (Gemini and ChatGPT):**

> Grim, sacred, decaying dark fantasy. Religious and funereal imagery twisted by grief and guilt:
> reliquaries, shrouds, tarnished gold, candle wax, iron, bone, marble stained by centuries of dark
> water. Hand-painted 2D concept art, heavy chiaroscuro, deep black shadows, rich textured
> brushwork, crisp dark ink outlines on silhouettes, readable on a phone screen. Desaturated earthy
> palette (ash grey, bone, rust, bruised blue, dried-blood brown, tarnished gold) broken by a few
> glowing accents: cold white-blue soul-light, fungal teal and violet, ember orange. Tragic,
> solemn, oppressive, beautiful in its decay. Grounded proportions, not chibi, not anime. Every
> surface is worn: dents, rust, wax drips, cracks, mould, torn cloth. No text, no logos, no
> watermark, no UI.

**Short version (Leonardo, Ideogram, Bing):**

> grim sacred dark fantasy, hand-painted 2D concept art, heavy chiaroscuro, ink outlines,
> desaturated ash and rust palette with glowing accents, decayed and tragic, no text

---

## A. Gemini — the Vessels and the Intruder

Paste the whole block below as your first message. Then send **"next"** after each image.

```text
You are the lead concept artist for "Soul Vessels", a 2.5D side-scrolling dark fantasy action game for mobile. You will make one image per message, in the order below. After each image, wait for me to say "next". Keep every character in exactly the same art style and lighting throughout.

STYLE (every image): Grim, sacred, decaying dark fantasy. Religious and funereal imagery twisted by grief and guilt: reliquaries, shrouds, tarnished gold, candle wax, iron, bone, marble stained by centuries of dark water. Hand-painted 2D concept art, heavy chiaroscuro, deep black shadows, rich textured brushwork, crisp dark ink outlines on silhouettes. Desaturated earthy palette (ash grey, bone, rust, bruised blue, dried-blood brown, tarnished gold) broken by a few glowing accents: cold white-blue soul-light, fungal teal and violet, ember orange. Tragic, solemn, beautiful in its decay. Grounded proportions, about 7.5 heads tall, not chibi, not anime. Worn surfaces: dents, rust, wax drips, cracks, torn cloth. No text, no logos, no watermark.

FORMAT (every character image): one full-body character, nothing cropped, feet visible. Side three-quarter view FACING RIGHT. Plain flat dark slate background (#3a3f4a), no scenery, no floor shadow. Neutral ready stance with arms and weapon held clear of the body (the weapon must not overlap the torso or legs). Key light from upper left, cool rim light from behind. Tall portrait image.

WORLD: Vael-Sora was a marble kingdom around a well of soul-light. 300 years ago the god-like Architects sank it underground in one night, the Descent, to seal away something called the Unwritten. The dead stayed bound to their bodies. The player is a bodiless soul who possesses fallen warriors called Vessels.

FOR EACH VESSEL, MAKE FOUR IMAGES BEFORE MOVING TO THE NEXT VESSEL:
 (a) DESIGN: the character as described, in the format above.
 (b) PARTS SHEET: the SAME character, taken apart and laid flat on the slate background with clear gaps between pieces, every piece facing right in its neutral orientation: head; torso; pelvis; for each arm the upper arm, forearm and hand as separate pieces; for each leg the thigh, shin and foot as separate pieces; the weapon; the shield or off-hand item; loose cloth (cape, cloak, robe tail) as its own piece. Draw every piece COMPLETE, including the areas normally hidden by other pieces (the shoulder under the pauldron, the hip under the cape), with clean ends at the joints. Same scale, colours and lighting as the design. Wide landscape image.
 (c) POSE SHEET: the SAME character, same scale and side three-quarter view facing right, in one row of key poses with space between them: idle, run (left leg forward), run (right leg forward), jump, fall, attack wind-up, attack strike, follow-through, block or dodge, hit recoil, kneeling or fallen, then one pose for each special ability named for that Vessel. Wide landscape image; split into two rows if needed.
 (d) TURNAROUND: the SAME character in front view, three-quarter view, side view and back view, side by side, same scale. Wide landscape image.
Ask me "next" between each image.

Special-ability poses per Vessel (for the pose sheet):
- Caelan: shield raised in a block; sword thrust forward in a lunge; sword raised overhead, about to bring down a shockwave; planting the sword into the ground.
- Nyra: a low dash with the cloak trailing; throwing three knives; a spinning slash; crouched in shadow.
- Seris: casting a bolt from the staff; staff planted with frost spreading; both hands raised, shaping a shield of light; the staff raised high, calling down a meteor.
- Darius: hammer raised far behind his head; the hammer slammed two-handed into the ground; a lowered-shoulder charge; a leap with the hammer overhead.
- Ilyr: one hand tearing the air open; pulling an enemy toward him with an open hand; blinking (body thin and smeared sideways); both arms raised as space breaks around him.

IMAGES, IN ORDER (each Vessel = images a to d):
1. CAELAN, the Knight. The queen's sworn knight, who died guarding a sealed door; noble, tired, loyal. 1.88 m, muscular, short brown hair, a scar through his left eyebrow, stubble. Weathered navy and dark-steel plate armour, dented and scratched, an oversized left pauldron, a torn deep-blue cape ragged at the hem, brown leather straps, a prayer cord and wax seal on his belt. A straight longsword held low in his right hand, and a tall dark-steel kite shield with a faded blue field on his left arm.
2. NYRA, the Wanderer. A smuggler who mapped escape routes while the city sank, found strangled by roots; quick, wry, wary. 1.69 m, slim and athletic, auburn hair in a high ponytail, amber eyes, a small tattoo behind her ear. Asymmetrical charcoal and violet leather armour, a hooded cloak with the hood down and deep purple lining, rope burns on her neck. Two curved daggers held reverse-grip away from the body, throwing knives on her belt.
3. SERIS, the Arcanist. The court arcanist, who sealed herself in crystal and is the only partly-living Vessel; graceful, sad, secretive. 1.73 m, long straight silver-white hair, pale lavender eyes, glowing pale-blue rune lines on her left forearm, small crystal shards still clinging to her skin. Long ivory robes with midnight-blue panels and tarnished gold trim, a high collar. A tall dark staff topped with a glowing pale-blue crystal held upright beside her, and a gold-edged spellbook in her other hand.
4. DARIUS, the Survivor. He came down from the surface 20 years ago looking for his lost expedition and never left; huge, hard, suspicious, grieving. 1.94 m, massive, barrel-chested, shaved head, a scarred clouded left eye, scowling. Patched mismatched armour of rust-iron plates, thick leather and salvaged machine parts (rivets, a gear-plate on the chest, riveted bracers), dark brown and faded orange. A heavy long-hafted warhammer with a blocky iron head held low in his right hand, clear of his legs.
5. ILYR, the Unwritten. A being from outside the world's writing, not quite real; eerie, calm, unsettling. 1.80 m, lean, unnaturally still, poised on his toes. Long pale silver hair, pointed ears, glowing pale-blue eyes, grey-white skin with thin glowing cracks like broken porcelain. Sharp layered white, black and pale-gold garments, with torn fragments of cloth floating detached around him like pages. A thin glass-like blade in his right hand, its edge flickering.
6. THE INTRUDER (the player's soul). A small floating wisp about the size of a head: a teardrop of white-blue soul-light with a brighter pulsing core, two trailing tendrils like a stretched candle flame, and a faint simple sigil inside (a ring and one vertical line). No face. Square image.
7. LINE-UP: all five Vessels standing side by side on the same dark slate background, same scale (Nyra shortest, Darius tallest), facing three-quarter right, for a character sheet.

AFTER THE LINE-UP, if I ask for second weapons, make a design image and a parts sheet for each: Caelan without a shield, holding a broad notched two-handed greatsword; Nyra with short straight blades with a green-black venom sheen; Seris with no staff and crystal shards orbiting her open hand; Darius with a crude hammer of two chained basalt stones with glowing orange cracks.

Start with image 1.
```

---

## B. ChatGPT — the bosses

Paste the whole block below. It makes 3 boss images, then the phase images if you have images left.

```text
You are the lead concept artist for "Soul Vessels", a 2.5D side-scrolling dark fantasy action game. Make one image per message, in the order below, and wait for me to say "next". Keep all images in the same style.

STYLE: Grim, sacred, decaying dark fantasy. Religious and funereal imagery twisted by grief and guilt: reliquaries, shrouds, tarnished gold, candle wax, iron, bone, drowned marble. Hand-painted 2D concept art, heavy chiaroscuro, deep black shadows, textured brushwork, crisp dark ink outlines. Desaturated palette (ash, bone, rust, bruised blue, tarnished gold) with a few glowing accents. Tragic, monumental, oppressive. No text, no logos, no watermark.

FORMAT: the whole boss in frame, nothing cropped, on a plain flat dark slate background (#3a3f4a) with no scenery, side three-quarter view. A human figure 1.9 m tall standing in the bottom corner for scale (a dark silhouette only).

WORLD: Vael-Sora, a marble kingdom sunk underground 300 years ago by the god-like Architects to seal away "the Unwritten". The dead are still bound to their bodies.

1. THE WEEPING SOVEREIGN, the drowned queen. Caelan's queen, mad with grief, still on her throne after 300 years; tragic, not evil. Tall and gaunt, in a ragged midnight-blue and violet gown floating at the hem as if underwater. A tall pale-blue crystal crown. Long white hair, pale blue-grey skin. Glowing tears run down her face and freeze into crystal on her cheeks, and crystal shards grow from her shoulders. She holds two swords burning with blue spirit flame out to the sides. Facing right.
2. THE GUARDIAN BELOW, the lift keeper. An ancient construct of the Architects, guarding the great elevator for 300 years; 4.4 m tall. A humanoid golem of weathered olive-grey stone plates bound with bronze bands, a small blocky head with a narrow visor slit, massive arms with oversized fists and bronze cuffs, and a round glowing orange reactor core in its chest inside a bronze frame. Moss, candle stubs and broken chains hang from it; prayer seals are stuck to its stone. Heavy, slow, facing right.
3. THE ABYSSAL LEVIATHAN, the thing in the black sea. It ate a whole surface expedition, and its death tears reality open. A colossal sea serpent-dragon rising from black water: a long coiling neck and body of dark blue-black scales, a spined fin crest down its back, swept-back horns, a wide jaw full of needle teeth, and TWELVE glowing pale-cyan eyes clustered on its head and neck (they must read clearly; they are its weak points). A curling barbed tail. Facing LEFT.

FOR EACH BOSS, after its design image, make two more images before the next boss:
 (a) PARTS SHEET: the SAME boss taken apart and laid flat on the slate background with gaps between pieces, every piece drawn complete, including areas normally hidden. Sovereign: head with crown, torso, gown skirt, each upper arm, forearm and hand, each sword. Guardian: head, torso with the core, pelvis, each upper arm, each forearm and fist, each leg; the core also drawn separately with its chest plates open. Leviathan: head with jaw closed, the lower jaw separately (so the mouth can open), the neck in three segments, the body coil, the tail, the tail tip, the fin crest.
 (b) POSE SHEET: the SAME boss, same scale and view, in a row of key poses with space between them: idle; hit recoil; staggered or kneeling; dying; then a WIND-UP and a STRIKE pose for each attack:
   - Sovereign: crystal tears flung outward; a two-sword cross slash; summoning, arms raised; a spinning blue-flame frenzy.
   - Guardian: right fist raised high, then slammed down; a backhand swing; both fists raised, then pounding the ground; leaning back with the chest open for the laser; arms crossed over the core, then flung open for the shockwave.
   - Leviathan: tail coiled back, then whipping; neck reared back with the jaw open, then lunging to bite; rearing up out of the water, then slamming down; the head raised in a roar; diving under the water; surfacing.
Ask me "next" between each image.

PHASES (only if I say "phases"; same boss, same style, each a separate image):
- Sovereign 2: arms raised as four ghostly drowned courtiers rise around her and the water floods in.
- Sovereign 3: her crown dropped at her feet, hair wild, the two blue-flame sabres crossed, flames roaring.
- Guardian 2: chains snapped and trailing from its wrists, tilting forward on a slanted floor.
- Guardian 3: chest plates opened outward, the core blazing, glowing orange cracks spread over its whole body.
- Leviathan 2: total darkness, only the twelve eyes and a faint outline visible.
- Leviathan 3: rifts torn in the air around it, beams of white light shooting from them, mid-roar.

Start with image 1.
```

---

## C. Leonardo.ai — the monsters

**Settings:**
- Turn on **Transparent background** if your model offers it; otherwise add "plain dark slate background".
- Use a portrait size (for example 832 × 1216), or square for the Watcher and Crawler.
- Choose a painterly or illustration model, not a 3D or anime one.

Paste each prompt on its own, in this order.

1. **Echo Crawler**
   > A stone spider monster the size of a large dog, built of cracked slate-grey stone plates like a
   > broken tombstone, eight thin jointed legs, a row of glowing green sacs along its spine, small
   > green eyes, side view facing right, crouched, full body, plain dark background, grim sacred
   > dark fantasy, hand-painted 2D concept art, heavy chiaroscuro, ink outlines, desaturated palette
   > with glowing accents, no text

2. **Subterranean Watcher**
   > A floating porcelain-white sphere sentinel about one metre wide with a hairline seam and faint
   > cracks, a single large glowing cyan lens eye, old reliquary feel, hovering, side view eye facing
   > right, plain dark background, grim sacred dark fantasy, hand-painted 2D concept art, heavy
   > chiaroscuro, ink outlines, no text

3. **Calcified Husk**
   > A calcified fungal corpse, a human figure turned to pale grey-green stone like a ruined saint
   > statue, mushrooms and glowing yellow-green fungus sprouting from its head and shoulders, roots
   > wrapped around its legs, hunched, side view facing right, full body, plain dark background, grim
   > sacred dark fantasy, hand-painted 2D concept art, heavy chiaroscuro, ink outlines, no text

4. **Branded Warden**
   > A towering armoured royal executioner-guard, 2.6 m, corroded iron plate armour, full great
   > helm with a small crown crest, a glowing orange brand burned into the chest plate, a huge
   > battered tower shield on the left arm, a gold-headed halberd upright in the right hand, torn
   > brown tabard, side view facing right, full body, plain dark background, grim sacred dark fantasy,
   > hand-painted 2D concept art, heavy chiaroscuro, ink outlines, no text

5. **Choir Prelate**
   > A floating headless priest, empty ochre and tarnished-gold vestments holding the shape of a body
   > with no head and no legs, gold stole with a sacred sigil, one pale ghostly hand swinging a smoking
   > brass censer, faint golden aura, side view facing right, plain dark background, grim sacred dark
   > fantasy, hand-painted 2D concept art, heavy chiaroscuro, ink outlines, no text

6. **Fungal Stalker**
   > A lanky fungal predator hanging upside-down from a cave ceiling, ribbed violet stalk body, a
   > drooping violet mushroom cap for a head with gills underneath, two pale glowing eye-spots, long
   > hooked forelimbs, mycelium threads hanging down, side view facing right, full body, plain dark
   > background, grim dark fantasy, hand-painted 2D concept art, heavy chiaroscuro, ink outlines, no
   > text

7. **Drowned Courtier**
   > A drowned court noble, thin and waterlogged, pale blue-grey skin, hair drifting as if underwater,
   > empty glowing white eyes, ruined teal and tarnished-gold court finery with a high lace collar,
   > holding a slim rapier, side view facing right, full body, plain dark background, grim sacred dark
   > fantasy, hand-painted 2D concept art, heavy chiaroscuro, ink outlines, no text

**Poses for each monster.** After a monster's design is done, upload it with Leonardo's
**Character Reference** (or "Image Guidance") and paste the matching line below. Make one image per
line, with the same settings.

> Pose sheet of the same monster, same scale and side view facing right, one row with space between
> poses: [poses], plain dark background, grim sacred dark fantasy, hand-painted 2D concept art, heavy
> chiaroscuro, ink outlines, no text

Replace `[poses]` with that monster's list:
- **Echo Crawler:** idle crouch, walking (legs mid-step), back sacs glowing before a lunge, leaping
  forward, hit recoil, flipped over dead.
- **Subterranean Watcher:** idle hover, eye charging bright, firing a beam, cracked and falling.
- **Calcified Husk:** frozen statue pose, waking and stepping, spores puffing from its fungus,
  roots lashing forward, crumbling.
- **Branded Warden:** standing guard, walking, halberd raised for a thrust, thrusting, shield
  charge, shield lowered and staggered, falling.
- **Choir Prelate:** floating idle, golden aura flaring, censer swung to throw orbs, vanishing in
  smoke, collapsing empty.
- **Fungal Stalker:** hanging from the ceiling, dropping, landing crouched, a hooked-claw swipe,
  dying.
- **Drowned Courtier:** half-submerged swimming, surfacing, rapier raised with a gold glint, a
  lunging slash, sinking.

Then make a **parts sheet** for each of the humanoid monsters (Husk, Warden, Prelate, Courtier):

> Parts sheet of the same monster taken apart and laid flat with gaps between pieces: head, torso,
> each upper arm, forearm and hand, each thigh, shin and foot, the weapon, the shield, every piece
> drawn complete including hidden areas, plain dark background, same style, no text

8. **Erased Echo** (one example; repeat with each Vessel's name and description if you have tokens left)
   > A ghostly half-erased knight in plate armour with a sword and shield, drained to pale near-white
   > as if overexposed, edges breaking into horizontal glitch slices, an afterimage offset to one side,
   > hollow glowing eyes, side view facing right, full body, plain dark background, grim dark fantasy,
   > hand-painted 2D concept art, no text

---

## D. Ideogram — the stage backgrounds

**Settings:**
- Aspect ratio **3:1** (or the widest it offers).
- Style "Design" or "General", not "Realistic". Magic Prompt **off**, so it keeps your wording.

Paste each prompt on its own.

1. **The Whispering Cavern**
   > Wide side-scrolling game background, a vast dark cavern of blue-grey rock with stalactites,
   > ruined white marble aqueduct arches and broken bridges in the middle distance, fallen columns,
   > still teal glowing pools, pale light shafts through cracks above with drifting dust, lonely and
   > silent, no characters, lower third dark and plain, horizontally tileable, grim sacred dark
   > fantasy, hand-painted 2D concept art, heavy chiaroscuro, desaturated with glowing accents, no text

2. **The Luminous Mycelium Forest**
   > Wide side-scrolling game background, a deep underground chasm of giant bioluminescent mushrooms
   > with teal and violet glowing spotted caps, hanging vines with glowing bulbs, rope and plank
   > bridges between stalks, drifting glowing spores, teal mist far below, eerie and alien, no
   > characters, lower third dark and plain, horizontally tileable, hand-painted 2D dark fantasy
   > concept art, heavy chiaroscuro, no text

3. **The Sunken Palace**
   > Wide side-scrolling game background, flooded underground palace halls, pale veined marble
   > columns and vaulted ceilings stained by dark water, still teal water reflecting candlelight,
   > golden glowing rune circles on the walls, tall stained glass windows lit blue and amber, a domed
   > throne hall in the distance, drowned grandeur and grief, no characters, lower third dark and
   > plain, horizontally tileable, grim sacred dark fantasy, hand-painted 2D concept art, heavy
   > chiaroscuro, no text

4. **The Sealed Rift**
   > Wide side-scrolling game background, a colossal underground rift, black basalt cliffs and jagged
   > spires, glowing white-blue tears hanging in the air like frozen lightning, ruined stone towers
   > clinging to the cliffs, faint orange heat veins in the rock, a vast elevator shaft with hanging
   > chains lit from below, oppressive and ancient, no characters, lower third dark and plain,
   > horizontally tileable, grim dark fantasy, hand-painted 2D concept art, heavy chiaroscuro, no text

5. **The Starless Shore**
   > Wide side-scrolling game background, a black underground ocean beneath a cavern ceiling so high
   > it looks like a starless night sky, wet slate shore, broken stone piers, ruins of an expedition
   > camp with torn tents, ropes and a dead lantern, black water with slow silver highlights, faint
   > white rift lights on the horizon, vast still and dreadful, no characters, lower third dark and
   > plain, horizontally tileable, grim dark fantasy, hand-painted 2D concept art, no text

6. **Beyond the Rift**
   > Wide side-scrolling game background, a dreamlike void, a pale cracked white stone floor floating
   > in black-blue nothingness, broken fragments of a marble aqueduct arch, a giant mushroom and a
   > palace column hanging in the distance, thin glowing pale-gold lines like unfinished sketch
   > strokes, unreal and quiet, no characters, horizontally tileable, hand-painted 2D dark fantasy
   > concept art, no text

---

## E. Copilot / Bing Image Creator — props, items, portraits

Use **square** images. Paste each prompt on its own.

1. **Soul Altar**
   > A soul altar shrine, stepped grey stone with a shallow basin holding a blue-white soul flame inside
   > a thin gold halo ring, wax drips and old offerings, plain dark background, grim sacred dark fantasy,
   > hand-painted 2D concept art, heavy chiaroscuro, no text

2. **Cracked masonry wall**
   > A wall of dark cracked stone blocks with glowing orange veins in the cracks, about to crumble,
   > plain dark background, hand-painted 2D dark fantasy game prop, heavy chiaroscuro, no text

3. **Rune door**
   > A round sealed stone door carved with a circle of dead runes, faint gold light in some grooves,
   > grim sacred dark fantasy, hand-painted 2D game prop, plain dark background, no text

4. **Arena portcullis**
   > A heavy iron portcullis with ember-red glow in its joints, rusted and spiked, plain dark
   > background, hand-painted 2D dark fantasy game prop, no text

5. **Items** (one image)
   > A set of four dark fantasy game item icons on a dark background: a curled yellowed parchment
   > scroll, a small glowing keepsake relic, a cluster of blue-white soul crystal shards, and a dark
   > basalt core with orange cracks, hand-painted, heavy chiaroscuro, no text

6. **Portraits** (one per Vessel; use the same descriptions as part A)
   > Head and shoulders portrait of [Caelan / Nyra / Seris / Darius / Ilyr: paste the
   > description], facing forward, square, plain dark background, grim sacred dark fantasy,
   > hand-painted, heavy chiaroscuro, no text

---

## When the images come back

Put them in `docs/design/concept-art/` with clear names (`caelan.png`, `boss_guardian.png`,
`stage_sunken_palace.png`, and so on) and tell me. I'll cut them out, rig them, and re-shoot the game
screens so you can compare before and after.
