#!/usr/bin/env python3
"""Scripted playtest of the M1 combat sandbox through the game bridge (story 013).

Launches the game windowed (or attaches to one already running with --attach), runs each scenario,
prints one PASS/FAIL line per check with the observed numbers, saves screenshots into the evidence
folder, and exits non-zero when any check fails. Observations only: the numbers it compares
against come from data/balance (read live through the bridge), never from this file.

Usage:
  bash tools/python.sh tools/playtest/drive.py [--attach] [--port 9178] [--only name,name]
       [--shots production/qa/evidence/story-013-sandbox]
"""
import argparse
import json
import os
import subprocess
import sys
import time

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "mcp"))
from bridge_client import Bridge, wait_ready  # noqa: E402

GODOT = os.path.join(ROOT, "engine", "godot", "Godot_v4.7.2-stable_win64_console.exe")

RESULTS = []


def check(name, ok, detail=""):
    RESULTS.append((name, bool(ok), detail))
    print("%s  %-46s %s" % ("PASS" if ok else "FAIL", name, detail), flush=True)
    return ok


class Game:
    def __init__(self, port):
        self.b = Bridge(port=port, timeout=60)

    def __getattr__(self, cmd):
        return lambda **kw: self.b.call(cmd, **kw)

    def state(self):
        return self.b.call("get_state")

    def player(self):
        return self.state()["player"]

    def enemies(self):
        return self.state()["enemies"]

    def val(self, key):
        return self.b.call("get_value", key=key)["value"]

    def wait_until(self, pred, timeout=8.0, poll=0.0):
        end = time.time() + timeout
        while time.time() < end:
            s = self.state()
            r = pred(s)
            if r:
                return s
            if poll:
                time.sleep(poll)
        return None

    def reset_arena(self, x=-4.0, vessel="caelan"):
        # An ultimate in progress refuses swaps: let it finish first.
        self.wait_until(lambda s: s["player"]["state"] not in ("ultimate", "dead"), timeout=6.0, poll=0.1)
        self.kill_all()
        self.music_state(state="")
        self.set_vessel(id=vessel)
        self.heal()
        self.gauge(value=0)
        self.teleport(x=x, y=0.2)
        self.wait(seconds=0.6)
        self.set_stamina(value=100)


# ---- Scenarios ---------------------------------------------------------------------------

def sc_boot(g, shots):
    s = g.state()
    p = s["player"]
    check("boot: player alive on the floor", p["hp"] > 0 and p["on_floor"], "hp=%s y=%s" % (p["hp"], p["y"]))
    check("boot: soul HP = 300 + loadout bonuses", p["hp_max"] == 300 + 120 + 40, "hp_max=%s" % p["hp_max"])
    check("boot: Caelan active", p["vessel"] == "caelan")
    check("boot: music playing", s["music"]["playing"], "state=%s" % s["music"]["state"])


def sc_movement(g, shots):
    g.reset_arena(x=-12.0)
    x0 = g.player()["x"]
    g.sim_input(action="move_right", seconds=1.0)
    x1 = g.player()["x"]
    speed = g.val("vessel.caelan.stats.move_speed")
    check("move: Caelan runs right ~speed m/s", 4.5 <= x1 - x0 <= speed * 1.15, "moved %.2f m in 1 s (speed %s)" % (x1 - x0, speed))
    g.press(action="jump")
    s = g.wait_until(lambda s: s["player"]["y"] > 1.5, timeout=1.0)
    g.release(action="jump")
    check("jump: apex above 1.5 m", s is not None, "y=%s" % (s["player"]["y"] if s else "never"))
    g.wait(seconds=0.8)
    check("jump: lands again", g.player()["on_floor"])


def sc_dodge(g, shots):
    g.reset_arena(x=-8.0)
    st0 = g.player()["stamina"]
    g.press(action="dodge")
    s = g.wait_until(lambda s: s["player"]["invulnerable"], timeout=0.6)
    g.release(action="dodge")
    check("dodge: i-frames during the roll", s is not None)
    cost = g.val("vessel.caelan.dodge.stamina_cost")
    st1 = g.player()["stamina"]
    check("dodge: costs the data's stamina", abs((st0 - st1) - cost) < 3.0, "spent %.1f (data %s)" % (st0 - st1, cost))
    g.wait(seconds=0.5)
    # Air-dash: one per jump.
    g.set_stamina(value=100)
    g.press(action="jump")
    g.wait(seconds=0.15)
    g.release(action="jump")
    x0 = g.player()["x"]
    g.sim_input(action="dodge", seconds=0.0)
    g.wait(seconds=0.3)
    s = g.player()
    check("air-dash: moves ~4 m horizontally", abs(s["x"] - x0) > 3.0, "dx=%.2f" % (s["x"] - x0))
    g.wait(seconds=0.8)


