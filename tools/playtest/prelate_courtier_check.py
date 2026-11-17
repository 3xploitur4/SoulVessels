"""Story 033: the Choir Prelate and the Drowned Courtier in the running game (room z1_03; Zone 3
places them for real in story 038).
Prelate: its aura rings two Crawlers in gold; Seris's Aether bolts Unravel it and the buff goes;
walking up to it makes it teleport away; its orb volley is a magic attack the Aether Shield eats.
Courtier: in a pool poured by the bridge it waits under water, rises to slash when Seris comes
close, and Frost Binding freezes it in place.

    bash tools/python.sh tools/playtest/prelate_courtier_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-033-courtier-prelate"


def tap(b, action):
    b.call("sim_input", action=action, seconds=0)


def st(b):
    return b.call("get_state")


def find(enemies, eid):
    return [e for e in enemies if e.get("id") == eid]


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
    with launch(args, log_name="prelate_check") as (b, _proc):
        wait(b, 1.0)
        b.call("goto", room="z1_03", x=3.0, y=2.0, instant=True)
        wait(b, 0.5)
        b.call("kill_all")
        b.call("debug_overlay", on=False)
        px = float(st(b)["player"]["x"])
        b.call("spawn", enemy_id="choir_prelate", x=px + 8.0)
        b.call("spawn", enemy_id="echo_crawler", x=px + 5.0)
        b.call("spawn", enemy_id="echo_crawler", x=px + 11.0)
        wait(b, 1.0)
        es = st(b)["enemies"]
        crawlers = find(es, "echo_crawler")
        check(len(crawlers) == 2 and all(c.get("buffed") for c in crawlers), "the aura buffs both Crawlers",
              str([(c.get("x"), c.get("buffed")) for c in crawlers]))
        shot(b, OUT + "/01-prelate-aura.png")
        # Seris shields herself and casts toward the Prelate; Aether bolts build Unravel.
        tap(b, "ability_2")
        wait(b, 0.3)
        shot(b, OUT + "/02-orbs-vs-shield.png")
        b.call("kill_all")
        wait(b, 0.3)
        b.call("spawn", enemy_id="choir_prelate", x=px + 9.0)
        b.call("spawn", enemy_id="echo_crawler", x=px + 12.0)
        wait(b, 0.6)
        for i in range(9):
            tap(b, "attack")
            wait(b, 0.42)
            pre = find(st(b)["enemies"], "choir_prelate")
            if pre and not find(st(b)["enemies"], "echo_crawler")[0].get("buffed", True):
                break
        wait(b, 0.8)
        es = st(b)["enemies"]
        c = find(es, "echo_crawler")
        check(bool(c) and not c[0].get("buffed"), "Unravel strips the buff", str([(e.get("id"), e.get("buffed"), e.get("hp")) for e in es]))
        shot(b, OUT + "/03-unraveled.png")
        pre = find(es, "choir_prelate")
        x0 = float(pre[0]["x"]) if pre else 0.0
        b.call("teleport", x=x0 - 2.0, y=2.0)
        wait(b, 1.0)
        pre = find(st(b)["enemies"], "choir_prelate")
        x1 = float(pre[0]["x"]) if pre else 0.0
        check(abs(x1 - x0) > 4.0, "walking up to it makes it teleport away", "%.1f -> %.1f" % (x0, x1))
        shot(b, OUT + "/04-teleported.png")

        b.call("kill_all")
        wait(b, 0.3)
        b.call("teleport", x=3.0, y=2.0)
        wait(b, 0.4)
        floor_y = float(st(b)["player"]["y"])
        b.call("water", id="pool", x=[8, 20], floor=floor_y - 0.05, level=floor_y + 2.0)
        b.call("spawn", enemy_id="drowned_courtier", x=15.0)
        wait(b, 1.2)
        c = find(st(b)["enemies"], "drowned_courtier")
        check(bool(c) and float(c[0]["y"]) < floor_y + 0.5, "the Courtier waits under water", str(c[0] if c else None))
        shot(b, OUT + "/05-courtier-submerged.png")
        b.call("press", action="move_right")
        wait(b, 1.5)
        b.call("release", action="move_right")
        seen_up = False
        for i in range(12):
            wait(b, 0.12)
            c = find(st(b)["enemies"], "drowned_courtier")
            if c and c[0].get("state") in ("telegraph", "attack"):
                seen_up = True
                shot(b, OUT + "/06-courtier-rises.png")
                break
        check(seen_up, "it rises to slash when Seris is close", str(c[0] if c else None))
        b.call("heal")
        wait(b, 0.8)
        pl = st(b)["player"]
        log.append("before the cast: %s" % {k: pl.get(k) for k in ("x", "y", "state", "facing", "water_depth", "cooldowns")})
        tap(b, "ability_1")
        wait(b, 0.5)
        log.append("after the cast: %s" % {k: st(b)["player"].get(k) for k in ("state", "cooldowns")})
        c = find(st(b)["enemies"], "drowned_courtier")
        check(bool(c) and c[0].get("frozen"), "Frost Binding freezes it in the water", str(c[0] if c else None))
        shot(b, OUT + "/07-courtier-frozen.png")
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "run-output.txt"), "w") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
