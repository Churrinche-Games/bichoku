# gdlint:disable=max-public-methods
extends GutTest
## A port of the web version's game.test.ts, plus the plan's extra cases.

const PUZZLE := "530070000600195000098000060800060003400803001700020006060000280000419005000080079"
const SOLUTION := "534678912672195348198342567859761423426853791713924856961537284287419635345286179"


func _grid(text: String) -> PackedInt32Array:
	var out := PackedInt32Array()
	for ch in text:
		out.append(int(ch))
	return out


func _fresh(difficulty: StringName = Difficulty.EASY) -> GameState:
	return GameState.create(_grid(PUZZLE), _grid(SOLUTION), difficulty, 1)


func _at(r: int, c: int) -> int:
	return r * 9 + c


func _count_filled(grid: PackedInt32Array) -> int:
	var n := 0
	for v in grid:
		if v:
			n += 1
	return n


func test_places_a_value_in_the_selected_empty_cell() -> void:
	var s := Rules.input(Rules.select(_fresh(), _at(0, 2)), 4)
	assert_eq(s.values[_at(0, 2)], 4)


func test_never_changes_a_given() -> void:
	var s := Rules.erase(Rules.input(Rules.select(_fresh(), _at(0, 0)), 1))
	assert_eq(s.values[_at(0, 0)], 5)


func test_does_nothing_without_a_selection() -> void:
	assert_eq(Rules.input(_fresh(), 4).values, _grid(PUZZLE))


func test_erases_a_placed_value() -> void:
	var s := Rules.erase(Rules.input(Rules.select(_fresh(), _at(0, 2)), 4))
	assert_eq(s.values[_at(0, 2)], 0)


func test_removes_the_placed_digit_from_the_notes_of_cells_that_see_it() -> void:
	var s := Rules.toggle_notes(_fresh())
	s = Rules.input(Rules.input(Rules.select(s, _at(0, 3)), 4), 6)
	s = Rules.input(Rules.select(s, _at(8, 0)), 4)
	s = Rules.input(Rules.select(Rules.toggle_notes(s), _at(0, 2)), 4)
	assert_eq(s.notes[_at(0, 3)], 1 << 5, "only the 6 is left")
	assert_eq(s.notes[_at(8, 0)], 1 << 3, "not a peer, untouched")


func test_toggles_pencil_marks_in_notes_mode() -> void:
	var s := Rules.input(Rules.input(Rules.select(Rules.toggle_notes(_fresh()), _at(0, 2)), 1), 2)
	assert_eq(s.notes[_at(0, 2)], 0b11)
	s = Rules.input(s, 1)
	assert_eq(s.notes[_at(0, 2)], 0b10)
	assert_eq(s.values[_at(0, 2)], 0)


func test_placing_a_value_clears_the_cell_notes() -> void:
	var s := Rules.input(Rules.select(Rules.toggle_notes(_fresh()), _at(0, 2)), 1)
	s = Rules.input(Rules.toggle_notes(s), 4)
	assert_eq(s.notes[_at(0, 2)], 0)


func test_undo_steps_back_through_moves() -> void:
	var s := Rules.input(Rules.input(Rules.select(_fresh(), _at(0, 2)), 4), 1)
	s = Rules.undo(s)
	assert_eq(s.values[_at(0, 2)], 4)
	s = Rules.undo(s)
	assert_eq(s.values[_at(0, 2)], 0)
	s = Rules.undo(s)
	assert_eq(s.values, _grid(PUZZLE))


func test_flags_every_cell_in_a_clash() -> void:
	var bad := Rules.conflicts(Rules.input(Rules.select(_fresh(), _at(0, 2)), 5))
	assert_has(bad, _at(0, 2))
	assert_has(bad, _at(0, 0))
	assert_does_not_have(bad, _at(0, 1))


func test_counts_how_many_of_each_animal_are_still_to_place() -> void:
	var fives := 0
	for v in _grid(PUZZLE):
		if v == 5:
			fives += 1
	assert_eq(Rules.remaining(_fresh())[5 - 1], 9 - fives)


func _solve_all(s: GameState) -> GameState:
	var puzzle := _grid(PUZZLE)
	var solution := _grid(SOLUTION)
	for i in 81:
		if not puzzle[i]:
			s = Rules.input(Rules.select(s, i), solution[i])
	return s


func test_wins_when_the_grid_matches_the_solution() -> void:
	var s := _solve_all(_fresh())
	assert_true(s.won)
	assert_eq(Rules.erase(s).values, _grid(SOLUTION), "nothing changes after winning")


