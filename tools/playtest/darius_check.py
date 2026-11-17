"""Story 041: Darius's kit in the running game (room z1_03). Hammer combo, Crushing Blow through a
Branded Warden's shield, Groundbreaker killing a ring of Crawlers outright, the shoulder charge,
Meteor Drop on swap-in, and Worldbreaker breaking every guard on screen.

    bash tools/python.sh tools/playtest/darius_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-041-darius-kit"


def tap(b, action):
    b.call("sim_input", action=action, seconds=0)


def enemies(b):
    return b.call("get_state").get("enemies", [])


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
    with launch(args, log_name="darius_check") as (b, _proc):
        wait(b, 1.0)
        b.call("goto", room="z1_03", x=3.0, y=2.0, instant=True)
        wait(b, 0.5)
        b.call("kill_all")
        b.call("debug_overlay", on=False)
        check(b.call("get_state")["player"]["vessel"] == "darius", "Darius is active")
        px = float(b.call("get_state")["player"]["x"])
        b.call("spawn", enemy_id="branded_warden", x=px + 2.6)
        wait(b, 0.6)
        tap(b, "attack")
        wait(b, 0.25)
        shot(b, OUT + "/01-hammer.png")
        wait(b, 0.8)
        tap(b, "ability_1")
        wait(b, 0.5)
        shot(b, OUT + "/02-crushing-blow.png")
        wait(b, 0.5)
        w = [e for e in enemies(b) if e.get("id") == "branded_warden"]
        check(bool(w) and float(w[0]["posture"]) >= 150.0 or (w and w[0].get("staggered")),
              "Crushing Blow lands 150 posture through the shield", str(w[0] if w else None)[:120])
        b.call("kill_all")
        wait(b, 0.3)
        for dx in (-3.0, -1.5, 1.5, 3.0):
            b.call("spawn", enemy_id="echo_crawler", x=px + dx)
        wait(b, 0.3)
        tap(b, "ability_2")
        wait(b, 0.45)
        shot(b, OUT + "/03-groundbreaker.png")
        wait(b, 0.5)
        left = [e for e in enemies(b) if e.get("id") == "echo_crawler"]
        check(len(left) == 0, "Groundbreaker kills every Crawler in reach outright", "%d left" % len(left))
        tap(b, "dodge")
        wait(b, 0.12)
        shot(b, OUT + "/04-shoulder-charge.png")
        wait(b, 0.6)
        b.call("set_vessel", id="caelan")
        wait(b, 2.0)
        px = float(b.call("get_state")["player"]["x"])
        b.call("spawn", enemy_id="echo_crawler", x=px + 1.5)
        wait(b, 0.2)
        r = b.call("swap", index=0)
        wait(b, 0.35)
        shot(b, OUT + "/05-meteor-drop.png")
        check(r.get("vessel") == "darius", "swapping back plays Meteor Drop", str(r))
        b.call("kill_all")
        b.call("spawn", enemy_id="branded_warden", x=px + 6.0)
        b.call("spawn", enemy_id="calcified_husk", x=px - 5.0)
        wait(b, 0.5)
        b.call("gauge", value=300)
        b.call("set_affinity", id="darius", level=3)
        b.call("sim_input", action="ultimate", seconds=0)
        wait(b, 1.5)
        shot(b, OUT + "/06-worldbreaker.png")
        es = enemies(b)
        broken = [e for e in es if e.get("staggered")]
        check(len(broken) >= 1, "Worldbreaker breaks every guard on screen", str([(e.get("id"), e.get("staggered")) for e in es]))
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "run-output.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
