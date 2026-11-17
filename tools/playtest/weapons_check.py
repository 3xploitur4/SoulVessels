"""Story 050: second weapons at a Soul Altar in the running game. With the Guardian fallen and a
Weapon Schematic held, the altar's Upgrade page offers Caelan's Greatsword and Nyra's Venom
Blades (Seris's Floating Focus stays locked without the rune); taking up the Greatsword is saved
and carried out of the altar. Each Vessel's page also names its Affinity 5 signature passive.

    bash tools/python.sh tools/playtest/weapons_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-050-weapons"


def main():
    os.makedirs(OUT, exist_ok=True)
    log, fails = [], 0

    def check(ok, what, detail=""):
        nonlocal fails
        fails += 0 if ok else 1
        line = "%s  %-50s %s" % ("PASS" if ok else "FAIL", what, detail)
        log.append(line)
        print(line, flush=True)

    args = ["--save-dir", "user://playtest_weapons", "--room", "z4_04", "--loadout", "caelan,nyra,seris"]
    with launch(args, log_name="weapons_check") as (b, _proc):
        wait(b, 1.0)
        b.call("debug_overlay", on=False)
        b.call("flag", key="unlock_greatsword")
        b.call("give", item="weapon_schematic", count=1)
        b.call("set_affinity", id="caelan", level=5)
        b.call("goto", room="z4_04", instant=True)
        wait(b, 0.5)
        b.call("teleport", x=11.6, y=2.05)
        wait(b, 0.4)
        verb = b.call("game_state").get("interact")
        if verb == "UI_KINDLE":
            b.call("interact")
            wait(b, 2.0)
            verb = b.call("game_state").get("interact")
        check(verb == "UI_REST", "the Rift altar is in reach", str(verb))
        b.call("interact")
        wait(b, 1.5)
        b.call("ui_press", name="Upgrade")
        wait(b, 0.5)
        btns = b.call("ui_buttons").get("buttons", [])
        check("Weapon_caelan_greatsword" in btns, "the Upgrade page lists Caelan's Greatsword", str(btns))
        shot(b, OUT + "/01-altar-weapons-caelan.png")
        b.call("ui_press", name="Weapon_caelan_greatsword")
        wait(b, 0.5)
        st = b.call("game_state")["state"]
        check(st.get("weapons", {}).get("caelan") == "greatsword", "Caelan takes up the Greatsword", str(st.get("weapons")))
        shot(b, OUT + "/02-greatsword-in-hand.png")
        b.call("ui_press", name="UpgradeNext")
        wait(b, 0.4)
        btns = b.call("ui_buttons").get("buttons", [])
        check("Weapon_nyra_venom_blades" in btns, "Nyra's Venom Blades are offered", str(btns))
        shot(b, OUT + "/03-altar-weapons-nyra.png")
        b.call("ui_press", name="UpgradeNext")
        wait(b, 0.4)
        btns = b.call("ui_buttons").get("buttons", [])
        check("Weapon_seris_floating_focus (disabled)" in btns, "the Floating Focus stays locked without the rune", str(btns))
        shot(b, OUT + "/04-altar-weapons-seris-locked.png")
        b.call("ui_press", name="UpgradeBack")
        wait(b, 0.3)
        b.call("ui_press", name="Leave")
        wait(b, 0.8)
        b.call("save")
        st = b.call("game_state")["state"]
        check(st.get("weapons", {}).get("caelan") == "greatsword", "the choice is in the save", str(st.get("weapons")))
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "run-output.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
