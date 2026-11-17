"""Story 047: Ilyr's awakening in the running game (a stand-in room entered by the bridge; Zone 4's
rift leads to the real one in story 049). The player becomes Ilyr; each erased echo is shown, fought
briefly with Ilyr's blade and abilities, then dispatched by the bridge; Ilyr's line, the fade and
the chapter-end screen follow; the title then offers Abyssal.

    bash tools/python.sh tools/playtest/awakening_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-047-awakening"


def tap(b, a):
    b.call("sim_input", action=a, seconds=0)


def main():
    os.makedirs(OUT, exist_ok=True)
    log, fails = [], 0

    def check(ok, what, detail=""):
        nonlocal fails
        fails += 0 if ok else 1
        line = "%s  %-46s %s" % ("PASS" if ok else "FAIL", what, detail)
        log.append(line)
        print(line, flush=True)

    args = ["--save-dir", "user://playtest_awakening", "--room", "z1_03", "--loadout", "caelan,darius"]
    with launch(args, log_name="awakening_check") as (b, _proc):
        wait(b, 1.0)
        b.call("debug_overlay", on=False)
        b.call("awakening")
        wait(b, 2.5)
        p = b.call("get_state")["player"]
        check(p.get("vessel") == "ilyr", "the Intruder is Ilyr", str(p.get("vessel")))
        shot(b, OUT + "/01-ilyr-wakes.png")
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
            b.call("sim_input", action="move_right", seconds=0.05)
            for a in ("attack", "attack", "ability_1", "attack", "ability_2"):
                tap(b, a)
                wait(b, 0.35)
                b.call("heal")
            shot(b, OUT + "/%02d-%s.png" % (n + 2, es[0]["id"]))
            b.call("kill_all")
            wait(b, 0.6)
        check(seen == ["echo_caelan", "echo_nyra", "echo_seris", "echo_darius"], "the four echoes come in order", str(seen))
        wait(b, 1.0)
        shot(b, OUT + "/06-ilyr-line.png")
        sub = b.call("game_state").get("subtitle", "")
        check("worn this face" in sub, "Ilyr speaks", sub)
        wait(b, 6.0)
        shot(b, OUT + "/07-chapter-end.png")
        btns = b.call("ui_buttons").get("buttons", [])
        check("ToTitle" in btns, "the chapter-end screen shows", str(btns))
        st = b.call("game_state")["state"]
        check(st.get("flags", {}).get("chapter1_complete") is True, "Chapter I is complete in the save")
        b.call("title")
        wait(b, 1.0)
        b.call("ui_press", name="Slot1")
        wait(b, 0.6)
        btns = b.call("ui_buttons").get("buttons", [])
        check("Difficulty_abyssal" in btns, "the title now offers Abyssal", str(btns))
        shot(b, OUT + "/08-abyssal-open.png")
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "run-output.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
