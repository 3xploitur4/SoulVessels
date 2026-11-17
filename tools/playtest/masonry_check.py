"""Story 042: cracked masonry in the running game. Darius walks to each of the five new masonry
secrets (z1_06, z1_14, z2_05, z2_14, z3_12), breaks the wall with Crushing Blow and takes what is
behind it; one wall is shot before and after. Caelan's sword first shows that nothing else breaks it.

    bash tools/python.sh tools/playtest/masonry_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-042-masonry"
# room, x to stand at, y of the floor, facing, the item behind the wall
SECRETS = [
    ("z1_14", 4.4, 2.0, -1, "standard_soul_shard"),
    ("z1_06", 10.3, 7.0, 1, "polished_basalt_core"),
    ("z2_05", 4.4, 3.0, -1, "greater_soul_shard"),
    ("z2_14", 4.4, 2.0, -1, "echoing_relic"),
    ("z3_12", 16.4, 2.0, 1, "polished_basalt_core"),
]


def tap(b, action):
    b.call("sim_input", action=action, seconds=0)


def face(b, d):
    b.call("sim_input", action="move_right" if d > 0 else "move_left", seconds=0.05)
    wait(b, 0.15)


def main():
    os.makedirs(OUT, exist_ok=True)
    log, fails = [], 0

    def check(ok, what, detail=""):
        nonlocal fails
        fails += 0 if ok else 1
        line = "%s  %-46s %s" % ("PASS" if ok else "FAIL", what, detail)
        log.append(line)
        print(line, flush=True)

    args = ["--save-dir", "user://playtest_saves", "--room", "z1_14", "--loadout", "caelan,darius"]
    with launch(args, log_name="masonry_check") as (b, _proc):
        wait(b, 1.0)
        b.call("debug_overlay", on=False)
        for n, (room, x, y, d, item) in enumerate(SECRETS):
            b.call("goto", room=room, x=x, y=y, instant=True)
            wait(b, 0.9)
            b.call("kill_all")
            face(b, d)
            if n == 0:
                b.call("set_vessel", id="caelan")
                wait(b, 0.3)
                face(b, d)
                tap(b, "attack")
                wait(b, 0.6)
                shot(b, OUT + "/01-cracked-wall.png")
                st = b.call("game_state")["state"]
                check("%s:masonry:0" % room not in st.get("opened_gates", []), "a sword does not break masonry")
                b.call("set_vessel", id="darius")
                wait(b, 2.0)
                face(b, d)
            if n > 0:
                wait(b, 7.2)  # Crushing Blow's 7 s cooldown from the last wall
            before = len([k for k in b.call("game_state")["state"].get("taken_pickups", []) if k.startswith(room)])
            tap(b, "ability_1")
            wait(b, 1.2)
            if n == 0:
                shot(b, OUT + "/02-wall-broken.png")
            st = b.call("game_state")["state"]
            opened = any(g.startswith(room + ":masonry") for g in st.get("opened_gates", []))
            check(opened, "%s: Crushing Blow breaks the wall" % room)
            b.call("press", action="move_right" if d > 0 else "move_left")
            wait(b, 1.0)
            b.call("release", action="move_right" if d > 0 else "move_left")
            wait(b, 0.8)
            after = len([k for k in b.call("game_state")["state"].get("taken_pickups", []) if k.startswith(room)])
            check(after > before, "%s: the %s behind it is taken" % (room, item), "%d -> %d" % (before, after))
            if n == 4:
                shot(b, OUT + "/03-z3-study-secret.png")
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "run-output.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
