extends TestCase
## Story 060 (D-071): the inventory shows items as icon tiles.


func test_every_item_has_an_icon_painting() -> void:
	for id in ItemDb.ids():
		var spec := InventoryView.icon_spec(id)
		assert_true(ResourceLoader.exists(InventoryView.ART_DIR + str(spec["art"]) + ".png"), id)


func test_items_carried_become_tiles_with_counts() -> void:
	var gs := GameState.new_game("normal")
	gs.add_item("lesser_soul_shard", 3)
	gs.add_item("heart_of_the_guardian", 1)
	var v := InventoryView.new()
	v.state = gs
	add_node(v)
	assert_eq(v.tiles.size(), 2)
	var tile := v.find_child("Item_lesser_soul_shard", true, false)
	assert_true(tile != null)
	var counts := tile.find_children("*", "Label", true, false)
	assert_true(counts.any(func(l: Node) -> bool: return (l as Label).text == "x3"), "the count shows")


func test_choosing_a_tile_shows_the_item() -> void:
	var gs := GameState.new_game("normal")
	gs.add_item("crude_stone", 1)
	gs.add_item("greater_soul_shard", 1)
	var v := InventoryView.new()
	v.state = gs
	add_node(v)
	v.show_item("greater_soul_shard")
	assert_eq(v._name.text, tr(ItemDb.name_key("greater_soul_shard")))
	assert_eq(v._desc.text, tr(ItemDb.desc_key("greater_soul_shard")))


func test_an_empty_bag_says_so() -> void:
	var v := InventoryView.new()
	v.state = GameState.new_game("normal")
	add_node(v)
	assert_eq(v.tiles.size(), 0)
