class_name GameScreen
extends Control
## The Bichoku screen: header, difficulty tabs, clock and hints, the board, the palette of nine
## animals and the tools. Every change goes through Rules and is saved.

signal game_started

const PAPER := Color("#f1e6d6")
const LINE := Color("#4a3b2e")
const PALETTE := {
	"paper": PAPER, "line": LINE, "accent": Color("#b5532a"), "error": BoardView.CLASH
}
## Side padding of the column (16 dp).
const PAD := 32.0
const GAP := 12
const HEADER_H := 72.0
const TABS_H := 64.0
const META_H := 44.0
## Palette and tool buttons are at least 48 dp tall.
const BUTTON_H := 96.0
## Everything in the column except the board, including gaps and the top and bottom margins.
const CHROME := HEADER_H + TABS_H + META_H + BUTTON_H * 2 + GAP * 5 + 48.0
const SAVE_EVERY_TICKS := 10
const SOUND_ON := preload("res://src/brand/sound-on.svg")
const SOUND_OFF := preload("res://src/brand/sound-off.svg")
const EFFECTS: Array[StringName] = [&"place", &"note", &"clash", &"hint", &"undo", &"win", &"pop"]

var store_path := "user://bichoku.json"
## Where the About, Feedback and Support pages read the game's facts (tests point elsewhere).
var info_path := KitGameInfo.PATH
## Whether the help lists the keyboard keys: 0 asks the platform, 1 yes, -1 no (tests).
var keyboard_override := 0
## The build's store (KitGameInfo.store()) unless a test sets it.
var store_override := &""
## The screen lays out inside the device's safe area; tests set this to pretend a notch.
var safe_rect_override := Rect2()
## What leaving does after the back button and "Leave" (tests replace it).
var quit_handler: Callable
var state: GameState
var board: BoardView
## Effects and music (sounds arrive with the art and sound plan); switches come from settings.
var sound: KitSound

var _store: GameStore
var _source: PuzzleSource
var _settings: Dictionary
var _focused := true
var _pending := &""
var _ticks_since_save := 0
var _sheet: KitSheet
var _confirm_open := false

var _language := ""

var _ui: Control
var _column: VBoxContainer
var _header: HBoxContainer
var _tabs: HBoxContainer
var _meta: HBoxContainer
var _palette: HBoxContainer
var _tools: HBoxContainer
var _clock_label: Label
var _hints_label: Label
var _preparing: Label
var _tab_buttons := {}
var _palette_buttons: Array[Button] = []
var _undo: Button
var _erase: Button
var _notes: Button
var _hint: Button
var _sound_button: Button
var _settings_button: Button
var _fireworks: Fireworks


func _ready() -> void:
	theme = KitTheme.make(PALETTE)
	if not quit_handler.is_valid():
		quit_handler = get_tree().quit
	_store = GameStore.new(store_path)
	_settings = _store.settings()
	_language = KitLanguage.apply(_settings.language)
	sound = KitSound.new()
	add_child(sound)
	for effect in EFFECTS:
		sound.add_effect(effect, load("res://src/sound/%s.wav" % effect))
	sound.set_music(load("res://src/sound/music.wav"))
	_source = PuzzleSource.new()
	_source.ready.connect(_on_source_ready)
	_build()
	_apply_sound()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(tick_clock)
	add_child(timer)
	timer.start()
	var saved := _store.load_game()
	if saved != null:
		_set_state(saved)
		game_started.emit()
	else:
		_start(Difficulty.EASY)
	for d in Difficulty.ALL:
		_source.prepare(d)
	_layout()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			if _column != null:
				_layout()
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_focused = false
			_save()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			_focused = true
		NOTIFICATION_WM_CLOSE_REQUEST:
			_save()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_on_back()


## One second of play. Called by the timer; the clock stops while the app is in the background.
func tick_clock() -> void:
	if not _focused or state == null or state.won:
		return
	state = Rules.tick(state, 1000)
	_ticks_since_save += 1
	if _ticks_since_save >= SAVE_EVERY_TICKS:
		_save()
	_refresh_meta()


func palette_button(digit: int) -> Button:
	return _palette_buttons[digit - 1]


