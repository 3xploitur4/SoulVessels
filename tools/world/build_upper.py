"""Story 054: the upper levels that make Chapter I's rooms tall and layered (decision D-060).

Writes data/world/upper/<zone>.json. Each room keeps its base layout (data/world/<zone>.json) as
its ground floor; WorldData stacks the upper rows written here on top, replacing the old ceiling
row, so every base coordinate (y up from the floor) is unchanged. Base rows only gain one-way
stair platforms ("set").

Per room the generator:
  - climbs from the hall to the old ceiling with a zigzag of one-way ledges (2 m steps: a jump
    rises 2.2 m), through a one-way hole in the new upper floor;
  - builds an upper level in the zone's style: the cavern's aqueduct galleries, the forest's
    mushroom towers, the palace's balconies, the rift's broken ledges over spikes;
  - adds an alcove with a reward on a high shelf, one or two enemies, drop-holes back to the hall,
    and, between chosen pairs of rooms, an upper doorway that makes a second route;
  - keeps every opening on the entrance side of a gate (rune door, ward, veil, masonry), so the
    upper level never leads around one;
  - checks with a jump/fall walker that every new pickup and doorway can be reached, retrying
    other seeds until it can.

    bash tools/python.sh tools/world/build_upper.py
"""
import json
import os
import random

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ZONES = ["zone1", "zone2", "zone3", "zone4"]
JUMP = 2          # metres a jump rises (2.2 m, rounded down to whole cells)
REACH = 4         # cells a jump crosses while rising
LEAP = 5          # cells a jump crosses at the same height or falling
MUSH = 6          # cells a bounce mushroom lifts

SOLID = set("#GVRKFO")          # cells the player stands on and cannot pass
STAND_ON = SOLID | {"="}
# Rooms left as they are: doorways in the ceiling, arenas and bosses, the awakening.
SKIP = {"z1_06", "z1_14", "z2_03", "z2_05", "z2_12", "z1_12", "z2_13", "z3_17", "z4_10", "z4_13", "z4_14"}
# Upper doorways between rooms: a second route through the zone.
LINKS = [("z1_01", "z1_02"), ("z1_04", "z1_05"), ("z1_09", "z1_10"),
         ("z2_01", "z2_02"), ("z2_08", "z2_09"), ("z2_15", "z2_16"),
         ("z3_03", "z3_04"), ("z3_14", "z3_15"),
         ("z4_01", "z4_02"), ("z4_11", "z4_12")]
ZONE_STYLE = {
    "zone1": {"enemies": "wc", "loot": ["crude_stone", "lesser_soul_shard"], "spikes": 0.25, "mush": 0.0},
    "zone2": {"enemies": "htwc", "loot": ["luminous_root_resin", "lesser_soul_shard"], "spikes": 0.15, "mush": 0.6},
    "zone3": {"enemies": "pwc", "loot": ["tarnished_censer_shard", "standard_soul_shard"], "spikes": 0.25, "mush": 0.0},
    "zone4": {"enemies": "wwW", "loot": ["polished_basalt_core", "standard_soul_shard"], "spikes": 0.6, "mush": 0.0},
}
# Interior height (cells between the upper floor and the new ceiling) per zone; some rooms tower.
HEIGHTS = {"zone1": (7, 10), "zone2": (9, 14), "zone3": (8, 11), "zone4": (7, 11)}
TOWERS = {"z1_05", "z1_11", "z2_07", "z2_10", "z2_15", "z3_08", "z3_14", "z4_05", "z4_12"}


class Grid:
    """A room grid with y up from the floor."""

    def __init__(self, rows_top_first):
        self.h = len(rows_top_first)
        self.w = len(rows_top_first[0])
        self.c = [list(rows_top_first[self.h - 1 - y]) for y in range(self.h)]

    def get(self, x, y):
        if x < 0 or x >= self.w or y < 0 or y >= self.h:
            return "#"
        return self.c[y][x]

    def set(self, x, y, ch):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.c[y][x] = ch

    def rows_top_first(self, y0, y1):
        return ["".join(self.c[y]) for y in range(y1, y0 - 1, -1)]


