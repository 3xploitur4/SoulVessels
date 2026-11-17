class_name ChapterEnd
extends CanvasLayer
## The chapter-end screen (story 047): black, the chapter's title, the run's play time, deaths and
## lore found, a line that Chapter II continues the story, and a button back to the title. Display
## only: the game shows it and answers `title_requested`.

signal title_requested

var state: GameState

var _root: Control


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiKit.theme()
	add_child(_root)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)
	var col := UiKit.centre_column(_root)
	col.add_child(UiKit.heading(tr("CHAPTER_ONE_END"), 60))
	col.add_child(UiKit.rule(520.0))
	if state != null:
		var stats := UiKit.label(tr("CHAPTER_STATS") % [UiKit.format_time(state.play_time_s), state.deaths,
			state.lore_found.size()], 26, UiKit.COL_DIM)
		stats.custom_minimum_size.x = 960.0
		col.add_child(stats)
	col.add_child(UiKit.label(tr("CHAPTER_TWO_TEASE"), 26, UiKit.COL_ACCENT))
	col.add_child(UiKit.label(tr("CHAPTER_ABYSSAL_UNLOCKED"), 22, UiKit.COL_GOLD))
	var b := UiKit.button(tr("CHAPTER_TO_TITLE"), 520.0)
	b.name = "ToTitle"
	b.pressed.connect(func() -> void: title_requested.emit())
	col.add_child(b)
	UiKit.link_focus([b] as Array[Control])
