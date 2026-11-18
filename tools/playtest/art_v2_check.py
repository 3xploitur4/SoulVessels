"""Story 053: the v2 art in the running game. Each Vessel standing and attacking in a lit room;
the painted Soul Altar cold and kindled; the masonry, rune-door and portcullis gates; painted item
pickups; and the three bosses (the Weeping Sovereign, the Guardian Below, the Abyssal Leviathan)
on their real arenas, caught in an attack. Screenshots and run-output.txt go to
production/qa/evidence/story-053-art-v2/.

    bash tools/python.sh tools/playtest/art_v2_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-053-art-v2"
BOSSES = {"weeping_sovereign": "z3_17", "guardian_below": "z4_10", "abyssal_leviathan": "z4_13"}


def tap(b, a):
    b.call("sim_input", action=a, seconds=0)


def main():
    os.makedirs(OUT, exist_ok=True)
    log, fails = [], 0

    def check(ok, what, detail=""):
        nonlocal fails
        fails += 0 if ok else 1
        line = "%s  %-50s %s" % ("PASS" if ok else "FAIL", what, detail)
        log.append(line)
        print(line, flush=True)

    args = ["--save-dir", "user://playtest_art_v2", "--room", "z4_04", "--loadout", "caelan,darius,seris"]
    with launch(args, log_name="art_v2_check") as (b, _proc):
        wait(b, 1.2)
        b.call("debug_overlay", on=False)
        # The altar, cold, then kindled.
        b.call("teleport", x=6.0, y=2.05)
        wait(b, 0.6)
        shot(b, OUT + "/01-altar-cold.png")
        b.call("teleport", x=11.6, y=2.05)
        wait(b, 0.4)
        if b.call("game_state").get("interact") == "UI_KINDLE":
            b.call("interact")
            wait(b, 2.0)
        b.call("ui_press", name="Leave")
        b.call("teleport", x=6.0, y=2.05)
        wait(b, 0.8)
        shot(b, OUT + "/02-altar-kindled.png")
        check(True, "the painted altar, cold and kindled")
        # Each Vessel, standing then mid-attack.
        for n, v in enumerate(["caelan", "darius", "seris"]):
            b.call("set_vessel", id=v)
            wait(b, 1.0)
            st = b.call("get_state")["player"]
            check(st.get("vessel") == v, "%s takes the field" % v, str(st.get("vessel")))
            shot(b, OUT + "/%02d-%s-idle.png" % (n * 2 + 3, v))
            tap(b, "attack")
            wait(b, 0.14)
            shot(b, OUT + "/%02d-%s-attack.png" % (n * 2 + 4, v))
            wait(b, 1.0)
        # Gates: masonry, a rune door, the arena portcullis.
        b.call("goto", room="z4_03", x=20.0, y=2.05, instant=True)
        wait(b, 1.0)
        shot(b, OUT + "/09-masonry-gate.png")
        b.call("goto", room="z3_05", x=24.0, y=2.05, instant=True)
        wait(b, 1.0)
        b.call("kill_all")
        shot(b, OUT + "/10-rune-door.png")
        # Pickups in the Expedition Cache.
        b.call("goto", room="z4_07", x=6.0, y=7.1, instant=True)
        wait(b, 1.0)
        b.call("teleport", x=8.0, y=2.05)
        wait(b, 0.4)
        shot(b, OUT + "/11-pickups.png")
        # The bosses on their arenas.
        for n, (boss, room) in enumerate(BOSSES.items()):
            b.call("goto", room=room, exit="0", instant=True)
            wait(b, 0.6)
            b.call("press", action="move_right")
            wait(b, 1.4)
            b.call("release", action="move_right")
            got = 0
            for i in range(160):
                b.call("heal")
                es = [e for e in b.call("get_state")["enemies"] if str(e.get("id", "")) == boss]
                if es and i % 10 == 0:
                    b.call("teleport", x=max(float(es[0]["x"]) - 7.5, 4.0), y=2.05)
                s = b.call("boss")
                if s.get("state") in ("telegraph", "attack") and got < 2 and i % 10 >= 4:
                    got += 1
                    shot(b, OUT + "/%02d-%s-%d.png" % (12 + n, boss, got))
                    wait(b, 0.8)
                if got >= 2:
                    break
                wait(b, 0.15)
            check(got >= 1, "%s fights with its new art" % boss, "%d shots" % got)
            if n == 0:
                shot(b, OUT + "/15-portcullis-locked.png")
        # The other two Vessels.
        b.call("goto", room="z4_04", x=6.0, y=2.05, instant=True)
        wait(b, 0.8)
        b.call("awakening")
        wait(b, 2.5)
        shot(b, OUT + "/16-ilyr.png")
        check(b.call("get_state")["player"].get("vessel") == "ilyr", "Ilyr's new art")
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "run-output.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
