extends "res://tests/screen/screen_test_base.gd"


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


func test_arrows_move_the_selection_after_tapping_a_button() -> void:
	var saved := _saved_game()
	var screen := _screen()
	screen.board.cell_pressed.emit(40)
	for part: String in ["header", "tabs", "palette", "tools"]:
		for child in (screen.layout_parts()[part] as Control).get_children():
			if child is Button:
				assert_eq(
					(child as Button).focus_mode, Control.FOCUS_NONE, "%s takes no focus" % part
				)
	screen.get_viewport().push_input(_key(KEY_RIGHT))
	assert_eq(screen.state.selected, 41)
	var hints_before: int = screen.state.hints_used
	screen.get_viewport().push_input(_key(KEY_SPACE))
	assert_eq(screen.state.hints_used, hints_before, "space doesn't press a game button")
	assert_eq(saved.puzzle, screen.state.puzzle)


func test_tabs_show_the_current_difficulty_after_asking() -> void:
	var saved := _saved_game()
	var screen := _screen()
	screen.board.cell_pressed.emit(_first_empty(saved))
	screen.palette_button(1).pressed.emit()
	var hard := screen.tab_button(Difficulty.HARD)
	hard.button_pressed = true  # what a click does to a toggle button before 'pressed'
	hard.pressed.emit()
	assert_true(screen.is_confirm_open())
	assert_false(hard.button_pressed, "hard not lit while asking")
	assert_true(screen.tab_button(Difficulty.EASY).button_pressed)


func test_palette_buttons_show_pictures() -> void:
	_saved_game()
	var screen := _screen()
	for d in range(1, 10):
		var b := screen.palette_button(d)
		assert_eq(b.icon, Animals.texture(d))
		assert_false(b.text.contains(Animals.initial(d)), b.text)


func test_win_sheet_shows_the_animal() -> void:
	var s := GameState.new_game(Difficulty.EASY, 11)
	s.values = s.solution.duplicate()
	var cell := -1
	for c in 81:
		if not s.puzzle[c]:
			cell = c
			break
	s.values[cell] = 0
	GameStore.new(PATH).save_game(s)
	var screen := _screen()
	screen.board.cell_pressed.emit(cell)
	screen.palette_button(s.solution[cell]).pressed.emit()
	assert_true(screen.state.won)
	var animal := posmod(s.seed, 9) + 1
	var pictures := _open_sheet_of(screen).find_children("*", "TextureRect", true, false)
	var textures := pictures.map(func(p: TextureRect) -> Texture2D: return p.texture)
	assert_has(textures, Animals.texture(animal, true))