## The speaker next to "?": mutes music and effects together.
func sound_button() -> Button:
	return _sound_button


func settings_button() -> Button:
	return _settings_button


func tab_button(difficulty: StringName) -> Button:
	return _tab_buttons[difficulty]


func layout_parts() -> Dictionary:
	return {
		"header": _header,
		"tabs": _tabs,
		"meta": _meta,
		"board": board,
		"palette": _palette,
		"tools": _tools
	}


func is_preparing() -> bool:
	return state == null


func is_confirm_open() -> bool:
	return _confirm_open


## Starts a new game of that difficulty, asking first if it would throw away a game in progress
## (animals placed or notes written). An untouched board of the same difficulty stays as it is.
func request_new_game(difficulty: StringName) -> void:
	# A click has already toggled the tab; show the current difficulty until a new game starts.
	_refresh()
	var progress := state != null and GameStore.needs_confirm_to_discard(state)
	if state != null and not state.won and not progress and state.difficulty == difficulty:
		return
	if progress:
		_confirm_open = true
		var sheet := _open_sheet()
		sheet.add_title(tr("CONFIRM_NEW_TITLE"))
		sheet.add_text(tr("CONFIRM_NEW_TEXT"))
		sheet.add_button(tr("CONFIRM_NEW_YES"), _start.bind(difficulty))
		sheet.add_button(tr("KIT_CANCEL"))
		sheet.closed.connect(func() -> void: _confirm_open = false)
	else:
		_start(difficulty)


func _start(difficulty: StringName) -> void:
	_end_fireworks()
	var game := _source.take(difficulty)
	if game == null:
		_pending = difficulty
		state = null
		_refresh()
		return
	_pending = &""
	_set_state(game)
	_save()
	game_started.emit()


func _on_source_ready(difficulty: StringName) -> void:
	if _pending == difficulty:
		_start(difficulty)


func _set_state(next: GameState) -> void:
	state = next
	_refresh()


## Applies an action's result: saves it and shows the win sheet on the move that wins.
## effect is the sound the action makes; the winning move plays the win sound instead.
func _apply(next: GameState, effect: StringName = &"") -> void:
	if state == null or next == state:
		return
	var was_won := state.won
	_set_state(next)
	_save()
	if state.won and not was_won:
		sound.play(&"win")
		_show_win(_store.record_win(state))
		_launch_fireworks()
	elif effect:
		sound.play(effect)


func _save() -> void:
	_ticks_since_save = 0
	if state != null:
		_store.save_game(state)


func _unhandled_input(event: InputEvent) -> void:
	if state == null or _sheet != null or not event is InputEventKey or not event.pressed:
		return
	var key := (event as InputEventKey).keycode
	if key >= KEY_1 and key <= KEY_9:
		_on_palette(key - KEY_0)
	elif key in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
		_move_selection(key)
	elif key in [KEY_BACKSPACE, KEY_DELETE]:
		_apply(Rules.erase(state), &"note")
	elif key == KEY_N:
		_set_state(Rules.toggle_notes(state))
	elif key == KEY_U or (key == KEY_Z and (event.ctrl_pressed or event.meta_pressed)):
		_apply(Rules.undo(state), &"undo")
	elif key == KEY_H:
		_apply(Rules.hint(state), &"hint")
	else:
		return
	get_viewport().set_input_as_handled()


func _move_selection(key: Key) -> void:
	var cell := maxi(state.selected, 0)
	var r := cell / 9
	var c := cell % 9
	match key:
		KEY_LEFT:
			c = (c + 8) % 9
		KEY_RIGHT:
			c = (c + 1) % 9
		KEY_UP:
			r = (r + 8) % 9
		KEY_DOWN:
			r = (r + 1) % 9
	_set_state(Rules.select(state, r * 9 + c))


# --- building -----------------------------------------------------------------------------------


