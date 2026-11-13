extends Node
## Autoload `Balance`: every tuning number in the game, loaded once from `res://data/balance/`
## (decision D-003). Gameplay code never hardcodes a number; it asks here with a dotted path:
##
##     var cost: float = Balance.combat("stamina.dodge_cost")
##     var caelan: Dictionary = Balance.vessel("caelan")
##     var warden_hp: float = Balance.enemy("branded_warden")["hp"]
##
## A missing key is a `push_error` and `null`, never a silent zero. `set_value` lets the debug
## bridge and the playtest bot tune live; `reload()` rereads the files.

const ROOT := "res://data/balance"

var _combat: Dictionary = {}
var _vessels: Dictionary[String, Dictionary] = {}
var _enemies: Dictionary[String, Dictionary] = {}
var _sandbox: Dictionary = {}


func _ready() -> void:
	reload()


## Reread every JSON file. Called at boot and by the bridge after a `set_value` batch.
func reload() -> void:
	_combat = _load_json(ROOT + "/combat.json")
	_sandbox = _load_json(ROOT + "/sandbox.json", true)
	_vessels.clear()
	for id in _list_json(ROOT + "/vessels"):
		_vessels[id] = _load_json(ROOT + "/vessels/%s.json" % id)
	# The bare Intruder is looked up like a Vessel but is not one (never in vessel_ids()).
	_vessels["wisp"] = _load_json(ROOT + "/wisp.json")
	_enemies.clear()
	for id in _list_json(ROOT + "/enemies"):
		_enemies[id] = _load_json(ROOT + "/enemies/%s.json" % id)


## A value from combat.json by dotted path ("stamina.dodge_cost"). Null and an error when absent.
func combat(path: String) -> Variant:
	return _lookup(_combat, path, "combat")


## A combat value as float (JSON numbers arrive as float already).
func combat_f(path: String) -> float:
	var v: Variant = combat(path)
	return float(v) if v != null else 0.0


## The whole data block of one Vessel ("caelan"). Empty and an error when unknown.
func vessel(id: String) -> Dictionary:
	if not _vessels.has(id):
		push_error("Balance: unknown vessel '%s'" % id)
		return {}
	return _vessels[id]


## Every Vessel id on disk, sorted.
func vessel_ids() -> Array[String]:
	var ids: Array[String] = []
	for k: String in _vessels.keys():
		if k != "wisp":
			ids.append(k)
	ids.sort()
	return ids


## The whole data block of one enemy ("branded_warden"). Empty and an error when unknown.
func enemy(id: String) -> Dictionary:
	if not _enemies.has(id):
		push_error("Balance: unknown enemy '%s'" % id)
		return {}
	return _enemies[id]


## Every enemy id on disk, sorted.
func enemy_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_enemies.keys())
	ids.sort()
	return ids


## Sandbox-only overrides (affinity, starting loadout); empty outside the sandbox.
func sandbox(path: String) -> Variant:
	return _lookup(_sandbox, path, "sandbox", true)


## Generic read for the bridge: "combat.stamina.dodge_cost", "vessel.caelan.stats.atk",
## "enemy.echo_crawler.hp".
func get_value(path: String) -> Variant:
	var parts := path.split(".", false, 1)
	if parts.size() < 2:
		push_error("Balance.get_value: path needs a table prefix: %s" % path)
		return null
	match parts[0]:
		"combat":
			return combat(parts[1])
		"sandbox":
			return sandbox(parts[1])
		"vessel":
			var sub := parts[1].split(".", false, 1)
			return _lookup(vessel(sub[0]), sub[1] if sub.size() > 1 else "", "vessel." + sub[0])
		"enemy":
			var sub := parts[1].split(".", false, 1)
			return _lookup(enemy(sub[0]), sub[1] if sub.size() > 1 else "", "enemy." + sub[0])
	push_error("Balance.get_value: unknown table '%s'" % parts[0])
	return null


## Generic live write for the bridge and the playtest bot. In memory only; files are untouched.
## Returns false when the path does not already exist (no new keys are invented at run time).
func set_value(path: String, value: Variant) -> bool:
	var parts := path.split(".", false, 1)
	if parts.size() < 2:
		return false
	var table: Dictionary
	var rest := parts[1]
	match parts[0]:
		"combat":
			table = _combat
		"sandbox":
			table = _sandbox
		"vessel", "enemy":
			var sub := rest.split(".", false, 1)
			if sub.size() < 2:
				return false
			table = _vessels.get(sub[0], {}) if parts[0] == "vessel" else _enemies.get(sub[0], {})
			rest = sub[1]
		_:
			return false
	var keys := rest.split(".")
	var node: Variant = table
	for i in range(keys.size() - 1):
		if node is Dictionary and (node as Dictionary).has(keys[i]):
			node = (node as Dictionary)[keys[i]]
		elif node is Array and keys[i].is_valid_int():
			node = (node as Array)[int(keys[i])]
		else:
			return false
	var last := keys[keys.size() - 1]
	if node is Dictionary and (node as Dictionary).has(last):
		(node as Dictionary)[last] = value
		return true
	if node is Array and last.is_valid_int() and int(last) < (node as Array).size():
		(node as Array)[int(last)] = value
		return true
	return false


func _lookup(table: Dictionary, path: String, label: String, quiet: bool = false) -> Variant:
	if path.is_empty():
		return table
	var node: Variant = table
	for key in path.split("."):
		if node is Dictionary and (node as Dictionary).has(key):
			node = (node as Dictionary)[key]
		elif node is Array and key.is_valid_int() and int(key) < (node as Array).size():
			node = (node as Array)[int(key)]
		else:
			if not quiet:
				push_error("Balance: missing key '%s' in %s" % [path, label])
			return null
	return node


func _load_json(path: String, optional: bool = false) -> Dictionary:
	if not FileAccess.file_exists(path):
		if not optional:
			push_error("Balance: file not found %s" % path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_error("Balance: %s is not a JSON object" % path)
		return {}
	return parsed


func _list_json(dir_path: String) -> Array[String]:
	var ids: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("Balance: folder not found %s" % dir_path)
		return ids
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(".json"):
			ids.append(name.get_basename())
		name = dir.get_next()
	dir.list_dir_end()
	return ids
