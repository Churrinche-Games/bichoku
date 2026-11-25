extends GutTest
## Shared setup and helpers for the screen tests (not a test file itself).

const DIR := "user://test_screen"
const PATH := DIR + "/store.json"
const SIZES := [Vector2i(720, 1280), Vector2i(720, 1600), Vector2i(960, 1280), Vector2i(2276, 1280)]


func _key(keycode: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = keycode
	e.pressed = true
	return e


func after_each() -> void:
	TranslationServer.set_locale("en")


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


func _open_sheet_of(screen: GameScreen) -> KitSheet:
	for child in screen.get_children():
		if child is KitSheet:
			return child
	return null


func _press_settings(screen: GameScreen) -> KitSheet:
	screen.settings_button().pressed.emit()
	return _open_sheet_of(screen)


func _button_in(node: Node, text: String) -> Button:
	for child in node.find_children("*", "Button", true, false):
		if (child as Button).text == text:
			return child
	return null


func _texts(node: Node) -> Array[String]:
	var out: Array[String] = []
	for child in node.find_children("*", "", true, false):
		if child is Label or child is Button:
			out.append(child.text)
	return out