func _build() -> void:
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ui)
	move_child(_ui, 0)
	var bg := ColorRect.new()
	bg.color = PAPER
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(bg)
	_column = VBoxContainer.new()
	_column.alignment = BoxContainer.ALIGNMENT_CENTER
	_column.add_theme_constant_override("separation", GAP)
	_ui.add_child(_column)

	_header = _row(HEADER_H)
	var title := Label.new()
	title.text = tr("TITLE")
	title.add_theme_font_size_override("font_size", 44)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.add_child(title)
	_header.add_child(_button("?", _show_help, 72))
	_sound_button = _button("", _toggle_mute, 72)
	_sound_button.expand_icon = true
	_sound_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header.add_child(_sound_button)
	_settings_button = _button(tr("SETTINGS_TITLE"), _show_settings)
	_header.add_child(_settings_button)

	_tabs = _row(TABS_H)
	for d in Difficulty.ALL:
		var tab := _button(tr("DIFF_" + String(d).to_upper()), request_new_game.bind(d))
		tab.toggle_mode = true
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_tab_buttons[d] = tab
		_tabs.add_child(tab)

	_meta = _row(META_H)
	_clock_label = Label.new()
	_clock_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_meta.add_child(_clock_label)
	_hints_label = Label.new()
	_meta.add_child(_hints_label)

	board = BoardView.new()
	board.cell_pressed.connect(_on_cell_pressed)
	_column.add_child(board)
	_preparing = Label.new()
	_preparing.text = tr("PREPARING")
	_preparing.set_anchors_preset(Control.PRESET_CENTER)
	_preparing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board.add_child(_preparing)

	_palette = _row(BUTTON_H)
	_palette.add_theme_constant_override("separation", 4)
	for d in range(1, 10):
		var b := _button("", _on_palette.bind(d))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.icon = Animals.texture(d)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_constant_override("h_separation", 0)
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_color_override("font_color", Animals.ink(d))
		b.add_theme_color_override("font_hover_color", Animals.ink(d))
		b.add_theme_color_override("font_pressed_color", Animals.ink(d))
		_palette_buttons.append(b)
		_palette.add_child(b)

	_tools = _row(BUTTON_H)
	_undo = _tool(tr("TOOL_UNDO"), func() -> void: _apply(Rules.undo(state), &"undo"))
	_erase = _tool(tr("TOOL_ERASE"), func() -> void: _apply(Rules.erase(state), &"note"))
	_notes = _tool(tr("TOOL_NOTES"), func() -> void: _set_state(Rules.toggle_notes(state)))
	_notes.toggle_mode = true
	_hint = _tool(tr("TOOL_HINT"), func() -> void: _apply(Rules.hint(state), &"hint"))


## Builds the controls again (after a language change); the game itself is untouched.
func _rebuild() -> void:
	_ui.free()
	_tab_buttons.clear()
	_palette_buttons.clear()
	_build()
	_refresh()
	_apply_sound()
	_layout()


func _on_cell_pressed(cell: int) -> void:
	if state != null:
		_set_state(Rules.select(state, cell))


## An animal from the palette or the keyboard: a note in notes mode, else placed (a clash sounds
## different when the animal just placed repeats in its row, column or box).
func _on_palette(digit: int) -> void:
	if state == null:
		return
	var next := Rules.input(state, digit)
	var effect := &"note" if state.notes_mode else &"place"
	# With clashes hidden, the sound mustn't give them away either.
	if effect == &"place" and _settings.mark_clashes and next.selected in Rules.conflicts(next):
		effect = &"clash"
	_apply(next, effect)


func _when_playing(action: Callable) -> void:
	if state != null:
		action.call()


func _row(height: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, height)
	row.add_theme_constant_override("separation", GAP)
	_column.add_child(row)
	return row


func _button(text: String, on_press: Callable, min_width: float = 0.0) -> Button:
	var b := Button.new()
	b.text = text
	# The game's buttons never take keyboard focus: arrows, Space and Enter belong to the board.
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(min_width, 0)
	b.pressed.connect(on_press)
	return b


func _tool(text: String, on_press: Callable) -> Button:
	var b := _button(text, _when_playing.bind(on_press))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tools.add_child(b)
	return b


## The device safe area in the screen's coordinates (or the test's override).
func _safe_area() -> Rect2:
	var area := Rect2(Vector2.ZERO, size)
	if safe_rect_override.has_area():
		return safe_rect_override
	if is_inside_tree():
		return KitMobile.current_safe_rect(get_viewport()).intersection(area)
	return area