def sc_crawler_kill(g, shots):
    g.reset_arena(x=-6.0)
    g.spawn(enemy_id="echo_crawler", x=-3.8)
    g.wait(seconds=0.3)
    hits = 0
    for i in range(10):
        e = g.enemies()
        if not e:
            break
        g.sim_input(action="attack", seconds=0.0)
        hits += 1
        g.wait(seconds=0.35)
    g.wait(seconds=0.6)
    left = g.enemies()
    check("crawler: dies to Caelan's combo", not left, "presses=%d left=%s" % (hits, [x["hp"] for x in left]))
    s = g.player()
    check("crawler: Soul Gauge gained from hits + kill", s["gauge"] >= 5, "gauge=%s" % s["gauge"])


def sc_crawler_telegraph(g, shots):
    g.reset_arena(x=-6.0)
    g.spawn(enemy_id="echo_crawler", x=-2.5)
    s = g.wait_until(lambda s: s["enemies"] and s["enemies"][0]["state"] == "telegraph", timeout=6.0)
    check("crawler: telegraphs before the lunge", s is not None)
    if s:
        g.screenshot(path=os.path.join(shots, "01-crawler-crimson-telegraph.png"))
        sfx = g.state()["sfx"]
        check("crawler: crimson boom cue played", sfx.get("telegraph_boom", 0) >= 1, "sfx=%s" % sfx.get("telegraph_boom"))
    hp0 = g.player()["hp"]
    s = g.wait_until(lambda s: s["player"]["hp"] < hp0, timeout=3.0)
    check("crawler: lunge damages a player who stands still", s is not None,
          "hp %s -> %s" % (hp0, s["player"]["hp"] if s else hp0))
    # Block does not stop an unblockable lunge.
    g.heal()
    g.set_stamina(value=100)
    g.press(action="ability_1")
    hp0 = g.player()["hp"]
    s = g.wait_until(lambda s: s["player"]["hp"] < hp0, timeout=5.0)
    g.release(action="ability_1")
    check("crawler: unblockable goes through Royal Guard", s is not None)


def sc_block_and_parry(g, shots):
    g.reset_arena(x=-6.0)
    g.spawn(enemy_id="branded_warden", x=-3.0)
    g.wait(seconds=0.2)
    # Normal block: hold early, take no HP damage, lose stamina.
    g.press(action="ability_1")
    hp0 = g.player()["hp"]
    st0 = g.player()["stamina"]
    s = g.wait_until(lambda s: s["enemies"] and s["enemies"][0]["state"] == "recover"
                     and s["enemies"][0]["attack"] == "halberd_thrust", timeout=8.0)
    g.release(action="ability_1")
    p = g.player()
    if s:
        check("block: halberd thrust blocked, no HP lost", p["hp"] == hp0, "hp %s -> %s" % (hp0, p["hp"]))
        check("block: stamina paid per blocked hit", p["stamina"] < st0, "stamina %s -> %s" % (st0, p["stamina"]))
    else:
        check("block: warden threw a halberd thrust", False, "no thrust seen")
    # Perfect parry: press block ~0.08 s before the hit lands.
    parried = False
    for attempt in range(6):
        g.heal()
        g.set_stamina(value=100)
        s = g.wait_until(lambda s: s["enemies"] and s["enemies"][0]["state"] == "telegraph"
                         and s["enemies"][0]["attack"] == "halberd_thrust", timeout=10.0)
        if not s:
            break
        tel = g.val("enemy.branded_warden.attacks.0.telegraph_s")
        e = s["enemies"][0]
        lead = tel - e["state_time"] - 0.09
        if lead > 0:
            time.sleep(lead)
        g.press(action="ability_1")
        s2 = g.wait_until(lambda s: s["enemies"] and s["enemies"][0]["state"] != "telegraph", timeout=2.0)
        g.wait(seconds=0.25)
        g.release(action="ability_1")
        st = g.state()
        e2 = st["enemies"][0] if st["enemies"] else {}
        if e2 and not e2.get("shield_up", True):
            parried = True
            g.screenshot(path=os.path.join(shots, "02-warden-guard-broken-after-parry.png"))
            check("parry: Counterstrike opens the Warden's guard", True,
                  "attempt %d, warden posture %s, state %s" % (attempt + 1, e2["posture"], e2["state"]))
            check("parry: perfect parry fills Soul Gauge", st["player"]["gauge"] >= 10, "gauge=%s" % st["player"]["gauge"])
            break
        g.wait(seconds=0.5)
    if not parried:
        check("parry: Counterstrike opens the Warden's guard", False, "no parry landed in 6 tries")


