class_name TestCase
extends RefCounted
## Base class for unit and integration tests run by `tests/runner/test_runner.gd`.
## A test file extends this, names its methods `test_<scenario>_<expected>`, and uses the
## assert helpers below. A failing assert records a message and lets the method carry on, so one
## method can report several problems. `before_each` / `after_each` run around every method.

## Failures recorded by the current method, cleared by the runner between methods.
var failures: PackedStringArray = []
## Set by the runner so tests that need the SceneTree (nodes, frames) can reach it.
var tree: SceneTree
## Nodes added with `add_node`; the runner frees them after the method.
var owned: Array[Node] = []


func before_each() -> void:
	pass


func after_each() -> void:
	pass


## Record a failure.
func fail(message: String) -> void:
	failures.append(message)


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		fail("expected true" + _suffix(message))


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		fail("expected false" + _suffix(message))


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		fail("expected %s, got %s%s" % [str(expected), str(actual), _suffix(message)])


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	if actual == unexpected:
		fail("expected anything but %s%s" % [str(unexpected), _suffix(message)])


## Floats within `epsilon`.
func assert_almost(actual: float, expected: float, epsilon: float = 0.001, message: String = "") -> void:
	if absf(actual - expected) > epsilon:
		fail("expected %s +/- %s, got %s%s" % [expected, epsilon, actual, _suffix(message)])


func assert_gt(actual: float, threshold: float, message: String = "") -> void:
	if not actual > threshold:
		fail("expected > %s, got %s%s" % [threshold, actual, _suffix(message)])


func assert_lt(actual: float, threshold: float, message: String = "") -> void:
	if not actual < threshold:
		fail("expected < %s, got %s%s" % [threshold, actual, _suffix(message)])


func assert_null(value: Variant, message: String = "") -> void:
	if value != null:
		fail("expected null, got %s%s" % [str(value), _suffix(message)])


func assert_not_null(value: Variant, message: String = "") -> void:
	if value == null:
		fail("expected a value, got null" + _suffix(message))


## Add a node to the tree for the test; the runner frees it after the method.
func add_node(node: Node) -> Node:
	tree.root.add_child(node)
	owned.append(node)
	return node


## Wait N physics frames (for integration tests).
func wait_frames(count: int) -> void:
	for _i in range(count):
		await tree.physics_frame


func _suffix(message: String) -> String:
	return "" if message.is_empty() else " (%s)" % message
