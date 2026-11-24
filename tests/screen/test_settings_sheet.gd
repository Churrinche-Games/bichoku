extends "res://tests/screen/screen_test_base.gd"


func test_help_opens_a_kit_sheet() -> void:
	_saved_game()
	var screen := _screen()
	(screen.layout_parts().header.get_child(1) as Button).pressed.emit()
	assert_not_null(_open_sheet_of(screen))


func test_language_follows_saved_setting() -> void:
	_saved_game()
	var store := GameStore.new(PATH)
	store.set_setting("language", "en")
	var screen := _screen()
	assert_eq(screen.tab_button(Difficulty.EASY).text, "Easy")
	screen.free()
	store.set_setting("language", "es")
	screen = _screen()
	assert_eq(screen.tab_button(Difficulty.EASY).text, "Fácil")


func test_switching_language_keeps_the_game() -> void:
	_saved_game()
	GameStore.new(PATH).set_setting("language", "en")
	var screen := _screen()
	var cell := _first_empty(screen.state)
	screen.board.cell_pressed.emit(cell)
	screen.tick_clock()
	var before := screen.state
	var sheet := _press_settings(screen)
	_button_in(sheet, "Español").button_pressed = true
	assert_eq(screen.tab_button(Difficulty.EASY).text, "Fácil")
	assert_eq(screen.state.values, before.values)
	assert_eq(screen.state.selected, cell)
	assert_eq(screen.state.elapsed_ms, before.elapsed_ms)
	var reopened := _open_sheet_of(screen)
	assert_not_null(reopened)
	assert_not_null(_button_in(reopened, "English"))
	assert_eq(GameStore.new(PATH).settings().language, "es")


func test_about_opens_with_version() -> void:
	_saved_game()
	var screen := _screen()
	_button_in(_press_settings(screen), "About").pressed.emit()
	var about := _open_sheet_of(screen)
	assert_has(_texts(about), "Version 0.1.0")
	assert_has(_texts(about), "Bichoku")
	_button_in(about, "Third-party licenses").pressed.emit()
	assert_string_contains(" ".join(_texts(_open_sheet_of(screen))), "Godot Engine")


func test_no_donation_words_in_play_settings() -> void:
	_saved_game()
	for code in ["es", "en"]:
		GameStore.new(PATH).set_setting("language", code)
		var screen := _screen()
		screen.info_path = "res://tests/screen/game_info_itch.cfg"
		var all := " ".join(_texts(_press_settings(screen))).to_lower()
		for word in ["donat", "donac", "apoy", "support", "ko-fi", "cafecito"]:
			assert_false(all.contains(word), "%s: %s" % [code, word])
		screen.free()


func test_support_shown_for_itch_with_links() -> void:
	_saved_game()
	var screen := _screen()
	screen.info_path = "res://tests/screen/game_info_itch.cfg"
	screen.store_override = &"itch"
	_button_in(_press_settings(screen), "Support").pressed.emit()
	assert_not_null(_button_in(_open_sheet_of(screen), "Ko-fi"))


func test_feedback_shows_issues_link() -> void:
	_saved_game()
	var screen := _screen()
	_button_in(_press_settings(screen), "Feedback").pressed.emit()
	var sheet := _open_sheet_of(screen)
	assert_not_null(_button_in(sheet, "Open an issue on GitHub"))
	assert_null(_button_in(sheet, "Send an email"))


func test_sound_settings_default() -> void:
	_saved_game()
	var screen := _screen()
	assert_false(screen.sound.music_on)
	assert_true(screen.sound.effects_on)


func test_toggling_sound_saves() -> void:
	_saved_game()
	var screen := _screen()
	var sheet := _press_settings(screen)
	(_button_in(sheet, "Music") as CheckButton).button_pressed = true
	(_button_in(sheet, "Sound effects") as CheckButton).button_pressed = false
	assert_true(screen.sound.music_on)
	assert_false(screen.sound.effects_on)
	var saved := GameStore.new(PATH).settings()
	assert_true(saved.music)
	assert_false(saved.effects)


func test_saved_sound_settings_apply_on_start() -> void:
	_saved_game()
	GameStore.new(PATH).set_setting("effects", false)
	assert_false(_screen().sound.effects_on)


func test_every_sheet_settles_in_both_languages() -> void:
	_saved_game()
	for code in ["es", "en"]:
		GameStore.new(PATH).set_setting("language", code)
		var screen := _screen()
		await wait_process_frames(2)
		for open: Callable in [
			func() -> void: (screen.layout_parts().header.get_child(1) as Button).pressed.emit(),
			func() -> void: _press_settings(screen),
		]:
			open.call()
			await wait_process_frames(3)
			var sheet := _open_sheet_of(screen)
			var rect := sheet.panel().get_rect()
			await wait_process_frames(2)
			assert_eq(sheet.panel().get_rect(), rect, "%s settles" % code)
			sheet.close()
		screen.free()
