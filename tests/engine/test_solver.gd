extends GutTest

var shape := Shape.classic9()


func test_classic9_houses() -> void:
	assert_eq(shape.houses.size(), 27)
	for house in shape.houses:
		assert_eq(house.size(), 9)
	assert_eq(shape.houses[0], PackedInt32Array([0, 1, 2, 3, 4, 5, 6, 7, 8]))
	assert_eq(shape.houses[9], PackedInt32Array([0, 9, 18, 27, 36, 45, 54, 63, 72]))
	assert_eq(shape.houses[18], PackedInt32Array([0, 1, 2, 9, 10, 11, 18, 19, 20]))
	for c in 81:
		assert_eq(shape.cell_houses[c].size(), 3)
		assert_eq(shape.peers[c].size(), 20)


func test_solve_fixture_matches_web() -> void:
	var empty := PackedInt32Array()
	empty.resize(81)
	var solved := Solver.solve(shape, empty, Mulberry32.new(5), 20000)
	assert_eq(solved, EngineFixtures.grid(EngineFixtures.data().solve))


func _fixture(i: int) -> Dictionary:
	return EngineFixtures.data().generate[i]


func test_uniqueness() -> void:
	var puzzle := EngineFixtures.grid(_fixture(2).puzzle)
	assert_eq(Solver.uniqueness(shape, puzzle), &"unique")
	var loose := puzzle.duplicate()
	for c in 81:
		loose[c] = 0
		if Solver.uniqueness(shape, loose) == &"multiple":
			break
	assert_eq(Solver.uniqueness(shape, loose), &"multiple")
	var bad := PackedInt32Array()
	bad.resize(81)
	bad[0] = 5
	bad[1] = 5
	assert_eq(Solver.uniqueness(shape, bad), &"none")
	var empty := PackedInt32Array()
	empty.resize(81)
	assert_eq(Solver.uniqueness(shape, empty, 1), &"unknown")


func test_count_solutions() -> void:
	var puzzle := EngineFixtures.grid(_fixture(2).puzzle)
	assert_eq(Solver.count_solutions(shape, puzzle), 1)


func test_is_valid_and_complete() -> void:
	var solution := EngineFixtures.grid(_fixture(0).solution)
	assert_true(Solver.is_complete(shape, solution))
	var broken := solution.duplicate()
	broken[1] = broken[0]
	assert_false(Solver.is_valid(shape, broken))
	assert_false(Solver.is_complete(shape, broken))
	assert_true(Solver.is_valid(shape, EngineFixtures.grid(_fixture(0).puzzle)))
