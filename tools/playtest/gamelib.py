"""Launch the game with the playtest bridge and talk to it (story 016/026).

    from gamelib import launch
    with launch(["--save-dir", "user://playtest_saves"]) as (b, proc):
        b.call("bridge_new_game"...)   # any bridge command: b.call("new_game", slot=0)

The game runs windowed at 1280x720 (rendering on, so screenshots work). Saves go to a separate
folder so a playtest never touches the player's slots.
"""
import contextlib
import os
import subprocess
import sys
import time

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "mcp"))
from bridge_client import Bridge, wait_ready  # noqa: E402

GODOT = os.path.join(ROOT, "engine", "godot", "Godot_v4.7.2-stable_win64_console.exe")


@contextlib.contextmanager
def launch(user_args=(), scene=None, port=9181, log_name="game"):
    env = dict(os.environ, BRIDGE_PORT=str(port))
    logs = os.path.join(ROOT, "builds", "logs")
    os.makedirs(logs, exist_ok=True)
    log = open(os.path.join(logs, "%s.log" % log_name), "w")
    cmd = [GODOT, "--path", ROOT, "--windowed", "--resolution", "1280x720"]
    if scene:
        cmd.append(scene)
    # Story 060: conversations play through on their own (nobody presses on in a playtest).
    cmd += ["--"] + list(user_args) + ["--auto-dialogue"]
    proc = subprocess.Popen(cmd, env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        ready, why = wait_ready(port, 90, alive=lambda: proc.poll() is None)
        if not ready:
            raise RuntimeError("game did not answer the bridge (%s), see builds/logs/%s.log" % (why, log_name))
        b = Bridge(port=port)
        yield b, proc
    finally:
        try:
            Bridge(port=port, timeout=5).call("quit")
        except Exception:
            pass
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            proc.kill()
        log.close()


def shot(b, path):
    """Screenshot to `path` (relative to the project root)."""
    return b.call("screenshot", path=path)


def wait(b, seconds):
    return b.call("wait", seconds=seconds)
