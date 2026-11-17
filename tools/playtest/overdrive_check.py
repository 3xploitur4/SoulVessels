"""Story 046: Overdrive in the running game (room z1_03). Darius and Caelan, Overdrive unlocked by
the bridge (in play it comes from the Leviathan's Pure Soul Matrix), a full gauge: the HUD shows
OVERDRIVE; the Ultimate input runs Worldbreaker, a free swap, Final Stand, then the finisher.

    bash tools/python.sh tools/playtest/overdrive_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-046-overdrive"


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
    with launch(args, log_name="overdrive_check") as (b, _proc):
        wait(b, 1.0)
        b.call("goto", room="z1_03", x=8.0, y=2.0, instant=True)
        wait(b, 0.5)
        b.call("kill_all")
        b.call("debug_overlay", on=False)
        b.call("overdrive", on=True)
        for v in ("darius", "caelan"):
            b.call("set_affinity", id=v, level=3)
        b.call("gauge", value=300)
        for x in (12.0, 14.0, 4.0):
            b.call("spawn", enemy_id="calcified_husk", x=x)
        wait(b, 0.6)
        shot(b, OUT + "/01-overdrive-ready.png")
        b.call("sim_input", action="ultimate", seconds=0)
        seen = []
        shots = 0
        for i in range(80):
            wait(b, 0.1)
            p = b.call("get_state")["player"]
            if p.get("vessel") not in seen:
                seen.append(p.get("vessel"))
            if i == 6:
                shot(b, OUT + "/02-darius-worldbreaker.png")
            if p.get("vessel") == "caelan" and shots == 0:
                wait(b, 0.4)
                shot(b, OUT + "/03-caelan-final-stand.png")
                shots = 1
            if p.get("state") == "overdrive_finisher" and shots == 1:
                shot(b, OUT + "/04-finisher.png")
                shots = 2
        check(seen[:2] == ["darius", "caelan"], "Darius's Ultimate, a free swap, Caelan's", str(seen))
        check(float(b.call("get_state")["player"]["gauge"]) < 50.0, "the gauge is spent")
        es = b.call("get_state")["enemies"]
        check(len([e for e in es if e.get("hp", 0) > 0]) < 3, "the finisher and Ultimates cut the Husks down", str([e.get("hp") for e in es]))
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "run-output.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
