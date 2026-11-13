class_name LoreDb
extends RefCounted
## Lore entries from `res://data/lore/lore.json` (stories 017, 019, 024): Faded Parchments (text),
## Echoing Relics, Vessel Memories (+1 Affinity when read at an altar) and Primeval Truths.
## Text keys: `LORE_<ID>_TITLE`, `LORE_<ID>_BODY`.
##
##     var next := LoreDb.next_unfound("parchment", state.lore_found)   # "" when all found

const PATH := "res://data/lore/lore.json"

static var _entries: Array[Dictionary] = []
static var _by_id: Dictionary[String, Dictionary] = {}


static func entry(id: String) -> Dictionary:
	_ensure()
	return _by_id.get(id, {})


## Entries of `kind` in story order.
static func of_kind(kind: String) -> Array[Dictionary]:
	_ensure()
	var out: Array[Dictionary] = []
	for e in _entries:
		if str(e.get("kind", "")) == kind:
			out.append(e)
	return out


## The first entry of `kind` not yet in `found`, or "".
static func next_unfound(kind: String, found: Array[String]) -> String:
	for e in of_kind(kind):
		if not found.has(str(e["id"])):
			return str(e["id"])
	return ""


## The Vessel a memory belongs to ("" for other lore).
static func vessel_of(id: String) -> String:
	return str(entry(id).get("vessel", ""))


static func title_key(id: String) -> String:
	return "LORE_%s_TITLE" % id.to_upper()


static func body_key(id: String) -> String:
	return "LORE_%s_BODY" % id.to_upper()


static func _ensure() -> void:
	if not _entries.is_empty():
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary:
		push_error("LoreDb: %s does not parse" % PATH)
		return
	for e: Variant in (parsed as Dictionary).get("entries", []):
		if e is Dictionary:
			_entries.append(e)
			_by_id[str((e as Dictionary)["id"])] = e