func _layout() -> void:
	var area := _safe_area()
	if _sheet != null:
		_sheet.area_rect = area
	var view := area.size
	var column := BoardLayout.column_width(view)
	var side := minf(BoardLayout.board_side(view, CHROME), column - PAD * 2)
	_column.position = area.position + Vector2(BoardLayout.column_left(view) + PAD, 0)
	_column.size = Vector2(column - PAD * 2, view.y)
	board.custom_minimum_size = Vector2(side, side)
	board.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


# --- refreshing ---------------------------------------------------------------------------------


func _refresh() -> void:
	_preparing.visible = state == null
	board.state = state
	board.show_numbers = _settings.show_numbers
	board.mark_clashes = _settings.mark_clashes
	for d: StringName in _tab_buttons:
		(_tab_buttons[d] as Button).set_pressed_no_signal(state != null and state.difficulty == d)
	var left := Rules.remaining(state) if state else PackedInt32Array([9, 9, 9, 9, 9, 9, 9, 9, 9])
	for i in 9:
		var b := _palette_buttons[i]
		b.text = ("%d" % left[i]) if _settings.animals_left else ""
		b.modulate.a = 0.35 if _settings.animals_left and left[i] == 0 else 1.0
	_undo.disabled = state == null or state.history.is_empty() or state.won
	_erase.disabled = state == null or state.won
	_hint.disabled = state == null or state.won or Rules.hints_left(state) == 0
	_notes.set_pressed_no_signal(state != null and state.notes_mode)
	_refresh_meta()


func _refresh_meta() -> void:
	_clock_label.text = format_time(state.elapsed_ms) if state else ""
	_hints_label.text = (tr("HINTS_LEFT") % Rules.hints_left(state)) if state else ""


static func format_time(ms: int) -> String:
	var total := ms / 1000
	var h := total / 3600
	var m := (total % 3600) / 60
	var s := total % 60
	return "%d:%02d:%02d" % [h, m, s] if h else "%d:%02d" % [m, s]


# --- sheets -------------------------------------------------------------------------------------


func _open_sheet() -> KitSheet:
	if _sheet != null:
		_sheet.close()
	_sheet = KitSheet.new()
	_sheet.area_rect = _safe_area()
	_sheet.closed.connect(func() -> void: _sheet = null)
	add_child(_sheet)
	return _sheet


## Android back: closes the open sheet, else asks before leaving.
func _on_back() -> void:
	if _sheet != null:
		_sheet.close()
		return
	var sheet := _open_sheet()
	sheet.add_title(tr("KIT_LEAVE_TITLE") % tr("TITLE"))
	sheet.add_text(tr("KIT_LEAVE_TEXT"))
	sheet.add_button(tr("KIT_LEAVE_YES"), _leave)
	sheet.add_button(tr("KIT_CANCEL"))


func _leave() -> void:
	_save()
	quit_handler.call()


## Desktops and the web build on a computer have a keyboard; phones and tablets (the app, or
## the web build in a phone's browser) are taken not to, even if one is plugged in. On the web a
## touchscreen also counts as no keyboard: iPad Safari reports itself as macOS.
static func has_keyboard(features: PackedStringArray, touchscreen := false) -> bool:
	for touch in ["mobile", "web_android", "web_ios"]:
		if touch in features:
			return false
	return not ("web" in features and touchscreen)


func _show_help() -> void:
	var sheet := _open_sheet()
	sheet.add_title(tr("HELP_TITLE"))
	sheet.add_text(tr("HELP_TEXT"))
	var keyboard := keyboard_override > 0
	if keyboard_override == 0:
		var features := PackedStringArray()
		for f in ["mobile", "web", "web_android", "web_ios"]:
			if OS.has_feature(f):
				features.append(f)
		keyboard = has_keyboard(features, DisplayServer.is_touchscreen_available())
	if keyboard:
		sheet.add_text(tr("HELP_KEYS"))
	sheet.add_button(tr("KIT_CLOSE"))