func test_nothing_changes_after_win() -> void:
	var s := _solve_all(_fresh())
	var before := s.values.duplicate()
	for next: GameState in [
		Rules.erase(s), Rules.undo(s), Rules.hint(s), Rules.tick(s, 1000), Rules.input(s, 1)
	]:
		assert_eq(next.values, before)
		assert_eq(next.elapsed_ms, s.elapsed_ms)
	assert_eq(Rules.select(s, 3).selected, 3)
	assert_true(Rules.toggle_notes(s).notes_mode != s.notes_mode)


func test_win_only_on_exact_solution() -> void:
	# Swapping two digits everywhere keeps the grid valid but differs from the stored solution.
	var other := _grid(SOLUTION)
	for i in 81:
		if other[i] == 1:
			other[i] = 2
		elif other[i] == 2:
			other[i] = 1
	var s := GameState.create(
		PackedInt32Array(other.duplicate()), _grid(SOLUTION), Difficulty.EASY, 1
	)
	s.values[0] = 0
	s.puzzle[0] = 0
	s = Rules.input(Rules.select(s, 0), other[0])
	assert_true(Solver.is_complete(Shape.classic9(), s.values))
	assert_false(s.won)


func test_hint_fills_the_selected_cell_with_its_answer() -> void:
	var s := Rules.hint(Rules.select(_fresh(), _at(0, 2)))
	assert_eq(s.values[_at(0, 2)], 4)
	assert_eq(s.hints_used, 1)


func test_hint_fixes_a_wrong_value() -> void:
	var s := Rules.hint(Rules.input(Rules.select(_fresh(), _at(0, 2)), 1))
	assert_eq(s.values[_at(0, 2)], 4)


func test_hint_picks_an_empty_cell_when_the_selection_needs_no_help() -> void:
	var s := Rules.hint(Rules.select(_fresh(), _at(0, 0)))
	assert_eq(_count_filled(s.values), _count_filled(_grid(PUZZLE)) + 1)
	assert_ne(s.selected, _at(0, 0))
	assert_eq(s.values[s.selected], _grid(SOLUTION)[s.selected])


func test_allows_fewer_hints_on_harder_levels() -> void:
	assert_eq(Difficulty.hints(Difficulty.EASY), 3)
	assert_eq(Difficulty.hints(Difficulty.MEDIUM), 2)
	assert_eq(Difficulty.hints(Difficulty.HARD), 1)
	assert_eq(Difficulty.min_clues(Difficulty.EASY), 40)
	assert_eq(Difficulty.min_clues(Difficulty.MEDIUM), 32)
	assert_eq(Difficulty.min_clues(Difficulty.HARD), 0)


func test_hints_count_down_and_stop_at_zero() -> void:
	var hard := _fresh(Difficulty.HARD)
	assert_eq(Rules.hints_left(hard), 1)
	var once := Rules.hint(hard)
	assert_eq(Rules.hints_left(once), 0)
	assert_eq(Rules.hint(once).values, once.values)
	assert_eq(Rules.hint(once).hints_used, 1)


func test_a_game_solved_with_a_hint_does_not_count_for_best_times() -> void:
	assert_true(Rules.counts_for_best(_fresh()))
	assert_false(Rules.counts_for_best(Rules.hint(_fresh())))


func test_timer_adds_elapsed_time() -> void:
	assert_eq(Rules.tick(Rules.tick(_fresh(), 1000), 500).elapsed_ms, 1500)


func test_new_game_more_clues_for_easier_levels() -> void:
	var clues := func(d: StringName) -> int: return _count_filled(GameState.new_game(d, 3).puzzle)
	assert_gt(clues.call(Difficulty.EASY), clues.call(Difficulty.MEDIUM))
	assert_gt(clues.call(Difficulty.MEDIUM), clues.call(Difficulty.HARD))


func test_new_game_is_the_same_for_the_same_seed() -> void:
	assert_eq(
		GameState.new_game(Difficulty.MEDIUM, 9).puzzle,
		GameState.new_game(Difficulty.MEDIUM, 9).puzzle
	)


func test_rules_never_mutate_input() -> void:
	var s := Rules.select(Rules.toggle_notes(_fresh()), _at(0, 2))
	var snapshot := s.duplicate_state()
	for next: GameState in [
		Rules.input(s, 3),
		Rules.erase(Rules.input(s, 3)),
		Rules.hint(s),
		Rules.tick(s, 10),
		Rules.undo(Rules.input(s, 3))
	]:
		assert_not_null(next)
	assert_eq(s.values, snapshot.values)
	assert_eq(s.notes, snapshot.notes)
	assert_eq(s.history.size(), snapshot.history.size())
	assert_eq(s.hints_used, snapshot.hints_used)
	assert_eq(s.elapsed_ms, snapshot.elapsed_ms)
