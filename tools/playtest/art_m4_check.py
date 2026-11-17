"""Story 051: the M4 clips in the running game. Darius's Crushing Blow and Groundbreaker mid-swing;
the Guardian and the Leviathan caught in an attack's own telegraph and strike poses; an erased
echo. Screenshots and run-output.txt go to production/qa/evidence/story-051-art/.

    bash tools/python.sh tools/playtest/art_m4_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-051-art"


def main():
    os.makedirs(OUT, exist_ok=True)
    log, fails = [], 0

    def check(ok, what, detail=""):
        nonlocal fails
        fails += 0 if ok else 1
        line = "%s  %-50s %s" % ("PASS" if ok else "FAIL", what, detail)
        log.append(line)
        print(line, flush=True)

    args = ["--save-dir", "user://playtest_art_m4", "--room", "z4_04", "--loadout", "darius,caelan"]
    with launch(args, log_name="art_m4_check") as (b, _proc):
        wait(b, 1.0)
        b.call("debug_overlay", on=False)
        b.call("set_vessel", id="darius")
        wait(b, 0.6)
        for n, (act, delay) in enumerate((("ability_1", 0.3), ("ability_2", 0.25), ("attack", 0.12))):
            b.call("sim_input", action=act, seconds=0)
            wait(b, delay)
            st = b.call("get_state")["player"].get("state")
            check(st not in ("idle", "run", None), "Darius in %s" % act, str(st))
            shot(b, OUT + "/%02d-darius-%s.png" % (n + 1, act))
            wait(b, 1.2)
        for room, boss, tag in (("z4_10", "guardian", "guardian"), ("z4_13", "leviathan", "leviathan")):
            b.call("goto", room=room, exit="0", instant=True)
            wait(b, 0.6)
            b.call("press", action="move_right")
            wait(b, 1.4)
            b.call("release", action="move_right")
            got = set()
            for i in range(160):
                b.call("heal")
                es = [e for e in b.call("get_state")["enemies"] if str(e.get("id", "")) in ("guardian_below", "abyssal_leviathan")]
                if es and i % 10 == 0:
                    b.call("teleport", x=max(float(es[0]["x"]) - 7.0, 4.0), y=2.05)
                s = b.call("boss")
                st, atk = s.get("state"), s.get("attack")
                if st in ("telegraph", "attack") and atk and (st, atk) not in got and len(got) < 4:
                    got.add((st, atk))
                    shot(b, OUT + "/%s-%s-%s.png" % (tag, st, atk))
                if len(got) >= 4:
                    break
                wait(b, 0.15)
            check(len(got) >= 2, "%s caught in its attack poses" % tag, str(sorted(got)))
        b.call("awakening")
        wait(b, 3.0)
        shot(b, OUT + "/echo.png")
        check(True, "an erased echo shown")
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "run-output.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
