"""Story 031: water in the running game. A pool is poured into room z1_03 with the bridge's
`water` command (Zone 3's real pools come with story 038). Seris wades in and floats, casts Frost
Binding from the water to freeze the surface, climbs onto the ice, then the water rises 1.5 m
the way it will in the Weeping Sovereign's phase 2.

    bash tools/python.sh tools/playtest/water_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-031-water"


def tap(b, action):
    b.call("sim_input", action=action, seconds=0)


def me(b):
    return b.call("get_state").get("player", {})


def main():
    os.makedirs(OUT, exist_ok=True)
    log, fails = [], 0

    def check(ok, what, detail=""):
        nonlocal fails
        fails += 0 if ok else 1
        line = "%s  %-46s %s" % ("PASS" if ok else "FAIL", what, detail)
        log.append(line)
        print(line, flush=True)

    args = ["--save-dir", "user://playtest_saves", "--room", "z1_03", "--loadout", "seris,caelan"]
    with launch(args, log_name="water_check") as (b, _proc):
        wait(b, 1.0)
        b.call("goto", room="z1_03", x=2.0, y=2.0, instant=True)
        wait(b, 0.5)
        b.call("kill_all")
        floor_y = float(me(b).get("y", 2.0))
        level = floor_y + 1.9
        r = b.call("water", id="pool", x=[6, 18], floor=floor_y - 0.05, level=level)
        check(abs(float(r.get("level", 0)) - level) < 0.01, "a pool is poured", str(r))
        wait(b, 0.3)
        shot(b, OUT + "/01-pool.png")
        b.call("press", action="move_right")
        wait(b, 1.6)
        b.call("release", action="move_right")
        wait(b, 1.5)
        p = me(b)
        check(float(p.get("water_depth", 0)) > 0.5, "Seris swims in the pool", "depth %s y %s" % (p.get("water_depth"), p.get("y")))
        check(float(p.get("y", 0)) > floor_y + 0.3, "she floats up off the bottom", "y %.2f (floor %.2f)" % (float(p.get("y", 0)), floor_y))
        shot(b, OUT + "/02-swimming.png")
        tap(b, "ability_1")
        wait(b, 0.5)
        r = b.call("water", id="pool")
        check(int(r.get("patches", 0)) >= 1, "Frost Binding freezes the surface", str(r))
        shot(b, OUT + "/03-frozen-patch.png")
        # Back off a step, then jump up onto the ice.
        b.call("press", action="move_left")
        wait(b, 0.25)
        b.call("release", action="move_left")
        b.call("press", action="move_right")
        b.call("sim_input", action="jump", seconds=0.3)
        wait(b, 0.5)
        b.call("release", action="move_right")
        wait(b, 0.6)
        p = me(b)
        check(bool(p.get("on_floor")) and float(p.get("y", 0)) >= level - 0.1, "Seris stands on the ice",
              "y %.2f level %.2f on_floor %s" % (float(p.get("y", 0)), level, p.get("on_floor")))
        shot(b, OUT + "/04-on-the-ice.png")
        b.call("water", id="pool", to=level + 1.5, seconds=2.0)
        wait(b, 1.0)
        shot(b, OUT + "/05-water-rising.png")
        wait(b, 1.4)
        r = b.call("water", id="pool")
        check(abs(float(r.get("level", 0)) - (level + 1.5)) < 0.02, "the water rose 1.5 m in 2 s", str(r))
        shot(b, OUT + "/06-risen.png")
        wait(b, 6.0)
        r = b.call("water", id="pool")
        check(int(r.get("patches", 1)) == 0, "the ice melts after 8 s", str(r))
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "water-run-output.txt"), "w") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
