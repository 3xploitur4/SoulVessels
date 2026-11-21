# Story 059 evidence: settings (volumes and difficulty)

`bash tools/python.sh tools/playtest/settings_check.py` (4 checks pass):

- 1-title.png: the title screen with its Settings button.
- 2-title-settings.png: the volumes page from the title screen.
- 3-pause-settings.png: the pause menu's Settings tab with the volumes and the game's difficulty.
- 4-story-chosen.png: Story chosen (the game changes at once and saves).

Tests: `tests/unit/ui/settings_test.gd` (6), `tests/integration/game/difficulty_change_test.gd`
(3); full suite 469 passed; smoke ok; drive and drive_m2 pass.
