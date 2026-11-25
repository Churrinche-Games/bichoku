extends GutTest


func test_cell_at_corners_and_outside() -> void:
	var view: BoardView = autofree(BoardView.new())
	view.size = Vector2(630, 630)
	assert_eq(view.cell_at(Vector2(1, 1)), 0)
	assert_eq(view.cell_at(Vector2(629, 629)), 80)
	assert_eq(view.cell_at(Vector2(70 * 4 + 1, 70 * 2 + 1)), 22)
	assert_eq(view.cell_at(Vector2(-1, 5)), -1)
	assert_eq(view.cell_at(Vector2(630, 10)), -1)
	assert_eq(view.cell_at(Vector2(10, 631)), -1)


func test_every_animal_is_drawn_at_the_same_size() -> void:
	var origin := Vector2(80, 160)
	var r := BoardView.picture_rect(origin, 80.0)
	assert_almost_eq(r.get_center(), origin + Vector2(40, 40), Vector2(0.5, 0.5))
	assert_almost_eq(r.size.x, 80.0 * 0.84, 0.01)
	assert_almost_eq(r.size.x / r.size.y, 200.0 / 196.0, 0.01)
	assert_true(Rect2(origin, Vector2(80, 80)).encloses(r))


func test_givens_sit_on_a_darker_cell() -> void:
	assert_lt(BoardView.GIVEN_FILL.v, BoardView.PAPER.v)
	# Lighter than the selected cell's highlight, so the selection still stands out.
	var selected := BoardView.PAPER.lerp(BoardView.LINE, 0.2)
	assert_gt(BoardView.GIVEN_FILL.v, selected.v)


func test_same_animal_underline_is_below_the_pictures() -> void:
	var origin := Vector2(80, 160)
	assert_gt(BoardView.underline_y(origin, 80.0), BoardView.picture_rect(origin, 80.0).end.y)
	assert_lt(BoardView.underline_y(origin, 80.0), origin.y + 80.0)


func test_pictures_are_sampled_with_mipmaps() -> void:
	# The project setting's own enum: 0 Nearest, 1 Linear, 2 Linear Mipmap, 3 Nearest Mipmap.
	assert_eq(
		ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"), 2
	)


func test_clashing_cells_are_tinted_in_the_clash_red() -> void:
	assert_eq(Color(BoardView.CLASH_FILL, 1.0), BoardView.CLASH)
	# Faint, so the animal and the shaded given cell still read through it (Juan, checkpoint 2).
	assert_between(BoardView.CLASH_FILL.a, 0.1, 0.2)


func test_clash_cells_follow_the_setting() -> void:
	var view: BoardView = autofree(BoardView.new())
	var blank := PackedInt32Array()
	blank.resize(81)
	var state := GameState.create(blank, blank, &"easy", 1)
	state.values[0] = 3
	state.values[1] = 3
	view.state = state
	assert_eq(view.clash_cells(), Rules.conflicts(state))
	assert_true(0 in view.clash_cells() and 1 in view.clash_cells())
	view.mark_clashes = false
	assert_eq(view.clash_cells(), PackedInt32Array())
