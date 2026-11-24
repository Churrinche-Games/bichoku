class_name Solver
extends RefCounted
## Backtracking over bitmasks, a port of the web solver. At each step it branches on the smaller of:
## the empty cell with the fewest candidates, or a digit missing from a house with the fewest
## places left (the exact-cover heuristic). Same order of work as the web, so seeds give the same
## results.


class _Search:
	var shape: Shape
	var used: PackedInt32Array
	var values: PackedInt32Array
	var empty := PackedInt32Array()
	var cand: PackedInt32Array
	var full: int
	var limit: int
	var max_nodes: int
	var rng: Mulberry32
	var nodes := 0
	var count := 0
	var first := PackedInt32Array()
	var aborted := false

	func _init(
		s: Shape, grid: PackedInt32Array, search_limit: int, random: Mulberry32, budget: int
	) -> void:
		shape = s
		values = grid.duplicate()
		limit = search_limit
		rng = random
		max_nodes = budget
		full = (1 << s.size) - 1
		used.resize(s.houses.size())
		cand.resize(values.size())

	func run() -> void:
		for c in values.size():
			var v := values[c]
			if v == 0:
				empty.append(c)
				continue
			var bit := 1 << (v - 1)
			for h in shape.cell_houses[c]:
				if used[h] & bit:
					return
				used[h] |= bit
		_rec()

	func _candidates(c: int) -> int:
		var mask := 0
		for h in shape.cell_houses[c]:
			mask |= used[h]
		return full & ~mask

	func _rec() -> void:
		nodes += 1
		if max_nodes >= 0 and nodes > max_nodes:
			aborted = true
			return
		var choice := _best_cell()
		if choice.is_empty():
			count += 1
			if first.is_empty():
				first = values.duplicate()
			return
		var best: int = choice[0]
		var best_mask: int = choice[1]
		var best_count: int = choice[2]
		if best_count == 0:
			return
		var house_best := -1
		var house_bit := 0
		if best_count > 1:
			var found := _best_house(best_count)
			if found.is_empty():
				return
			house_best = found[0]
			house_bit = found[1]
		var branches: Array = []
		if house_best >= 0:
			var d := _bit_index(house_bit) + 1
			for c in shape.houses[house_best]:
				if values[c] == 0 and cand[c] & house_bit:
					branches.append([c, d])
		else:
			for d in range(1, shape.size + 1):
				if best_mask & (1 << (d - 1)):
					branches.append([best, d])
		if rng != null:
			branches = Mulberry32.shuffle(branches, rng)
		for branch: Array in branches:
			var c: int = branch[0]
			var bit := 1 << (int(branch[1]) - 1)
			values[c] = branch[1]
			for h in shape.cell_houses[c]:
				used[h] |= bit
			_rec()
			for h in shape.cell_houses[c]:
				used[h] &= ~bit
			values[c] = 0
			if count >= limit or aborted:
				return

	## [cell, mask, count] of the empty cell with the fewest candidates; [] when none is empty.
	## Also fills cand[] for every empty cell.
	func _best_cell() -> Array:
		var best := -1
		var best_mask := 0
		var best_count := 1 << 30
		var open := 0
		for c in empty:
			if values[c] != 0:
				continue
			open += 1
			var mask := _candidates(c)
			cand[c] = mask
			var n := _popcount(mask)
			if n < best_count:
				best = c
				best_mask = mask
				best_count = n
		if open == 0:
			return []
		return [best, best_mask, best_count]

	## [house, bit] of a missing digit with fewer places than best_count, [-1, 0] when there is none,
	## or [] for a dead end (a missing digit with no place at all).
	func _best_house(best_count: int) -> Array:
		var house_best := -1
		var house_bit := 0
		for h in shape.houses.size():
			var missing := full & ~used[h]
			if missing == 0:
				continue
			var bit := 1
			while bit <= missing:
				if missing & bit:
					var n := 0
					for c in shape.houses[h]:
						if values[c] == 0 and cand[c] & bit:
							n += 1
					if n == 0:
						return []
					if n < best_count:
						best_count = n
						house_best = h
						house_bit = bit
						if n == 1:
							break
				bit <<= 1
			if best_count == 1:
				break
		return [house_best, house_bit]

	static func _popcount(n: int) -> int:
		var total := 0
		while n:
			n &= n - 1
			total += 1
		return total

	static func _bit_index(bit: int) -> int:
		var i := 0
		while bit > 1:
			bit >>= 1
			i += 1
		return i


static func _search(
	shape: Shape, grid: PackedInt32Array, limit: int, rng: Mulberry32, max_nodes: int
) -> _Search:
	var s := _Search.new(shape, grid, limit, rng, max_nodes)
	s.run()
	return s


## One solution, or an empty array when there is none or the search gave up (max_nodes < 0: no limit).
static func solve(
	shape: Shape, grid: PackedInt32Array, rng: Mulberry32 = null, max_nodes: int = -1
) -> PackedInt32Array:
	var s := _search(shape, grid, 1, rng, max_nodes)
	return PackedInt32Array() if s.aborted else s.first


## Number of solutions, counting no further than limit.
static func count_solutions(shape: Shape, grid: PackedInt32Array, limit: int = 2) -> int:
	return _search(shape, grid, limit, null, -1).count


## &"unique", &"multiple", &"none", or &"unknown" when the search ran past max_nodes first.
static func uniqueness(shape: Shape, grid: PackedInt32Array, max_nodes: int = -1) -> StringName:
	var s := _search(shape, grid, 2, null, max_nodes)
	if s.count >= 2:
		return &"multiple"
	if s.aborted:
		return &"unknown"
	return &"unique" if s.count == 1 else &"none"


## No digit twice in any house (empty cells allowed).
static func is_valid(shape: Shape, grid: PackedInt32Array) -> bool:
	for house in shape.houses:
		var seen := 0
		for c in house:
			var v := grid[c]
			if v == 0:
				continue
			var bit := 1 << (v - 1)
			if seen & bit:
				return false
			seen |= bit
	return true


static func is_complete(shape: Shape, grid: PackedInt32Array) -> bool:
	if grid.size() != shape.cell_count:
		return false
	for v in grid:
		if v < 1 or v > shape.size:
			return false
	return is_valid(shape, grid)
