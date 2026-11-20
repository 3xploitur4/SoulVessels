# Attack pose prompts for Leonardo AI (story 057)

The attacks are animated by bending the cut-out parts of each character's painting. However the
joints are tuned, a painted arm rotated at the shoulder can't look like a real swing. These prompts
make **pose sheets**: the same character drawn in every key moment of each attack. With them I
can do one of two things:

1. **Frame animation (best).** If a sheet is clean (same character, same size, plain background), I
   cut every pose out as its own frame and the attacks play as real drawn frames, like Blasphemous.
2. **Re-pose the rig.** If the frames don't match each other well enough, I copy the body and blade
   angles from them into the rig, so at least the motion is right.

## Leonardo AI settings

Do these once for every character:

1. **Image Guidance → Character Reference:** upload the character's v2 painting from
   `docs/design/concept-art/v2/` (`caelan.png`, `nyra.png`, `darius.png`, `ilyr.png`,
   `seris.png`). Strength **High**, so the armour, face and colours stay the same.
2. **Image Guidance → Style Reference:** the same painting. Strength **Mid**.
3. **Model:** Lucid Origin or Phoenix. **Aspect ratio 16:9**, the largest size the free tier allows.
4. **Number of images:** 2 to 4, then keep the best one.
5. **Negative prompt** (paste it every time):

> different character, different armour, different weapon, extra limbs, extra weapons, extra
> fingers, merged figures, overlapping poses, cropped feet, cropped weapon, cut off head,
> perspective, three-quarter view, front view, back view, motion blur, speed lines, text,
> numbers, labels, watermark, frame, border, scenery, background objects, floor, shadow

If a sheet comes out with the character changed between poses, generate it again or split it into
two sheets of 3 poses each.

## The part to paste first, every time

> Sprite animation sheet for a dark gothic 2D action game in the style of Blasphemous. The SAME
> character repeated in a single horizontal row of separate poses, left to right in order, every
> pose the same size and drawn at the same scale, feet on the same baseline, evenly spaced with
> empty space between poses, no overlap. Strict side view, character facing RIGHT, full body, the
> whole weapon visible in every pose. Plain flat dark grey background (#2a2d36), no floor, no
> scenery. Painterly dark fantasy, consistent lighting from the upper left. The character exactly
> matches the reference image: same armour, face, cape and weapon.

Then add **one** of the move lines below, plus the character line for whoever it is.

## Character lines (add one)

| Character | Add |
| --- | --- |
| Caelan | A battle-worn knight in dark plate armour with a blue-black tattered cape, a longsword in his right hand and a tall blue heraldic kite shield on his left arm. Heavy, disciplined, every swing driven by the hips. |
| Nyra | A lithe rogue in dark leather with a hood, two curved daggers, one in each hand. Fast, low, cat-like, slashes in quick pairs. |
| Darius | A huge bald bearded warrior in rusted riveted armour with an orange scarf, a massive two-handed stone war hammer. Slow, crushing, his whole body throws the weight of the hammer. |
| Ilyr | A pale young man in torn dark robes, a blade of violet aether light in his hand. Uncanny, precise, the body slightly too still, the blade leaves rifts in the air. |
| Seris | A pale queen-like mage in a flowing ice-blue gown with a crystal staff. She does not swing: she casts. Elegant, controlled, her free hand guides the spell. |

## Move lines (one sheet each)

**A. Ground combo, hits 1 and 2: 6 poses**

> Poses in order: 1 ready stance, weapon low. 2 wind-up for a horizontal slash, weapon drawn far
> back behind the body at chest height, torso twisted away, weight on the back leg. 3 the strike,
> a wide horizontal slash at chest height, weapon level and pointing forward, arm fully extended,
> front foot stepping forward, torso twisted toward the target. 4 follow-through, the weapon swung
> past the body to the far side, shoulders turned. 5 the backhand return, the weapon sweeping back
> horizontally the other way at chest height. 6 recovery, back to the ready stance.

**B. Ground combo, hits 3 and 4 (the finisher): 6 poses**

> Poses in order: 1 crouching low, weapon down and behind near the ground, ready to rise. 2 a
> rising diagonal slash, from low behind to high in front, the body rising off the crouch. 3 the
> top of the rising slash, weapon high above the head, body stretched upward. 4 wind-up for a
> spinning slash, torso twisted fully away, weapon held far back at waist height. 5 mid-spin, the
> back turned to the viewer for a moment, weapon extended horizontally, cape flaring out. 6 the end
> of the spin, a low wide stance, weapon swept forward level, cape still swinging.

**C. Air and dash: 6 poses**

> Poses in order: 1 in the air, knees tucked, weapon drawn back for a horizontal air slash. 2 in
> the air, the horizontal slash extended forward, knees tucked. 3 in the air, a downward diagonal
> slash, weapon from high to low in front. 4 a low dash lunge, front leg far forward, back knee
> almost on the ground, weapon pulled back at the hip. 5 the dash thrust, body almost horizontal,
> arm and weapon fully extended forward, cape streaming behind. 6 recovering from the lunge,
> rising.

**D. Rising cut and hurt: 6 poses**

> Poses in order: 1 crouching, weapon held low. 2 a rising vertical slash straight up, the weapon
> sweeping from the ground to above the head, body leaning back slightly, looking up. 3 the
> weapon held straight up at the top of the cut. 4 recoiling from a hit, head snapped back, body
> bent backward. 5 staggering, off balance, one foot lifted. 6 back to the ready stance.

**For Seris only (instead of A to D)**

> Poses in order: 1 ready, staff held upright. 2 drawing the staff back, gathering cold light in
> the free hand. 3 thrusting the staff forward to cast a bolt, arm extended, the gown swinging.
> 4 sweeping the staff in a horizontal arc to cast a spread of ice. 5 planting the staff into the
> ground, kneeling, frost spreading. 6 raising the staff overhead with both hands for a great
> spell.

**For Darius, add to every move line:**

> The hammer is so heavy his whole body leans into each swing; at the wind-up the hammer head is
> behind his back, at the strike it is level in front, and at the follow-through it drags him
> forward.

## Naming and delivery

- Name each sheet `<character>_attack_<A/B/C/D>.png`, for example `caelan_attack_A.png` or
  `darius_attack_C.png`. Seris's sheet is `seris_attack_cast.png`.
- Put them in `docs/design/concept-art/attacks/`.
- Start with Caelan, sheets A and B. I'll wire those in first and you can judge the result before
  doing the rest.

## What makes a sheet usable

- Each pose is separate, with a gap around it, and nothing overlaps.
- The character is the same size in every pose, with the feet on one line.
- The whole weapon is inside the picture in every pose.
- The background is plain, with no floor and no shadow.

A sheet that breaks one of these still helps: I copy the angles from it instead of cutting frames.
