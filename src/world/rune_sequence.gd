class_name RuneSequence
extends RefCounted
## The rule of one light-rune door (story 032, addendum "Light-rune puzzles"). Pure, so tests and
## the puzzle node share it.
## - "sequence": the runes must be lit in their listed (mural) order; a wrong rune puts every rune out.
## - "all": every rune lit, in any order.
##
##     var s := RuneSequence.new("sequence", 3)
##     if s.light(0) == RuneSequence.SOLVED: open_the_door()

const LIT := "lit"
const WRONG := "wrong"
const ALREADY := "already"
const SOLVED := "solved"

var kind: String = "all"
var solved: bool = false
var _lit: Array[bool] = []


func _init(puzzle_kind: String = "all", count: int = 1) -> void:
	kind = puzzle_kind
	_lit.resize(maxi(count, 1))
	_lit.fill(false)


## Light rune `index`; returns LIT, WRONG, ALREADY or SOLVED.
func light(index: int) -> String:
	if solved or index < 0 or index >= _lit.size() or _lit[index]:
		return ALREADY
	if kind == "sequence" and index != lit_count():
		_lit.fill(false)
		return WRONG
	_lit[index] = true
	if lit_count() == _lit.size():
		solved = true
		return SOLVED
	return LIT


func is_lit(index: int) -> bool:
	return index >= 0 and index < _lit.size() and _lit[index]


func lit_count() -> int:
	return _lit.count(true)


func size() -> int:
	return _lit.size()


## A door opened in an earlier visit: every rune shows lit.
func restore_solved() -> void:
	_lit.fill(true)
	solved = true
