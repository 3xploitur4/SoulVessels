"""Story 044: the Guardian Below in the running game. Room z1_03 stands in for its elevator (Zone 4's
arena comes in story 049): a slide floor is laid with the bridge, the Guardian is spawned, Darius
fights it, and the bridge's `boss` command walks its phases. Screens: phase 1 with its fists and
bars, phase 2 with the arena tilted and a boulder rolling, phase 3 with the core open.

    bash tools/python.sh tools/playtest/guardian_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-044-guardian"


def main():
    os.makedirs(OUT, exist_ok=True)
    log, fails = [], 0

    def check(ok, what, detail=""):
        nonlocal fails
        fails += 0 if ok else 1
        line = "%s  %-46s %s" % ("PASS" if ok else "FAIL", what, detail)
        log.append(line)
        print(line, flush=True)

    args = ["--save-dir", "user://playtest_saves", "--room", "z1_03", "--loadout", "darius,caelan"]
    with launch(args, log_name="guardian_check") as (b, _proc):
        wait(b, 1.0)
        b.call("goto", room="z1_03", x=4.0, y=2.0, instant=True)
        wait(b, 0.5)
        b.call("kill_all")
        b.call("debug_overlay", on=False)
        b.call("slide", x=[1, 30], y=[2.0, 3.5], angle=0)
        b.call("spawn", enemy_id="guardian_below", x=13.0)
        wait(b, 1.5)
        r = b.call("boss")
        check(r.get("phase") == 0, "the Guardian stands, phase 1", str(r))
        seen = set()
        for i in range(40):
            wait(b, 0.15)
            b.call("heal")
            r = b.call("boss")
            if r.get("state") == "telegraph" and r.get("attack") not in seen:
                seen.add(r.get("attack"))
                shot(b, OUT + "/01-p1-%s.png" % r.get("attack"))
            if len(seen) >= 2:
                break
        check(len(seen) >= 1, "it attacks in phase 1", str(sorted(seen)))
        r = b.call("boss", fraction=0.64, strike=100)
        check(r.get("phase") == 1, "below 65 %: phase 2", str(r))
        rock = False
        for i in range(50):
            wait(b, 0.2)
            b.call("heal")
            if i == 12:
                shot(b, OUT + "/02-p2-tilted.png")
        r = b.call("boss")
        check(int(r.get("rocks", 0)) >= 1, "boulders roll down the tilted elevator", "%s rolled in 10 s" % r.get("rocks"))
        shot(b, OUT + "/03-p2-boulder.png")
        r = b.call("boss", fraction=0.29, strike=100)
        check(r.get("phase") == 2, "below 30 %: phase 3, the core opens", str(r))
        for i in range(10):
            wait(b, 0.2)
            b.call("heal")
        shot(b, OUT + "/04-p3-core.png")
        b.call("boss", fraction=0.0001, strike=500)
        wait(b, 1.0)
        st = b.call("game_state")["state"]
        check(st.get("flags", {}).get("unlock_greatsword") is True, "it falls; the Greatsword is unlocked",
              str(st.get("flags", {}).get("unlock_greatsword")))
        shot(b, OUT + "/05-fallen.png")
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "run-output.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
