"""Story 038: write data/world/zone3.json (The Sunken Palace) from short room specs.

Each room is drawn on a canvas with y up (row 0 = the bottom), then written as the text grid the
game reads (top row first; legend in src/world/room_data.gd). Specs place solids, pits, platforms,
exits, enemies, pickups, rune doors, the altar and the event body by coordinates, so the rooms
stay easy to read and edit here. Rerun after editing:

    bash tools/python.sh tools/world/build_zone3.py
"""
import json
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "data", "world", "zone3.json")


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


def room(name, mapxy, w, h, build, exits, **extra):
    r = Room(w, h, extra.pop("floor", 2))
    build(r)
    d = {"name": name, "map": mapxy, "theme": "palace", "exits": exits}
    d.update(extra)
    d["grid"] = r.grid()
    return d


rooms = {}

# z3_01 The Flooded Stair: in from Zone 2; shallow water over the floor.
def b01(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.put(6, 8, "Y")
    r.put(22, 8, "T")
rooms["z3_01"] = room("ROOM_Z3_01", [33, 1, 1, 1], 30, 12, b01,
    {"0": {"to": "z2_16", "exit": "2"}, "1": {"to": "z3_02", "exit": "0"}},
    water=[{"id": "stair", "x": [1, 29], "level": 2.5, "floor": 1.95}],
    story=[{"kind": "line", "key": "SOV_Z3_ENTER", "speaker": "SPEAKER_VOICE", "x": [3, 14]},
           {"kind": "tutorial", "key": "TUT_SWIM", "x": [15, 28]}])

# z3_02 The Drowned Gallery: a deep pool with Courtiers; banks at floor 4.
def b02(r):
    r.fill(1, 34, 2, 3, "#")
    r.fill(10, 25, 1, 3, ".")
    r.exit("left", "0", 4)
    r.exit("right", "1", 4)
    r.put(14, 1, "d")
    r.put(21, 1, "d")
    r.put(8, 10, "Y")
    r.put(28, 10, "T")
rooms["z3_02"] = room("ROOM_Z3_02", [34, 1, 1, 1], 36, 14, b02,
    {"0": {"to": "z3_01", "exit": "1"}, "1": {"to": "z3_03", "exit": "0"}},
    water=[{"id": "gallery", "x": [10, 26], "level": 3.6, "floor": 0.95}],
    story=[{"kind": "line", "key": "SOV_Z3_COURT", "speaker": "SPEAKER_VOICE", "x": [6, 12]}])

# z3_03 The Antechamber: the first altar.
def b03(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.put(12, 2, "A")
    r.put(5, 8, "T")
    r.put(20, 8, "Y")
rooms["z3_03"] = room("ROOM_Z3_03", [35, 1, 1, 1], 26, 12, b03,
    {"0": {"to": "z3_02", "exit": "1"}, "1": {"to": "z3_04", "exit": "0"}},
    altar={"id": "altar_z3_a", "name": "ALTAR_Z3_A"})

# z3_04 The Crystal Sanctum: Seris sealed in crystal.
def b04(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.put(14, 2, "E")
    r.put(6, 8, "Y")
    r.put(22, 8, "Y")
rooms["z3_04"] = room("ROOM_Z3_04", [36, 1, 1, 1], 28, 12, b04,
    {"0": {"to": "z3_03", "exit": "1"}, "1": {"to": "z3_05", "exit": "0"}},
    events=[{"vessel": "seris", "kind": "crystal"}],
    story=[{"kind": "line", "key": "SOV_Z3_CRYSTAL", "speaker": "SPEAKER_VOICE", "x": [3, 10]},
           {"kind": "tutorial", "key": "TUT_CRYSTAL", "needs": "vessel", "x": [8, 20]},
           {"kind": "tutorial", "key": "TUT_FREE_CRYSTAL", "on": "crystal_cut"},
           {"kind": "line", "key": "SERIS_FREED", "speaker": "VESSEL_SERIS", "on": "freed", "color": "#9fd8ff"},
           {"kind": "tutorial", "key": "TUT_BOLT", "on": "freed"}])

# z3_05 The Hall of Murals: puzzle 1, a three-rune sequence in one row (mural order 2-1-3 by x).
def b05(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.fill(30, 31, 2, 4, "R")
    r.put(10, 9, "T")
rooms["z3_05"] = room("ROOM_Z3_05", [37, 1, 1, 1], 34, 12, b05,
    {"0": {"to": "z3_04", "exit": "1"}, "1": {"to": "z3_06", "exit": "0"}},
    runes={"id": "z3_05_door", "kind": "sequence", "runes": [[20.5, 2.95], [14.5, 2.95], [26.5, 2.95]],
           "mural": [6.0, 6.0]},
    story=[{"kind": "tutorial", "key": "TUT_RUNES", "x": [3, 12]}])

# z3_06 The Tide Pool: Courtiers and the Frost tutorial.
def b06(r):
    r.fill(1, 30, 2, 3, "#")
    r.fill(8, 22, 1, 3, ".")
    r.exit("left", "0", 4)
    r.exit("right", "1", 4)
    r.put(12, 1, "d")
    r.put(18, 1, "d")
    r.put(26, 10, "Y")
rooms["z3_06"] = room("ROOM_Z3_06", [38, 1, 1, 1], 32, 14, b06,
    {"0": {"to": "z3_05", "exit": "1"}, "1": {"to": "z3_07", "exit": "0"}},
    water=[{"id": "tide", "x": [8, 23], "level": 3.6, "floor": 0.95}],
    story=[{"kind": "tutorial", "key": "TUT_FROST_WATER", "x": [3, 9]}])

# z3_07 The Mirror Hall: puzzle 2, turn the mirror so the bolt rises into the high rune.
def b07(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.fill(28, 29, 2, 4, "R")
    r.fill(18, 26, 7, 7, "#")
    r.put(6, 8, "T")
rooms["z3_07"] = room("ROOM_Z3_07", [39, 1, 1, 1], 32, 12, b07,
    {"0": {"to": "z3_06", "exit": "1"}, "1": {"to": "z3_08", "exit": "0"}},
    runes={"id": "z3_07_door", "kind": "all", "runes": [[14.5, 8.5]]},
    mirrors=[{"pos": [14.5, 2.95], "angle": 0}],
    story=[{"kind": "tutorial", "key": "TUT_MIRROR", "x": [8, 16]}])

# z3_08 The Choir Nave: the first Choir Prelate, with Crawlers it empowers.
def b08(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.fill(14, 21, 6, 6, "=")
    for x in (10, 16, 22):
        r.put(x, 2, "c")
    r.put(28, 4, "p")
    r.put(8, 9, "T")
    r.put(28, 9, "Y")
rooms["z3_08"] = room("ROOM_Z3_08", [40, 1, 1, 1], 36, 12, b08,
    {"0": {"to": "z3_07", "exit": "1"}, "1": {"to": "z3_09", "exit": "0"}},
    pickups=[],
    story=[{"kind": "line", "key": "SOV_Z3_CHOIR", "speaker": "SPEAKER_VOICE", "x": [10, 20]},
           {"kind": "tutorial", "key": "TUT_PRELATE", "x": [14, 24]}])

# z3_09 The Tide Gate: puzzle 3, the rune is in line only from ice frozen on the pool.
def b09(r):
    r.fill(1, 32, 2, 4, "#")
    r.fill(8, 24, 1, 4, ".")
    r.exit("left", "0", 5)
    r.exit("right", "1", 5)
    r.fill(29, 30, 5, 7, "R")
    r.put(6, 10, "Y")
rooms["z3_09"] = room("ROOM_Z3_09", [41, 1, 1, 1], 34, 14, b09,
    {"0": {"to": "z3_08", "exit": "1"}, "1": {"to": "z3_10", "exit": "0"}},
    water=[{"id": "tidegate", "x": [8, 25], "level": 3.4, "floor": 0.95}],
    runes={"id": "z3_09_door", "kind": "all", "runes": [[22.5, 4.35]]},
    story=[{"kind": "tutorial", "key": "TUT_TIDE", "x": [3, 10]}])

# z3_10 The Cloister: the second altar; a ledge up to Seris's study.
def b10(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.exit("right", "2", 7)
    r.fill(18, 24, 6, 6, "=")
    r.fill(12, 15, 4, 4, "=")
    r.put(8, 2, "A")
    r.put(4, 9, "T")
rooms["z3_10"] = room("ROOM_Z3_10", [42, 1, 1, 1], 26, 12, b10,
    {"0": {"to": "z3_09", "exit": "1"}, "1": {"to": "z3_11", "exit": "0"}, "2": {"to": "z3_12", "exit": "0"}},
    altar={"id": "altar_z3_b", "name": "ALTAR_Z3_B"})

# z3_11 The Litany: puzzle 4, four runes at two heights; the high ones need a jump shot.
def b11(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.fill(32, 33, 2, 4, "R")
    r.put(18, 9, "T")
rooms["z3_11"] = room("ROOM_Z3_11", [43, 1, 1, 1], 36, 12, b11,
    {"0": {"to": "z3_10", "exit": "1"}, "1": {"to": "z3_13", "exit": "0"}},
    runes={"id": "z3_11_door", "kind": "sequence",
           "runes": [[22.5, 2.95], [10.5, 2.95], [16.5, 4.6], [28.5, 4.6]], "mural": [5.0, 6.5]})

# z3_12 Seris's Study: a side room with lore.
def b12(r):
    r.exit("left", "0", 7)
    r.fill(1, 6, 6, 6, "=")
    r.fill(1, 4, 2, 5, "#")
    r.put(12, 2, "*")
    r.put(18, 2, "*")
    r.fill(19, 19, 2, 4, "K")
    r.put(20, 2, "*")
    r.put(10, 8, "Y")
rooms["z3_12"] = room("ROOM_Z3_12", [42, 0, 1, 1], 22, 12, b12,
    {"0": {"to": "z3_10", "exit": "2"}},
    pickups=["echoing_relic", "faded_parchment", "polished_basalt_core"],
    story=[{"kind": "line", "key": "SERIS_STUDY", "speaker": "VESSEL_SERIS", "x": [8, 16], "needs": "vessel",
            "color": "#9fd8ff"}])

# z3_13 The Reflecting Pool: puzzle 5, two mirrors carry the bolt up and across to a high rune.
def b13(r):
    r.fill(1, 32, 2, 3, "#")
    r.fill(16, 24, 1, 3, ".")
    r.exit("left", "0", 4)
    r.exit("right", "1", 4)
    r.fill(30, 31, 4, 6, "R")
    r.fill(9, 14, 8, 8, "=")
    r.put(20, 1, "d")
    r.put(4, 11, "Y")
rooms["z3_13"] = room("ROOM_Z3_13", [44, 1, 1, 1], 34, 14, b13,
    {"0": {"to": "z3_11", "exit": "1"}, "1": {"to": "z3_14", "exit": "0"}},
    water=[{"id": "reflect", "x": [16, 25], "level": 3.6, "floor": 0.95}],
    runes={"id": "z3_13_door", "kind": "all", "runes": [[27.5, 10.6]]},
    mirrors=[{"pos": [12.5, 4.95], "angle": 45}, {"pos": [12.5, 10.6], "angle": 0}])

# z3_14 The Choir Loft: a Prelate behind a Branded Warden.
def b14(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.fill(22, 30, 6, 6, "=")
    r.put(16, 2, "W")
    r.put(26, 7, "p")
    r.put(10, 2, "c")
    r.put(6, 9, "T")
    r.put(30, 9, "Y")
rooms["z3_14"] = room("ROOM_Z3_14", [45, 1, 1, 1], 36, 12, b14,
    {"0": {"to": "z3_13", "exit": "1"}, "1": {"to": "z3_15", "exit": "0"}})

# z3_15 The Drowned Courtyard: a long pool, Courtiers, and steps across.
def b15(r):
    r.fill(1, 34, 2, 3, "#")
    r.fill(6, 30, 1, 3, ".")
    r.exit("left", "0", 4)
    r.exit("right", "1", 4)
    r.fill(12, 14, 5, 5, "=")
    r.fill(22, 24, 5, 5, "=")
    for x in (10, 18, 27):
        r.put(x, 1, "d")
    r.put(18, 11, "T")
rooms["z3_15"] = room("ROOM_Z3_15", [46, 1, 1, 1], 36, 14, b15,
    {"0": {"to": "z3_14", "exit": "1"}, "1": {"to": "z3_16", "exit": "0"}},
    water=[{"id": "courtyard", "x": [6, 31], "level": 3.6, "floor": 0.95}],
    pickups=[])

# z3_16 The Throne Door: puzzle 6, all three kinds at once (a row rune, a mirror, a tide rune).
def b16(r):
    r.fill(1, 34, 2, 4, "#")
    r.fill(18, 26, 1, 4, ".")
    r.exit("left", "0", 5)
    r.exit("right", "1", 5)
    r.fill(31, 32, 5, 7, "R")
    r.put(8, 11, "T")
rooms["z3_16"] = room("ROOM_Z3_16", [47, 1, 1, 1], 36, 14, b16,
    {"0": {"to": "z3_15", "exit": "1"}, "1": {"to": "z3_17", "exit": "0"}},
    water=[{"id": "throne_pool", "x": [18, 27], "level": 3.4, "floor": 0.95}],
    runes={"id": "z3_16_door", "kind": "sequence",
           "runes": [[12.5, 5.95], [10.5, 10.5], [25.5, 4.35]], "mural": [4.0, 9.0]},
    mirrors=[{"pos": [10.5, 5.95], "angle": 90}],
    story=[{"kind": "line", "key": "SOV_Z3_DOOR", "speaker": "SPEAKER_VOICE", "x": [3, 14]}])

# z3_17 The Throne Hall: the Weeping Sovereign.
def b17(r):
    r.exit("left", "0", 2)
    r.exit("right", "1", 2)
    r.fill(2, 2, 2, 4, "L")
    r.fill(31, 31, 2, 4, "L")
    r.put(24, 2, "B")
    r.put(8, 9, "Y")
    r.put(26, 9, "Y")
rooms["z3_17"] = room("ROOM_Z3_17", [48, 1, 1, 1], 34, 12, b17,
    {"0": {"to": "z3_16", "exit": "1"}, "1": {"to": "z3_18", "exit": "0"}},
    boss="weeping_sovereign",
    arena={"id": "z3_17_throne", "trigger_x": [6.0, 28.0]},
    water=[{"id": "arena", "x": [3, 31], "level": 2.3, "floor": 1.95}],
    story=[{"kind": "line", "key": "SOV_Z3_THRONE", "speaker": "SPEAKER_VOICE", "on": "arena_start"}])

# z3_18 The Breach: the way down to Zone 4, sealed by cracked masonry until Darius (M4).
def b18(r):
    r.exit("left", "0", 2)
    r.fill(20, 21, 2, 6, "K")
    r.put(12, 2, "*")
    r.put(6, 8, "T")
rooms["z3_18"] = room("ROOM_Z3_18", [49, 1, 1, 1], 26, 12, b18,
    {"0": {"to": "z3_17", "exit": "1"}},
    pickups=["faded_parchment"],
    story=[{"kind": "line", "key": "SERIS_BREACH", "speaker": "VESSEL_SERIS", "x": [8, 18], "color": "#9fd8ff"}])

for k, v in rooms.items():
    if not v.get("pickups"):
        v.pop("pickups", None)

zone = {
    "_source": "Story 038. Zone 3 - The Sunken Palace (addendum zone table: 18 rooms, 2 altars, Seris in room 4 frozen in crystal, water levels, 6 light-rune puzzles, the Weeping Sovereign, Track 05). Generated by tools/world/build_zone3.py: edit the specs there and rerun. Grid legend in src/world/room_data.gd.",
    "title": "ZONE_3_TITLE",
    "music": "zone3",
    "rooms": rooms,
}
with open(OUT, "w", newline="\n") as f:
    json.dump(zone, f, indent=2)
    f.write("\n")
print("wrote %d rooms to %s" % (len(rooms), OUT))
