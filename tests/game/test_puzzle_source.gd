extends GutTest

var _next_seed := 100


func _seeds() -> int:
	_next_seed += 1
	return _next_seed


func _source() -> PuzzleSource:
	_next_seed = 100
	return PuzzleSource.new(_seeds)


func test_take_before_ready_returns_null_then_ready() -> void:
	var source := _source()
	watch_signals(source)
	assert_null(source.take(Difficulty.EASY))
	source.wait_until_ready(Difficulty.EASY)
	await wait_for_signal(source.ready, 2)
	assert_signal_emitted_with_parameters(source.ready, [Difficulty.EASY])
	var game := source.take(Difficulty.EASY)
	assert_not_null(game)
	var expected := Generator.generate(Shape.classic9(), 101, 40)
	assert_eq(game.puzzle, expected.puzzle)
	assert_eq(game.difficulty, Difficulty.EASY)
	assert_eq(game.seed, 101)


func test_take_prepares_the_next() -> void:
	var source := _source()
	source.prepare(Difficulty.MEDIUM)
	source.wait_until_ready(Difficulty.MEDIUM)
	var first := source.take(Difficulty.MEDIUM)
	assert_not_null(first)
	source.wait_until_ready(Difficulty.MEDIUM)
	var second := source.take(Difficulty.MEDIUM)
	assert_not_null(second)
	assert_ne(first.seed, second.seed)


func test_difficulties_are_independent() -> void:
	var source := _source()
	source.prepare(Difficulty.HARD)
	source.wait_until_ready(Difficulty.HARD)
	assert_null(source.take(Difficulty.EASY))
	assert_not_null(source.take(Difficulty.HARD))


func test_prepare_twice_starts_one_job() -> void:
	var source := _source()
	source.prepare(Difficulty.EASY)
	source.prepare(Difficulty.EASY)
	source.wait_until_ready(Difficulty.EASY)
	assert_eq(_next_seed, 101, "one seed used")


func test_without_threads_generation_waits_for_the_next_frame() -> void:
	_next_seed = 100
	var source := PuzzleSource.new(_seeds, false)
	source.prepare(Difficulty.EASY)
	assert_null(source.take(Difficulty.EASY), "not generated inside the call")
	await wait_process_frames(2)
	assert_not_null(source.take(Difficulty.EASY))
