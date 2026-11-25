extends "res://tests/screen/screen_test_base.gd"
## The win's fanfare: a short show of fireworks over the screen.

var _played: Array[StringName] = []


func _record(effect: StringName) -> void:
	_played.append(effect)


func _show() -> Fireworks:
	var fw := Fireworks.new(7)
	fw.size = Vector2(720, 1280)
	add_child_autofree(fw)
	return fw


## A saved game one move from the end; returns the screen after that move.
func _win(muted := false) -> GameScreen:
	var s := GameState.new_game(Difficulty.EASY, 11)
	s.values = s.solution.duplicate()
	var cell := -1
	for c in 81:
		if not s.puzzle[c]:
			cell = c
			break
	s.values[cell] = 0
	var store := GameStore.new(PATH)
	store.save_game(s)
	store.set_setting("muted", muted)
	if muted:
		store.set_setting("effects", true)
	var screen := _screen()
	_played.clear()
	screen.sound.played.connect(_record)
	screen.board.cell_pressed.emit(cell)
	screen.palette_button(s.solution[cell]).pressed.emit()
	return screen


func _fireworks_of(screen: GameScreen) -> Fireworks:
	for child in screen.get_children():
		if child is Fireworks:
			return child
	return null


func test_bursts_follow_the_schedule() -> void:
	var fw := _show()
	watch_signals(fw)
	fw.advance(0.0)
	assert_signal_emit_count(fw, "burst", 1)
	fw.advance(Fireworks.BURST_EVERY * (Fireworks.BURSTS - 1))
	assert_signal_emit_count(fw, "burst", Fireworks.BURSTS)


func test_the_show_is_short_and_frees_itself() -> void:
	var fw := _show()
	assert_lt(Fireworks.length(), 3.0)
	fw.advance(Fireworks.length() + 0.05)
	assert_true(fw.is_queued_for_deletion())


func test_never_blocks_a_tap() -> void:
	assert_eq(_show().mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_each_burst_is_in_an_animal_ink() -> void:
	var fw := _show()
	var inks := []
	for d in range(1, 10):
		inks.append(Animals.ink(d))
	for i in Fireworks.BURSTS:
		assert_has(inks, fw.burst_color(i), "burst %d" % i)


func test_sparks_fall_and_fade() -> void:
	var v := Vector2(100, -100)
	var early := Fireworks.spark_offset(v, 0.2)
	var late := Fireworks.spark_offset(v, 0.9)
	# Gravity bends the path down: below the straight line, and more so as time passes.
	assert_gt(early.y - v.y * 0.2, 0.0)
	assert_gt(late.y - v.y * 0.9, early.y - v.y * 0.2)
	assert_lt(early.y, 0.0)
	assert_eq(Fireworks.spark_alpha(0.0), 1.0)
	assert_eq(Fireworks.spark_alpha(Fireworks.SPARK_LIFE), 0.0)


func test_winning_launches_fireworks_above_the_win_sheet() -> void:
	var screen := _win()
	var fw := _fireworks_of(screen)
	assert_not_null(fw)
	var sheet := _open_sheet_of(screen)
	assert_not_null(sheet)
	assert_gt(fw.get_index(), sheet.get_index())


func test_each_burst_pops() -> void:
	var screen := _win()
	_fireworks_of(screen).advance(Fireworks.length())
	assert_eq(_played.count(&"pop"), Fireworks.BURSTS)
	assert_eq(_played[0], &"win")


func test_no_pops_when_muted() -> void:
	var screen := _win(true)
	_fireworks_of(screen).advance(Fireworks.length())
	assert_eq(_played, [] as Array[StringName])


func test_a_new_game_ends_the_show() -> void:
	var screen := _win()
	var fw := _fireworks_of(screen)
	_button_in(_open_sheet_of(screen), tr("NEW_GAME")).pressed.emit()
	assert_true(not is_instance_valid(fw) or fw.is_queued_for_deletion())


func test_the_show_fills_the_screen() -> void:
	var screen := _win()
	await wait_process_frames(1)
	assert_eq(_fireworks_of(screen).size, screen.size)
