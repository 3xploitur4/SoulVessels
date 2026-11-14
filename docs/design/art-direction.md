# Soul Vessels — Art Direction (from the concept sheets)

2026-11-14. The look of the game follows the three concept sheets in `docs/design/concept-art/`
(`vessels.webp`, `enemies.webp`, `zones.webp`). This note says how the sheets become the game, what
is still a stand-in, and how to replace any piece. Decisions D-032 and D-033.

## The rule

Painted characters in built rooms. Vessels and enemies are the concept paintings themselves, cut
out and animated; rooms are 3D (so parallax, lights and fog are real) and dressed to match the
zone paintings, with the painting itself as the far backdrop.

## Characters and enemies

| What | How |
| --- | --- |
| Source | `tools/art/slice_concepts.gd` removes the sheet background, separates the figures and writes one sprite each to `assets/art/sprites/` (13 figures: 5 Vessels, 5 enemies, 3 bosses). |
| In the world | `data/art/sprites.json`: height in metres, which way the painting faces, feet or centre anchor, where its tell glows, weapon-arc colour, face square for the swap wheel. |
| Motion | One pose per figure, so motion comes from the body shader (`spatial_char_sprite_body`): legs step in turn, the body leans, squashes, rolls and breathes, cape edges sway. Attacks add a weapon arc of light; blocks a gold guard glow; dashes leave afterimages; landings puff dust; deaths burn away in soul-light. |
| Readability | Sprites carry their own light (about 60 % self-lit), so they stay clear in dark rooms. Telegraphs keep colour + shape + sound; the enemy's own tell glows on the painting (Crawler spine sacs, Watcher eye, Warden brand). |
| Screen size | Camera 11.5 m back: a Vessel is about a quarter of the screen height. |

## Rooms

| Layer | Zone 1, Whispering Cavern | Zone 2, Luminous Mycelium Forest |
| --- | --- | --- |
| Far backdrop | The zone 1 painting, mirror-tiled | The zone 2 painting, mirror-tiled |
| Far (z -15) | A few dark stone arches | Towering dim mushrooms |
| Middle (z -6.5) | Broken columns, lone arches | Teal and violet spotted mushrooms |
| Floor dressing | Rubble blocks, teal pools | Glowing sprouts |
| Ceiling | Stalactites | Stalactites, vines with glowing bulbs |
| Air | Dust motes, pale light shafts, blue ground mist | Spores, teal shafts, teal mist |
| Play surfaces | Dark cave rock, ashlar ledges, pale worn slabs on every walkable top | Violet rock, bark ledges, glowing moss on every walkable top |

Walkable tops always carry the brightest surface in the room, so platforms never get lost in the
decor. Textures are generated tileable files in `assets/art/textures/` (`tools/art/make_textures.gd`)
and applied in world space, so any file can be replaced by hand-painted art of the same name.

## Gates, altars, UI

Gates read by shape as well as colour: iron portcullis with embers (arena lock), bars of gold light
(shield ward), rising black mist with a violet rim (shadow veil), stone door with a rune circle
(light-rune), cracked stone with orange veins (masonry), dark water (flooded stair). Altars are
stepped stone with a basin and a blue-white soul flame in a gold halo. Menus use dark plates with a
worn gold edge and a serif display face taken from the device; the title shows the Vessel line-up.

## Still stand-ins (need art or a decision)

| Item | Now | To finish |
| --- | --- | --- |
| Fungal Stalker | The Husk painting, smaller, tinted violet | A concept painting for it |
| Animation | One pose per figure, moved by shader | Extra poses per figure (attack, run, hurt) would allow real frame animation |
| Sprite sharpness | Sheets are 1024 px wide; each figure is about 230 x 470 px | Larger sheets: rerun the slicer, nothing else changes |
| Rooms | Code-built shapes with generated textures | Modelled set pieces (needs Blender and a 3D generator, not on this PC) |
| Zones 3 and 4 | Paintings cut and ready as backdrops | Built in M3 and M4 |
| M1 combat sandbox | Old primitive arena (test bed only) | Not planned |

## Replacing art

- A better character sheet: overwrite the file in `docs/design/concept-art/`, run
  `godot --headless --path . -s tools/art/slice_concepts.gd`, check `builds/art/contact.png`.
- One sprite by hand: overwrite `assets/art/sprites/<id>.png` (transparent background), adjust
  `height_m` in `data/art/sprites.json` if its proportions changed.
- A surface: overwrite `assets/art/textures/<name>.png` and `<name>_n.png`.
