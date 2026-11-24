extends "res://tests/screen/screen_test_base.gd"

var _played: Array[StringName] = []


func _record(effect: StringName) -> void:
	_played.append(effect)


func _listening_screen(saved: GameState = null) -> GameScreen:
	if saved == null:
		_saved_game()
	var screen := _screen()
	_played.clear()
	screen.sound.played.connect(_record)
	return screen


func test_place_plays_place() -> void:
	var saved := _saved_game()
	var screen := _listening_screen(saved)
	var cell := _first_empty(saved)
	screen.board.cell_pressed.emit(cell)
	screen.palette_button(saved.solution[cell]).pressed.emit()
	assert_eq(_played, [&"place"] as Array[StringName])


func test_clash_only_for_the_move_that_clashes() -> void:
	var saved := _saved_game()
	var screen := _listening_screen(saved)
	var cell := _first_empty(saved)
	# The cell's row already holds every given in it, so any of those clashes.
	var clashing := 0
	for c in range(cell - cell % 9, cell - cell % 9 + 9):
		if saved.puzzle[c]:
			clashing = saved.puzzle[c]
			break
	screen.board.cell_pressed.emit(cell)
	screen.palette_button(clashing).pressed.emit()
	assert_eq(_played, [&"clash"] as Array[StringName])
	# Another, unrelated correct move while that clash stays on the board is just a place.
	var other := -1
	for c in range(80, -1, -1):
		if not saved.puzzle[c] and c / 9 != cell / 9 and c % 9 != cell % 9:
			other = c
			break
	screen.board.cell_pressed.emit(other)
	screen.palette_button(saved.solution[other]).pressed.emit()
	assert_eq(_played, [&"clash", &"place"] as Array[StringName])


func test_note_mode_plays_note() -> void:
	var saved := _saved_game()
	var screen := _listening_screen(saved)
	screen.board.cell_pressed.emit(_first_empty(saved))
	screen._notes.pressed.emit()
	screen.palette_button(2).pressed.emit()
	assert_eq(_played, [&"note"] as Array[StringName])


func test_no_sound_for_a_no_op() -> void:
	var saved := _saved_game()
	var screen := _listening_screen(saved)
	screen._undo.pressed.emit()
	var given := 0
	while not saved.puzzle[given]:
		given += 1
	screen.board.cell_pressed.emit(given)
	screen.palette_button(1).pressed.emit()
	assert_eq(_played, [] as Array[StringName])


func test_undo_and_hint_sounds() -> void:
	var saved := _saved_game()
	var screen := _listening_screen(saved)
	var cell := _first_empty(saved)
	screen.board.cell_pressed.emit(cell)
	screen.palette_button(saved.solution[cell]).pressed.emit()
	screen._undo.pressed.emit()
	screen._hint.pressed.emit()
	assert_eq(_played, [&"place", &"undo", &"hint"] as Array[StringName])


func test_winning_move_plays_win() -> void:
	var s := GameState.new_game(Difficulty.EASY, 11)
	s.values = s.solution.duplicate()
	var cell := _first_empty(GameState.new_game(Difficulty.EASY, 11))
	s.values[cell] = 0
	GameStore.new(PATH).save_game(s)
	var screen := _listening_screen(s)
	screen.board.cell_pressed.emit(cell)
	screen.palette_button(s.solution[cell]).pressed.emit()
	assert_eq(_played, [&"win"] as Array[StringName])


func test_effects_off_plays_nothing() -> void:
	var saved := _saved_game()
	GameStore.new(PATH).set_setting("effects", false)
	var screen := _listening_screen(saved)
	var cell := _first_empty(saved)
	screen.board.cell_pressed.emit(cell)
	screen.palette_button(saved.solution[cell]).pressed.emit()
	assert_eq(_played, [] as Array[StringName])


func test_music_is_loaded_and_off_by_default() -> void:
	var screen := _listening_screen()
	assert_false(screen.sound.music_on)
	assert_false(screen.sound.is_music_playing())
	screen.sound.music_on = true
	assert_true(screen.sound.is_music_playing())
