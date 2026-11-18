"""Story 054: the zoomed-out pixel-art look in the running game. One shot per zone (a room with the
player and enemies in view), the pause-menu map, and a boss. Screenshots go to
production/qa/evidence/story-054-look/ (or the folder given with --out).

    bash tools/python.sh tools/playtest/look_check.py [--out folder] [--rooms z1_02,z2_05]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-054-look"
ROOMS = ["z1_02", "z1_05", "z2_03", "z2_08", "z3_02", "z3_08", "z4_02", "z4_11"]


def main():
    out = OUT
    rooms = ROOMS
    if "--out" in sys.argv:
        out = sys.argv[sys.argv.index("--out") + 1]
    if "--rooms" in sys.argv:
        rooms = sys.argv[sys.argv.index("--rooms") + 1].split(",")
    os.makedirs(out, exist_ok=True)
    args = ["--save-dir", "user://playtest_look", "--room", rooms[0], "--loadout", "caelan,nyra,seris"]
    with launch(args, log_name="look_check") as (b, _proc):
        wait(b, 1.2)
        b.call("debug_overlay", on=False)
        for room in rooms:
            b.call("goto", room=room, exit="0", instant=True)
            wait(b, 0.5)
            b.call("press", action="move_right")
            wait(b, 0.9)
            b.call("release", action="move_right")
            wait(b, 0.8)
            shot(b, os.path.join(out, "room-%s.png" % room))
        b.call("sim_input", action="pause", seconds=0)
        wait(b, 0.6)
        try:
            b.call("ui_press", name="map")
        except Exception:  # noqa: BLE001
            pass
        wait(b, 0.6)
        shot(b, os.path.join(out, "map.png"))
    print("shots in %s" % out)


if __name__ == "__main__":
    main()
