extends SceneTree
## Rasterizes the Play store graphics from src/brand into a folder (default build/store):
##   icon-512.png                     the Play icon (opaque)
##   feature-es-419.png, feature-en-US.png   the feature graphic, 1024×500, opaque, with the name
##   adaptive-preview.png             the adaptive icon's layers composed, for a look (not uploaded)
## Needs a window (the name is drawn with the game's font), so no --headless:
##   godot --path . -s tools/art/render_store.gd -- [out_dir]

const PAPER := Color("#f1e6d6")
const LINE := Color("#4a3b2e")
const TAGLINES := {"es-419": "Sudoku de bichos argentinos", "en-US": "Sudoku with Argentine animals"}

var _out := "build/store"
var _frames := 0
var _views: Dictionary = {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	if not _out.is_absolute_path():
		_out = ProjectSettings.globalize_path("res://").path_join(_out)
	DirAccess.make_dir_recursive_absolute(_out)
	_opaque(_svg("icon.svg", 1.0)).save_png(_out.path_join("icon-512.png"))
	var preview := _svg("icon-background.svg", 1.0)
	preview.blend_rect(_svg("icon-foreground.svg", 1.0), Rect2i(0, 0, 432, 432), Vector2i.ZERO)
	preview.save_png(_out.path_join("adaptive-preview.png"))
	for lang: String in TAGLINES:
		_views[lang] = _feature(TAGLINES[lang])


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 4:
		return false
	for lang: String in _views:
		var image: Image = _views[lang].get_texture().get_image()
		_opaque(image).save_png(_out.path_join("feature-%s.png" % lang))
	print("wrote the store graphics to ", _out)
	return true


func _svg(file: String, scale: float) -> Image:
	var image := Image.new()
	var text := FileAccess.get_file_as_string("res://src/brand/" + file)
	var err := image.load_svg_from_string(text, scale)
	assert(err == OK, file)
	image.convert(Image.FORMAT_RGBA8)
	return image


func _opaque(image: Image) -> Image:
	image.convert(Image.FORMAT_RGB8)
	return image


func _feature(tagline: String) -> SubViewport:
	var view := SubViewport.new()
	view.size = Vector2i(1024, 500)
	view.transparent_bg = false
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var art := TextureRect.new()
	art.texture = ImageTexture.create_from_image(_svg("feature.svg", 1.0))
	view.add_child(art)
	var bold := FontVariation.new()
	bold.base_font = ThemeDB.fallback_font
	bold.variation_embolden = 0.9
	var title := Label.new()
	title.text = "Bichoku"
	title.add_theme_font_override("font", bold)
	title.add_theme_font_size_override("font_size", 120)
	title.add_theme_color_override("font_color", LINE)
	title.position = Vector2(56, 136)
	view.add_child(title)
	var sub := Label.new()
	sub.text = tagline
	sub.add_theme_font_size_override("font_size", 34)
	sub.add_theme_color_override("font_color", LINE)
	sub.position = Vector2(62, 300)
	view.add_child(sub)
	return view