func _show_settings() -> void:
	var sheet := _open_sheet()
	sheet.add_title(tr("SETTINGS_TITLE"))
	for key in ["animals_left", "mark_clashes", "show_numbers"]:
		sheet.add_check(tr("SETTING_" + key.to_upper()), _settings[key], _change_setting.bind(key))
	sheet.add_check(tr("KIT_MUSIC"), _settings.music, _change_setting.bind("music"))
	sheet.add_check(tr("KIT_EFFECTS"), _settings.effects, _change_setting.bind("effects"))
	sheet.add_text(tr("KIT_LANGUAGE"))
	var languages: Array[Dictionary] = []
	for code: String in KitLanguage.SUPPORTED:
		languages.append({"text": KitLanguage.display_name(code), "value": code})
	sheet.add_choice(languages, _language, _change_language)
	var info := KitGameInfo.from_file(info_path)
	var store := store_override if store_override else KitGameInfo.store()
	sheet.add_button(tr("KIT_ABOUT"), _show_about.bind(info))
	if KitPages.has_feedback(info):
		sheet.add_button(tr("KIT_FEEDBACK"), _show_page.bind(KitPages.feedback.bind(info)))
	if KitPages.has_support(info, store):
		sheet.add_button(tr("KIT_SUPPORT"), _show_page.bind(KitPages.support.bind(info, store)))
	sheet.add_button(tr("KIT_CLOSE"))


func _show_about(info: KitGameInfo) -> void:
	KitPages.about(_open_sheet(), info, _show_page.bind(KitPages.licenses))


## Opens a sheet and lets fill(sheet) put a kit page in it.
func _show_page(fill: Callable) -> void:
	fill.call(_open_sheet())


func _change_language(code: String) -> void:
	if code == _language:
		return
	_store.set_setting("language", code)
	_settings = _store.settings()
	_language = KitLanguage.apply(code)
	_rebuild()
	_show_settings()


func _change_setting(value: bool, key: String) -> void:
	_store.set_setting(key, value)
	_settings = _store.settings()
	_apply_sound()
	_refresh()


func _apply_sound() -> void:
	sound.music_on = _settings.music and not _settings.muted
	sound.effects_on = _settings.effects and not _settings.muted
	if _sound_button != null:
		_sound_button.icon = SOUND_OFF if _settings.muted else SOUND_ON
		_sound_button.tooltip_text = tr("SOUND_UNMUTE" if _settings.muted else "SOUND_MUTE")


func _toggle_mute() -> void:
	_store.set_setting("muted", not _settings.muted)
	_settings = _store.settings()
	_apply_sound()


## Fireworks over everything, the win sheet included; each burst pops.
func _launch_fireworks() -> void:
	_end_fireworks()
	var show := Fireworks.new(state.seed)
	show.set_anchors_preset(Control.PRESET_FULL_RECT)
	show.burst.connect(func(_i: int) -> void: sound.play(&"pop"))
	add_child(show)
	_fireworks = show


## A new game ends the last one's show.
func _end_fireworks() -> void:
	if is_instance_valid(_fireworks):
		_fireworks.queue_free()
	_fireworks = null


func _show_win(new_best: bool) -> void:
	var sheet := _open_sheet()
	sheet.add_title(tr("WIN_TITLE"))
	sheet.add_text(tr("WIN_TIME") % format_time(state.elapsed_ms))
	var best := _store.best_ms(state.difficulty)
	if new_best:
		sheet.add_text(tr("WIN_NEW_BEST"))
	elif best:
		sheet.add_text(tr("WIN_BEST") % format_time(best))
	if not Rules.counts_for_best(state):
		sheet.add_text(tr("WIN_HINTS_NOTE"))
	var animal := posmod(state.seed, 9) + 1
	sheet.add_image(Animals.texture(animal, true), 220)
	var name_label := sheet.add_text(tr(Animals.name_key(animal)))
	name_label.add_theme_color_override("font_color", Animals.ink(animal))
	sheet.add_text(tr(Animals.fact_key(animal)))
	sheet.add_button(tr("NEW_GAME"), _start.bind(state.difficulty))
	sheet.add_button(tr("KIT_CLOSE"))
