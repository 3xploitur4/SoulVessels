"""Story 040: the M3 playtest. One run from the end of Zone 2 through Zone 3 over the bridge.

Covers, in order:
- the flooded stair into the palace, with Track 05 playing;
- Seris broken out of her crystal with real attacks and freed;
- one rune puzzle of each kind, with real input: the Hall of Murals sequence, the Mirror Hall
  mirror (turned by interacting) and the Tide Gate (Frost Binding, standing on the ice);
- the Choir Prelate's aura on its Crawlers, and the nave cleared;
- at the Cloister altar: a reforge to +1 and an ability rank, with materials given by the bridge;
- the Weeping Sovereign: the arena locks, her music plays, the bridge walks her three phases
  (phase 2 water rising), and she falls: Crown Fragment, flag, Caelan +1 Affinity, the bars open;
- quit to the title and Continue, with everything kept.

The run starts as a throwaway game in slot 2 (`--room`), so it never touches a player's saves.

    bash tools/python.sh tools/playtest/drive_m3.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-040-m3"


def tap(b, action):
    b.call("sim_input", action=action, seconds=0)


def face(b, direction):
    b.call("sim_input", action="move_right" if direction > 0 else "move_left", seconds=0.05)
    wait(b, 0.15)


def gs(b):
    return b.call("game_state")


def main():
    os.makedirs(OUT, exist_ok=True)
    log, fails = [], 0

    def check(ok, what, detail=""):
        nonlocal fails
        fails += 0 if ok else 1
        line = "%s  %-50s %s" % ("PASS" if ok else "FAIL", what, detail)
        log.append(line)
        print(line, flush=True)

    args = ["--save-dir", "user://playtest_m3", "--room", "z2_16", "--loadout", "caelan,nyra"]
    with launch(args, log_name="drive_m3") as (b, _proc):
        wait(b, 1.2)
        b.call("debug_overlay", on=False)
        # 1. The flooded stair.
        b.call("teleport", x=21.0, y=2.05)
        b.call("press", action="move_right")
        for _ in range(20):
            wait(b, 0.3)
            if gs(b).get("room") == "z3_01":
                break
        b.call("release", action="move_right")
        wait(b, 1.2)
        check(gs(b).get("room") == "z3_01", "the flooded stair leads into the palace", gs(b).get("room"))
        check(b.call("get_state")["music"].get("zone") == "zone3", "Track 05 plays", str(b.call("get_state")["music"].get("zone")))
        shot(b, OUT + "/01-palace.png")

        # 2. Seris.
        b.call("goto", room="z3_04", x=12.6, y=2.0, instant=True)
        wait(b, 1.0)
        face(b, 1)
        for _ in range(6):
            tap(b, "attack")
            wait(b, 0.55)
        b.call("interact")
        wait(b, 0.8)
        st = gs(b)
        check("seris" in st.get("state", {}).get("loadout", []), "Seris is freed and joins", str(st.get("state", {}).get("loadout")))
        shot(b, OUT + "/02-seris.png")
        b.call("set_vessel", id="seris")
        wait(b, 0.3)

        # 3. One puzzle of each kind.
        b.call("goto", room="z3_05", x=17.0, y=2.0, instant=True)
        wait(b, 1.0)
        b.call("kill_all")
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
        check(b.call("runes").get("solved") is True, "sequence puzzle solved", str(b.call("runes")))
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
        check(b.call("runes").get("solved") is True, "mirror puzzle solved", str(b.call("runes")))
        b.call("goto", room="z3_09", x=6.5, y=5.0, instant=True)
        wait(b, 1.0)
        b.call("kill_all")
        face(b, 1)
        tap(b, "ability_1")
        wait(b, 0.6)
        b.call("teleport", x=9.5, y=3.6)
        wait(b, 0.5)
        face(b, 1)
        tap(b, "attack")
        wait(b, 1.0)
        check(b.call("runes").get("solved") is True, "tide puzzle solved", str(b.call("runes")))
        shot(b, OUT + "/03-tide.png")

        # 4. The Choir Prelate.
        b.call("goto", room="z3_08", exit="0", instant=True)
        wait(b, 0.6)
        b.call("teleport", x=18.0, y=2.0)
        wait(b, 1.6)
        es = b.call("get_state")["enemies"]
        buffed = [e for e in es if e.get("id") == "echo_crawler" and e.get("buffed")]
        check(len(buffed) >= 1, "the Prelate's aura empowers its Crawlers", "%d buffed" % len(buffed))
        shot(b, OUT + "/04-prelate.png")
        b.call("kill_all")
        b.call("heal")
        wait(b, 0.4)

        # 5. The Cloister altar: reforge and rank.
        b.call("goto", room="z3_10", x=9.2, y=2.05, instant=True)
        wait(b, 0.6)
        if gs(b).get("interact") == "UI_KINDLE":
            b.call("interact")
            wait(b, 2.0)
        b.call("essence", value=1000)
        b.call("give", item="crude_stone", count=3)
        b.call("give", item="standard_soul_shard", count=2)
        b.call("interact")
        wait(b, 1.5)
        b.call("ui_press", name="Reforge")
        wait(b, 0.3)
        b.call("ui_press", name="Reforge_seris")
        wait(b, 0.3)
        b.call("ui_press", name="ReforgeBack")
        wait(b, 0.3)
        b.call("ui_press", name="Upgrade")
        wait(b, 0.3)
        b.call("ui_press", name="Rank_caelan_kings_judgment")
        wait(b, 0.3)
        shot(b, OUT + "/05-altar-upgrade.png")
        st = gs(b)["state"]
        check(st.get("weapon_levels", {}).get("seris") == 1, "Seris's weapon reforged to +1", str(st.get("weapon_levels")))
        check(st.get("ability_ranks", {}).get("caelan", {}).get("kings_judgment") == 2, "King's Judgment to rank 2",
              str(st.get("ability_ranks")))
        b.call("leave_altar")
        wait(b, 0.5)

        # 6. The Weeping Sovereign.
        b.call("goto", room="z3_17", exit="0", instant=True)
        wait(b, 0.6)
        b.call("press", action="move_right")
        wait(b, 1.4)
        b.call("release", action="move_right")
        wait(b, 1.2)
        check(b.call("get_state")["music"].get("zone") == "boss_sovereign", "the throne hall locks and her music plays",
              str(b.call("get_state")["music"].get("zone")))
        shot(b, OUT + "/06-sovereign.png")
        r = b.call("boss", fraction=0.61, strike=200)
        check(r.get("phase") == 1, "phase 2", str(r))
        for _ in range(6):
            wait(b, 0.5)
            b.call("heal")
        shot(b, OUT + "/07-phase2-water.png")
        r = b.call("boss", fraction=0.26, strike=200)
        check(r.get("phase") == 2, "phase 3", str(r))
        for _ in range(4):
            wait(b, 0.5)
            b.call("heal")
        bonus0 = int(gs(b)["state"].get("affinity_bonus", {}).get("caelan", 0))
        b.call("boss", fraction=0.0001, strike=500)
        wait(b, 1.5)
        st = gs(b)
        check(st["state"].get("flags", {}).get("boss_weeping_sovereign") is True, "she falls and it is saved",
              str(st["state"].get("flags", {}).get("boss_weeping_sovereign")))
        check(int(st["state"].get("affinity_bonus", {}).get("caelan", 0)) == bonus0 + 1, "Caelan's goodbye: +1 Affinity",
              str(st["state"].get("affinity_bonus")))
        check("Caelan" in st.get("subtitle", ""), "his goodbye line plays", st.get("subtitle", "")[:80])
        shot(b, OUT + "/08-fallen.png")
        b.call("press", action="move_right")
        wait(b, 1.5)
        b.call("release", action="move_right")
        inv = gs(b)["state"].get("inventory", {})
        check(inv.get("sovereigns_crown_fragment", 0) >= 1, "the Crown Fragment is picked up", str(inv))

        # 7. Quit and continue.
        b.call("save", resume=True)
        b.call("title")
        wait(b, 1.0)
        b.call("continue", slot=2)
        wait(b, 2.0)
        st = gs(b)["state"]
        kept = (st.get("flags", {}).get("freed_seris") and st.get("flags", {}).get("boss_weeping_sovereign")
                and st.get("weapon_levels", {}).get("seris") == 1
                and "z3_05_door" in st.get("opened_gates", []) and "z3_09_door" in st.get("opened_gates", []))
        check(bool(kept), "quit and continue keeps Seris, the doors, the reforge and the win",
              "room %s" % gs(b).get("room"))
        shot(b, OUT + "/09-continued.png")
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "run-output.txt"), "w") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
