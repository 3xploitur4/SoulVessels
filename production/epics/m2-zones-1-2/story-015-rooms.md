# Story 015: Room format, room builder and transitions

> **Epic**: M2 — Zones 1–2 · **Status**: Done (2026-11-14) · **Layer**: Feature · **Type**: Integration · **Estimate**: L

## Context

**Design**: addendum "Level design" (62 rooms in Chapter I, 30 in Zones 1–2), "Rendering approach"
(3D rooms, side-on camera, parallax depth, at most 3 dynamic lights per screen). Decision D-023
(rooms as text grids).

## Acceptance Criteria

- [x] Rooms are authored as text grids in `data/world/zone*.json` (1 cell = 1 m): solid, one-way platform, and markers for exits, enemies, pickups, altar, gates, mushrooms and events. A pure `RoomData` parses them (greedy rect merge), so tests read rooms without a scene tree.
- [x] `RoomBuilder` builds collision and merged meshes per material, theme decor on parallax layers, the environment, and at most 2 omni lights plus the key light.
- [x] `RoomManager` loads one room at a time, spawns its enemies with stable ids, moves the player through exits with a fade (arrival point per exit), and clamps the camera to the room on both axes.
- [x] Draw calls under 150 in the busiest room; room build under 100 ms on the dev PC.
- [x] Unit tests: grid parse, rect merge, exits and arrival points, every exit's target exists and links back.

## Files

- `src/world/room_data.gd`, `room_builder.gd`, `room_manager.gd`, `world_data.gd`, `mesh_merger.gd`
- `data/world/zone1.json`, `zone2.json`
- `tests/unit/world/room_data_test.gd`, `world_links_test.gd`

---

## Completion

Decision D-023. All 30 rooms build in 20-110 ms at about 30 draw calls (room viewer, `tests/manual/room_viewer.tscn`). Zone 2 enemies that do not exist yet were logged and skipped until story 022.
