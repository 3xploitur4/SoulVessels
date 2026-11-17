"""Story 026: the debug APK on an Android emulator (or phone) boots to the title and loads a room.

Installs builds/android/soulvessels-debug.apk with adb, starts it, forwards the playtest bridge
port, checks the title screen, starts a new game and confirms room 1 is built, then a later
room with the rigged Warden, then (story 040) Zone 3's throne hall with the Weeping Sovereign.
--out <folder> writes the screenshots and log elsewhere (story 040 uses its own folder). Screenshots come from the device (adb screencap) into
production/qa/evidence/story-026-m2/. Needs a booted emulator or a phone with USB debugging.

    bash tools/python.sh tools/playtest/android_check.py
"""
import os
import subprocess
import sys
import time

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "mcp"))
from bridge_client import Bridge, wait_ready  # noqa: E402

SDK = os.environ.get("ANDROID_SDK_ROOT", os.path.expanduser(r"~\AppData\Local\Android\Sdk"))
ADB = os.path.join(SDK, "platform-tools", "adb.exe")
APK = os.path.join(ROOT, "builds", "android", "soulvessels-debug.apk")
PKG = "com.soulvessels.chapter1"
OUT = os.path.join(ROOT, "production", "qa", "evidence", "story-026-m2")
if "--out" in sys.argv:
    OUT = os.path.join(ROOT, sys.argv[sys.argv.index("--out") + 1])
HOST_PORT = 9190
DEVICE_PORT = 9177


def adb(*args, capture=False):
    r = subprocess.run([ADB, *args], capture_output=True)
    if capture:
        return r.stdout
    return r.stdout.decode(errors="replace") + r.stderr.decode(errors="replace")


def screencap(name):
    png = adb("exec-out", "screencap", "-p", capture=True)
    with open(os.path.join(OUT, name), "wb") as f:
        f.write(png)


def main():
    os.makedirs(OUT, exist_ok=True)
    log, fails = [], 0

    def check(ok, what, detail=""):
        nonlocal fails
        fails += 0 if ok else 1
        line = "%s  %-44s %s" % ("PASS" if ok else "FAIL", what, detail)
        log.append(line)
        print(line, flush=True)

    adb("start-server")
    subprocess.run([ADB, "wait-for-device"], timeout=120)
    devices = adb("devices")
    check("\tdevice" in devices, "a device is attached", devices.strip().splitlines()[-1] if devices.strip() else "")
    out = adb("install", "-r", APK)
    check("Success" in out, "the APK installs", out.strip().splitlines()[-1] if out.strip() else "")
    adb("shell", "am", "force-stop", PKG)
    adb("forward", "tcp:%d" % HOST_PORT, "tcp:%d" % DEVICE_PORT)
    adb("shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1")
    t0 = time.time()
    ready, why = wait_ready(HOST_PORT, 240)
    check(ready, "the game boots and the bridge answers", "%.0f s %s" % (time.time() - t0, why or ""))
    if ready:
        b = Bridge(port=HOST_PORT, timeout=60)
        time.sleep(4.0)
        buttons = b.call("ui_buttons").get("buttons", [])
        check("Slot0" in buttons, "the title screen shows its slots", str(buttons))
        screencap("android-01-title.png")
        st = b.call("new_game", slot=2)
        time.sleep(4.0)
        check(st.get("room") == "z1_01", "a new game loads room 1", str(st.get("room")))
        screencap("android-02-room1.png")
        st = b.call("goto", room="z1_12", exit="0", instant=True)
        time.sleep(4.0)
        check(st.get("room") == "z1_12", "the Warden's hall loads", str(st.get("room")))
        s = b.call("get_state")
        check(len(s.get("enemies", [])) == 1, "the Warden is there", str([e.get("name") for e in s.get("enemies", [])]))
        log.append("fps on device: %s" % s.get("fps"))
        screencap("android-03-warden-hall.png")
        # Story 040: the Sunken Palace and the Weeping Sovereign's throne hall.
        st = b.call("goto", room="z3_17", exit="0", instant=True)
        # The emulator draws in software (a few frames a second): give the room fade time to finish.
        time.sleep(12.0)
        check(st.get("room") == "z3_17", "the throne hall loads", str(st.get("room")))
        s = b.call("get_state")
        check(any(e.get("id") == "weeping_sovereign" for e in s.get("enemies", [])), "the Sovereign is there",
              str([e.get("id") for e in s.get("enemies", [])]))
        log.append("fps on device (throne hall): %s" % s.get("fps"))
        screencap("android-04-throne-hall.png")
        try:
            b.call("quit")
        except Exception:
            pass
    adb("forward", "--remove", "tcp:%d" % HOST_PORT)
    log.append("SUMMARY: %d failed" % fails)
    with open(os.path.join(OUT, "android-run-output.txt"), "w") as f:
        f.write("\n".join(log) + "\n")
    print("SUMMARY: %d failed" % fails)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
