extends GutTest

const DIR := "user://test_screen"
const PATH := DIR + "/store.json"
const SIZES := [Vector2i(720, 1280), Vector2i(720, 1600), Vector2i(960, 1280), Vector2i(2276, 1280)]


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	for f in ["", ".tmp", ".broken"]:
		DirAccess.remove_absolute(PATH + f)


func _saved_game() -> GameState:
	var s := GameState.new_game(Difficulty.EASY, 11)
	GameStore.new(PATH).save_game(s)
	return s


func _screen(parent: Node = null) -> GameScreen:
	var screen: GameScreen = load("res://src/screen/game_screen.tscn").instantiate()
	screen.store_path = PATH
	if parent == null:
		add_child_autofree(screen)
	else:
		parent.add_child(screen)
	return screen


func _first_empty(s: GameState) -> int:
	for c in 81:
		if not s.values[c]:
			return c
	return -1


func test_resumes_the_saved_game() -> void:
	var saved := _saved_game()
	var screen := _screen()
	assert_eq(screen.state.puzzle, saved.puzzle)


func test_clock_stops_when_focus_lost() -> void:
	_saved_game()
	var screen := _screen()
	screen.tick_clock()
	var before: int = screen.state.elapsed_ms
	assert_eq(before, 1000)
	screen.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	for i in 3:
		screen.tick_clock()
	assert_eq(screen.state.elapsed_ms, before)
	screen.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	screen.tick_clock()
	assert_eq(screen.state.elapsed_ms, before + 1000)


func test_input_through_screen_saves() -> void:
	var saved := _saved_game()
	var screen := _screen()
	var cell := _first_empty(saved)
	screen.board.cell_pressed.emit(cell)
	screen.palette_button(7).pressed.emit()
	assert_eq(GameStore.new(PATH).load_game().values[cell], 7)


func test_nothing_overlaps_at_each_size() -> void:
	_saved_game()
	for size: Vector2i in SIZES:
		var viewport: SubViewport = autofree(SubViewport.new())
		viewport.size = size
		add_child(viewport)
		var screen := _screen(viewport)
		await wait_process_frames(3)
		var area := Rect2(Vector2.ZERO, Vector2(size))
		var parts: Dictionary = screen.layout_parts()
		var names: Array = parts.keys()
		for name: String in names:
			var rect: Rect2 = (parts[name] as Control).get_global_rect()
			assert_true(rect.size.x > 0 and rect.size.y > 0, "%s visible at %s" % [name, size])
			assert_true(area.encloses(rect), "%s inside at %s: %s" % [name, size, rect])
		for i in names.size():
			for j in range(i + 1, names.size()):
				var a: Rect2 = (parts[names[i]] as Control).get_global_rect()
				var b: Rect2 = (parts[names[j]] as Control).get_global_rect()
				assert_false(a.intersects(b), "%s overlaps %s at %s" % [names[i], names[j], size])
		var board: Rect2 = (parts["board"] as Control).get_global_rect()
		assert_almost_eq(board.size.x, board.size.y, 1.0, "board square at %s" % size)
		viewport.remove_child(screen)
		screen.free()


func test_first_launch_shows_preparing_then_plays() -> void:
	var screen := _screen()
	if screen.state == null:
		assert_true(screen.is_preparing())
		await wait_for_signal(screen.game_started, 5)
	assert_false(screen.is_preparing())
	assert_eq(screen.state.difficulty, Difficulty.EASY)


func test_new_game_with_progress_asks_first() -> void:
	var saved := _saved_game()
	var screen := _screen()
	screen.board.cell_pressed.emit(_first_empty(saved))
	screen.palette_button(1).pressed.emit()
	screen.request_new_game(Difficulty.HARD)
	assert_true(screen.is_confirm_open())
	assert_eq(screen.state.difficulty, Difficulty.EASY, "not replaced yet")


func test_buttons_are_big_enough_to_tap() -> void:
	_saved_game()
	var viewport: SubViewport = autofree(SubViewport.new())
	viewport.size = Vector2i(720, 1280)
	add_child(viewport)
	var screen := _screen(viewport)
	await wait_process_frames(3)
	for part: String in ["header", "palette", "tools"]:
		for child in (screen.layout_parts()[part] as Control).get_children():
			if child is Button:
				var b := child as Button
				assert_gte(b.size.y, 64.0, "%s button '%s' height" % [part, b.text])
				assert_gte(b.size.x, 64.0, "%s button '%s' width" % [part, b.text])
	viewport.remove_child(screen)
	screen.free()
