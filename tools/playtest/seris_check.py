"""Story 030: Seris's kit in the running game. Arcane Bolt chain, Frost Binding, Aether Shield,
Rift Step out of a root-snare, Aether Burst on swap-in. Screenshots and a log go to the evidence
folder.

    bash tools/python.sh tools/playtest/seris_check.py
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-030-seris-kit"


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

    args = ["--save-dir", "user://playtest_saves", "--room", "z1_03", "--loadout", "seris,caelan"]
    with launch(args, log_name="seris_check") as (b, _proc):
        wait(b, 1.0)
        b.call("goto", room="z1_03", x=2.0, y=2.0, instant=True)
        wait(b, 0.6)
        st = b.call("get_state")
        check(st.get("player", {}).get("vessel") == "seris", "Seris is the active Vessel", str(st.get("player", {}).get("vessel")))
        b.call("kill_all")
        wait(b, 0.3)
        px = float(b.call("get_state").get("player", {}).get("x", 2.0))
        b.call("spawn", enemy_id="echo_crawler", x=px + 9.0)
        wait(b, 0.4)
        shot(b, OUT + "/01-idle.png")
        hp0 = sum(float(e.get("hp", 0)) for e in enemies(b))
        tap(b, "attack")
        wait(b, 0.2)
        shot(b, OUT + "/02-arcane-bolt-flight.png")
        wait(b, 0.5)
        tap(b, "attack")
        wait(b, 0.35)
        tap(b, "attack")
        wait(b, 0.5)
        hp1 = sum(float(e.get("hp", 0)) for e in enemies(b))
        check(hp1 < hp0, "Arcane Bolts hurt a Crawler 9 m away", "%.0f -> %.0f" % (hp0, hp1))
        b.call("kill_all")
        wait(b, 0.3)
        px = float(b.call("get_state").get("player", {}).get("x", 2.0))
        b.call("spawn", enemy_id="echo_crawler", x=px + 2.0)
        wait(b, 0.3)
        tap(b, "ability_1")
        wait(b, 0.35)
        shot(b, OUT + "/03-frost-binding.png")
        wait(b, 0.4)
        es = enemies(b)
        check(len(es) > 0, "a Crawler stands in the Frost field", json.dumps(es)[:120])
        b.call("kill_all")
        wait(b, 0.3)
        tap(b, "ability_2")
        wait(b, 0.2)
        dbg = b.call("get_state").get("player", {}).get("shield", 0)
        check(float(dbg) > 2.0, "Aether Shield is up", str(dbg))
        shot(b, OUT + "/04-aether-shield.png")
        wait(b, 3.2)
        dbg = b.call("get_state").get("player", {}).get("shield", 0)
        check(float(dbg) == 0.0, "the shield drops after 3 s", str(dbg))
        b.call("kill_all")
        wait(b, 0.3)
        b.call("root_player")
        wait(b, 0.1)
        tap(b, "dodge")
        wait(b, 0.2)
        dbg = b.call("get_state").get("player", {}).get("rooted")
        check(dbg is False, "Rift Step breaks a root-snare at once", str(dbg))
        shot(b, OUT + "/05-rift-step.png")
        b.call("set_vessel", id="caelan")
        wait(b, 2.0)
        px = float(b.call("get_state").get("player", {}).get("x", 2.0))
        b.call("spawn", enemy_id="echo_crawler", x=px + 1.5)
        wait(b, 0.3)
        r = b.call("swap", index=0)
        wait(b, 0.12)
        shot(b, OUT + "/06-aether-burst.png")
        check(r.get("vessel") == "seris", "swap back to Seris plays Aether Burst", str(r))
        b.call("gauge", value=300)
        b.call("set_affinity", id="seris", level=3)
        wait(b, 0.1)
        b.call("spawn", enemy_id="echo_crawler", x=px + 3.0)
        b.call("spawn", enemy_id="echo_crawler", x=px + 5.0)
        wait(b, 0.2)
        px = float(b.call("get_state").get("player", {}).get("x", 2.0))
        b.call("sim_input", action="ultimate", seconds=0)
        wait(b, 1.1)
        shot(b, OUT + "/07-cataclysm.png")
        st = b.call("get_state")
        log.append("state after ultimate: %s" % json.dumps(st.get("player", {}))[:300])
        left = sum(float(e.get("hp", 0)) for e in st.get("enemies", []))
        check(left < 180.0, "Cataclysm meteors hit the Crawlers", "%.0f hp left of 180" % left)
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "seris-run-output.txt"), "w") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