def solid(ch):
    return ch in SOLID


def standable(g, x, y):
    """Feet at cell (x, y): the cell and the one above are open, the one below holds."""
    if y <= 0 or y + 1 >= g.h:
        return False
    a, b, below = g.get(x, y), g.get(x, y + 1), g.get(x, y - 1)
    if solid(a) or solid(b) or a == "^" or b == "^":
        return False
    return below in STAND_ON or below == "M"


def head_clear(g, x, y0, y1):
    for y in range(y0, y1 + 2):
        if solid(g.get(x, y)):
            return False
    return True


def reachable(g, starts):
    """Cells a player can stand on from `starts`: walk, jump up 2, leap across, fall, bounce."""
    seen = set()
    todo = [s for s in starts if standable(g, *s)]
    seen.update(todo)
    while todo:
        x, y = todo.pop()
        nxt = []
        lift = MUSH if g.get(x, y - 1) == "M" or g.get(x - 1, y - 1) == "M" or g.get(x + 1, y - 1) == "M" else JUMP
        for dx in range(-LEAP, LEAP + 1):
            for dy in range(-12, lift + 1):
                nx, ny = x + dx, y + dy
                if (nx, ny) in seen or not standable(g, nx, ny):
                    continue
                if dy > 0 and abs(dx) > REACH:
                    continue
                if dy > 0 and not head_clear(g, x, y, y + dy):
                    continue
                if dy < 0 and abs(dx) > LEAP + 2:
                    continue
                # Nothing solid on the straight line between (a coarse sweep).
                ok = True
                steps = max(abs(dx), abs(dy), 1)
                for k in range(1, steps):
                    sx = x + round(dx * k / steps)
                    # A jump rises first: full height by mid-flight.
                    sy = y + min(dy, round(dy * 2 * k / steps)) if dy >= 0 else y
                    if solid(g.get(sx, sy)) or solid(g.get(sx, sy + 1)):
                        ok = False
                        break
                if ok:
                    nxt.append((nx, ny))
        for n in nxt:
            seen.add(n)
            todo.append(n)
    return seen


def gate_span(base, exit0_side):
    """The x range openings may use: from the entrance wall to the nearest gate column."""
    gx = [x for x in range(base.w) for y in range(base.h) if base.get(x, y) in "GVRKF" and 0 < y < base.h - 1]
    if not gx:
        return 1, base.w - 2
    if exit0_side == "R":
        return max(gx) + 2, base.w - 2
    return 1, min(gx) - 2


def entrance(room):
    """Where the player can walk from doorway 0 without passing a gate: (reach, open_room).
    open_room is True when every doorway of the room is reachable that way (no gate between)."""
    base = Grid(room["grid"])
    cells = {}
    for y in range(base.h):
        for x in range(base.w):
            ch = base.get(x, y)
            if ch.isdigit():
                cells.setdefault(ch, []).append((x, y))
    def inner_start(digit):
        pts = cells.get(digit, [])
        if not pts:
            return None
        x0 = pts[0][0]
        ix = 1 if x0 == 0 else (base.w - 2 if x0 == base.w - 1 else x0)
        for _, y in sorted(pts, key=lambda p: p[1]):
            for yy in range(y, y + 3):
                if standable(base, ix, yy):
                    return (ix, yy)
        return None
    s0 = inner_start("0")
    if s0 is None:
        return set(), False
    reach = reachable(base, [s0])
    ok = True
    for d in cells:
        st = inner_start(d)
        if st is None or st not in reach:
            ok = False
    return reach, ok


def floor_surface(base, x):
    """The lowest open cell above the floor in column x (the hall's ground)."""
    for y in range(1, base.h - 1):
        if not solid(base.get(x, y)) and solid(base.get(x, y - 1)):
            return y
    return None


def exit_side(room, digit):
    for r, line in enumerate(room["grid"]):
        if digit in line:
            c = line.index(digit)
            return "L" if c == 0 else "R" if c == len(line) - 1 else "M"
    return "L"


FAILS = {}


def _fail(n):
    FAILS[n] = FAILS.get(n, 0) + 1
    return None


