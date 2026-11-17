"""Story 049: write data/world/zone4.json (The Sealed Rift and the Starless Shore) from short room
specs, the same way as tools/world/build_zone3.py (canvas with y up, row 0 = the bottom; grid
legend in src/world/room_data.gd). Rerun after editing:

    bash tools/python.sh tools/world/build_zone4.py

Part one, the Sealed Rift (z4_01-z4_10, theme "rift", Track 09): dark halls, sliding floors,
masonry only Darius breaks, Crawler swarms of 8, Wardens, Darius in room 3, the altar in room 4,
and the Guardian Below on the lift. Part two, the Starless Shore below the lift (z4_11-z4_14,
theme "shore", Track 12): the Abyssal Leviathan, and the rift its fall tears open into Ilyr's
awakening. A checkpoint stands before each boss (death returns there, not to the altar).
"""
import json
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "data", "world", "zone4.json")

DARIUS = "#ffb070"


class Room:
    def __init__(self, w, h, floor=2):
        self.w, self.h = w, h
        self.c = [["." for _ in range(w)] for _ in range(h)]
        for y in range(h):
            self.c[y][0] = "#"
            self.c[y][w - 1] = "#"
        for x in range(w):
            self.c[h - 1][x] = "#"
            for y in range(floor):
                self.c[y][x] = "#"

    def put(self, x, y, ch):
        self.c[y][x] = ch

    def fill(self, x0, x1, y0, y1, ch):
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                self.c[y][x] = ch

    def exit(self, side, digit, y0, height=3):
        x = 0 if side == "left" else self.w - 1
        for y in range(y0, y0 + height):
            self.c[y][x] = digit

    def grid(self):
        return ["".join(self.c[y]) for y in range(self.h - 1, -1, -1)]


def room(name, mapxy, w, h, build, exits, theme="rift", **extra):
    r = Room(w, h, extra.pop("floor", 2))
    build(r)
    d = {"name": name, "map": mapxy, "theme": theme, "exits": exits}
    d.update(extra)
    d["grid"] = r.grid()
    return d


def swarm(r, x0, y, n=8, step=2):
    """A Crawler swarm (addendum "Resolved contradictions": groups of 8)."""
    for i in range(n):
        r.put(x0 + i * step, y, "c")


rooms = {}

# ---- Part one: the Sealed Rift ---------------------------------------------------------------

