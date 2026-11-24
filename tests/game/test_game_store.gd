extends GutTest

const PATH := "user://test_bichoku/store.json"


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute("user://test_bichoku")
	for f in ["", ".tmp", ".broken"]:
		DirAccess.remove_absolute(PATH + f)


func _game() -> GameState:
	var s := GameState.new_game(Difficulty.MEDIUM, 7)
	for c in 81:
		if not s.puzzle[c]:
			s = Rules.input(Rules.select(s, c), s.solution[c])
			break
	s = Rules.input(Rules.select(Rules.toggle_notes(s), _first_empty(s)), 3)
	s = Rules.hint(s)
	s = Rules.tick(s, 4321)
	return s


func _first_empty(s: GameState) -> int:
	for c in 81:
		if not s.values[c]:
			return c
	return -1


func test_saved_game_round_trip() -> void:
	var s := _game()
	GameStore.new(PATH).save_game(s)
	var loaded := GameStore.new(PATH).load_game()
	assert_not_null(loaded)
	for field in [
		"puzzle",
		"solution",
		"values",
		"notes",
		"hints_used",
		"elapsed_ms",
		"difficulty",
		"seed",
		"won"
	]:
		assert_eq(loaded.get(field), s.get(field), field)
	assert_eq(typeof(loaded.difficulty), TYPE_STRING_NAME)
	assert_eq(loaded.history.size(), 0)
	assert_eq(loaded.selected, -1)
	assert_false(loaded.notes_mode)


func test_no_saved_game_returns_null() -> void:
	assert_null(GameStore.new(PATH).load_game())
	var store := GameStore.new(PATH)
	store.save_game(_game())
	store.clear_game()
	assert_null(GameStore.new(PATH).load_game())


func _won(hints: int, ms: int) -> GameState:
	var s := GameState.new_game(Difficulty.EASY, 3)
	s.won = true
	s.hints_used = hints
	s.elapsed_ms = ms
	return s


func test_best_only_without_hints() -> void:
	var store := GameStore.new(PATH)
	assert_false(store.record_win(_won(1, 1000)))
	assert_eq(store.best_ms(Difficulty.EASY), 0)
	assert_true(store.record_win(_won(0, 5000)))
	assert_eq(GameStore.new(PATH).best_ms(Difficulty.EASY), 5000)


func test_best_keeps_the_faster() -> void:
	var store := GameStore.new(PATH)
	store.record_win(_won(0, 5000))
	assert_false(store.record_win(_won(0, 6000)))
	assert_true(store.record_win(_won(0, 4000)))
	assert_eq(store.best_ms(Difficulty.EASY), 4000)
	assert_eq(store.best_ms(Difficulty.HARD), 0)


func test_settings_defaults_and_changes() -> void:
	var store := GameStore.new(PATH)
	assert_eq(store.settings(), {"animals_left": true, "mark_clashes": true, "show_numbers": false})
	store.set_setting("show_numbers", true)
	assert_true(GameStore.new(PATH).settings().show_numbers)


func test_needs_confirm_to_discard() -> void:
	var s := GameState.new_game(Difficulty.EASY, 5)
	assert_false(GameStore.needs_confirm_to_discard(s))
	s = Rules.input(Rules.select(s, _first_empty(s)), 1)
	assert_true(GameStore.needs_confirm_to_discard(s))
	s.won = true
	assert_false(GameStore.needs_confirm_to_discard(s))


func test_broken_save_starts_fresh() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	var store := GameStore.new(PATH)
	assert_null(store.load_game())
	assert_true(store.settings().mark_clashes)


func test_wrong_sized_game_is_ignored() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(
		'{"version": 1, "data": {"game": {"difficulty": "easy", "puzzle": [1, 2], "values": [1]}}}'
	)
	f.close()
	assert_null(GameStore.new(PATH).load_game())
