"""Story 025: walk Zone 2 (the Luminous Mycelium Forest) in the running game.

Caelan cuts Nyra out of the roots in room 8 with real attacks and frees her; the swap tutorial
shows and a real swap makes Nyra active; she Shadowsteps through the veil on the critical path;
the Husk ambush gauntlet locks, sends three waves and opens; every room is visited through its
west door and screenshotted. Checks print PASS/FAIL; screenshots and run-output.txt go to
production/qa/evidence/story-025-zone2/.

    bash tools/python.sh tools/playtest/zone2_walk.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-025-zone2"
ROOMS = ["z2_%02d" % i for i in range(1, 17)]


def main():
    os.makedirs(OUT, exist_ok=True)
    log = []
    fails = 0

    def check(ok, what, detail=""):
        nonlocal fails
        fails += 0 if ok else 1
        line = "%s  %s %s" % ("PASS" if ok else "FAIL", what, detail)
        log.append(line)
        print(line)

    args = ["--save-dir", "user://playtest_saves", "--room", "z2_01", "--loadout", "caelan"]
    with launch(args, log_name="zone2_walk") as (b, _proc):
        wait(b, 1.2)
        st = b.call("game_state")
        check(st.get("room") == "z2_01", "the forest opens", st.get("room"))
        shot(b, OUT + "/01-forest.png")
        # Room 8: Nyra in the roots.
        b.call("goto", room="z2_08", x=11.5, y=2.0, instant=True)
        wait(b, 1.0)
        st = b.call("game_state")
        check(st.get("tutorial", "") != "", "told to cut the roots", st.get("tutorial"))
        shot(b, OUT + "/02-nyra-bound.png")
        b.call("teleport", x=13.4, y=2.0)
        wait(b, 0.3)
        for _ in range(6):
            b.call("sim_input", action="attack", seconds=0)
            wait(b, 0.55)
        st = b.call("game_state")
        check(st.get("interact") == "UI_FREE", "the roots are cut and Free is offered", st.get("prompt"))
        shot(b, OUT + "/03-roots-cut.png")
        b.call("interact")
        wait(b, 0.8)
        st = b.call("game_state")
        loadout = st.get("state", {}).get("loadout", [])
        check("nyra" in loadout, "Nyra joins the loadout", str(loadout))
        check("Nyra" in st.get("subtitle", ""), "Nyra speaks", st.get("subtitle"))
        check(st.get("tutorial", "") != "", "swap tutorial", st.get("tutorial"))
        shot(b, OUT + "/04-nyra-freed.png")
        b.call("sim_input", action="swap_next", seconds=0)
        wait(b, 0.8)
        st = b.call("game_state")
        check("vessel nyra" in b.call("get_state").get("debug", ""), "a swap makes Nyra active")
        shot(b, OUT + "/05-nyra-active.png")
        # The veil on the critical path (z2_11): Nyra's Shadowstep goes through.
        b.call("goto", room="z2_11", x=11.5, y=2.0, instant=True)
        wait(b, 0.8)
        shot(b, OUT + "/06-veil.png")
        b.call("press", action="move_right")
        wait(b, 0.4)
        b.call("release", action="move_right")
        b.call("sim_input", action="ability_1", seconds=0)
        wait(b, 0.8)
        x = float(b.call("get_state").get("player", {}).get("x", 0.0))
        check(x > 15.0, "Nyra Shadowsteps through the veil", "x=%.1f" % x)
        shot(b, OUT + "/07-through-veil.png")
        # The gauntlet.
        b.call("goto", room="z2_13", exit="0", instant=True)
        wait(b, 0.6)
        b.call("press", action="move_right")
        wait(b, 1.2)
        b.call("release", action="move_right")
        wait(b, 0.4)
        st = b.call("game_state")
        check(st.get("subtitle", "") != "", "the queen calls the husks", st.get("subtitle"))
        shot(b, OUT + "/08-gauntlet-wave1.png")
        for n in range(2):
            b.call("kill_all")
            wait(b, 1.0)
            shot(b, OUT + "/%02d-gauntlet-wave%d.png" % (9 + n, n + 2))
            check(len(b.call("get_state").get("enemies", [])) == 3, "wave %d arrives" % (n + 2))
        b.call("kill_all")
        wait(b, 1.0)
        st = b.call("game_state")
        check("z2_13_gauntlet" in st.get("state", {}).get("cleared_arenas", []), "the gauntlet is cleared and saved")
        shot(b, OUT + "/11-gauntlet-cleared.png")
        for room in ROOMS:
            b.call("goto", room=room, exit="0", instant=True)
            wait(b, 0.9)
            shot(b, "%s/room-%s.png" % (OUT, room))
            check(b.call("game_state").get("room") == room, "room %s builds" % room)
    log.append("SUMMARY: %d failed" % fails)
    with open(OUT + "/run-output.txt", "w") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
