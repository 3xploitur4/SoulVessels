"""Story 032: light-rune doors in the running game.
1. z1_02: one Arcane Bolt lights the rune on the secret door; it opens and the shard behind it
   can be taken.
2. z2_12: the three-rune sequence with its mural. A bolt from the wrong side puts the runes out.
   From the left, two bolts light runes 1 and 2, and a mirror-shield stood under rune 3 bounces
   the third bolt up into it.
Zone 3's tide puzzles are played in story 038; the tide rule is covered by
tests/integration/world/rune_puzzles_test.gd.

    bash tools/python.sh tools/playtest/rune_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-032-light-runes"


def tap(b, action):
    b.call("sim_input", action=action, seconds=0)


def face(b, direction):
    action = "move_right" if direction > 0 else "move_left"
    b.call("sim_input", action=action, seconds=0.05)
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

    args = ["--save-dir", "user://playtest_saves", "--room", "z1_02", "--loadout", "seris,caelan"]
    with launch(args, log_name="rune_check") as (b, _proc):
        wait(b, 1.0)
        b.call("goto", room="z1_02", x=15.0, y=5.2, instant=True)
        wait(b, 0.8)
        r = b.call("runes")
        check(r.get("door") is True and r.get("lit") == 0, "z1_02: the rune door is shut and dark", str(r))
        face(b, 1)
        shot(b, OUT + "/01-z1-door-dark.png")
        tap(b, "attack")
        wait(b, 0.8)
        r = b.call("runes")
        check(r.get("solved") is True and r.get("door") is False, "one bolt lights it and the door opens", str(r))
        shot(b, OUT + "/02-z1-door-open.png")
        st = b.call("game_state").get("state", {})
        check("z1_02_rune" in st.get("opened_gates", []), "the open door is saved", str(st.get("opened_gates")))
        b.call("press", action="move_right")
        wait(b, 1.4)
        b.call("release", action="move_right")
        wait(b, 0.6)
        st = b.call("game_state").get("state", {})
        inv = st.get("inventory", st.get("items", {}))
        check("standard_soul_shard" in str(inv), "the shard behind the door is taken", str(inv)[:120])

        b.call("goto", room="z2_12", x=12.2, y=3.2, instant=True)
        wait(b, 1.0)
        b.call("kill_all")
        face(b, -1)
        shot(b, OUT + "/03-z2-sequence-mural.png")
        tap(b, "attack")
        wait(b, 0.25)
        shot(b, OUT + "/04-z2-wrong-rune-flash.png")
        wait(b, 0.6)
        r = b.call("runes")
        check(r.get("lit") == 0, "a bolt from the right hits rune 2 first: all out", str(r))
        b.call("teleport", x=2.0, y=3.2)
        wait(b, 0.5)
        face(b, 1)
        tap(b, "attack")
        wait(b, 0.9)
        tap(b, "attack")
        wait(b, 0.9)
        r = b.call("runes")
        check(r.get("lit") == 2, "from the left: runes 1 and 2 in order", str(r))
        shot(b, OUT + "/05-z2-two-lit.png")
        b.call("mirror", x=12.4, y=3.95, angle=135)
        wait(b, 0.3)
        tap(b, "attack")
        wait(b, 0.35)
        shot(b, OUT + "/06-z2-mirror-bounce.png")
        wait(b, 0.6)
        r = b.call("runes")
        check(r.get("solved") is True and r.get("door") is False, "the mirror bounces bolt 3 up into rune 3", str(r))
        shot(b, OUT + "/07-z2-solved.png")
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "rune-run-output.txt"), "w") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
