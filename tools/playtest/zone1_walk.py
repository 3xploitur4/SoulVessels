"""Story 024: walk Zone 1 (the Whispering Cavern) in the running game.

A new save starts as the wisp in room 1; it drifts to the Knight's Vigil, is refused the far exit,
takes Caelan's body with the interact control, and walks out. Then every room is visited in
order (through its west door) and screenshotted, and the Warden's hall is fought: the bars shut
when Caelan walks in and open when the Warden falls. Checks print PASS/FAIL; screenshots and
run-output.txt go to production/qa/evidence/story-024-zone1/.

    bash tools/python.sh tools/playtest/zone1_walk.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-024-zone1"
ROOMS = ["z1_%02d" % i for i in range(1, 15)]


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

    with launch(["--save-dir", "user://playtest_saves"], log_name="zone1_walk") as (b, _proc):
        st = b.call("new_game", slot=1)
        check(st.get("room") == "z1_01", "a new game starts in Awakening Hollow", st.get("room"))
        wait(b, 1.2)
        st = b.call("game_state")
        check("{" not in st.get("tutorial", "{") and st.get("tutorial", "") != "", "move tutorial shows with real keys", st.get("tutorial"))
        shot(b, OUT + "/01-wisp-wakes.png")
        b.call("goto", room="z1_01", x=20.0, y=2.0, instant=True)
        wait(b, 0.6)
        st = b.call("game_state")
        check(st.get("subtitle", "") != "", "the voice calls the wisp a thief", st.get("subtitle"))
        shot(b, OUT + "/02-thief.png")
        # The Knight's Vigil: refused at the far exit, then possession.
        b.call("goto", room="z1_02", exit="0")
        wait(b, 0.8)
        b.call("teleport", x=21.0, y=2.0)
        b.call("press", action="move_right")
        wait(b, 0.8)
        b.call("release", action="move_right")
        st = b.call("game_state")
        check(st.get("room") == "z1_02", "the wisp cannot leave the Vigil yet", st.get("tutorial"))
        shot(b, OUT + "/03-refused.png")
        b.call("teleport", x=16.5, y=5.1)
        wait(b, 0.5)
        st = b.call("game_state")
        check(st.get("interact") == "UI_POSSESS", "the body offers Possess", st.get("prompt"))
        shot(b, OUT + "/04-body.png")
        b.call("interact")
        wait(b, 0.8)
        st = b.call("game_state")
        loadout = st.get("state", {}).get("loadout", [])
        check(loadout == ["caelan"], "the wisp is now Caelan", str(loadout))
        check(st.get("subtitle", "") != "", "the voice answers the possession", st.get("subtitle"))
        shot(b, OUT + "/05-possessed.png")
        b.call("teleport", x=21.0, y=2.0)
        b.call("press", action="move_right")
        wait(b, 1.0)
        b.call("release", action="move_right")
        wait(b, 0.6)
        st = b.call("game_state")
        check(st.get("room") == "z1_03", "Caelan walks out of the Vigil", st.get("room"))
        check(st.get("tutorial", "") != "", "attack tutorial on entering the steps", st.get("tutorial"))
        # Every room in order.
        for i, room in enumerate(ROOMS):
            b.call("goto", room=room, exit="0" if room != "z1_01" else "", instant=True)
            wait(b, 0.9)
            shot(b, "%s/room-%s.png" % (OUT, room))
            st = b.call("game_state")
            check(st.get("room") == room, "room %s builds" % room)
        # The Warden's hall.
        b.call("goto", room="z1_12", exit="0", instant=True)
        wait(b, 0.6)
        b.call("press", action="move_right")
        wait(b, 1.4)
        b.call("release", action="move_right")
        wait(b, 0.4)
        st = b.call("game_state")
        check(st.get("subtitle", "") != "", "the voice orders Caelan to kneel", st.get("subtitle"))
        shot(b, OUT + "/06-warden-hall-locked.png")
        wait(b, 1.5)
        shot(b, OUT + "/07-warden-fight.png")
        b.call("kill_all")
        wait(b, 1.0)
        st = b.call("game_state")
        check("z1_12_warden" in st.get("state", {}).get("cleared_arenas", []), "the hall is cleared and saved")
        shot(b, OUT + "/08-warden-falls.png")
    log.append("SUMMARY: %d failed" % fails)
    with open(OUT + "/run-output.txt", "w") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
