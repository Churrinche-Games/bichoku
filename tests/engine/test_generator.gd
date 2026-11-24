extends GutTest

var shape := Shape.classic9()


func test_generate_matches_web() -> void:
	for f: Dictionary in EngineFixtures.data().generate:
		var started := Time.get_ticks_msec()
		var out := Generator.generate(shape, int(f.seed), int(f.minClues))
		gut.p("seed %d min_clues %d: %d ms" % [f.seed, f.minClues, Time.get_ticks_msec() - started])
		assert_eq(out.solution, EngineFixtures.grid(f.solution), "solution seed %d" % f.seed)
		assert_eq(
			out.puzzle,
			EngineFixtures.grid(f.puzzle),
			"puzzle seed %d min %d" % [f.seed, f.minClues]
		)


func test_generated_puzzles_are_unique() -> void:
	for f: Dictionary in EngineFixtures.data().generate:
		assert_eq(Solver.uniqueness(shape, EngineFixtures.grid(f.puzzle)), &"unique")
