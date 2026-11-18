"""Story 054: the zoomed-out pixel-art look in the running game. One shot per zone (a room with the
player and enemies in view), upper levels, shadows and dust in motion (run, jump, land, strike)
and the pause-menu map. Screenshots go to
production/qa/evidence/story-054-look/ (or the folder given with --out).

    bash tools/python.sh tools/playtest/look_check.py [--out folder] [--rooms z1_02,z2_05]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-054-look"
ROOMS = ["z1_02", "z1_05", "z2_03", "z2_08", "z3_02", "z3_08", "z4_02", "z4_11"]
# Upper levels (story 054): (room, x, y) standing spots.
UPPER = [("z1_05", 6, 12.05), ("z2_09", 10, 12.05), ("z3_14", 8, 12.05), ("z4_05", 14, 12.05)]


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
        for room, x, y in UPPER:
            b.call("goto", room=room, x=float(x), y=float(y), instant=True)
            wait(b, 1.0)
            b.call("kill_all")
            wait(b, 0.3)
            shot(b, os.path.join(out, "upper-%s.png" % room))
        # Second pass of story 054: shadows and dust in motion, mid-run, in the air, landing and
        # striking.
        b.call("goto", room="z1_02", exit="0", instant=True)
        wait(b, 0.6)
        b.call("kill_all")
        b.call("press", action="move_right")
        wait(b, 0.75)
        shot(b, os.path.join(out, "action-run.png"))
        b.call("press", action="jump")
        wait(b, 0.25)
        shot(b, os.path.join(out, "action-jump.png"))
        b.call("release", action="jump")
        wait(b, 0.55)
        b.call("release", action="move_right")
        wait(b, 0.05)
        shot(b, os.path.join(out, "action-land.png"))
        wait(b, 0.6)
        b.call("sim_input", action="attack", seconds=0.0)
        wait(b, 0.16)
        shot(b, os.path.join(out, "action-attack.png"))
        wait(b, 0.6)
        # Story 055: the dodge is a fast low step, not a roll.
        b.call("sim_input", action="dodge", seconds=0.0)
        wait(b, 0.12)
        shot(b, os.path.join(out, "action-dodge.png"))
        wait(b, 0.6)
        b.call("pause")
        wait(b, 0.8)
        shot(b, os.path.join(out, "map.png"))
    print("shots in %s" % out)


if __name__ == "__main__":
    main()
