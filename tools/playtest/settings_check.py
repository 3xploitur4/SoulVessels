"""Story 059: the settings page in the running game. On the title screen: Settings opens the
volumes page. In a game: the pause menu's Settings tab shows the volumes and the game's difficulty,
and choosing Story changes the game. Screenshots go to production/qa/evidence/story-059-settings/.

    bash tools/python.sh tools/playtest/settings_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-059-settings"
RESULTS = []


def check(ok, what, detail=""):
    RESULTS.append(ok)
    print("%s  %-52s %s" % ("PASS" if ok else "FAIL", what, detail), flush=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    with launch(["--save-dir", "user://playtest_settings"], log_name="settings_check") as (b, _proc):
        wait(b, 1.5)
        b.call("debug_overlay", on=False)
        names = b.call("ui_buttons").get("buttons", [])
        check("Settings" in names, "the title screen has a Settings button", str(names))
        shot(b, os.path.join(OUT, "1-title.png"))
        b.call("ui_press", name="Settings")
        wait(b, 0.4)
        names = b.call("ui_buttons").get("buttons", [])
        check("Back" in names, "the settings page opens with a Back button", str(names))
        shot(b, os.path.join(OUT, "2-title-settings.png"))
        b.call("ui_press", name="Back")
        wait(b, 0.3)
    with launch(["--save-dir", "user://playtest_settings", "--room", "z1_02"], log_name="settings_check2") as (b, _proc):
        wait(b, 1.5)
        b.call("debug_overlay", on=False)
        b.call("pause")
        wait(b, 0.6)
        b.call("ui_press", name="Tab_settings")
        wait(b, 0.4)
        names = b.call("ui_buttons").get("buttons", [])
        check("Difficulty_story" in names and "Difficulty_normal" in names,
              "in a game the settings show the difficulty", str(names))
        shot(b, os.path.join(OUT, "3-pause-settings.png"))
        b.call("ui_press", name="Difficulty_story")
        wait(b, 0.3)
        st = b.call("game_state")["state"]
        check(st.get("difficulty") == "story", "choosing Story changes the game", str(st.get("difficulty")))
        shot(b, os.path.join(OUT, "4-story-chosen.png"))
    print("SUMMARY: %d passed, %d failed" % (RESULTS.count(True), RESULTS.count(False)))
    sys.exit(0 if all(RESULTS) else 1)


if __name__ == "__main__":
    main()
