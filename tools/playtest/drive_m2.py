"""Story 026: the M2 playtest. A new game from the title through both zones over the bridge.

Covers, in order: the title and a new slot; the wisp and the move tutorial; Caelan's possession;
an altar kindled and rested at (save); loot from a kill; a Soul Core purchase; the shield ward
opened by blocking; death, the Soul Echo and its recovery; Nyra freed from the roots; the veil
crossed with her Shadowstep; the Husk gauntlet; quit to title and Continue, with everything kept.
Every check prints PASS/FAIL with what was seen; screenshots and run-output.txt go to
production/qa/evidence/story-026-m2/. Exits non-zero when a check fails.

    bash tools/python.sh tools/playtest/drive_m2.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-026-m2"


def main():
    os.makedirs(OUT, exist_ok=True)
    log = []
    fails = 0

    def check(ok, what, detail=""):
        nonlocal fails
        fails += 0 if ok else 1
        line = "%s  %-48s %s" % ("PASS" if ok else "FAIL", what, detail)
        log.append(line)
        print(line, flush=True)
        return ok

    def state(b):
        return b.call("game_state")

    def save_state(b):
        return state(b).get("state", {})

    with launch(["--save-dir", "user://playtest_m2"], log_name="drive_m2") as (b, _proc):
        wait(b, 1.5)
        buttons = b.call("ui_buttons").get("buttons", [])
        check("Slot0" in buttons, "the title offers save slots", str(buttons))
        shot(b, OUT + "/01-title.png")
        st = b.call("new_game", slot=0)
        check(st.get("room") == "z1_01", "a new game starts in room 1", st.get("room"))
        wait(b, 1.0)
        check(state(b).get("tutorial", "") != "", "the move tutorial", state(b).get("tutorial"))
        # Possession.
        b.call("goto", room="z1_02", exit="0")
        wait(b, 0.6)
        b.call("teleport", x=16.5, y=5.1)
        wait(b, 0.4)
        b.call("interact")
        wait(b, 0.6)
        check(save_state(b).get("loadout") == ["caelan"], "the wisp possesses Caelan", str(save_state(b).get("loadout")))
        shot(b, OUT + "/02-caelan.png")
        # Altar: kindle and rest, which saves.
        b.call("goto", room="z1_04", x=11.5, y=2.0, instant=True)
        wait(b, 0.6)
        b.call("interact")
        wait(b, 0.6)
        buttons = b.call("ui_buttons").get("buttons", [])
        check("SoulCore" in buttons, "the altar menu opens", str(buttons))
        check(save_state(b).get("checkpoint", {}).get("room") == "z1_04", "resting sets the checkpoint",
              str(save_state(b).get("checkpoint")))
        shot(b, OUT + "/03-altar.png")
        # Soul Core purchase with a shard.
        b.call("give", item="lesser_soul_shard", count=1)
        b.call("ui_press", name="SoulCore")
        wait(b, 0.3)
        b.call("ui_press", name="Core_core_heart")
        wait(b, 0.4)
        check("core_heart" in save_state(b).get("soul_core", []), "a Soul Core node is bought",
              str(save_state(b).get("soul_core")))
        shot(b, OUT + "/04-soul-core.png")
        b.call("leave_altar")
        wait(b, 0.3)
        # Loot: a kill with drops forced on.
        b.call("drop_chance", tier="common", value=1.0)
        b.call("goto", room="z1_03", exit="0", instant=True)
        wait(b, 0.6)
        inv_before = dict(save_state(b).get("inventory", {}))
        essence_before = int(save_state(b).get("essence", 0))
        b.call("kill_all")
        b.call("spawn", enemy_id="echo_crawler", x=4.0)
        wait(b, 0.2)
        en = b.call("get_state").get("enemies", [])
        for e in en:
            b.call("teleport", x=float(e.get("x", 4.0)) - 1.2, y=2.0)
        for _ in range(10):
            b.call("sim_input", action="attack", seconds=0)
            wait(b, 0.4)
            if not b.call("get_state").get("enemies", []):
                break
        wait(b, 1.6)
        ss = save_state(b)
        check(int(ss.get("essence", 0)) > essence_before, "a kill gives Soul Essence",
              "%d -> %d" % (essence_before, int(ss.get("essence", 0))))
        check(ss.get("inventory", {}) != inv_before or len(ss.get("lore_found", [])) > 0, "the kill drops loot",
              str(ss.get("inventory")))
        shot(b, OUT + "/05-loot.png")
        # The shield ward: block facing the statue from the right spot.
        b.call("goto", room="z1_08", x=17.6, y=2.0, instant=True)
        wait(b, 0.4)
        b.call("press", action="move_right")
        wait(b, 0.05)
        b.call("release", action="move_right")
        b.call("press", action="ability_1")
        wait(b, 2.5)
        b.call("release", action="ability_1")
        check("z1_08:ward" in save_state(b).get("opened_gates", []), "Caelan's block opens the shield ward",
              str(save_state(b).get("opened_gates")))
        shot(b, OUT + "/06-ward-open.png")
        # Death and the Soul Echo.
        b.call("goto", room="z1_09", x=8.0, y=2.0, instant=True)
        wait(b, 0.5)
        essence = int(save_state(b).get("essence", 0))
        b.call("kill_player")
        wait(b, 4.0)
        ss = save_state(b)
        echo = ss.get("echo", {})
        check(bool(echo) and int(echo.get("essence", 0)) == essence, "death leaves a Soul Echo with the Essence",
              str(echo))
        check(state(b).get("room") == "z1_04", "the player returns to the altar", state(b).get("room"))
        shot(b, OUT + "/07-respawn.png")
        if echo:
            b.call("goto", room=str(echo.get("room", "z1_09")), x=float(echo.get("x", 8.0)) - 2.0, y=2.0, instant=True)
            wait(b, 0.5)
            b.call("teleport", x=float(echo.get("x", 8.0)), y=float(echo.get("y", 2.0)))
            wait(b, 1.0)
            ss = save_state(b)
            check(not ss.get("echo") and int(ss.get("essence", 0)) >= essence, "touching the echo returns the Essence",
                  "%s, essence %s" % (ss.get("echo"), ss.get("essence")))
            shot(b, OUT + "/08-echo-recovered.png")
        # Nyra.
        b.call("goto", room="z2_08", x=13.4, y=2.0, instant=True)
        wait(b, 0.6)
        for _ in range(6):
            b.call("sim_input", action="attack", seconds=0)
            wait(b, 0.55)
        b.call("interact")
        wait(b, 0.6)
        check("nyra" in save_state(b).get("loadout", []), "Nyra is freed and joins", str(save_state(b).get("loadout")))
        shot(b, OUT + "/09-nyra.png")
        b.call("sim_input", action="swap_next", seconds=0)
        wait(b, 0.8)
        b.call("goto", room="z2_11", x=11.5, y=2.0, instant=True)
        wait(b, 0.6)
        b.call("press", action="move_right")
        wait(b, 0.4)
        b.call("release", action="move_right")
        b.call("sim_input", action="ability_1", seconds=0)
        wait(b, 0.8)
        x = float(b.call("get_state").get("player", {}).get("x", 0.0))
        check(x > 15.0, "Nyra Shadowsteps through the veil", "x=%.1f" % x)
        # Gauntlet.
        b.call("goto", room="z2_13", exit="0", instant=True)
        wait(b, 0.5)
        b.call("teleport", x=10.0, y=2.0)
        wait(b, 0.5)
        for _ in range(3):
            b.call("kill_all")
            wait(b, 0.8)
        check("z2_13_gauntlet" in save_state(b).get("cleared_arenas", []), "the gauntlet is cleared",
              str(save_state(b).get("cleared_arenas")))
        shot(b, OUT + "/10-gauntlet.png")
        # Save, quit to title, continue.
        before = save_state(b)
        b.call("save", resume=True)
        b.call("title")
        wait(b, 1.0)
        st = b.call("continue", slot=0)
        wait(b, 1.0)
        after = save_state(b)
        for key in ("loadout", "soul_core", "opened_gates", "cleared_arenas", "unlocked_vessels"):
            check(sorted(map(str, after.get(key, []))) == sorted(map(str, before.get(key, []))),
                  "continue keeps %s" % key, str(after.get(key)))
        check(after.get("flags", {}).get("possessed_caelan") and after.get("flags", {}).get("freed_nyra"),
              "continue keeps the story flags")
        check(st.get("room") == "z2_13", "continue resumes where the player stood", st.get("room"))
        shot(b, OUT + "/11-continued.png")
    log.append("SUMMARY: %d failed" % fails)
    with open(OUT + "/run-output.txt", "w") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
