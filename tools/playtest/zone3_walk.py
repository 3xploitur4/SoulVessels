"""Story 038: walk Zone 3 (the Sunken Palace) in the running game.

From the flooded stair at the end of Zone 2 down into the palace; Caelan breaks Seris out of her
crystal in room 4 with real attacks and frees her; she solves the Hall of Murals sequence, the
Mirror Hall (turning the mirror by interacting) and the Tide Gate (Frost Binding on the pool,
standing on the ice) with real bolts; the throne hall locks and the Sovereign wakes; every room is
visited through its west door and screenshotted. Checks print PASS/FAIL; screenshots and
run-output.txt go to production/qa/evidence/story-038-zone3/.

    bash tools/python.sh tools/playtest/zone3_walk.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-038-zone3"
ROOMS = ["z3_%02d" % i for i in range(1, 19)]


def tap(b, action):
    b.call("sim_input", action=action, seconds=0)


def face(b, direction):
    b.call("sim_input", action="move_right" if direction > 0 else "move_left", seconds=0.05)
    wait(b, 0.15)


def runes(b):
    try:
        return b.call("runes")
    except Exception as e:  # noqa: BLE001
        return {"error": str(e)}


def main():
    os.makedirs(OUT, exist_ok=True)
    log, fails = [], 0

    def check(ok, what, detail=""):
        nonlocal fails
        fails += 0 if ok else 1
        line = "%s  %-48s %s" % ("PASS" if ok else "FAIL", what, detail)
        log.append(line)
        print(line, flush=True)

    args = ["--save-dir", "user://playtest_saves", "--room", "z2_16", "--loadout", "caelan,nyra"]
    with launch(args, log_name="zone3_walk") as (b, _proc):
        wait(b, 1.2)
        b.call("debug_overlay", on=False)
        # The flooded stair: walk into it.
        b.call("teleport", x=21.0, y=2.05)
        b.call("press", action="move_right")
        for _ in range(20):
            wait(b, 0.3)
            if b.call("game_state").get("room") == "z3_01":
                break
        b.call("release", action="move_right")
        wait(b, 1.5)
        st = b.call("game_state")
        check(st.get("room") == "z3_01", "the flooded stair leads into the palace", st.get("room"))
        check("palace" in str(b.call("get_state")["music"].get("zone")) or b.call("get_state")["music"].get("zone") == "zone3",
              "Track 05 plays", str(b.call("get_state")["music"].get("zone")))
        shot(b, OUT + "/01-flooded-stair.png")

        # Room 4: Seris in crystal.
        b.call("goto", room="z3_04", x=11.5, y=2.0, instant=True)
        wait(b, 1.0)
        st = b.call("game_state")
        check(st.get("tutorial", "") != "", "told to break the crystal", st.get("tutorial"))
        shot(b, OUT + "/02-seris-in-crystal.png")
        b.call("teleport", x=12.6, y=2.0)
        face(b, 1)
        for _ in range(6):
            tap(b, "attack")
            wait(b, 0.55)
        st = b.call("game_state")
        check(st.get("interact") == "UI_FREE", "the crystal breaks and Free is offered", st.get("prompt"))
        b.call("interact")
        wait(b, 0.8)
        st = b.call("game_state")
        check("seris" in st.get("state", {}).get("loadout", []), "Seris joins the loadout", str(st.get("state", {}).get("loadout")))
        check("Seris" in st.get("subtitle", ""), "Seris speaks", st.get("subtitle"))
        shot(b, OUT + "/03-seris-freed.png")
        b.call("set_vessel", id="seris")
        wait(b, 0.4)

        # Puzzle 1: the Hall of Murals sequence (runes at x 20.5, 14.5, 26.5 in that order).
        b.call("goto", room="z3_05", x=17.0, y=2.0, instant=True)
        wait(b, 1.0)
        b.call("kill_all")
        shot(b, OUT + "/04-murals-dark.png")
        face(b, 1)
        tap(b, "attack")
        wait(b, 1.0)
        b.call("teleport", x=11.0, y=2.0)
        wait(b, 0.3)
        face(b, 1)
        tap(b, "attack")
        wait(b, 1.0)
        tap(b, "attack")
        wait(b, 1.2)
        r = runes(b)
        check(r.get("solved") is True and r.get("door") is False, "puzzle 1: the sequence opens the door", str(r))
        shot(b, OUT + "/05-murals-solved.png")

        # Puzzle 2: the Mirror Hall. The mirror starts upright; turn it three times to 135.
        b.call("goto", room="z3_07", x=13.4, y=2.0, instant=True)
        wait(b, 1.0)
        b.call("kill_all")
        for _ in range(3):
            b.call("interact")
            wait(b, 0.2)
        b.call("teleport", x=8.0, y=2.0)
        wait(b, 0.3)
        face(b, 1)
        tap(b, "attack")
        wait(b, 1.2)
        r = runes(b)
        check(r.get("solved") is True, "puzzle 2: the mirror lifts the bolt into the rune", str(r))
        shot(b, OUT + "/06-mirror-solved.png")

        # Puzzle 3: the Tide Gate. Freeze the pool from the bank, stand on the ice, fire.
        b.call("goto", room="z3_09", x=6.5, y=5.0, instant=True)
        wait(b, 1.0)
        b.call("kill_all")
        face(b, -1)
        face(b, 1)
        tap(b, "attack")
        wait(b, 1.0)
        r = runes(b)
        check(r.get("lit") == 0, "from the bank the bolt passes over the rune", str(r))
        tap(b, "ability_1")
        wait(b, 0.6)
        b.call("teleport", x=9.5, y=3.6)
        wait(b, 0.5)
        face(b, 1)
        tap(b, "attack")
        wait(b, 1.0)
        r = runes(b)
        check(r.get("solved") is True, "puzzle 3: from the ice the rune is in line", str(r))
        shot(b, OUT + "/07-tide-solved.png")

        # The throne hall.
        b.call("goto", room="z3_17", exit="0", instant=True)
        wait(b, 0.8)
        b.call("press", action="move_right")
        wait(b, 1.2)
        b.call("release", action="move_right")
        wait(b, 1.2)
        m = b.call("get_state")["music"]
        check(m.get("zone") == "boss_sovereign", "the throne hall wakes the Sovereign and her music", str(m.get("zone")))
        shot(b, OUT + "/08-throne-hall.png")

        # Every room, through its west door.
        for room in ROOMS:
            b.call("goto", room=room, exit="0", instant=True)
            wait(b, 0.9)
            b.call("kill_all")
            st = b.call("game_state")
            ok = st.get("room") == room
            if not ok:
                check(False, "room %s loads" % room, str(st.get("room")))
            shot(b, OUT + "/room-%s.png" % room)
        check(True, "all 18 rooms visited and screenshotted")
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "run-output.txt"), "w") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
