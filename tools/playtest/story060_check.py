"""Story 060 in the running game: a conversation that waits for presses (Nyra, freed), a line in
passing, the inventory as icon tiles, crouching and the slow walk, and the up-attack still swinging
when it is spammed. Screenshots go to production/qa/evidence/story-060-conversations/.

    bash tools/python.sh tools/playtest/story060_check.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gamelib import launch, shot, wait  # noqa: E402

OUT = "production/qa/evidence/story-060-conversations"
RESULTS = []


def check(ok, what, detail=""):
    RESULTS.append(ok)
    print("%s  %-56s %s" % ("PASS" if ok else "FAIL", what, detail), flush=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    args = ["--save-dir", "user://playtest_060", "--room", "z1_02", "--loadout", "caelan,nyra,darius"]
    with launch(args, log_name="story060_check") as (b, _proc):
        wait(b, 1.5)
        b.call("debug_overlay", on=False)

        # A conversation that waits for presses.
        r = b.call("conversation", id="nyra", wait=True)
        wait(b, 3.0)
        st = b.call("game_state")
        check(r.get("playing") and st.get("paused"), "a conversation pauses play", str(r.get("speaker")))
        shot(b, os.path.join(OUT, "1-conversation-nyra.png"))
        texts, speakers, memory_shot = [], [], False
        for _ in range(12):
            n = b.call("dialogue_next")
            if not n.get("open"):
                break
            texts.append(n.get("text", ""))
            speakers.append(n.get("speaker", ""))
            if n.get("speaker") == "SPEAKER_MEMORY" and not memory_shot:
                memory_shot = True
                wait(b, 4.0)
                shot(b, os.path.join(OUT, "2-memory-read.png"))
        check("SPEAKER_MEMORY" in speakers, "the conversation reads a memory", str(sorted(set(speakers))))
        wait(b, 0.5)
        check(not b.call("game_state").get("paused"), "play goes on when it ends")

        # A line in passing (the Sovereign's voice) does not stop play.
        b.call("conversation", id="sovereign")
        wait(b, 2.4)
        st = b.call("game_state")
        check(st.get("subtitle", "") != "" and not st.get("paused"), "a line in passing does not stop play",
              st.get("subtitle", "")[:40])
        shot(b, os.path.join(OUT, "3-line-in-passing.png"))
        wait(b, 8.0)

        # The inventory as icon tiles.
        for item, n in [("lesser_soul_shard", 4), ("greater_soul_shard", 1), ("crude_stone", 2),
                        ("heart_of_the_guardian", 1)]:
            b.call("give", item=item, count=n)
        wait(b, 0.5)
        b.call("pause")
        wait(b, 0.5)
        b.call("ui_press", name="Tab_inventory")
        wait(b, 0.5)
        names = b.call("ui_buttons").get("buttons", [])
        tiles = [x for x in names if x.startswith("Item_")]
        check(len(tiles) >= 4, "the inventory shows the items as tiles", str(tiles))
        shot(b, os.path.join(OUT, "4-inventory.png"))
        b.call("resume")
        wait(b, 0.5)

        # Crouching and the slow walk.
        b.call("press", action="move_down")
        wait(b, 0.4)
        st = b.call("get_state")["player"]
        check(st.get("state") == "crouch", "down crouches", str(st.get("state")))
        shot(b, os.path.join(OUT, "5-crouch.png"))
        b.call("release", action="move_down")
        b.call("press", action="walk")
        b.call("press", action="move_right")
        wait(b, 0.5)
        st = b.call("get_state")["player"]
        check(st.get("state") == "walk", "the walk key walks", str(st.get("state")))
        shot(b, os.path.join(OUT, "6-walk.png"))
        b.call("release", action="walk")
        wait(b, 0.5)
        shot(b, os.path.join(OUT, "7-run.png"))
        b.call("release", action="move_right")
        wait(b, 0.4)

        # The up-attack, spammed: every press swings.
        def slashes():
            c = b.call("get_state").get("sfx", {})
            return int(c.get("slash", 0)) + int(c.get("slash_heavy", 0))
        before = slashes()
        b.call("press", action="move_up")
        for _ in range(8):
            b.call("sim_input", action="attack", seconds=0.05)
            wait(b, 0.3)
        b.call("release", action="move_up")
        wait(b, 0.4)
        swings = slashes() - before
        check(swings >= 6, "the up-attack swings every time it is spammed", "%d swings for 8 presses" % swings)
    print("SUMMARY: %d passed, %d failed" % (RESULTS.count(True), RESULTS.count(False)))
    sys.exit(0 if all(RESULTS) else 1)


if __name__ == "__main__":
    main()
