extends "res://tests/screen/screen_test_base.gd"

var _quits := 0


func _quit() -> void:
	_quits += 1


func _phone(size: Vector2i, safe: Rect2) -> GameScreen:
	var viewport: SubViewport = autofree(SubViewport.new())
	viewport.size = size
	add_child(viewport)
	var screen: GameScreen = load("res://src/screen/game_screen.tscn").instantiate()
	screen.store_path = PATH
	screen.safe_rect_override = safe
	viewport.add_child(screen)
	return screen


func test_back_closes_open_sheet() -> void:
	_quits = 0
	var saved := _saved_game()
	var screen := _screen()
	screen.quit_handler = _quit
	screen.board.cell_pressed.emit(_first_empty(saved))
	screen.palette_button(1).pressed.emit()
	screen.request_new_game(Difficulty.HARD)
	assert_true(screen.is_confirm_open())
	screen.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_false(screen.is_confirm_open())
	assert_null(_open_sheet_of(screen))
	assert_eq(_quits, 0)
	assert_eq(screen.state.difficulty, Difficulty.EASY, "the game was kept")


func test_back_asks_then_leaves() -> void:
	_quits = 0
	var saved := _saved_game()
	var screen := _screen()
	screen.quit_handler = _quit
	var cell := _first_empty(saved)
	screen.board.cell_pressed.emit(cell)
	screen.palette_button(1).pressed.emit()
	screen.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	var sheet := _open_sheet_of(screen)
	assert_not_null(sheet)
	assert_has(_texts(sheet), "Leave Bichoku?")
	assert_eq(_quits, 0)
	_button_in(sheet, "Leave").pressed.emit()
	assert_eq(_quits, 1)
	assert_eq(GameStore.new(PATH).load_game().values[cell], 1, "saved before leaving")


func test_back_then_cancel_stays() -> void:
	_quits = 0
	_saved_game()
	var screen := _screen()
	screen.quit_handler = _quit
	screen.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_button_in(_open_sheet_of(screen), "Cancel").pressed.emit()
	assert_null(_open_sheet_of(screen))
	assert_eq(_quits, 0)


func test_layout_inside_safe_rect() -> void:
	_saved_game()
	for size: Vector2i in SIZES:
		var safe := Rect2(0, 100, size.x, size.y - 180)
		var screen := _phone(size, safe)
		await wait_process_frames(3)
		var parts: Dictionary = screen.layout_parts()
		for name: String in parts:
			var rect: Rect2 = (parts[name] as Control).get_global_rect()
			assert_true(
				safe.encloses(rect), "%s inside the safe area at %s: %s" % [name, size, rect]
			)
		if size == Vector2i(720, 1280):
			assert_gte((parts.board as Control).size.x, 560.0)
		screen.get_parent().remove_child(screen)
		screen.free()
