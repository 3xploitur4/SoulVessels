"""Story 037: the altar Upgrade page in the running game (ability ranks and Sync passives).
At the Zone 1 altar (z1_04) with shards given by the bridge: the page lists Caelan's four abilities
with rank and cost and his three Sync passives; King's Judgment is bought to rank 3 and King's
Mercy is bought and slotted.

    bash tools/python.sh tools/playtest/upgrade_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-037-ranks-passives"


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
        b.call("give", item="standard_soul_shard", count=5)
        b.call("give", item="greater_soul_shard", count=1)
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
        check("Upgrade" in btns, "the altar menu has an Upgrade page", str(btns))
        b.call("ui_press", name="Upgrade")
        wait(b, 0.4)
        shot(b, OUT + "/01-upgrade-page.png")
        b.call("ui_press", name="Rank_caelan_kings_judgment")
        wait(b, 0.3)
        b.call("ui_press", name="Rank_caelan_kings_judgment")
        wait(b, 0.3)
        b.call("ui_press", name="Passive_caelan_kings_mercy")
        wait(b, 0.4)
        st = b.call("game_state")["state"]
        check(st.get("ability_ranks", {}).get("caelan", {}).get("kings_judgment") == 3, "King's Judgment to rank 3",
              str(st.get("ability_ranks")))
        check(st.get("sync_passive", {}).get("caelan") == "kings_mercy", "King's Mercy slotted", str(st.get("sync_passive")))
        shot(b, OUT + "/02-after-buying.png")
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "run-output.txt"), "w") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
