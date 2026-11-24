extends GutTest


func test_rng_matches_web() -> void:
	var rng_fixtures: Dictionary = EngineFixtures.data().rng
	for seed_text: String in rng_fixtures:
		var rng := Mulberry32.new(int(seed_text))
		for expected: float in rng_fixtures[seed_text]:
			assert_almost_eq(rng.next_float(), expected, 1e-12, "seed %s" % seed_text)


func test_shuffle_matches_web() -> void:
	var items: Array = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
	var out := Mulberry32.shuffle(items, Mulberry32.new(7))
	assert_eq(out, EngineFixtures.data().shuffle.map(func(v: float) -> int: return int(v)))
	assert_eq(items, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], "input unchanged")
