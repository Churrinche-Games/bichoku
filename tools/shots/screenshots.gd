extends SceneTree
## Store screenshots: the game screen in four scenes, at the store's sizes, in one language.
##   godot --path . -s tools/shots/screenshots.gd -- <out_dir> <es|en> [WxH ...]
## Writes <out_dir>/<W>x<H>-<scene>.png. Each shot is rendered in a SubViewport at the device's
## pixel size with the canvas the project's stretch settings give it (canvas_items, expand from
## 720×1280), so the sizes don't depend on this machine's screen. Needs a window (no --headless).

const BASE := Vector2(720, 1280)
const SCENES: Array[StringName] = [&"board", &"notes", &"win", &"settings"]
## Phone 9:16 (also Play's tablet slots), a tall phone at Play's 2:1 limit (the long side may be at
## most twice the short one), a 4:3 tablet in portrait (the game is portrait-locked), and the
## 16:9 desktop window of the web build.
const SIZES: Array[Vector2i] = [
	Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1536, 2048), Vector2i(1280, 720)
]
const DIR := "user://shots"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "build/store/screenshots/es"
	if not out.is_absolute_path():
		out = ProjectSettings.globalize_path("res://").path_join(out)
	var lang := args[1] if args.size() > 1 else "es"
	var sizes: Array[Vector2i] = []
	for a in args.slice(2):
		var wh := a.split("x")
		sizes.append(Vector2i(int(wh[0]), int(wh[1])))
	if sizes.is_empty():
		sizes = SIZES
	DirAccess.make_dir_recursive_absolute(out)
	DirAccess.make_dir_recursive_absolute(DIR)
	_run.call_deferred(out, lang, sizes)


## The canvas size Godot gives a window of this size (stretch aspect "expand" from BASE), rounded
## to whole units (Godot keeps the fraction; the difference is under a pixel).
static func canvas_for(pixels: Vector2i) -> Vector2i:
	var scale := minf(pixels.x / BASE.x, pixels.y / BASE.y)
	return Vector2i((Vector2(pixels) / scale).round())


func _run(out: String, lang: String, sizes: Array[Vector2i]) -> void:
	for px in sizes:
		for scene in SCENES:
			var image := await _shot(px, lang, scene)
			image.convert(Image.FORMAT_RGB8)
			image.save_png(out.path_join("%dx%d-%s.png" % [px.x, px.y, scene]))
	print("wrote %d screenshots to %s" % [sizes.size() * SCENES.size(), out])
	quit()


func _shot(px: Vector2i, lang: String, scene: StringName) -> Image:
	var path := DIR.path_join("%s.json" % scene)
	for f in ["", ".tmp", ".broken"]:
		DirAccess.remove_absolute(path + f)
	var store := GameStore.new(path)
	store.set_setting("language", lang)
	var s := _game(scene)
	store.save_game(s)

	var view := SubViewport.new()
	view.size = px
	view.size_2d_override = canvas_for(px)
	view.size_2d_override_stretch = true
	view.transparent_bg = false
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var screen: GameScreen = load("res://src/screen/game_screen.tscn").instantiate()
	screen.store_path = path
	view.add_child(screen)
	await process_frame
	_act(screen, s, scene)
	for i in 6:
		await process_frame
	var image := view.get_texture().get_image()
	view.queue_free()
	await process_frame
	return image


## A medium game in progress: about half the empty cells filled correctly, a few notes.
func _game(scene: StringName) -> GameState:
	var s := GameState.new_game(Difficulty.MEDIUM, 2026)
	var empty: Array[int] = []
	for c in 81:
		if not s.puzzle[c]:
			empty.append(c)
	for i in empty.size():
		if i % 2 == 0:
			s.values[empty[i]] = s.solution[empty[i]]
	var notes := 0 if scene == &"win" else (14 if scene == &"notes" else 5)
	for i in range(empty.size() - 1, -1, -1):
		var c := empty[i]
		if notes > 0 and not s.values[c]:
			var other := (s.solution[c] + 2 + c % 5) % 9 + 1
			s.notes[c] = (1 << (s.solution[c] - 1)) | (1 << (other - 1))
			notes -= 1
	if scene == &"win":
		s.values = s.solution.duplicate()
		s.values[empty[1]] = 0
	s.elapsed_ms = 252000 if scene != &"win" else 731000
	return s


func _act(screen: GameScreen, s: GameState, scene: StringName) -> void:
	match scene:
		&"board":
			# A given selected: its row, column and box lit, the same animal underlined.
			for c in range(30, 81):
				if s.puzzle[c]:
					screen.board.cell_pressed.emit(c)
					break
		&"notes":
			(screen.layout_parts().tools.get_child(2) as Button).pressed.emit()
			for c in range(40, 81):
				if not s.values[c] and not s.notes[c]:
					screen.board.cell_pressed.emit(c)
					break
		&"win":
			for c in 81:
				if not s.values[c]:
					screen.board.cell_pressed.emit(c)
					screen.palette_button(s.solution[c]).pressed.emit()
					break
		&"settings":
			(screen.layout_parts().header.get_child(2) as Button).pressed.emit()
