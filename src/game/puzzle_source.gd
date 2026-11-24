class_name PuzzleSource
extends RefCounted
## Generates puzzles in the background so "New game" is instant: one game ready per difficulty.
## take() hands over the ready game (or null if it isn't ready yet) and starts the next one.

## Emitted on the main thread when a game for that difficulty is ready to take.
signal ready(difficulty: StringName)

var _seed_source: Callable
var _mutex := Mutex.new()
## difficulty -> WorkerThreadPool task id, until someone has waited on it.
var _tasks := {}
## difficulty -> GameState ready to play (written by the worker).
var _games := {}


func _init(seed_source: Callable = Callable()) -> void:
	_seed_source = seed_source


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Methods can't be called while the object is being freed; wait on the tasks directly.
		for id: int in _tasks.values():
			WorkerThreadPool.wait_for_task_completion(id)


## Starts generating one game for the difficulty, unless one is ready or on its way.
func prepare(difficulty: StringName) -> void:
	if _tasks.has(difficulty) or _has_game(difficulty):
		return
	var seed: int = _seed_source.call() if _seed_source.is_valid() else randi()
	_tasks[difficulty] = WorkerThreadPool.add_task(_generate.bind(difficulty, seed))


## The ready game, or null when it isn't ready yet. Either way the next one is prepared.
func take(difficulty: StringName) -> GameState:
	_mutex.lock()
	var game: GameState = _games.get(difficulty)
	_games.erase(difficulty)
	_mutex.unlock()
	if game != null:
		_finish_task(difficulty)
	prepare(difficulty)
	return game


## Blocks until the difficulty's game is generated. For tests.
func wait_until_ready(difficulty: StringName) -> void:
	_finish_task(difficulty)


func _has_game(difficulty: StringName) -> bool:
	_mutex.lock()
	var has := _games.has(difficulty)
	_mutex.unlock()
	return has


## Waits on the difficulty's task (each task can be waited on once) and forgets it.
func _finish_task(difficulty: StringName) -> void:
	if _tasks.has(difficulty):
		WorkerThreadPool.wait_for_task_completion(_tasks[difficulty])
		_tasks.erase(difficulty)


func _generate(difficulty: StringName, seed: int) -> void:
	var game := GameState.new_game(difficulty, seed)
	_mutex.lock()
	_games[difficulty] = game
	_mutex.unlock()
	_announce.call_deferred(difficulty)


func _announce(difficulty: StringName) -> void:
	ready.emit(difficulty)
