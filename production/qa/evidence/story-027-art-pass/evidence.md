# Evidence — Stories 027 and 028: art pass from the concept sheets

Run result: VERIFIED in the running game (bridge captures at 1280x720 of the 1920x1080 view).
Reference: `docs/design/concept-art/` (the user's three sheets). Look rules:
`docs/design/art-direction.md`.

| Shot | Shows |
| --- | --- |
| `01-zone1-caelan-strike-*.png` | Painted Caelan striking a painted Echo Crawler: weapon arc, white hit flash, the Crawler's green spine-sac tell, Essence pop-up; Zone 1 painting behind ashlar ruins and slab floor. |
| `02-warden-telegraph-guard.png` | Caelan's gold guard glow; the Branded Warden with the crimson X cue. |
| `03-zone2-nyra-running.png` | Nyra mid-stride in the Lantern Bridge room; Zone 2 painting, bark and moss surfaces. |
| `04-zone2-glowcap-path.png` | Spotted mushrooms, glowing sprouts, spores, teal mist. |
| `05-watcher-beam.png` | The Subterranean Watcher firing its beam. |
| `07-title-lineup.png`, `08-difficulty.png` | Title in the serif display face with the Vessel line-up; gold-edged buttons. |
| `09-altar-lit.png`, `10-altar-menu.png` | Stepped stone altar with the soul flame; the altar menu; ornate HP frame and slanted Soul Gauge. |
| `11`-`16` gates | Iron portcullis with embers, shadow veil, golden shield ward, rune door, veined masonry, flooded stair. |
| `17-nyra-shadowstep-afterimages.png` | Violet afterimages behind a Shadowstep. |

Checks: 142 unit and integration tests pass; smoke passes; the M1 combat playtest passes 44/44
with the painted bodies. Room viewer: 13-27 draw calls per room.

Found while looking: enemies could walk out of a room through its exits (two Crawlers left the
Sunken Colonnade). Fixed with side walls only enemies collide with.

Not verified: frame rate on a phone with the new blended layers (mist, shafts, vignette); how the
shader motion feels in hand. Known stand-ins are listed in `docs/design/art-direction.md`.
