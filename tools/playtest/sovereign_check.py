"""Story 034: the Weeping Sovereign in the running game. In room z1_03 with a pool poured by the
bridge (her real throne hall comes in story 038), she is spawned and fights Seris; the bridge's
`boss` command sets her health to walk the three phases. Screens: her bars, an attack, the phase
2 water rising, a phase 3 Ember attack, and her fall.

    bash tools/python.sh tools/playtest/sovereign_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-034-sovereign"


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
    with launch(args, log_name="sovereign_check") as (b, _proc):
        wait(b, 1.0)
        b.call("goto", room="z1_03", x=4.0, y=2.0, instant=True)
        wait(b, 0.5)
        b.call("kill_all")
        b.call("debug_overlay", on=False)
        floor_y = float(b.call("get_state")["player"]["y"])
        b.call("water", id="arena", x=[1, 30], floor=floor_y - 0.05, level=floor_y + 0.25)
        b.call("spawn", enemy_id="weeping_sovereign", x=11.0)
        b.call("set_hp", hp=9999)
        wait(b, 1.5)
        r = b.call("boss")
        check(r.get("phase") == 0, "she is up, phase 1", str(r))
        m = b.call("get_state")["music"]
        check(m.get("zone") == "boss_sovereign" and m.get("state") == "phase1", "her track plays its phase 1 clip",
              "%s / %s" % (m.get("zone"), m.get("state")))
        shot(b, OUT + "/01-sovereign-bars.png")
        seen = set()
        for i in range(40):
            wait(b, 0.15)
            r = b.call("boss")
            b.call("heal")
            if r.get("state") == "telegraph" and r.get("attack") not in seen:
                seen.add(r.get("attack"))
                shot(b, OUT + "/02-p1-%s.png" % r.get("attack"))
            if len(seen) >= 2:
                break
        check(len(seen) >= 1, "she attacks in phase 1", str(sorted(seen)))
        r = b.call("boss", fraction=0.61, strike=200)
        check(r.get("phase") == 1 and r.get("transition") is True, "below 60 %: phase 2 begins", str(r))
        wait(b, 1.2)
        shot(b, OUT + "/03-p2-water-rising.png")
        wait(b, 1.8)
        lvl = b.call("water", id="arena").get("level", 0)
        check(abs(float(lvl) - (floor_y + 1.75)) < 0.1, "the water rose 1.5 m", "%.2f" % float(lvl))
        m = b.call("get_state")["music"]
        for i in range(28):
            if m.get("state") == "phase2":
                break
            wait(b, 0.5)
            b.call("heal")
            m = b.call("get_state")["music"]
        check(m.get("state") == "phase2", "the phase 2 clip comes in on a boundary", str(m.get("history"))[-160:])
        shot(b, OUT + "/04-p2-flooded.png")
        r = b.call("boss", fraction=0.26, strike=200)
        check(r.get("phase") == 2, "below 25 %: phase 3", str(r))
        wait(b, 1.8)
        burned = False
        for i in range(60):
            wait(b, 0.15)
            b.call("heal")
            r = b.call("boss")
            if r.get("state") in ("telegraph", "attack") and r.get("attack", "").startswith(("ember", "pyre")):
                shot(b, OUT + "/05-p3-%s.png" % r.get("attack"))
                burned = True
                break
        check(burned, "phase 3 uses Ember attacks", str(r))
        b.call("boss", fraction=0.0001, strike=500)
        wait(b, 0.6)
        es = [e for e in b.call("get_state")["enemies"] if e.get("id") == "weeping_sovereign"]
        check(not es, "she falls", str(es))
        wait(b, 0.5)
        m = b.call("get_state")["music"]
        check(m.get("zone") == "zone1", "the zone track returns", str(m.get("zone")))
        shot(b, OUT + "/06-fallen.png")
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "run-output.txt"), "w") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
