class_name DataPatch
extends RefCounted
## Applies a patch of dotted paths to a deep copy of a data dictionary (story 037). Patches come
## from `ability_ranks.json` and `sync_passives.json` and look like
## `{"set": {"ability_2.knives": 7}, "mul": {"ability_2.motion": 1.2}, "add": {...}}`.
## Pure: the input dictionary is never modified, the output is a deep copy.
##
##     var out := DataPatch.apply(Balance.vessel("caelan"), {"mul": {"ability_2.motion": 1.2}})


## Return a deep copy of `data` with `patch` applied. `patch` may hold the keys "set" (write the
## value, creating missing intermediate dictionaries), "mul" (multiply the existing number;
## a missing path is left untouched) and "add" (add to the existing number; missing counts as 0).
## Each key maps a dotted path to a value. Unknown keys are ignored.
static func apply(data: Dictionary, patch: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	for kind: Variant in patch.keys():
		var entries: Variant = patch[kind]
		if not entries is Dictionary:
			continue
		for path: Variant in (entries as Dictionary).keys():
			var p := str(path)
			var value: Variant = (entries as Dictionary)[path]
			match str(kind):
				"set":
					_set_path(out, p, value)
				"mul":
					var current: Variant = _get_path(out, p)
					if current is float or current is int:
						_set_path(out, p, float(current) * float(value))
				"add":
					var current: Variant = _get_path(out, p)
					var base := float(current) if current is float or current is int else 0.0
					_set_path(out, p, base + float(value))
	return out


## The value at a dotted path, or null when any step is missing.
static func _get_path(data: Dictionary, path: String) -> Variant:
	var node: Variant = data
	for key: String in path.split("."):
		if node is Dictionary and (node as Dictionary).has(key):
			node = (node as Dictionary)[key]
		else:
			return null
	return node


## Write `value` at a dotted path, creating intermediate dictionaries (replacing non-dictionaries).
static func _set_path(data: Dictionary, path: String, value: Variant) -> void:
	var parts := path.split(".")
	var node: Variant = data
	for i in range(parts.size() - 1):
		if not node is Dictionary:
			return
		var dict := node as Dictionary
		if not dict.has(parts[i]) or not dict[parts[i]] is Dictionary:
			dict[parts[i]] = {}
		node = dict[parts[i]]
	if node is Dictionary:
		(node as Dictionary)[parts[parts.size() - 1]] = value