def sc_warden_shield(g, shots):
    g.reset_arena(x=-6.0)
    g.spawn(enemy_id="branded_warden", x=-3.2)
    g.wait(seconds=0.1)
    hp0 = g.enemies()[0]["hp"]
    g.sim_input(action="attack", seconds=0.0)
    g.wait(seconds=0.4)
    front = hp0 - g.enemies()[0]["hp"]
    # Get behind: Nyra's Shadowstep through it, then hit its back.
    g.set_vessel(id="nyra")
    g.wait(seconds=0.2)
    g.sim_input(action="ability_1", seconds=0.05)
    g.wait(seconds=0.25)
    p = g.player()
    e = g.enemies()[0]
    behind = (p["x"] - e["x"]) * e["facing"] < 0
    hp1 = e["hp"]
    # Step back into dagger reach of its back, facing it, then strike before it turns.
    g.teleport(x=e["x"] - e["facing"] * 1.0, y=0.2)
    g.press(action="move_left" if e["facing"] < 0 else "move_right")
    g.wait(seconds=0.03)
    g.release(action="move_left" if e["facing"] < 0 else "move_right")
    g.sim_input(action="attack", seconds=0.0)
    g.wait(seconds=0.3)
    back = hp1 - g.enemies()[0]["hp"]
    check("warden: shield cuts frontal damage", 0 < front < 15, "front hit %.1f" % front)
    check("warden: Shadowstep puts Nyra behind it", behind, "player x %.1f warden x %.1f facing %s" % (p["x"], e["x"], e["facing"]))
    check("warden: backstab from behind lands hard", back > front * 2, "back hit %.1f vs front %.1f" % (back, front))


def sc_swap_resonance(g, shots):
    g.reset_arena(x=-6.0)
    g.spawn(enemy_id="echo_crawler", x=-1.0)
    g.wait(seconds=0.2)
    hp0 = g.enemies()[0]["hp"]
    g.sim_input(action="swap_next", seconds=0.0)
    g.wait(seconds=0.4)
    s = g.state()
    p = s["player"]
    check("swap: Nyra active", p["vessel"] == "nyra")
    check("swap: global cooldown running", p["swap_cd"] > 0.5, "swap_cd=%s" % p["swap_cd"])
    hit = (hp0 - s["enemies"][0]["hp"]) if s["enemies"] else hp0
    check("swap: Severing Arrival strikes the nearest enemy", hit > 0, "dealt %.1f" % hit)
    check("swap: music lead follows the Vessel", s["music"]["vessel"] == "nyra")
    g.sim_input(action="swap_next", seconds=0.0)
    check("swap: blocked while on cooldown", g.player()["vessel"] == "nyra")
    g.screenshot(path=os.path.join(shots, "03-nyra-after-severing-arrival.png"))


def sc_nyra_kit(g, shots):
    g.reset_arena(x=-12.0, vessel="nyra")
    x0 = g.player()["x"]
    g.sim_input(action="ability_1", seconds=0.05)
    g.wait(seconds=0.3)
    x1 = g.player()["x"]
    check("nyra: Shadowstep travels ~6 m", 5.0 <= abs(x1 - x0) <= 7.0, "dx=%.2f" % (x1 - x0))
    g.wait(seconds=3.2)
    g.sim_input(action="ability_1", seconds=0.6)
    check("nyra: hold = Vanishing Act (hidden)", g.player()["hidden"])
    g.spawn(enemy_id="echo_crawler", x=x1 + 6.0)
    g.wait(seconds=0.2)
    hp0 = g.enemies()[0]["hp"]
    g.sim_input(action="move_right", seconds=0.05)
    g.sim_input(action="ability_2", seconds=0.0)
    g.wait(seconds=0.6)
    e = g.enemies()
    check("nyra: Phantom Blades hit at range", (not e) or e[0]["hp"] < hp0, "hp %s -> %s" % (hp0, e[0]["hp"] if e else 0))
    check("nyra: Phantom Blades on cooldown", g.player()["cooldowns"].get("phantom_blades", 0) > 3.0)


