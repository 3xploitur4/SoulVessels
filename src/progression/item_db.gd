class_name ItemDb
extends RefCounted
## Item definitions from `res://data/progression/items.json` (story 019). Text keys follow the id:
## `ITEM_<ID>` and `ITEM_<ID>_DESC`.
##
##     ItemDb.rarity("lesser_soul_shard")   # "common"
##     tr(ItemDb.name_key("crude_stone"))

const PATH := "res://data/progression/items.json"

static var _items: Dictionary = {}


static func item(id: String) -> Dictionary:
	_ensure()
	return _items.get(id, {})


static func exists(id: String) -> bool:
	_ensure()
	return _items.has(id)


static func ids() -> Array[String]:
	_ensure()
	var out: Array[String] = []
	out.assign(_items.keys())
	return out


static func rarity(id: String) -> String:
	return str(item(id).get("rarity", "common"))


static func kind(id: String) -> String:
	return str(item(id).get("kind", "material"))


static func name_key(id: String) -> String:
	return "ITEM_" + id.to_upper()


static func desc_key(id: String) -> String:
	return "ITEM_%s_DESC" % id.to_upper()


static func color(id: String) -> Color:
	return UiKit.RARITY_COLORS.get(rarity(id), UiKit.COL_TEXT)


static func _ensure() -> void:
	if not _items.is_empty():
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary:
		_items = (parsed as Dictionary).get("items", {})
	else:
		push_error("ItemDb: %s does not parse" % PATH)
