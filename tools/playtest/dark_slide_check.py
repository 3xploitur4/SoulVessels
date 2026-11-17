"""Story 043: darkness and sliding floors in the running game (room z1_03; Zone 4 uses them for real
in story 049). The room goes dark with a lamp; the light around the player grows with the Soul
Gauge; a Crawler's attack cue shows through the dark; a 15 degree slope carries the player.

    bash tools/python.sh tools/playtest/dark_slide_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-043-darkness-sliding"


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
    with launch(args, log_name="dark_slide_check") as (b, _proc):
        wait(b, 1.0)
        b.call("goto", room="z1_03", x=6.0, y=2.0, instant=True)
        wait(b, 0.6)
        b.call("kill_all")
        b.call("debug_overlay", on=False)
        r = b.call("dark", on=True, lamps=[[14.5, 3.5]])
        check(r.get("dark", 0) > 0.9 and r.get("lamps") == 1, "the room goes dark with one lamp", str(r))
        wait(b, 0.4)
        shot(b, OUT + "/01-dark-empty-gauge.png")
        b.call("gauge", value=300)
        wait(b, 0.4)
        shot(b, OUT + "/02-dark-full-gauge.png")
        b.call("spawn", enemy_id="echo_crawler", x=12.0)
        seen = False
        for i in range(30):
            wait(b, 0.12)
            es = b.call("get_state")["enemies"]
            if es and es[0].get("state") == "telegraph":
                shot(b, OUT + "/03-cue-in-the-dark.png")
                seen = True
                break
        check(seen, "a Crawler's attack cue is caught on screen in the dark")
        b.call("kill_all")
        b.call("dark", on=False)
        b.call("slide", x=[3, 30], y=[2.0, 3.5], angle=15)
        b.call("teleport", x=8.0, y=2.05)
        wait(b, 0.3)
        x0 = float(b.call("get_state")["player"]["x"])
        wait(b, 1.2)
        shot(b, OUT + "/04-slope.png")
        x1 = float(b.call("get_state")["player"]["x"])
        check(x1 > x0 + 1.0, "standing on the slope carries Darius downhill", "%.1f -> %.1f" % (x0, x1))
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "run-output.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