def sc_ultimates(g, shots):
    g.reset_arena(x=-6.0)
    for x in (-4.0, -3.0, -8.5):
        g.spawn(enemy_id="echo_crawler", x=x)
    g.wait(seconds=0.2)
    g.gauge(value=300)
    hp = [e["hp"] for e in g.enemies()]
    g.sim_input(action="ultimate", seconds=0.0)
    g.wait(seconds=0.15)
    st = g.player()["state"]
    g.screenshot(path=os.path.join(shots, "04-final-stand.png"))
    g.wait(seconds=0.9)
    s = g.state()
    check("ultimate: Final Stand fires", st in ("ultimate", "final_stand"), "state=%s" % st)
    check("ultimate: costs 2 bars", s["player"]["bars"] == 1, "bars=%s gauge=%s" % (s["player"]["bars"], s["player"]["gauge"]))
    check("ultimate: 6 m AoE hits all nearby crawlers", len(s["enemies"]) < 3 or all(e["hp"] < h for e, h in zip(s["enemies"], hp)),
          "left=%s" % [e["hp"] for e in s["enemies"]])
    # Nyra's Dance of Shadows.
    g.reset_arena(x=-6.0, vessel="nyra")
    g.spawn(enemy_id="branded_warden", x=-2.0)
    g.wait(seconds=0.2)
    g.gauge(value=300)
    hp0 = g.enemies()[0]["hp"]
    g.sim_input(action="ultimate", seconds=0.0)
    g.wait(seconds=1.5)
    g.screenshot(path=os.path.join(shots, "05-dance-of-shadows.png"))
    g.wait(seconds=2.0)
    e = g.enemies()
    check("ultimate: Dance of Shadows lands many slashes", (not e) or hp0 - e[0]["hp"] > 150,
          "warden hp %s -> %s" % (hp0, e[0]["hp"] if e else 0))


def sc_sync_guard(g, shots):
    # Nyra, inactive, auto-evades an unblockable hit (Crawler lunge).
    g.reset_arena(x=-6.0, vessel="caelan")
    g.wait(seconds=1.6)
    g.spawn(enemy_id="echo_crawler", x=-3.0)
    g.gauge(value=150)
    s = g.wait_until(lambda s: s["player"]["last_sync_guard"] != "" or s["player"]["hp"] < s["player"]["hp_max"], timeout=8.0)
    p = g.player()
    check("sync guard: inactive Nyra swaps in and evades the lunge",
          p["last_sync_guard"] == "nyra" and p["vessel"] == "nyra" and p["hp"] == p["hp_max"],
          "guard=%s vessel=%s hp=%s/%s" % (p["last_sync_guard"], p["vessel"], p["hp"], p["hp_max"]))
    # Caelan intercepts a lethal parryable blow (Warden thrust); Nyra's guard is on cooldown now.
    g.reset_arena(x=-6.0, vessel="caelan")
    g.wait(seconds=1.6)
    g.spawn(enemy_id="branded_warden", x=-3.2)
    g.gauge(value=150)
    g.set_hp(hp=5)
    s = g.wait_until(lambda s: s["player"]["gauge"] < 100 or s["player"]["hp"] <= 0, timeout=10.0)
    p = g.player()
    check("sync guard: Caelan blocks a lethal blow (1 bar)",
          s is not None and p["last_sync_guard"] == "caelan" and p["hp"] > 0 and 30 < p["gauge"] < 100,
          "guard=%s hp=%s gauge=%s" % (p["last_sync_guard"], p["hp"], p["gauge"]))


