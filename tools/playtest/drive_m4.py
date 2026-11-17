"""Story 052: the M4 playtest. One run from the Breach after the Sovereign through Zone 4 to the
end of Chapter I, over the bridge.

Covers, in order:
- the Breach open after the Sovereign; down into the Sealed Rift with Track 09;
- Darius dug out of the rubble with real attacks, freed, and his Crushing Blow breaking masonry;
- a dark room with its lamps, and a sliding floor;
- the Guardian Below on the real lift: arena lock, Track 10, its three phases (the bridge sets its
  health), boulders on the tilted lift, its fall unlocking the Greatsword;
- the Starless Shore with Track 12; the Leviathan on the real shore: three phases, the dark phase,
  its fall unlocking Overdrive and opening the rift; the Primeval Truth in the lore;
- Overdrive: Darius's Ultimate, the free swap, the second Ultimate;
- the rift into Ilyr's awakening, the four echoes, the chapter-end screen;
- the title then offers Abyssal.

The run uses its own save folder, so it never touches a player's saves.

    bash tools/python.sh tools/playtest/drive_m4.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-052-m4"


def tap(b, action):
    b.call("sim_input", action=action, seconds=0)


def face(b, d):
    b.call("sim_input", action="move_right" if d > 0 else "move_left", seconds=0.05)
    wait(b, 0.15)


def music(b):
    return str(b.call("get_state")["music"].get("zone"))


def walk_in(b):
    b.call("press", action="move_right")
    wait(b, 1.4)
    b.call("release", action="move_right")
    wait(b, 1.2)


def main():
    os.makedirs(OUT, exist_ok=True)
    log, fails = [], 0

    def check(ok, what, detail=""):
        nonlocal fails
        fails += 0 if ok else 1
        line = "%s  %-52s %s" % ("PASS" if ok else "FAIL", what, detail)
        log.append(line)
        print(line, flush=True)

    args = ["--save-dir", "user://playtest_m4", "--room", "z3_18", "--loadout", "caelan,nyra,seris"]
    with launch(args, log_name="drive_m4") as (b, _proc):
        wait(b, 1.2)
        b.call("debug_overlay", on=False)
        b.call("flag", key="boss_weeping_sovereign")
        b.call("goto", room="z3_18", x=8.0, y=2.05, instant=True)
        wait(b, 0.8)
        b.call("press", action="move_right")
        for _ in range(25):
            wait(b, 0.3)
            if b.call("game_state").get("room") == "z4_01":
                break
        b.call("release", action="move_right")
        wait(b, 1.2)
        check(b.call("game_state").get("room") == "z4_01" and music(b) == "zone4",
              "the Breach leads into the Rift, Track 09", music(b))
        shot(b, OUT + "/01-sealed-rift.png")

        # Darius.
        b.call("goto", room="z4_03", x=11.8, y=2.05, instant=True)
        wait(b, 1.0)
        face(b, 1)
        for _ in range(6):
            tap(b, "attack")
            wait(b, 0.55)
        b.call("interact")
        wait(b, 0.8)
        st = b.call("game_state")["state"]
        check("darius" in st.get("loadout", []), "Darius is freed and joins", str(st.get("loadout")))
        b.call("set_vessel", id="darius")
        wait(b, 1.0)
        b.call("teleport", x=23.4, y=2.05)
        face(b, 1)
        tap(b, "ability_1")
        wait(b, 1.2)
        st = b.call("game_state")["state"]
        check("z4_03:masonry:0" in st.get("opened_gates", []), "Crushing Blow breaks the masonry")
        shot(b, OUT + "/02-darius-masonry.png")

        # Dark and slide.
        b.call("goto", room="z4_06", exit="0", instant=True)
        wait(b, 1.0)
        shot(b, OUT + "/03-lightless-gallery.png")
        b.call("kill_all")
        b.call("goto", room="z4_08", x=6.0, y=2.05, instant=True)
        wait(b, 0.3)
        b.call("kill_all")
        x0 = float(b.call("get_state")["player"]["x"])
        wait(b, 1.4)
        x1 = float(b.call("get_state")["player"]["x"])
        check(x1 > x0 + 1.0, "the Basalt Chute slides you down", "%.1f -> %.1f" % (x0, x1))

        # The Guardian.
        b.call("goto", room="z4_10", exit="0", instant=True)
        wait(b, 0.6)
        walk_in(b)
        check(music(b) == "boss_guardian", "the lift locks and Track 10 plays", music(b))
        r = b.call("boss")
        check(r.get("phase") == 0, "the Guardian, phase 1", str(r))
        shot(b, OUT + "/04-guardian-p1.png")
        r = b.call("boss", fraction=0.64, strike=100)
        check(r.get("phase") == 1, "phase 2: the lift tilts", str(r))
        for i in range(50):
            wait(b, 0.2)
            b.call("heal")
        r = b.call("boss")
        check(int(r.get("rocks", 0)) >= 1, "boulders roll down the lift", str(r.get("rocks")))
        shot(b, OUT + "/05-guardian-p2.png")
        r = b.call("boss", fraction=0.29, strike=100)
        check(r.get("phase") == 2, "phase 3: the core opens", str(r))
        wait(b, 2.0)
        b.call("heal")
        shot(b, OUT + "/06-guardian-p3.png")
        b.call("boss", fraction=0.0001, strike=500)
        wait(b, 1.5)
        st = b.call("game_state")["state"]
        check(st.get("flags", {}).get("unlock_greatsword") is True, "the Guardian falls; the Greatsword unlocks")

        # The shore and the Leviathan.
        b.call("goto", room="z4_11", exit="0", instant=True)
        wait(b, 1.0)
        check(music(b) == "zone4_shore", "the Starless Shore, Track 12", music(b))
        b.call("kill_all")
        b.call("goto", room="z4_13", exit="0", instant=True)
        wait(b, 0.6)
        walk_in(b)
        check(music(b) == "boss_leviathan", "the shore locks and Track 13 plays", music(b))
        r = b.call("boss")
        check(r.get("phase") == 0, "the Leviathan, phase 1", str(r))
        shot(b, OUT + "/07-leviathan-p1.png")
        r = b.call("boss", fraction=0.64, strike=100)
        check(r.get("phase") == 1, "phase 2: the dark", str(r))
        wait(b, 2.5)
        b.call("heal")
        shot(b, OUT + "/08-leviathan-p2-dark.png")
        r = b.call("boss", fraction=0.29, strike=100)
        check(r.get("phase") == 2, "phase 3", str(r))
        wait(b, 1.5)
        b.call("heal")
        b.call("boss", fraction=0.0001, strike=500)
        wait(b, 2.0)
        st = b.call("game_state")["state"]
        flags = st.get("flags", {})
        check(flags.get("unlock_overdrive") is True and flags.get("rift_open") is True,
              "it falls: Overdrive unlocks, the rift opens")
        drops_ok = "truth_01" in st.get("lore_found", [])
        check(drops_ok, "the Primeval Truth is found", str(st.get("lore_found", [])[-3:]))
        shot(b, OUT + "/09-leviathan-fallen.png")

        # Overdrive.
        b.call("kill_all")
        b.call("overdrive", on=True)
        for v in ("darius", "caelan"):
            b.call("set_affinity", id=v, level=3)
        b.call("set_vessel", id="darius")
        wait(b, 0.5)
        b.call("gauge", value=300)
        for x in (24.0, 26.0):
            b.call("spawn", enemy_id="calcified_husk", x=x)
        b.call("teleport", x=21.0, y=2.05)
        wait(b, 0.4)
        tap(b, "ultimate")
        seen = []
        for i in range(70):
            wait(b, 0.1)
            v = b.call("get_state")["player"].get("vessel")
            if v not in seen:
                seen.append(v)
            if i == 8:
                shot(b, OUT + "/10-overdrive.png")
        check(len(seen) >= 2 and seen[0] == "darius", "Overdrive: two Ultimates with a free swap", str(seen))
        b.call("kill_all")

        # The rift and the awakening.
        b.call("goto", room="z4_13", x=18.5, y=2.05, instant=True)
        wait(b, 0.8)
        b.call("kill_all")
        gs = b.call("game_state")
        check(gs.get("interact") == "UI_ENTER", "the rift offers Enter", gs.get("interact"))
        b.call("interact")
        wait(b, 2.5)
        p = b.call("get_state")["player"]
        check(b.call("game_state").get("room") == "z4_14" and p.get("vessel") == "ilyr",
              "beyond the rift the Intruder is Ilyr", str(p.get("vessel")))
        shot(b, OUT + "/11-ilyr-wakes.png")
        seen = []
        for n in range(4):
            es = []
            for i in range(30):
                es = [e for e in b.call("get_state")["enemies"] if str(e.get("id", "")).startswith("echo_")]
                if es:
                    break
                wait(b, 0.2)
            if not es:
                break
            seen.append(es[0]["id"])
            b.call("teleport", x=float(es[0]["x"]) - 2.2, y=2.05)
            face(b, 1)
            for a in ("attack", "attack", "ability_1"):
                tap(b, a)
                wait(b, 0.35)
                b.call("heal")
            if n == 1:
                shot(b, OUT + "/12-echo.png")
            b.call("kill_all")
            wait(b, 0.6)
        check(seen == ["echo_caelan", "echo_nyra", "echo_seris", "echo_darius"], "the four echoes", str(seen))
        wait(b, 7.0)
        btns = b.call("ui_buttons").get("buttons", [])
        check("ToTitle" in btns, "the chapter-end screen", str(btns))
        shot(b, OUT + "/13-chapter-end.png")
        b.call("title")
        wait(b, 1.0)
        b.call("ui_press", name="Slot1")
        wait(b, 0.6)
        btns = b.call("ui_buttons").get("buttons", [])
        check("Difficulty_abyssal" in btns, "the title offers Abyssal", str(btns))
        shot(b, OUT + "/14-abyssal.png")
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "run-output.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