# z4_01 The Breach Stair: down from the Palace through the broken masonry.
def b01(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.fill(10, 14, 5, 5, "=")
    r.put(12, 6, "*")
    r.put(4, 8, "T")
    r.put(24, 8, "Y")
rooms["z4_01"] = room("ROOM_Z4_01", [50, 1, 1, 1], 30, 12, b01,
    {"0": {"to": "z3_18", "exit": "1"}, "1": {"to": "z4_02", "exit": "0"}},
    pickups=["faded_parchment"],
    story=[{"kind": "line", "key": "VOICE_Z4_ENTER", "speaker": "SPEAKER_VOICE", "x": [3, 12]}])

# z4_02 The Ember Hall: the first dark room; a swarm of 8 Crawlers in the black.
def b02(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.fill(8, 12, 6, 6, "=")
    swarm(r, 16, 2)
    r.put(10, 8, "T")
    r.put(28, 8, "Y")
rooms["z4_02"] = room("ROOM_Z4_02", [51, 1, 1, 1], 36, 12, b02,
    {"0": {"to": "z4_01", "exit": "1"}, "1": {"to": "z4_03", "exit": "0"}},
    dark=True, lamps=[[20, 3]],
    story=[{"kind": "tutorial", "key": "TUT_DARK", "x": [2, 9]}])

# z4_03 The Fallen Camp: Darius, pinned under the basalt that fell on his last camp. The way on is
# cracked masonry, which only he breaks.
def b03(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.put(13, 2, "E")
    r.put(6, 2, "*")
    r.fill(25, 26, 2, 10, "K")
    r.put(4, 8, "T")
    r.put(20, 8, "T")
rooms["z4_03"] = room("ROOM_Z4_03", [52, 1, 1, 1], 30, 12, b03,
    {"0": {"to": "z4_02", "exit": "1"}, "1": {"to": "z4_04", "exit": "0"}},
    pickups=["echoing_relic"],
    events=[{"vessel": "darius", "kind": "rubble"}],
    story=[{"kind": "line", "key": "DARIUS_FOUND", "speaker": "VESSEL_DARIUS", "x": [5, 11], "color": DARIUS},
           {"kind": "tutorial", "key": "TUT_RUBBLE", "x": [9, 18]},
           {"kind": "line", "key": "DARIUS_DOUBT", "speaker": "VESSEL_DARIUS", "on": "rubble_cut", "color": DARIUS},
           {"kind": "tutorial", "key": "TUT_FREE_RUBBLE", "on": "rubble_cut"},
           {"kind": "line", "key": "DARIUS_JOINS", "speaker": "VESSEL_DARIUS", "on": "freed", "color": DARIUS},
           {"kind": "tutorial", "key": "TUT_CRUSH", "on": "freed"}])

# z4_04 The Rift Altar: the zone's one altar, and a rift scar that will not open yet.
def b04(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.put(10, 2, "A")
    r.put(19, 2, "X")
    r.put(4, 8, "T")
    r.put(16, 8, "Y")
rooms["z4_04"] = room("ROOM_Z4_04", [53, 1, 1, 1], 26, 12, b04,
    {"0": {"to": "z4_03", "exit": "1"}, "1": {"to": "z4_05", "exit": "0"}},
    altar={"id": "altar_z4_a", "name": "ALTAR_Z4_A"},
    story=[{"kind": "line", "key": "DARIUS_ALTAR", "speaker": "VESSEL_DARIUS", "x": [6, 14], "needs": "vessel",
            "color": DARIUS}])

# z4_05 The Long Incline: polished basalt tilted downhill, with Wardens holding the slope.
def b05(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.fill(14, 18, 6, 6, "=")
    r.put(22, 2, "W")
    r.put(33, 2, "W")
    r.put(6, 8, "Y")
    r.put(30, 8, "T")
rooms["z4_05"] = room("ROOM_Z4_05", [54, 1, 1, 1], 40, 12, b05,
    {"0": {"to": "z4_04", "exit": "1"}, "1": {"to": "z4_06", "exit": "0"}},
    slides=[{"x": [4, 36], "y": [2, 4], "angle": 12}],
    story=[{"kind": "tutorial", "key": "TUT_SLIDE", "x": [2, 9]}])

# z4_06 The Lightless Gallery: dark, a swarm and a Warden; high on the right, masonry hides a cache.
def b06(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.exit("right", "2", 7)
    r.fill(23, 26, 4, 4, "=")
    r.fill(28, 36, 6, 6, "=")
    r.fill(34, 35, 7, 9, "K")
    swarm(r, 6, 2)
    r.put(26, 2, "W")
    r.put(12, 8, "T")
    r.put(30, 9, "Y")
rooms["z4_06"] = room("ROOM_Z4_06", [55, 1, 1, 1], 38, 12, b06,
    {"0": {"to": "z4_05", "exit": "1"}, "1": {"to": "z4_08", "exit": "0"}, "2": {"to": "z4_07", "exit": "0"}},
    dark=True)

# z4_07 The Expedition Cache: what Darius's people left behind, sealed in by a cave-in.
def b07(r):
    r.exit("left", "0", 7)
    r.fill(1, 6, 6, 6, "=")
    r.fill(1, 4, 2, 5, "#")
    r.put(10, 2, "*")
    r.put(14, 2, "*")
    r.put(18, 2, "*")
    r.put(12, 8, "T")
rooms["z4_07"] = room("ROOM_Z4_07", [55, 0, 1, 1], 22, 12, b07,
    {"0": {"to": "z4_06", "exit": "2"}},
    pickups=["faded_parchment", "echoing_relic", "polished_basalt_core"],
    story=[{"kind": "line", "key": "DARIUS_CACHE", "speaker": "VESSEL_DARIUS", "x": [8, 16], "needs": "vessel",
            "color": DARIUS}])

# z4_08 The Basalt Chute: a slide down into a wall of cracked masonry; Wardens on the slope.
def b08(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.fill(30, 31, 2, 10, "K")
    r.put(14, 2, "W")
    r.put(24, 2, "W")
    r.put(35, 2, "*")
    r.put(8, 8, "Y")
    r.put(34, 8, "T")
rooms["z4_08"] = room("ROOM_Z4_08", [56, 1, 1, 1], 40, 12, b08,
    {"0": {"to": "z4_06", "exit": "1"}, "1": {"to": "z4_09", "exit": "0"}},
    slides=[{"x": [3, 27], "y": [2, 4], "angle": 10}],
    pickups=["echoing_relic"])

# z4_09 The Elevator Landing: the checkpoint before the Guardian.
def b09(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.put(8, 2, "*")
    r.put(4, 8, "T")
    r.put(20, 8, "T")
rooms["z4_09"] = room("ROOM_Z4_09", [57, 1, 1, 1], 26, 12, b09,
    {"0": {"to": "z4_08", "exit": "1"}, "1": {"to": "z4_10", "exit": "0"}},
    checkpoint=True,
    pickups=["faded_parchment"],
    story=[{"kind": "line", "key": "DARIUS_LIFT", "speaker": "VESSEL_DARIUS", "x": [4, 14], "needs": "vessel",
            "color": DARIUS}])

# z4_10 The Guardian's Lift: the Guardian Below on the elevator that tilts in phase 2.
def b10(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.fill(2, 2, 2, 4, "L")
    r.fill(33, 33, 2, 4, "L")
    r.put(24, 2, "B")
    r.put(8, 9, "T")
    r.put(28, 9, "T")
rooms["z4_10"] = room("ROOM_Z4_10", [58, 1, 1, 1], 36, 12, b10,
    {"0": {"to": "z4_09", "exit": "1"}, "1": {"to": "z4_11", "exit": "0"}},
    boss="guardian_below",
    arena={"id": "z4_10_lift", "trigger_x": [6.0, 30.0]},
    slides=[{"x": [3, 33], "y": [2, 4], "angle": 0, "strip": False}],
    story=[{"kind": "line", "key": "VOICE_Z4_GUARDIAN", "speaker": "SPEAKER_VOICE", "on": "arena_start"}])

# ---- Part two: the Starless Shore, below the lift --------------------------------------------

# z4_11 The Starless Shore: black water under no sky; a swarm on the near bank, a Warden beyond.
def b11(r):
    r.fill(1, 38, 2, 3, "#")
    r.fill(20, 29, 1, 3, ".")
    r.exit("left", "0", 4)
    r.exit("right", "1", 4)
    swarm(r, 4, 4, 8, 2)
    r.put(33, 4, "W")
    r.put(36, 4, "*")
    r.put(10, 9, "Y")
    r.put(32, 9, "Y")
rooms["z4_11"] = room("ROOM_Z4_11", [58, 2, 1, 1], 40, 12, b11,
    {"0": {"to": "z4_10", "exit": "1"}, "1": {"to": "z4_12", "exit": "0"}},
    theme="shore", music="zone4_shore", dark=True,
    water=[{"id": "black_water", "x": [20, 30], "level": 3.6, "floor": 0.95}],
    pickups=["echoing_relic"],
    story=[{"kind": "line", "key": "DARIUS_SHORE", "speaker": "VESSEL_DARIUS", "x": [3, 10], "needs": "vessel",
            "color": DARIUS}])

# z4_12 The Drowned Expedition: Darius's people, what is left of them. The checkpoint before the
# Leviathan.
def b12(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.put(9, 2, "*")
    r.put(15, 2, "*")
    r.put(21, 2, "*")
    r.put(5, 8, "T")
    r.put(24, 8, "Y")
rooms["z4_12"] = room("ROOM_Z4_12", [59, 2, 1, 1], 30, 12, b12,
    {"0": {"to": "z4_11", "exit": "1"}, "1": {"to": "z4_13", "exit": "0"}},
    theme="shore", music="zone4_shore", checkpoint=True,
    pickups=["faded_parchment", "echoing_relic", "faded_parchment"],
    story=[{"kind": "line", "key": "DARIUS_EXPEDITION", "speaker": "VESSEL_DARIUS", "x": [8, 18], "needs": "vessel",
            "color": DARIUS}])

# z4_13 The Abyssal Shore: 40 m of shore and the sea it rises from. Its fall tears the rift.
def b13(r):
    r.exit("left", "0", 2)
    r.fill(2, 2, 2, 4, "L")
    r.put(28, 2, "B")
    r.put(8, 9, "Y")
    r.put(36, 9, "Y")
rooms["z4_13"] = room("ROOM_Z4_13", [60, 2, 1, 1], 46, 12, b13,
    {"0": {"to": "z4_12", "exit": "1"}},
    theme="shore", music="zone4_shore",
    boss="abyssal_leviathan",
    arena={"id": "z4_13_shore", "trigger_x": [6.0, 42.0]},
    water=[{"id": "sea", "x": [30, 45], "level": 2.4, "floor": 1.95}],
    rift={"pos": [20.0, 2.0], "flag": "rift_open", "to": "z4_14", "at": [5.0, 2.05]},
    story=[{"kind": "line", "key": "VOICE_Z4_LEVIATHAN", "speaker": "SPEAKER_VOICE", "on": "arena_start"}])

# z4_14 Beyond the Rift: Ilyr's awakening (story 047), the end of Chapter I.
def b14(r):
    r.put(6, 9, "Y")
    r.put(26, 9, "Y")
rooms["z4_14"] = room("ROOM_Z4_14", [61, 2, 1, 1], 34, 12, b14, {},
    music="finale_short",
    awakening={"echoes": ["echo_caelan", "echo_nyra", "echo_seris", "echo_darius"], "spawn_x": 22})

for k, v in rooms.items():
    if not v.get("pickups"):
        v.pop("pickups", None)

zone = {
    "_source": "Story 049. Zone 4 - The Sealed Rift and the Starless Shore (addendum zone table: 14 rooms, 1 altar plus boss checkpoints, Darius in room 3, darkness and sliding floors, the Guardian Below, the Abyssal Leviathan, Ilyr's awakening; Tracks 09, 10, 12, 13). Generated by tools/world/build_zone4.py: edit the specs there and rerun. Grid legend in src/world/room_data.gd.",
    "title": "ZONE_4_TITLE",
    "music": "zone4",
    "rooms": rooms,
}
with open(OUT, "w", newline="\n", encoding="utf-8") as f:
    json.dump(zone, f, indent=2)
    f.write("\n")
print("wrote %d rooms to %s" % (len(rooms), OUT))
