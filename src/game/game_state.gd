class_name GameState
extends RefCounted
## One game of Bichoku. Rules never change a GameState; they return a new one.

var difficulty: StringName
var seed: int
var puzzle: PackedInt32Array
var solution: PackedInt32Array
var values: PackedInt32Array
## Pencil marks per cell: bit d - 1 set for digit d.
var notes: PackedInt32Array
## Selected cell, or -1.
var selected := -1
var notes_mode := false
## Earlier {"values", "notes"} snapshots, oldest first.
var history: Array[Dictionary] = []
var hints_used := 0
var elapsed_ms := 0
var won := false


static func create(
	game_puzzle: PackedInt32Array,
	game_solution: PackedInt32Array,
	game_difficulty: StringName,
	game_seed: int
) -> GameState:
	var s := GameState.new()
	s.difficulty = game_difficulty
	s.seed = game_seed
	s.puzzle = game_puzzle.duplicate()
	s.solution = game_solution.duplicate()
	s.values = game_puzzle.duplicate()
	s.notes = PackedInt32Array()
	s.notes.resize(game_puzzle.size())
	return s


## A new game from the generator: the same seed and difficulty always give the same puzzle.
static func new_game(game_difficulty: StringName, game_seed: int) -> GameState:
	var g := Generator.generate(Shape.classic9(), game_seed, Difficulty.min_clues(game_difficulty))
	return create(g.puzzle, g.solution, game_difficulty, game_seed)


func duplicate_state() -> GameState:
	var s := GameState.new()
	s.difficulty = difficulty
	s.seed = seed
	s.puzzle = puzzle.duplicate()
	s.solution = solution.duplicate()
	s.values = values.duplicate()
	s.notes = notes.duplicate()
	s.selected = selected
	s.notes_mode = notes_mode
	s.history = history.duplicate(true)
	s.hints_used = hints_used
	s.elapsed_ms = elapsed_ms
	s.won = won
	return s
