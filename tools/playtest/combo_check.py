"""Story 057: the horizontal combo and the combo moves in the running game. One shot at the moment
each blow lands: the four ground hits (forward cut, backhand, rising diagonal, spinning finisher),
an air cut, the dash slash out of a dodge and the rising cut. Also checks the moves start (the
player's state names). Screenshots go to production/qa/evidence/story-057-combo/.

    bash tools/python.sh tools/playtest/combo_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-057-combo"
RESULTS = []


def check(ok, what, detail=""):
    RESULTS.append(ok)
    print("%s  %-50s %s" % ("PASS" if ok else "FAIL", what, detail), flush=True)


def state(b):
    return str(b.call("get_state").get("player", {}).get("state", ""))


def main():
    os.makedirs(OUT, exist_ok=True)
    args = ["--save-dir", "user://playtest_combo", "--room", "z1_02", "--loadout", "caelan,nyra,darius"]
    with launch(args, log_name="combo_check") as (b, _proc):
        wait(b, 1.2)
        b.call("debug_overlay", on=False)
        b.call("goto", room="z1_02", exit="0", instant=True)
        wait(b, 0.6)
        b.call("kill_all")
        # The ground chain: four presses, one shot as each blow lands.
        for i, name in enumerate(["cut", "backhand", "rising", "finisher"]):
            b.call("sim_input", action="attack", seconds=0.0)
            wait(b, 0.13 if i < 3 else 0.17)
            st = state(b)
            check(st == "primary_%d" % i, "hit %d is %s" % (i + 1, name), st)
            shot(b, os.path.join(OUT, "%d-%s.png" % (i + 1, name)))
            wait(b, 0.12)
        wait(b, 0.8)
        # An air cut at the top of a jump.
        b.call("press", action="jump")
        wait(b, 0.25)
        b.call("sim_input", action="attack", seconds=0.0)
        wait(b, 0.1)
        st = state(b)
        check(st.startswith("slash_air"), "an attack in the air is an air cut", st)
        shot(b, os.path.join(OUT, "5-air-cut.png"))
        b.call("release", action="jump")
        wait(b, 1.0)
        # A dash slash out of a dodge.
        b.call("sim_input", action="dodge", seconds=0.0)
        wait(b, 0.33)
        b.call("sim_input", action="attack", seconds=0.0)
        wait(b, 0.1)
        st = state(b)
        check(st == "slash_dash", "an attack out of a dodge is a dash slash", st)
        shot(b, os.path.join(OUT, "6-dash-slash.png"))
        wait(b, 0.8)
        # The rising cut: up held.
        b.call("press", action="move_up")
        wait(b, 0.05)
        b.call("sim_input", action="attack", seconds=0.0)
        wait(b, 0.12)
        st = state(b)
        check(st == "slash_up", "up + attack is the rising cut", st)
        shot(b, os.path.join(OUT, "7-rising-cut.png"))
        b.call("release", action="move_up")
        wait(b, 0.6)
    print("SUMMARY: %d passed, %d failed" % (RESULTS.count(True), RESULTS.count(False)))
    sys.exit(0 if all(RESULTS) else 1)


if __name__ == "__main__":
    main()
