"""Story 029: see the cut-out rigs in the running game (Caelan running, attacking, blocking,
hurt; Echo Crawlers scuttling and striking). Screenshots go to the evidence folder.

    bash tools/python.sh tools/playtest/rig_check.py
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-029-cutout-rig"


def main():
    os.makedirs(OUT, exist_ok=True)
    log = []
    args = ["--save-dir", "user://playtest_saves", "--room", "z1_03", "--loadout", "caelan"]
    with launch(args, log_name="rig_check") as (b, _proc):
        wait(b, 1.0)
        b.call("goto", room="z1_03", x=4.0, y=2.0, instant=True)
        log.append("start: %s" % b.call("game_state").get("room"))
        wait(b, 0.8)
        shot(b, OUT + "/01-idle.png")
        b.call("press", action="move_right")
        wait(b, 0.25)
        shot(b, OUT + "/02-run-a.png")
        wait(b, 0.15)
        shot(b, OUT + "/03-run-b.png")
        b.call("release", action="move_right")
        wait(b, 0.3)
        for i, name in enumerate(["04-attack-windup", "05-attack-strike"]):
            if i == 0:
                b.call("press", action="attack")
                wait(b, 0.06)
            else:
                wait(b, 0.08)
            shot(b, OUT + "/%s.png" % name)
        b.call("release", action="attack")
        wait(b, 0.6)
        # Walk toward the first Crawler so it closes in and attacks.
        b.call("press", action="move_right")
        wait(b, 0.5)
        b.call("release", action="move_right")
        for n in range(6):
            wait(b, 0.35)
            shot(b, OUT + "/%02d-crawlers-%d.png" % (6 + n, n))
        b.call("press", action="ability_1")
        wait(b, 0.3)
        shot(b, OUT + "/12-block.png")
        b.call("release", action="ability_1")
        st = b.call("game_state")
        log.append("end: room %s" % st.get("room"))
    with open(OUT + "/run-output.txt", "w") as f:
        f.write("\n".join(log) + "\n")
    print("\n".join(log))


if __name__ == "__main__":
    main()
