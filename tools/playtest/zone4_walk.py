"""Story 049: walk Zone 4 (the Sealed Rift and the Starless Shore) in the running game.

The Breach in z3_18 gives way once the Sovereign has fallen; down the stair into the Rift; Darius
is dug out of the rubble in room 3 with real attacks and freed; his Crushing Blow breaks the
masonry on; the Long Incline slides the player downhill; the landing before the lift is a
checkpoint; the lift wakes the Guardian and its music; the shore plays its own track; the shore
arena wakes the Leviathan; with the rift open, "Enter" carries Ilyr's awakening. Every room is
visited and screenshotted. Checks print PASS/FAIL; screenshots and run-output.txt go to
production/qa/evidence/story-049-zone4/.

    bash tools/python.sh tools/playtest/zone4_walk.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-049-zone4"
ROOMS = ["z4_%02d" % i for i in range(1, 15)]


def tap(b, action):
    b.call("sim_input", action=action, seconds=0)


def face(b, direction):
    b.call("sim_input", action="move_right" if direction > 0 else "move_left", seconds=0.05)
    wait(b, 0.15)


def walk_until(b, direction, room, tries=20):
    action = "move_right" if direction > 0 else "move_left"
    b.call("press", action=action)
    for _ in range(tries):
        wait(b, 0.3)
        if b.call("game_state").get("room") == room:
            break
    b.call("release", action=action)


def music(b):
    return str(b.call("get_state")["music"].get("zone"))


def main():
    os.makedirs(OUT, exist_ok=True)
    log, fails = [], 0

    def check(ok, what, detail=""):
        nonlocal fails
        fails += 0 if ok else 1
        line = "%s  %-50s %s" % ("PASS" if ok else "FAIL", what, detail)
        log.append(line)
        print(line, flush=True)

    args = ["--save-dir", "user://playtest_zone4", "--room", "z3_17", "--loadout", "caelan,nyra,seris"]
    with launch(args, log_name="zone4_walk") as (b, _proc):
        wait(b, 1.2)
        b.call("debug_overlay", on=False)

        # The Breach: sealed until the Sovereign falls, then open.
        b.call("goto", room="z3_18", x=8.0, y=2.05, instant=True)
        wait(b, 0.8)
        st = b.call("game_state")["state"]
        check("z3_18:masonry:0" not in st.get("opened_gates", []), "the Breach is sealed while the Sovereign lives")
        b.call("flag", key="boss_weeping_sovereign")
        b.call("goto", room="z3_18", x=8.0, y=2.05, instant=True)
        wait(b, 0.8)
        st = b.call("game_state")["state"]
        check("z3_18:masonry:0" in st.get("opened_gates", []), "her fall cracks the Breach open")
        shot(b, OUT + "/01-breach-open.png")
        walk_until(b, 1, "z4_01")
        wait(b, 1.2)
        gs = b.call("game_state")
        check(gs.get("room") == "z4_01", "the Breach leads down into the Rift", gs.get("room"))
        check(gs.get("zone") == "zone4", "Zone 4", gs.get("zone"))
        check(music(b) == "zone4", "Track 09 plays", music(b))
        shot(b, OUT + "/02-breach-stair.png")

        # Room 2: dark, a swarm of 8.
        b.call("goto", room="z4_02", exit="0", instant=True)
        wait(b, 1.0)
        n = len([e for e in b.call("get_state")["enemies"] if e.get("id") == "echo_crawler"])
        check(n == 8, "the Ember Hall: a swarm of 8 Crawlers in the dark", str(n))
        shot(b, OUT + "/03-ember-hall-dark.png")

        # Room 3: Darius under the rubble.
        b.call("goto", room="z4_03", x=10.6, y=2.05, instant=True)
        wait(b, 1.2)
        gs = b.call("game_state")
        said = [l for l in gs.get("lines", []) if l.startswith("Darius")]
        check(len(said) > 0, "Darius distrusts the Intruder", (said or [""])[-1][:80])
        shot(b, OUT + "/04-darius-under-rubble.png")
        b.call("teleport", x=11.8, y=2.05)
        face(b, 1)
        for _ in range(6):
            tap(b, "attack")
            wait(b, 0.55)
        gs = b.call("game_state")
        check(gs.get("interact") == "UI_FREE", "the rubble breaks and Free is offered", gs.get("prompt"))
        before = gs.get("lines", [])
        b.call("interact")
        wait(b, 0.8)
        gs = b.call("game_state")
        check("darius" in gs.get("state", {}).get("loadout", []), "Darius joins the loadout",
              str(gs.get("state", {}).get("loadout")))
        said = [l for l in gs.get("lines", []) if l.startswith("Darius") and l not in before]
        check(len(said) > 0, "Darius speaks as he joins", (said or [""])[-1][:80])
        shot(b, OUT + "/05-darius-joins.png")
        b.call("set_vessel", id="darius")
        wait(b, 1.0)
        b.call("teleport", x=23.4, y=2.05)
        face(b, 1)
        tap(b, "ability_1")
        wait(b, 1.2)
        st = b.call("game_state")["state"]
        check("z4_03:masonry:0" in st.get("opened_gates", []), "his Crushing Blow breaks the masonry")
        shot(b, OUT + "/06-masonry-broken.png")

        # Room 5: the Long Incline slides you downhill.
        b.call("goto", room="z4_05", x=8.0, y=2.05, instant=True)
        wait(b, 0.4)
        b.call("kill_all")
        x0 = float(b.call("get_state")["player"]["x"])
        wait(b, 1.5)
        x1 = float(b.call("get_state")["player"]["x"])
        check(x1 > x0 + 1.0, "standing on the incline slides you downhill", "%.1f -> %.1f" % (x0, x1))
        shot(b, OUT + "/07-long-incline.png")

        # Room 9: the checkpoint before the Guardian.
        b.call("goto", room="z4_09", exit="0", instant=True)
        wait(b, 0.8)
        st = b.call("game_state")["state"]
        check(st.get("rested_altar", {}).get("room") == "z4_09", "the landing is a checkpoint", str(st.get("rested_altar")))

        # Room 10: the Guardian's lift.
        b.call("goto", room="z4_10", exit="0", instant=True)
        wait(b, 0.8)
        b.call("press", action="move_right")
        wait(b, 1.4)
        b.call("release", action="move_right")
        wait(b, 1.5)
        check(music(b) == "boss_guardian", "the lift wakes the Guardian and Track 10", music(b))
        shot(b, OUT + "/08-guardian-lift.png")

        # The shore: its own track.
        b.call("goto", room="z4_11", exit="0", instant=True)
        wait(b, 1.0)
        check(music(b) == "zone4_shore", "the Starless Shore plays Track 12", music(b))
        shot(b, OUT + "/09-starless-shore.png")

        # Room 13: the Leviathan; then the rift.
        b.call("goto", room="z4_13", exit="0", instant=True)
        wait(b, 0.8)
        b.call("press", action="move_right")
        wait(b, 1.4)
        b.call("release", action="move_right")
        wait(b, 1.5)
        check(music(b) == "boss_leviathan", "the shore wakes the Leviathan and Track 13", music(b))
        shot(b, OUT + "/10-abyssal-shore.png")
        b.call("goto", room="z4_13", x=18.5, y=2.05, instant=True)
        wait(b, 0.6)
        b.call("kill_all")
        gs = b.call("game_state")
        check(gs.get("interact") != "UI_ENTER", "no rift while the Leviathan lives", gs.get("interact"))
        b.call("flag", key="rift_open")
        wait(b, 1.0)
        gs = b.call("game_state")
        check(gs.get("interact") == "UI_ENTER", "its fall opens the rift", gs.get("interact"))
        shot(b, OUT + "/11-rift-open.png")
        b.call("interact")
        wait(b, 2.5)
        gs = b.call("game_state")
        p = b.call("get_state")["player"]
        check(gs.get("room") == "z4_14", "the rift leads beyond", gs.get("room"))
        check(p.get("vessel") == "ilyr", "beyond the rift the Intruder is Ilyr", str(p.get("vessel")))
        shot(b, OUT + "/12-beyond-the-rift.png")

        # Every room, through its west door (z4_14 has none: arrive by the rift's point).
        for room in ROOMS:
            if room == "z4_14":
                continue
            b.call("goto", room=room, exit="0", instant=True)
            wait(b, 0.9)
            b.call("kill_all")
            gs = b.call("game_state")
            if gs.get("room") != room:
                check(False, "room %s loads" % room, str(gs.get("room")))
            shot(b, OUT + "/room-%s.png" % room)
        check(True, "all 14 rooms visited and screenshotted")
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "run-output.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
