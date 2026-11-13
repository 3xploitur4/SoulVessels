extends SceneTree
## In-repo test runner (decision D-005). Run with:
##   godot --headless --path . -s res://tests/runner/test_runner.gd -- [--integration] [--filter name]
## Finds `tests/unit/**/*_test.gd` (plus `tests/integration/**` with --integration), runs every
## `test_*` method on a fresh instance, prints one line per failure and a summary, and quits with
## 0 when everything passed, 1 on failures, 2 when no test ran.

const UNIT_ROOT := "res://tests/unit"
const INTEGRATION_ROOT := "res://tests/integration"

var _passed := 0
var _failed := 0
var _errors: PackedStringArray = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var roots: Array[String] = [UNIT_ROOT]
	var filter := ""
	for i in range(args.size()):
		if args[i] == "--integration":
			roots.append(INTEGRATION_ROOT)
		elif args[i] == "--filter" and i + 1 < args.size():
			filter = args[i + 1]
	_run_all.call_deferred(roots, filter)


func _run_all(roots: Array[String], filter: String) -> void:
	await process_frame
	var files: Array[String] = []
	for root in roots:
		_collect(root, files)
	files.sort()
	for path in files:
		if not filter.is_empty() and not path.contains(filter):
			continue
		await _run_file(path)
	var total := _passed + _failed
	for line in _errors:
		printerr(line)
	print("TESTS: passed=%d failed=%d total=%d" % [_passed, _failed, total])
	if total == 0:
		print("TESTS: no test ran")
		quit(2)
	elif _failed > 0:
		quit(1)
	else:
		quit(0)


func _collect(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := dir_path.path_join(name)
		if dir.current_is_dir():
			if not name.begins_with("."):
				_collect(full, out)
		elif name.ends_with("_test.gd"):
			out.append(full)
		name = dir.get_next()
	dir.list_dir_end()


func _run_file(path: String) -> void:
	var script: GDScript = load(path)
	if script == null:
		_failed += 1
		_errors.append("FAIL %s: could not load script" % path)
		return
	var probe: Variant = script.new()
	if not (probe is TestCase):
		_failed += 1
		_errors.append("FAIL %s: does not extend TestCase" % path)
		return
	var methods: Array[String] = []
	for m: Dictionary in probe.get_method_list():
		var mname: String = m["name"]
		if mname.begins_with("test_") and not methods.has(mname):
			methods.append(mname)
	methods.sort()
	for mname in methods:
		var test: TestCase = script.new()
		test.tree = self
		test.before_each()
		await test.call(mname)
		test.after_each()
		for node in test.owned:
			if is_instance_valid(node):
				node.queue_free()
		if test.failures.is_empty():
			_passed += 1
		else:
			_failed += 1
			for f in test.failures:
				_errors.append("FAIL %s::%s: %s" % [path.get_file(), mname, f])
	await process_frame
