"""Story 036: the altar's Reforge page in the running game. At the Zone 1 altar (z1_04) with
Essence and materials given by the bridge: the page lists each weapon with its cost, a reforge
to +1 spends the cost and raises ATK, and the Censer Core is crafted from three shards.

    bash tools/python.sh tools/playtest/reforge_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-036-reforge"


def main():
    os.makedirs(OUT, exist_ok=True)
    log, fails = [], 0

    def check(ok, what, detail=""):
        nonlocal fails
        fails += 0 if ok else 1
        line = "%s  %-46s %s" % ("PASS" if ok else "FAIL", what, detail)
        log.append(line)
        print(line, flush=True)

    args = ["--save-dir", "user://playtest_saves", "--room", "z1_04", "--loadout", "caelan,seris"]
    with launch(args, log_name="reforge_check") as (b, _proc):
        wait(b, 1.0)
        b.call("debug_overlay", on=False)
        b.call("essence", value=2000)
        b.call("give", item="crude_stone", count=4)
        b.call("give", item="tarnished_censer_shard", count=3)
        st = b.call("game_state")["state"]
        altar_x = None
        b.call("goto", room="z1_04", instant=True)
        wait(b, 0.5)
        # The altar stands at x 11.5 on the floor (y 2): kindle it, then rest.
        b.call("teleport", x=12.6, y=2.05)
        wait(b, 0.4)
        verb = b.call("game_state").get("interact")
        if verb == "UI_KINDLE":
            b.call("interact")
            wait(b, 2.0)
            verb = b.call("game_state").get("interact")
        altar_x = 12.6 if verb == "UI_REST" else None
        check(altar_x is not None, "the altar is in reach", str(verb))
        b.call("interact")
        wait(b, 1.5)
        btns = b.call("ui_buttons").get("buttons", [])
        check("Reforge" in btns, "the altar menu has a Reforge page", str(btns))
        b.call("ui_press", name="Reforge")
        wait(b, 0.4)
        shot(b, OUT + "/01-reforge-page.png")
        atk0 = None
        b.call("ui_press", name="Reforge_caelan")
        wait(b, 0.4)
        st = b.call("game_state")["state"]
        check(st.get("weapon_levels", {}).get("caelan") == 1 and st.get("essence") == 1700,
              "Caelan's weapon to +1 for 300 Essence and 3 stones", "%s / %s" % (st.get("weapon_levels"), st.get("essence")))
        b.call("ui_press", name="Craft_censer_core")
        wait(b, 0.4)
        st = b.call("game_state")["state"]
        inv = st.get("inventory", {})
        check(inv.get("censer_core") == 1 and not inv.get("tarnished_censer_shard"),
              "three shards become a Censer Core", str(inv))
        shot(b, OUT + "/02-after-reforge-and-craft.png")
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "run-output.txt"), "w") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