def build_room(rid, room, zone, link_sides, rng, reach):
    style = ZONE_STYLE[zone]
    base = Grid(room["grid"])
    B, W = base.h, base.w
    lo_h, hi_h = HEIGHTS[zone]
    interior = rng.randint(lo_h, hi_h) + (5 if rid in TOWERS else 0)
    U = interior + 2
    R = U + B - 1
    full_rows = ["#" * W for _ in range(U)] + room["grid"][1:]
    g = Grid(full_rows)
    fy = B - 1                      # the upper floor row (the old ceiling)
    top = R - 1                     # the new ceiling row
    # Open the upper interior.
    for y in range(fy + 1, top):
        for x in range(1, W - 1):
            g.set(x, y, ".")
    # Openings into the hall only above where the entrance side can walk (no way around gates);
    # the upper floor itself spans the whole width.
    allowed = set(x for x, _ in reach)
    if len(allowed) < 8:
        return _fail(1)
    lo, hi = 1, W - 2
    sets = []
    water = room.get("water", [])
    wet = set()
    for w in water:
        # Shallow water (wading depth) does not stop a climb; a pool does.
        if float(w.get("level", 0.0)) - float(w.get("floor", 0.0)) < 1.2:
            continue
        for x in range(int(w["x"][0]), int(w["x"][1]) + 1):
            wet.add(x)
    # 1. The climb: a zigzag of 3-wide one-way ledges from the hall to the upper floor.
    cands = []
    for sx in range(lo + 1, hi - 7):
        cols = range(sx, sx + 7)
        gs = [floor_surface(base, x) for x in cols]
        if None in gs or any(x in wet for x in cols) or max(gs) - min(gs) > 1:
            continue
        if any(x not in allowed for x in cols) or (sx, max(gs)) not in reach and (sx, min(gs)) not in reach:
            continue
        cands.append((sx, max(gs)))
    if not cands:
        return _fail(2)
    sx, gnd = rng.choice(cands)
    y = gnd + 1
    left = rng.random() < 0.5
    last_x = sx

    def free(px, py):
        return all(g.get(x, py) == "." and g.get(x, py + 1) in ".T Y" for x in range(px, px + 3))

    # Ledge rows counted down from the hole (the top ledge is 2 below the upper floor's surface),
    # so every step is one jump.
    ledge_rows = list(range(fy - 2, gnd, -2))
    if ledge_rows and min(ledge_rows) > gnd + 1:
        ledge_rows.append(gnd + 1)
    placed_top = None
    # Three staggered positions (0, 2, 4): a column comes back only every 6 m, so no jump hits
    # its head on the ledge above.
    order = [0, 2, 4] if left else [4, 2, 0]
    for i, ly in enumerate(sorted(ledge_rows)):
        px = sx + order[i % 3]
        if free(px, ly):
            for x in range(px, px + 3):
                g.set(x, ly, "=")
                sets.append([x, ly, "="])
            if ly == fy - 2:
                placed_top = px
    if placed_top is None:
        return _fail(6)
    last_x = placed_top
    left = True
    hole_x = last_x
    # The one-way opening spans the whole stair column: the last jumps pass under it.
    for x in range(sx - 1, sx + 8):
        if 1 <= x < W - 1 and g.get(x, fy) == "#":
            g.set(x, fy, "=")
    # 2. Drop-holes back to the hall (inside the entrance span, away from the climb).
    for _ in range(rng.randint(1, 2)):
        for _try in range(20):
            dx = rng.randint(lo + 1, hi - 3)
            if abs(dx - hole_x) < 6 or dx not in allowed or dx + 1 not in allowed:
                continue
            if all(base.get(x, fy - 1) == "." and base.get(x, fy - 2) == "." for x in range(dx, dx + 2)):
                g.set(dx, fy, ".")
                g.set(dx + 1, fy, ".")
                break
    # 3. The level's shape, by zone.
    surf = fy + 1
    picks = []
    spawn_cells = []
    ledge_side = rng.choice(["L", "R"])
    span = (lo, hi)
    if zone == "zone2" and rng.random() < style["mush"]:
        # A mushroom lifts the player to a high cap shelf.
        mx = rng.randint(lo + 3, hi - 4)
        g.set(mx, surf, "M")
        shelf_y = min(surf + 6, top - 3)
        sx0 = max(lo, mx - 5) if ledge_side == "L" else mx + 2
        for x in range(sx0, min(sx0 + 4, hi + 1)):
            g.set(x, shelf_y, "#")
        picks.append((sx0 + 1, shelf_y + 1))
    else:
        # A ledge by one wall up to a long balcony with jumpable gaps; the reward waits at its far
        # end. In tall rooms a second climb from there reaches a high shelf with another.
        lad_x = lo + 1 if ledge_side == "L" else hi - 3
        dirn = 1 if ledge_side == "L" else -1
        for x in range(lad_x, lad_x + 3):
            g.set(x, surf + 1, "=")
        bal_y = surf + 3
        length = max(8, min(16, (hi - lo) // 2))
        b0 = lad_x + 4 if dirn > 0 else lad_x - 2
        cells = [b0 + dirn * i for i in range(length)]
        cells = [x for x in cells if lo <= x <= hi]
        gaps = set()
        for frac in (0.35, 0.7):
            gi = int(len(cells) * frac)
            gaps.update(cells[gi:gi + 2])
        for x in cells:
            if x not in gaps:
                g.set(x, bal_y, "=")
        end = cells[-1]
        picks.append((end - dirn, bal_y + 1))
        if top - bal_y >= 9:
            yy = bal_y + 2
            k = 0
            last = None
            while yy + 2 < top - 1:
                px = end - dirn * (2 + 2 * (k % 3)) - (2 if dirn > 0 else 0)
                last = (px, yy)
                if yy + 4 < top - 1:
                    for x in range(px, px + 3):
                        if lo <= x <= hi:
                            g.set(x, yy, "=")
                yy += 2
                k += 1
            if last:
                px, py = last
                for x in range(px, px + 3):
                    if lo <= x <= hi:
                        g.set(x, py, "#")
                picks.append((px + 1, py + 1))
    # Low ruins on the upper floor to jump over (1-2 cells).
    for _ in range(rng.randint(1, 3)):
        rx = rng.randint(lo + 2, hi - 3)
        if abs(rx - hole_x) < 4:
            continue
        hgt = rng.randint(1, 2)
        for y in range(surf, surf + hgt):
            g.set(rx, y, "#")
            g.set(rx + 1, y, "#")
    # Spikes: a strip on the upper floor to leap (never under the climb hole).
    if rng.random() < style["spikes"]:
        for _try in range(20):
            kx = rng.randint(lo + 3, hi - 5)
            if abs(kx - hole_x) < 6:
                continue
            if all(g.get(x, surf) == "." and g.get(x, fy) == "#" for x in range(kx, kx + 3)):
                for x in range(kx, kx + 3):
                    g.set(x, surf, "^")
                break
    # 4. Upper doorways.
    exits = {}
    for side, digit, target, tdigit in link_sides:
        x = 0 if side == "L" else W - 1
        inner = 1 if side == "L" else W - 2
        if not (lo <= inner <= hi):
            return _fail(3)
        for y in range(surf, surf + 3):
            g.set(x, y, digit)
            g.set(inner, y, ".")
            g.set(inner + (1 if side == "L" else -1), y, ".")
        exits[digit] = {"to": target, "exit": tdigit}
    # 5. Enemies on the upper floor.
    codes = style["enemies"]
    for _ in range(rng.randint(1, 2)):
        for _try in range(30):
            ex = rng.randint(lo + 3, hi - 3)
            code = rng.choice(codes)
            if abs(ex - hole_x) < 5:
                continue
            ey = surf + 3 if code == "w" else (top - 1 if code == "t" else surf)
            if g.get(ex, ey) == "." and standable(g, ex, surf):
                g.set(ex, ey, code)
                spawn_cells.append((ex, ey))
                break
    # 6. Rewards: the shelf, and in tall rooms a second cache.
    loot = []
    for (px, py) in picks:
        if g.get(px, py) == "." and g.get(px, py - 1) in "#=":
            g.set(px, py, "*")
            loot.append(rng.choice(style["loot"]))
    # Check: from every base exit's floor and the hall, every reward and doorway is reachable.
    seen = reachable(g, list(reach))
    goals = [(x, y) for y in range(fy, R) for x in range(W) if g.get(x, y) == "*"]
    for digit in exits:
        side = "L" if any(g.get(0, y) == digit for y in range(R)) else "R"
        inner = 1 if side == "L" else W - 2
        goals.append((inner, surf))
    for gx_, gy_ in goals:
        if (gx_, gy_) not in seen:
            return _fail(4)
    # The upper floor itself must be reached (the climb works).
    if not any((x, surf) in seen for x in range(lo, hi + 1)):
        return _fail(5)
    rows = g.rows_top_first(fy, top)
    lamps = [[float(hole_x + 1), float(surf + 2)], [float((lo + hi) // 2), float(top - 2)]] if room.get("dark") else None
    out = {"rows": rows, "set": sets, "exits": exits}
    if loot:
        out["pickups"] = loot
    if lamps:
        out["lamps"] = lamps
    return out


def main():
    rooms_all = {}
    zone_of = {}
    for z in ZONES:
        d = json.load(open(os.path.join(ROOT, "data", "world", z + ".json"), encoding="utf-8"))
        for k, v in d["rooms"].items():
            rooms_all[k] = v
            zone_of[k] = z
    reaches = {rid: entrance(room) for rid, room in rooms_all.items() if rid not in SKIP}
    gated = [rid for rid, (_, ok) in reaches.items() if not ok]
    print("rooms with a gate between their doorways:", ", ".join(sorted(gated)))
    links = {}
    for a, b in LINKS:
        if a in gated or b in gated:
            print("no upper doorway between", a, b, "(a gate)")
            continue
        links.setdefault(a, []).append(("R", "7", b, "8"))
        links.setdefault(b, []).append(("L", "8", a, "7"))
    out = {z: {} for z in ZONES}
    failed = []
    for rid, room in rooms_all.items():
        if rid in SKIP:
            continue
        z = zone_of[rid]
        result = None
        for seed in range(400):
            rng = random.Random(hash(rid) % 100000 * 1000 + seed if False else (sum(map(ord, rid)) * 7919 + seed))
            result = build_room(rid, room, z, links.get(rid, []), rng, reaches[rid][0])
            if result:
                break
        if result is None:
            failed.append(rid)
            continue
        out[z][rid] = result
    # A link only stands if both of its rooms got their upper level: rebuild the survivor without it.
    for a, b in LINKS:
        za, zb = zone_of[a], zone_of[b]
        if (a in out[za]) != (b in out[zb]):
            rid, z = (a, za) if a in out[za] else (b, zb)
            if not out[z][rid].get("exits"):
                continue
            keep = [l for l in links.get(rid, []) if l[2] not in (a, b)]
            for seed in range(400):
                rng = random.Random(sum(map(ord, rid)) * 7919 + seed)
                result = build_room(rid, rooms_all[rid], z, keep, rng, reaches[rid][0])
                if result:
                    out[z][rid] = result
                    print("rebuilt", rid, "without its upper doorway (partner has no upper level)")
                    break
    os.makedirs(os.path.join(ROOT, "data", "world", "upper"), exist_ok=True)
    for z in ZONES:
        doc = {"_source": "Story 054, decision D-060. Generated by tools/world/build_upper.py: the upper levels stacked on each room (WorldData merges them). Edit the generator and rerun; do not edit by hand.",
               "rooms": out[z]}
        with open(os.path.join(ROOT, "data", "world", "upper", z + ".json"), "w", encoding="utf-8", newline="\n") as f:
            json.dump(doc, f, indent=1)
            f.write("\n")
        print("%s: %d rooms with upper levels" % (z, len(out[z])))
    if failed:
        print("no valid layout for:", ", ".join(failed))
        print("failure points (return number: count):", FAILS)


if __name__ == "__main__":
    main()
