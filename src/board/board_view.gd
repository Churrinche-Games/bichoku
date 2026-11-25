class_name BoardView
extends Control
## The 9x9 board: paper, lines, animals (placeholder initials in each animal's ink), notes as dots,
## highlights for the selection, same animal and clashes (a faint red cell and a red ring).

signal cell_pressed(cell: int)

const PAPER := Color("#f1e6d6")
const LINE := Color("#4a3b2e")
const CLASH := Color("#c0392b")
## Under a clashing animal, with the ring around it (Juan, art checkpoint 2).
const CLASH_FILL := Color(CLASH, 0.14)
## The cells of the animals the puzzle starts with (Juan, art checkpoint 2).
const GIVEN_FILL := Color("#e3d2ba")

var state: GameState:
	set(value):
		state = value
		queue_redraw()
var show_numbers := false:
	set(value):
		show_numbers = value
		queue_redraw()
var mark_clashes := true:
	set(value):
		mark_clashes = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func cell_size() -> float:
	return minf(size.x, size.y) / 9.0


## The cell under a point in local coordinates, or -1 outside the board.
func cell_at(local: Vector2) -> int:
	var side := cell_size() * 9.0
	if local.x < 0 or local.y < 0 or local.x >= side or local.y >= side:
		return -1
	var c := int(local.x / cell_size())
	var r := int(local.y / cell_size())
	return r * 9 + c


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = (
		(
			event is InputEventMouseButton
			and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT
		)
		or (event is InputEventScreenTouch and event.pressed)
	)
	if pressed:
		var cell := cell_at(event.position)
		if cell >= 0:
			cell_pressed.emit(cell)
			accept_event()


## The cells marked as clashing: every repeated animal, or none when the setting is off.
func clash_cells() -> PackedInt32Array:
	if state == null or not mark_clashes:
		return PackedInt32Array()
	return Rules.conflicts(state)


func _draw() -> void:
	var s := cell_size()
	draw_rect(Rect2(Vector2.ZERO, Vector2(s * 9, s * 9)), PAPER)
	if state == null:
		_draw_lines(s)
		return
	for c in 81:
		if state.puzzle[c]:
			draw_rect(Rect2(Vector2(c % 9, c / 9) * s, Vector2(s, s)), GIVEN_FILL)
	_draw_highlights(s)
	var clashes := clash_cells()
	for c in clashes:
		draw_rect(Rect2(Vector2(c % 9, c / 9) * s, Vector2(s, s)), CLASH_FILL)
	var font := get_theme_default_font()
	for cell in 81:
		var origin := Vector2(cell % 9, cell / 9) * s
		var v := state.values[cell]
		if v:
			_draw_animal(font, origin, s, v)
			if cell in clashes:
				draw_arc(
					origin + Vector2(s, s) / 2,
					s * 0.42,
					0,
					TAU,
					32,
					CLASH,
					maxf(2.0, s * 0.05),
					true
				)
		elif state.notes[cell]:
			_draw_notes(font, origin, s, state.notes[cell])
	_draw_lines(s)


func _draw_highlights(s: float) -> void:
	var sel := state.selected
	if sel < 0:
		return
	var sel_row := sel / 9
	var sel_col := sel % 9
	var box := Vector2i(sel_col / 3, sel_row / 3)
	for cell in 81:
		var r := cell / 9
		var c := cell % 9
		var related := r == sel_row or c == sel_col or Vector2i(c / 3, r / 3) == box
		if cell == sel:
			draw_rect(Rect2(Vector2(c, r) * s, Vector2(s, s)), Color(LINE, 0.2))
		elif related:
			draw_rect(Rect2(Vector2(c, r) * s, Vector2(s, s)), Color(LINE, 0.07))
	var v := state.values[sel]
	if v:
		for cell in 81:
			if cell != sel and state.values[cell] == v:
				var o := Vector2(cell % 9, cell / 9) * s
				var y := underline_y(o, s)
				draw_line(
					Vector2(o.x + s * 0.25, y),
					Vector2(o.x + s * 0.75, y),
					Animals.ink(v),
					maxf(2.0, s * 0.04)
				)


## The same-animal underline's height in a cell: below the pictures, above the grid line.
static func underline_y(origin: Vector2, s: float) -> float:
	return origin.y + s * 0.94


## Where an animal's picture goes in a cell (the same for givens and entered animals).
static func picture_rect(origin: Vector2, s: float) -> Rect2:
	var w := s * 0.84
	var size := Vector2(w, w * 196.0 / 200.0)
	return Rect2(origin + (Vector2(s, s) - size) / 2, size)


func _draw_animal(font: Font, origin: Vector2, s: float, digit: int) -> void:
	draw_texture_rect(Animals.texture(digit), picture_rect(origin, s), false)
	if show_numbers:
		draw_string(
			font,
			origin + Vector2(s * 0.08, s * 0.28),
			str(digit),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			int(s * 0.22),
			LINE
		)


## A note is a dot in the animal's ink at its fixed spot of a 3x3 mini grid (1 top left, 9 bottom
## right), or a small digit there when numbers are shown.
func _draw_notes(font: Font, origin: Vector2, s: float, mask: int) -> void:
	for d in range(1, 10):
		if not mask & (1 << (d - 1)):
			continue
		var spot := origin + Vector2(((d - 1) % 3 + 0.5) * s / 3.0, ((d - 1) / 3 + 0.5) * s / 3.0)
		if show_numbers:
			var fs := int(s * 0.24)
			draw_string(
				font,
				spot + Vector2(-fs * 0.3, fs * 0.36),
				str(d),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				fs,
				Animals.ink(d)
			)
		else:
			draw_circle(spot, s * 0.075, Animals.ink(d), true, -1.0, true)


func _draw_lines(s: float) -> void:
	for i in 10:
		var w := 3.0 if i % 3 == 0 else 1.0
		draw_line(Vector2(0, i * s), Vector2(9 * s, i * s), LINE, w)
		draw_line(Vector2(i * s, 0), Vector2(i * s, 9 * s), LINE, w)
