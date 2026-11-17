"""Story 045: the Abyssal Leviathan in the running game (room z1_03 with a sea poured by the bridge;
the Starless Shore comes in story 049). Screens: phase 1 with its eyes, eyes destroyed and the
stagger, phase 2 in the dark with only its eyes and Darius's light, a blindside strike, phase 3,
the fall.

    bash tools/python.sh tools/playtest/leviathan_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-045-leviathan"


def main():
    os.makedirs(OUT, exist_ok=True)
    log, fails = [], 0

    def check(ok, what, detail=""):
        nonlocal fails
        fails += 0 if ok else 1
        line = "%s  %-46s %s" % ("PASS" if ok else "FAIL", what, detail)
        log.append(line)
        print(line, flush=True)

    args = ["--save-dir", "user://playtest_saves", "--room", "z1_03", "--loadout", "darius,caelan"]
    with launch(args, log_name="leviathan_check") as (b, _proc):
        wait(b, 1.0)
        b.call("goto", room="z1_03", x=6.0, y=2.0, instant=True)
        wait(b, 0.5)
        b.call("kill_all")
        b.call("debug_overlay", on=False)
        fy = float(b.call("get_state")["player"]["y"])
        b.call("water", id="sea", x=[18, 43], floor=fy - 0.05, level=fy + 0.4)
        b.call("spawn", enemy_id="abyssal_leviathan", x=14.0)
        wait(b, 1.5)
        r = b.call("boss")
        check(r.get("phase") == 0, "the Leviathan rises, phase 1", str(r))
        shot(b, OUT + "/01-p1-eyes.png")
        # Jump attacks reach the eyes high on its head.
        lv = [e for e in b.call("get_state")["enemies"] if e.get("id") == "abyssal_leviathan"]
        lx = float(lv[0]["x"]) if lv else 14.0
        b.call("teleport", x=lx - 4.2, y=fy)
        b.call("sim_input", action="move_right", seconds=0.05)
        for i in range(16):
            b.call("sim_input", action="jump", seconds=0.25)
            b.call("sim_input", action="attack", seconds=0)
            wait(b, 0.5)
            b.call("heal")
            if b.call("boss").get("eyes", 12) < 12:
                break
        r = b.call("boss")
        check(int(r.get("eyes", 12)) < 12, "a jump attack bursts an eye", "%s eyes left" % r.get("eyes"))
        shot(b, OUT + "/02-eyes-struck.png")
        r = b.call("boss", fraction=0.64, strike=100)
        check(r.get("phase") == 1, "below 65 %: phase 2", str(r))
        seen_blind = False
        for i in range(100):
            wait(b, 0.2)
            b.call("heal")
            r = b.call("boss")
            if i == 8:
                lv = [e for e in b.call("get_state")["enemies"] if e.get("id") == "abyssal_leviathan"]
                if lv:
                    b.call("teleport", x=float(lv[0]["x"]) - 6.0, y=fy)
                    wait(b, 0.6)
                shot(b, OUT + "/03-p2-dark-eyes.png")
            if r.get("attack") == "blindside_bite" and r.get("state") == "telegraph":
                shot(b, OUT + "/04-p2-blindside.png")
                seen_blind = True
                break
        check(seen_blind, "in the dark it strikes from behind (cue shown)")
        r = b.call("boss", fraction=0.29, strike=100)
        check(r.get("phase") == 2, "below 30 %: phase 3, the dark lifts", str(r))
        for i in range(12):
            wait(b, 0.2)
            b.call("heal")
        shot(b, OUT + "/05-p3-rifts.png")
        b.call("boss", fraction=0.0001, strike=500)
        wait(b, 1.2)
        st = b.call("game_state")["state"]
        flags = st.get("flags", {})
        check(flags.get("unlock_overdrive") is True and flags.get("rift_open") is True,
              "it falls: Overdrive unlocked, the rift opens", str({k: flags.get(k) for k in ("unlock_overdrive", "rift_open")}))
        shot(b, OUT + "/06-fallen.png")
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "run-output.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