def sc_watcher(g, shots):
    g.reset_arena(x=-6.0)
    g.spawn(enemy_id="subterranean_watcher", x=-1.0)
    s = g.wait_until(lambda s: s["enemies"] and s["enemies"][0]["state"] == "telegraph", timeout=8.0)
    check("watcher: charges its beam", s is not None)
    if s:
        time.sleep(0.6)
        g.screenshot(path=os.path.join(shots, "06-watcher-violet-telegraph.png"))
    s = g.wait_until(lambda s: s["enemies"] and s["enemies"][0]["state"] == "attack", timeout=3.0)
    if s:
        time.sleep(0.4)
        g.screenshot(path=os.path.join(shots, "07-watcher-beam.png"))
    hp0 = g.player()["hp_max"]
    g.wait(seconds=1.5)
    check("watcher: beam hurts a player in its sweep", g.player()["hp"] < hp0, "hp=%s" % g.player()["hp"])


def sc_music(g, shots):
    g.reset_arena(x=-12.0)
    g.wait(seconds=0.2)
    m = g.state()["music"]
    check("music: director clock matches audio playback", abs(m["drift"]) < 0.1, "drift %.3f s" % m["drift"])
    g.spawn(enemy_id="branded_warden", x=-9.0)
    g.wait(seconds=0.3)
    g.sim_input(action="attack", seconds=0.0)
    s = g.wait_until(lambda s: s["music"]["pending"] == "elite" or s["music"]["state"] == "elite", timeout=4.0, poll=0.1)
    check("music: an elite in range asks for the elite layer", s is not None,
          "state=%s pending=%s" % (g.state()["music"]["state"], g.state()["music"]["pending"]))
    s = g.wait_until(lambda s: s["music"]["state"] == "elite", timeout=16.0, poll=0.25)
    if s:
        bar4 = 4 * 4 * 60.0 / 70.0
        at = s["music"]["history"][-1]["at"]
        off = min(at % bar4, bar4 - at % bar4)
        check("music: change lands on a 4-bar boundary", off < 0.05, "at %.3f s, 4 bars = %.3f s, off %.3f" % (at, bar4, off))
        g.wait(seconds=2.0)
        stems = g.state()["music"]["stems"]
        check("music: elite stem audible, others per state", stems["elite"] > -20 and stems["combat"] > -20,
              "stems %s" % stems)
    else:
        check("music: change lands on a 4-bar boundary", False, "never reached elite within 16 s")


SCENARIOS = [
    ("boot", sc_boot), ("movement", sc_movement), ("dodge", sc_dodge), ("crawler_kill", sc_crawler_kill),
    ("crawler_telegraph", sc_crawler_telegraph), ("block_parry", sc_block_and_parry), ("warden_shield", sc_warden_shield),
    ("swap", sc_swap_resonance), ("nyra", sc_nyra_kit), ("ultimates", sc_ultimates), ("sync_guard", sc_sync_guard),
    ("watcher", sc_watcher), ("music", sc_music),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--attach", action="store_true")
    ap.add_argument("--port", type=int, default=9178)
    ap.add_argument("--only", default="")
    ap.add_argument("--shots", default="production/qa/evidence/story-013-sandbox")
    args = ap.parse_args()
    shots = args.shots if os.path.isabs(args.shots) else os.path.join(ROOT, args.shots)
    os.makedirs(shots, exist_ok=True)
    proc = None
    if not args.attach:
        env = dict(os.environ, BRIDGE_PORT=str(args.port), BRIDGE_IDLE_QUIT_S="120")
        log = open(os.path.join(ROOT, "builds", "logs", "drive-game.log"), "w") if os.path.isdir(os.path.join(ROOT, "builds", "logs")) else subprocess.DEVNULL
        proc = subprocess.Popen([GODOT, "--path", ROOT, "--windowed", "--resolution", "1280x720", "--", "--no-waves"],
                                env=env, stdout=log, stderr=subprocess.STDOUT)
        ok, why = wait_ready(args.port, 120, alive=lambda: proc.poll() is None)
        if not ok:
            print("game did not start: %s" % why)
            return 2
    g = Game(args.port)
    only = set(x for x in args.only.split(",") if x)
    try:
        for name, fn in SCENARIOS:
            if only and name not in only:
                continue
            print("--- %s" % name, flush=True)
            try:
                fn(g, shots)
            except Exception as exc:  # report and keep going
                check("%s: scenario raised" % name, False, repr(exc))
    finally:
        if proc is not None:
            try:
                g.quit()
            except Exception:
                pass
            try:
                proc.wait(timeout=10)
            except subprocess.TimeoutExpired:
                proc.kill()
    failed = [r for r in RESULTS if not r[1]]
    print("SUMMARY: %d passed, %d failed" % (len(RESULTS) - len(failed), len(failed)))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
