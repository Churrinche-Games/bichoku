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


func test_entered_animals_are_drawn_smaller_than_givens() -> void:
	var origin := Vector2(80, 160)
	var given := BoardView.picture_rect(origin, 80.0, true)
	var entered := BoardView.picture_rect(origin, 80.0, false)
	assert_gt(given.size.x, entered.size.x)
	for r: Rect2 in [given, entered]:
		assert_almost_eq(r.get_center(), origin + Vector2(40, 40), Vector2(0.5, 0.5))
		assert_almost_eq(r.size.x / r.size.y, 200.0 / 196.0, 0.01)
		assert_true(Rect2(origin, Vector2(80, 80)).encloses(r))


func test_same_animal_underline_is_below_the_pictures() -> void:
	var origin := Vector2(80, 160)
	assert_gt(BoardView.underline_y(origin, 80.0), BoardView.picture_rect(origin, 80.0, true).end.y)
	assert_lt(BoardView.underline_y(origin, 80.0), origin.y + 80.0)


func test_pictures_are_sampled_with_mipmaps() -> void:
	# The project setting's own enum: 0 Nearest, 1 Linear, 2 Linear Mipmap, 3 Nearest Mipmap.
	assert_eq(
		ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"), 2
	)
