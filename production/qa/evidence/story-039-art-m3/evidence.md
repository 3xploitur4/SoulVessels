# Story 039 evidence: M3 art

Waiting for your sign-off: this is a look pass, and the rules say the look is yours to approve.

| Shot | Shows |
| --- | --- |
| rig-seris-new-clips.png | Seris's new rig clips, 4 frames each: bolt (the staff levelled like a spear, crystal forward), frost (staff raised, then planted), swim |
| 01-seris-bolt-cast.png | In game: the bolt pose as an Arcane Bolt leaves |
| 02-seris-frost.png | Frost Binding: crystals along the floor |
| 03-seris-swim.png | Swimming (the new "swim" player state) |
| rig-prelate-clips.png | The Choir Prelate: idle, telegraph (censer swung back), attack (censer forward), hurt |
| 04-prelate-cast.png | In game: the orb volley, the aura line on the floor, a buffed Crawler's gold ring |
| 05-p3-*.png | The Sovereign in phase 3; her Ember tint shows under the attack cue's flash |
| palace-murals.png | The Zone 3 palace theme: marble, gold trim, the zone painting behind |

Made in M3 stories 030-038 and kept here:
- VFX: the Arcane Bolt orb, the Frost Binding crystals, the Aether Shield bubble, the carved runes with lit sigils and red wrong-rune flash, the mural, the Prelate's aura line and buffed-ally rings, the water surface shimmer, ice slabs, and Seris's crystal.

Not done:
- **The Drowned Courtier has no painting** on `docs/design/concept-art/enemies.webp`. It stays the Husk figure tinted sea-green. It needs concept art to get its own rig.
- **The swim clip is stiff**: one lean and a paddle.
- **The Sovereign has no clip per attack**: all her attacks share her telegraph and attack poses.

Test: `tests/unit/vfx/clip_map_test.gd` (2), for Seris's own clips and the fallback for other Vessels. It first failed to load because `clip_for_rig` did not exist.
