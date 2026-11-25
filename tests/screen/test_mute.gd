extends "res://tests/screen/screen_test_base.gd"
## The speaker button next to "?": silences music and effects together; the switches in Ajustes
## stay as they are and come back when unmuted.


func test_the_speaker_sits_next_to_help() -> void:
	_saved_game()
	var screen := _screen()
	var header: HBoxContainer = screen.layout_parts().header
	assert_eq(screen.sound_button().get_index(), header.get_child(1).get_index() + 1)
	assert_eq((header.get_child(1) as Button).text, "?")


func test_mute_silences_music_and_effects() -> void:
	_saved_game()
	var screen := _screen()
	var on_icon := screen.sound_button().icon
	screen.sound_button().pressed.emit()
	assert_false(screen.sound.music_on)
	assert_false(screen.sound.effects_on)
	assert_ne(screen.sound_button().icon, on_icon)
	assert_true(GameStore.new(PATH).settings().muted)


func test_unmute_restores_the_switches() -> void:
	_saved_game()
	GameStore.new(PATH).set_setting("music", false)
	var screen := _screen()
	screen.sound_button().pressed.emit()
	screen.sound_button().pressed.emit()
	assert_false(screen.sound.music_on, "music stays off: its switch is off")
	assert_true(screen.sound.effects_on)


func test_mute_survives_a_restart() -> void:
	_saved_game()
	GameStore.new(PATH).set_setting("muted", true)
	var screen := _screen()
	assert_false(screen.sound.music_on)
	assert_false(screen.sound.effects_on)


func test_the_switches_still_work_when_unmuted() -> void:
	_saved_game()
	var screen := _screen()
	var sheet := _press_settings(screen)
	var music: CheckButton = null
	for b in sheet.find_children("*", "CheckButton", true, false):
		if (b as CheckButton).text == tr("KIT_MUSIC"):
			music = b
	music.button_pressed = false
	assert_false(screen.sound.music_on)
	assert_true(screen.sound.effects_on)


func test_cmd_z_undoes() -> void:
	var saved := _saved_game()
	var screen := _screen()
	var cell := _first_empty(saved)
	screen.board.cell_pressed.emit(cell)
	screen.palette_button(saved.solution[cell]).pressed.emit()
	var z := _key(KEY_Z)
	z.meta_pressed = true
	screen._unhandled_input(z)
	assert_eq(screen.state.values[cell], 0)
