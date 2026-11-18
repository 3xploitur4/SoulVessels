# Ground art prompts (story 054)

The game now builds its ground in code: single stones, each with its own colour and broken
corners, laid in courses, with cracks, water stains, fallen stones, candles, skulls, bones,
rubble, broken columns and gravestones. If you want the ground hand-painted instead, generate the
sheets below and put them in `docs/design/concept-art/ground/`. I cut them up and put them on the
ground's front face and walkable edge, and the code ground stays as the fallback.

Use the same free tool you used for the concept sheets. Generate one zone per image. If a tool
cannot do transparency, ask for a flat pure-black background and I will remove it.

## What every image must follow

- **Camera:** straight side view, perfectly front-on, no perspective and no vanishing point. It
  is a 2D platformer cross-section.
- **Tiling:** the left and right edges must join seamlessly when repeated side by side.
- **Layout:** the walkable top edge runs straight and level across the image, at about 20 % from
  the top. Everything above that line is empty (transparent or black). Below it, the ground fades
  into near-black by the bottom 30 %.
- **Style:** dark gothic religious pixel art, in the style of Spanish Baroque ruins. Hand-placed
  stones, nothing repeated, nothing clean. Muted palette: charcoal, iron grey, dirty white,
  tarnished gold, burgundy, muted blue. Light comes from the upper left.
- **Size:** 2048 x 512 pixels. Pixel art drawn at 512 x 128 and scaled up 4x with no smoothing is
  ideal.
- **No text,** no characters, no frame or border.

## Prompt A: the ground strip (one per zone)

> A seamless, horizontally tileable 2D side-view ground strip for a dark gothic pixel-art
> platformer in the style of Blasphemous. Straight front-on cross-section, no perspective. A
> level walkable top edge 20 % from the top, made of worn paving slabs of different lengths:
> chipped corners, cracks, stains, a thin layer of ancient dust, a few broken and sunken slabs.
> Below the edge, a wall of hand-laid ashlar stones in uneven courses. Every stone is a
> different size, shade and level of erosion. Dark mortar gaps, a few stones fallen out leaving
> black holes, water stains running down from the top edge, hairline cracks, [ZONE DETAILS].
> The masonry fades into deep shadow and near-black toward the bottom. Light from the upper
> left catches the top edge and the upper stones. Muted palette of charcoal, iron grey, dirty
> white and tarnished gold. Empty transparent background above the top edge. Crisp pixel art,
> no anti-aliasing, 2048x512, no text.

Replace `[ZONE DETAILS]` with one of these:

| Zone | Zone details |
| --- | --- |
| 1, the Whispering Cavern | blue-grey limestone of a collapsed aqueduct, dark green moss hanging from the joints of the top edge, a few dripping stains, cold blue-grey light |
| 2, the Luminous Mycelium Forest | rough violet-grey rock instead of cut stone, thick roots growing over the edge and through the joints, glowing teal and pink fungus buds on the roots and in the cracks, mossy teal top |
| 3, the Sunken Palace | pale veined marble blocks of a drowned palace, a tarnished gold moulding running under the top edge, green-black water stains, barnacle-like crust near the bottom |
| 4, the Sealed Rift | black basalt chunks, glowing orange ember seams in some joints and cracks, ash dust on the top edge, scorched stains |
| 4, the Starless Shore | wet slate stones, dark and glossy, pale salt crust along the top edge, small shells and bone fragments wedged in the joints |

## Prompt B: ground props (one sheet for every zone)

> A sprite sheet of separate props on a transparent background for a dark gothic pixel-art
> platformer in the style of Blasphemous. Straight side view, no perspective, every prop isolated
> with space around it, no overlaps. Clusters of melted church candles of different heights with
> small flames and pooled wax; human skulls on their own and piled with bones; scattered long
> bones; small heaps of broken masonry rubble; broken stone column stumps at three heights;
> leaning weathered gravestones with rounded tops and worn carved crosses; a cracked stone
> reliquary box; a small wayside shrine with a candle. Muted palette of charcoal, bone white,
> tarnished gold and dried burgundy, light from the upper left. Crisp pixel art, no anti-aliasing,
> 2048x2048, no text.

## Prompt C: seamless stone surface (optional, one per zone)

This texture goes on every single stone, so it only needs surface detail, not stone shapes.

> A seamless tileable square texture of a weathered stone surface, viewed straight on, for a dark
> gothic game: fine grain, pitting, erosion, faint stains and hairline cracks, a thin layer of
> ancient dust, no individual bricks or joints, evenly lit with no shadows, mid-grey with subtle
> [blue-grey / violet / pale marble with faint veins / black basalt] tones. 1024x1024, no text.

## What I do with them

- **Ground strips:** cut to the walkable edge line, laid along every edge facing the camera (in
  front of the stones), the black fade blending into the existing darkness.
- **Props:** sliced out like the earlier concept sheets and scattered on the walkable tops in
  place of the built candles, skulls and gravestones.
- **Stone textures:** they replace the current rock grain on the built stones, so every stone
  carries painted detail.
