"""Story 029: every rigged figure that appears in Zones 1-2, seen in the running game.

Each Vessel in turn (idle, mid-run, mid-attack), then the rooms that hold the Watcher, the
Branded Warden, the Calcified Husk and the Fungal Stalker. Screenshots go to the evidence folder.

    bash tools/python.sh tools/playtest/rig_cast.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-029-cutout-rig/cast"
VESSELS = ["caelan", "nyra", "seris", "darius", "ilyr"]


def vessel_shots(b, log, name):
    log.append("%s: shots taken" % name)
    shot(b, "%s/%s-1-idle.png" % (OUT, name))
    b.call("press", action="move_right")
    wait(b, 0.3)
    shot(b, "%s/%s-2-run.png" % (OUT, name))
    b.call("release", action="move_right")
    wait(b, 0.25)
    # A burst: attacks are short, so several frames are taken back to back.
    b.call("sim_input", action="attack", seconds=0)
    for n in range(4):
        shot(b, "%s/%s-3-attack-%d.png" % (OUT, name, n))
    wait(b, 0.8)


def main():
    os.makedirs(OUT, exist_ok=True)
    log = []
    # A loadout holds three Vessels, so the cast is seen in two runs.
    for group in (VESSELS[:3], VESSELS[3:]):
        args = ["--save-dir", "user://playtest_saves", "--room", "z1_01", "--loadout", ",".join(group)]
        with launch(args, log_name="rig_cast") as (b, _proc):
            wait(b, 1.0)
            for i, v in enumerate(group):
                b.call("goto", room="z1_01", x=5.0, y=2.0, instant=True)
                wait(b, 0.6)
                vessel_shots(b, log, v)
                if i < len(group) - 1:
                    b.call("press", action="swap_next")
                    wait(b, 0.1)
                    b.call("release", action="swap_next")
                    wait(b, 1.6)
    args = ["--save-dir", "user://playtest_saves", "--room", "z1_01", "--loadout", "caelan"]
    with launch(args, log_name="rig_cast") as (b, _proc):
        wait(b, 1.0)
        for room, x, label in [("z1_07", 5.0, "watcher"), ("z1_12", 4.0, "warden"),
                               ("z2_06", 3.0, "husk-stalker"), ("z2_02", 3.0, "husk")]:
            b.call("goto", room=room, x=x, y=2.0, instant=True)
            wait(b, 0.8)
            shot(b, "%s/enemy-%s-1.png" % (OUT, label))
            b.call("press", action="move_right")
            wait(b, 1.2)
            b.call("release", action="move_right")
            for n in range(3):
                wait(b, 0.45)
                shot(b, "%s/enemy-%s-%d.png" % (OUT, label, n + 2))
            log.append("%s: room %s" % (label, b.call("game_state").get("room")))
    with open(OUT + "/run-output.txt", "w") as f:
        f.write("\n".join(log) + "\n")
    print("\n".join(log))


if __name__ == "__main__":
    main()
