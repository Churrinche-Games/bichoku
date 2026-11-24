extends SceneTree
## Renders src/animals/art into a contact sheet for art reviews:
##   godot --headless --path . -s tools/art/contact_sheet.gd -- <out.png>
## Per animal: the simple level at 160, 40 and 32 px, as a black silhouette at 40 px, and the full
## level at 160 px where it exists.

const PAPER := Color("#f1e6d6")
const IDS := [
	"yaguarete", "lobo_marino", "pinguino", "condor", "hornero", "yacare", "flamenco", "guanaco", "ballena"
]
const ROW := 180
const W := 760


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "build/art/contact-sheet.png"
	var sheet := Image.create_empty(W, ROW * IDS.size() + 20, false, Image.FORMAT_RGBA8)
	sheet.fill(PAPER)
	for i in IDS.size():
		var id: String = IDS[i]
		var y := 10 + i * ROW
		var simple := _svg("res://src/animals/art/%s-simple.svg" % id)
		var x := 10
		for px in [160, 40, 32]:
			_blit(sheet, _raster(simple, px), x, y + (160 - px) / 2)
			x += px + 20
		_blit(sheet, _raster(_silhouette(simple), 40), x, y + 60)
		x += 80
		var full_path := "res://src/animals/art/%s-full.svg" % id
		if FileAccess.file_exists(full_path):
			_blit(sheet, _raster(_svg(full_path), 160), x, y)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	sheet.save_png(out)
	print("wrote ", out)
	quit()


func _svg(path: String) -> String:
	return FileAccess.get_file_as_string(path)


## Everything in ink: what the shape reads like without its markings.
func _silhouette(svg: String) -> String:
	var ink := RegEx.create_from_string('stroke="(#[0-9a-f]{6})"').search(svg).get_string(1)
	return svg.replace("#f1e6d6", ink).replace(ink, "#000000")


func _raster(svg: String, px: int) -> Image:
	var img := Image.new()
	img.load_svg_from_string(svg, px / 200.0)
	return img


func _blit(sheet: Image, img: Image, x: int, y: int) -> void:
	sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(x, y))
