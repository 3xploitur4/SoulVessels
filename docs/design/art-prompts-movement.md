# Movement pose prompts for Leonardo AI (story 060)

The run, the slow walk and the crouch are still animated by bending the cut-out parts of the
character's painting. Story 060 made the arms swing and the torso turn with the stride, but a
painted arm rotated at the shoulder never looks fully natural. The attacks looked wrong in the
same way until you made Caelan's attack sheet; his attacks now play as drawn frames. These sheets
do the same for moving around: once they are cut into frames, the run, walk and crouch play as
drawn frames, like the attacks.

Use the same Leonardo settings, negative prompt and character lines as
`docs/design/art-prompts-attacks.md` (Character Reference and Style Reference set to the
character's v2 painting, 16:9, plain dark grey background).

## The part to paste first, every time

> Sprite animation sheet for a dark gothic 2D action game in the style of Blasphemous. The SAME
> character repeated in a single horizontal row of separate poses, left to right in order, every
> pose the same size and drawn at the same scale, feet on the same baseline, evenly spaced with
> empty space between poses, no overlap. Strict side view, character facing RIGHT, full body, the
> whole weapon visible in every pose. Plain flat dark grey background (#2a2d36), no floor, no
> scenery. Painterly dark fantasy, consistent lighting from the upper left. The character exactly
> matches the reference image: same armour, face, cape and weapon.

Then add **one** move line below, plus the character line from the attack prompts.

## Move lines (one sheet each)

**E. Run cycle: 8 poses**

> A heavy armoured run cycle, one full stride in 8 poses, as in a classic animation run cycle.
> 1 contact, right foot striking the ground ahead, left arm forward, sword arm back. 2 down, the
> body lowest, right knee bent taking the weight. 3 passing, left leg swinging through under the
> body. 4 up, pushing off the right foot, body highest, left knee high. 5 contact, left foot
> striking the ground ahead, right arm forward, shield arm back. 6 down, left knee bent taking the
> weight. 7 passing, right leg swinging through. 8 up, pushing off the left foot. The arms swing
> opposite to the legs in every pose, the torso turns with the stride and leans slightly forward,
> the cape trails and bounces behind, the sword carried low and angled back.

**F. Slow walk: 6 poses**

> A slow, wary walk cycle, one full stride in 6 poses, the body upright and guarded. 1 right foot
> forward, heel touching down. 2 weight over the right foot, the left foot lifting behind. 3 the
> left leg passing under the body. 4 left foot forward, heel touching down. 5 weight over the left
> foot. 6 the right leg passing under the body. The arms swing a little, opposite to the legs, the
> shield held in front of the chest, the sword low and ready, the cape hanging and swaying.

**G. Crouch and crouch walk: 6 poses**

> 1 standing, about to crouch. 2 a deep crouch at rest, knees fully bent, back bent forward, head
> low, shield raised in front, sword held low. 3 to 6: creeping forward in the crouch, one full
> stride of a low sneaking walk, the head never rising, small careful steps, the cape dragging
> close to the ground.

## Naming and delivery

- Name each sheet `<character>_move_<E/F/G>.png`, for example `caelan_move_E.png`.
- Put them in `docs/design/concept-art/attacks/` next to the attack sheets.
- Start with Caelan's run (E): it is on screen most of the time.

The same rules as the attack sheets make a sheet usable: separate poses with a gap, one size, feet
on one line, the whole weapon inside, a plain background. For a run cycle, the 8 poses must also
be one stride. Pose 8 has to flow back into pose 1.
