extends GutTest

const SIZES := [Vector2(720, 1280), Vector2(720, 1600), Vector2(960, 1280), Vector2(2276, 1280)]


func test_board_side_fits() -> void:
	for size: Vector2 in SIZES:
		var column := BoardLayout.column_width(size)
		assert_eq(column, minf(size.x, 720.0), str(size))
		assert_eq(BoardLayout.board_side(size, 560.0), minf(column, size.y - 560.0), str(size))
		assert_eq(BoardLayout.column_left(size), (size.x - column) / 2.0, "centred " + str(size))


func test_board_side_never_negative() -> void:
	assert_eq(BoardLayout.board_side(Vector2(720, 300), 560.0), 0.0)
