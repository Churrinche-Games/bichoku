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
