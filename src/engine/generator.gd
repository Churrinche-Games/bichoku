class_name Generator
extends RefCounted
## Fill the shape with a random solution, then remove clues one at a time in random order, putting a
## clue back whenever removing it would allow a second solution. A port of the web generator.


## {"puzzle": PackedInt32Array, "solution": PackedInt32Array}. min_clues stops early (easier puzzles).
## A uniqueness check that runs past check_nodes keeps its clue, so the puzzle is always unique.
static func generate(
	shape: Shape, seed: int, min_clues: int = 0, check_nodes: int = 5000
) -> Dictionary:
	var rng := Mulberry32.new(seed)
	# A random fill sometimes wanders into a huge dead end; many short tries beat one long one.
	var empty := PackedInt32Array()
	empty.resize(shape.cell_count)
	var solution := PackedInt32Array()
	var attempt := 0
	while solution.is_empty() and attempt < 100:
		solution = Solver.solve(shape, empty, rng, 20000)
		attempt += 1
	if solution.is_empty():
		push_error("could not fill the shape")
		return {}
	var puzzle := solution.duplicate()
	var clues := puzzle.size()
	for c: int in Mulberry32.shuffle(range(shape.cell_count), rng):
		if clues <= min_clues:
			break
		var v := puzzle[c]
		puzzle[c] = 0
		if Solver.uniqueness(shape, puzzle, check_nodes) == &"unique":
			clues -= 1
		else:
			puzzle[c] = v
	return {"puzzle": puzzle, "solution": solution}
