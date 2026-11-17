# Evidence — Story 029: cut-out rig pilot (Caelan, Echo Crawler)

Run result: VERIFIED in the running game (`tools/playtest/rig_check.py`, `run-output.txt`), in
the pose sheets, and by tests.

In the game (z1_03, started as Caelan): he runs with his legs striding and the cape trailing,
raises the sword overhead and cuts down on an attack, and settles back to his idle; the Crawler
scuttles on its legs as it closes in. Draw calls rose from about 62 (wisp) to 88-96 with Caelan
and two Crawlers on screen (budget 150).

| Shot | Shows |
| --- | --- |
| `01-idle.png` | Caelan at rest. |
| `02-run-a.png`, `03-run-b.png` | Two points of the run cycle. |
| `04-attack-windup.png`, `05-attack-strike.png` | The first attack: sword raised, then the cut. |
| `06-crawlers-0.png` … `11-crawlers-5.png` | Crawlers approaching and striking. |
| `12-block.png` | The shield raised. |

Pose sheets: `godot --path . -s tools/art/rig_preview.gd -- caelan 6` writes every clip to
`builds/art/rig_caelan_poses.png` (copies kept here as `13-pose-sheet-caelan.png` and
`14-pose-sheet-crawler.png`).

Tests: `tests/unit/vfx/rig_body_test.gd` (8): the rig is chosen when it exists; every part is a
bone; clips ease between keys and treat a missing joint as rest; `pose_now` turns the joints;
ticking blends instead of snapping; an unknown clip falls back to idle; turning around keeps
the sword in front of the torso (this one was seen failing before the fix).

Fixed while looking: the sword's soft light edge was left behind in the body as a faint second
blade, so a part can now claim a few pixels around its outline (`grow_px`); the cape swung far
enough to show its painted-in back, so it swings less and its outline is narrower; a 165-degree
wind-up flipped the shoulder plate over the face, now 135.

Full suite: 206 tests pass. One earlier run had `death_echo_test` fail once; it passed on two
reruns with these changes and once without them (a timing flake, not this story).

## Tweak pass (2026-11-17, same day)

User asked to tweak the pilot before the rest of the cast. Changed:

- Attacks follow the hit timing in `data/balance/vessels/caelan.json` (wind-up ends about 30 %
  in, the blow lands by about 50 %): a small anticipation, the sword raised, a fast strike that
  accelerates into contact (key easing "in"), a small overshoot, then recovery. Attacks blend
  at 45 per second so the snap survives. The downward cuts now finish in front of him.
- The cape is a spring driven by movement: it trails behind when he runs, lifts when he falls,
  and settles late when he stops (`secondary` in `data/art/rigs/caelan.json`).
- The cape now reaches under the arm to the body, and hidden areas lean toward the part's average
  colour (`fill_mean`), so a lifted arm shows dark cloth, not a black wedge or a gap.
- Stronger hurt recoil for both; the Crawler coils down and wide on its telegraph and stretches
  on its lunge (`squash`).

Shots 01-14 were retaken after these changes. Tests: 12 in `rig_body_test.gd` (easing, cape
trail and settle, a teleport does not fling the cape, squash); full suite 210 pass.

## Second tweak pass (2026-11-17)

- Idle breathes: a slow rise of the whole body (about 1 %), the head drifting out of step with
  the torso, small arm, sword and shield shifts (3.4 s loop).
- Run has weight: the body compresses on each footfall and rises on the passing step, the head
  steadies against the lean, and the shield arm swings against the sword arm.
- Jumps stretch on take-off; landing squashes the body on a spring that rebounds and settles in
  about half a second; turning round gives a small squash so the flip does not snap
  (`kicks` in the rig data).
- The Crawler's idle twitches its legs out of step and scans with its head.

New shots `15-jump-0.png` to `19-jump-4.png`: in the air (knee tucked, cape lifted), then the
landing (body compressed, cape flaring). Tests: 14 in `rig_body_test.gd` (adds the landing squash
peak and settle, and the turn squash).

## The whole cast (2026-11-17)

Every painted figure is now a cut-out rig: the five Vessels (Caelan, Nyra, Seris, Darius,
Ilyr) and every enemy and boss (Echo Crawler, Subterranean Watcher, Calcified Husk, Fungal
Stalker, Branded Warden, Choir Prelate, Weeping Sovereign, Guardian Below, Abyssal Leviathan).

- Humanoid Vessels borrow Caelan's clips (`clips_from`) and map their own parts onto his
  channels (`alias`): Nyra's second dagger and forearm follow his sword arm, scaled; Seris's feet
  step under her robe on a quarter of his thigh swing and her skirt sways; Ilyr's blade arm takes
  the sword channel. Seris has her own staff casts (the crystal is held high and aimed forward)
  and a steadier run.
- The Husk's clips are the shared enemy set (lumbering walk, arms raised to telegraph, a slam,
  recoil, stagger, knockdown); the Guardian, Prelate and Sovereign borrow them, with forearms,
  a pendulum censer, a swaying skirt and two blades following their arms. The Fungal Stalker
  uses the Husk's rig (`rig` in sprites.json), as it uses its painting.
- The Warden, Watcher and Leviathan have their own clips. The Warden's painting faces left and
  its rig is mirrored, so its angles were worked out for the mirror: it holds the halberd back
  to telegraph and chops forward over its shield. The Watcher rolls with its eye turning against
  the roll; the Leviathan rears, strikes and ripples its tail from base to tip.

Seen in the running game (`tools/playtest/rig_cast.py`, shots in `cast/`): every Vessel's run;
Caelan's and Nyra's attacks; the Watcher, the Warden (telegraph and charge), the Husk room and
the Stalker. Seris, Darius and Ilyr have no primary attack data yet (their kits are later-chapter
work), so their attacks are checked in the pose sheets only, and the four bosses are not placed in
Zones 1-2 yet, so they too are seen in their sheets (`poses/`, every clip of every figure).

Tests: 17 in `rig_body_test.gd` (adds: every sprite is rigged; the Stalker borrows the Husk rig;
borrowed clips merge with the rig's own winning; an aliased part follows a scaled channel).
Full suite 215 pass, smoke boot ok, M1 combat playtest 44/44.

Known limits, unchanged: painted 3/4 views show a flat cut edge when a limb turns far; areas
hidden in the painting are filled with the part's own colours, not new detail.
