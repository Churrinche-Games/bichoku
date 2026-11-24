class_name Rules
extends RefCounted
## The game's rules, a port of the web version's game.ts. Every action returns a new GameState (or the
## same one when nothing changes) and never modifies the one it was given.

static var _shape: Shape


static func shape() -> Shape:
	if _shape == null:
		_shape = Shape.classic9()
	return _shape


static func select(s: GameState, cell: int) -> GameState:
	var next := s.duplicate_state()
	next.selected = cell
	return next


static func toggle_notes(s: GameState) -> GameState:
	var next := s.duplicate_state()
	next.notes_mode = not s.notes_mode
	return next


static func tick(s: GameState, ms: int) -> GameState:
	if s.won:
		return s
	var next := s.duplicate_state()
	next.elapsed_ms += ms
	return next


static func input(s: GameState, digit: int) -> GameState:
	if s.won or not _editable(s):
		return s
	var cell := s.selected
	if s.notes_mode:
		if s.values[cell]:
			return s
		var next := _with_snapshot(s)
		next.notes[cell] ^= 1 << (digit - 1)
		return next
	if s.values[cell] == digit:
		return s
	return _place(s, cell, digit)


static func erase(s: GameState) -> GameState:
	if s.won or not _editable(s):
		return s
	var cell := s.selected
	if not s.values[cell] and not s.notes[cell]:
		return s
	var next := _with_snapshot(s)
	next.values[cell] = 0
	next.notes[cell] = 0
	return next


static func undo(s: GameState) -> GameState:
	if s.won or s.history.is_empty():
		return s
	var next := s.duplicate_state()
	var last: Dictionary = next.history.pop_back()
	next.values = last.values
	next.notes = last.notes
	return next


## Fills the selected cell if it is empty or wrong; otherwise fixes the first wrong value, or else
## fills the empty cell with the fewest options. Limited per game by the difficulty.
static func hint(s: GameState) -> GameState:
	if s.won or hints_left(s) <= 0:
		return s
	var target := -1
	if s.selected >= 0 and s.values[s.selected] != s.solution[s.selected]:
		target = s.selected
	if target < 0:
		for c in s.values.size():
			if s.values[c] and s.values[c] != s.solution[c]:
				target = c
				break
	if target < 0:
		var best := 1 << 30
		for c in s.values.size():
			if s.values[c]:
				continue
			var seen := 0
			for p in shape().peers[c]:
				if s.values[p]:
					seen |= 1 << (s.values[p] - 1)
			var options := 9 - _popcount(seen)
			if options < best:
				best = options
				target = c
	if target < 0:
		return s
	var next := _place(s, target, s.solution[target])
	next.selected = target
	next.hints_used += 1
	return next


static func hints_left(s: GameState) -> int:
	return maxi(0, Difficulty.hints(s.difficulty) - s.hints_used)


## Only games solved without hints can set a best time.
static func counts_for_best(s: GameState) -> bool:
	return s.hints_used == 0


## Cells whose animal appears twice in one of their houses, ascending.
static func conflicts(s: GameState) -> PackedInt32Array:
	var bad := {}
	for house in shape().houses:
		var by_value := {}
		for c in house:
			var v := s.values[c]
			if v:
				if by_value.has(v):
					bad[c] = true
					bad[by_value[v]] = true
				else:
					by_value[v] = c
	var out := PackedInt32Array(bad.keys())
	out.sort()
	return out


## How many of each animal are still to place, index digit - 1.
static func remaining(s: GameState) -> PackedInt32Array:
	var left := PackedInt32Array([9, 9, 9, 9, 9, 9, 9, 9, 9])
	for v in s.values:
		if v:
			left[v - 1] -= 1
	return left


static func _editable(s: GameState) -> bool:
	return s.selected >= 0 and not s.puzzle[s.selected]


static func _with_snapshot(s: GameState) -> GameState:
	var next := s.duplicate_state()
	next.history.append({"values": s.values.duplicate(), "notes": s.notes.duplicate()})
	return next


## Puts a digit in a cell: clears its notes and drops the digit from the notes of its peers.
static func _place(s: GameState, cell: int, digit: int) -> GameState:
	var next := _with_snapshot(s)
	next.values[cell] = digit
	next.notes[cell] = 0
	if digit:
		for p in shape().peers[cell]:
			next.notes[p] &= ~(1 << (digit - 1))
	next.won = next.values == next.solution
	return next


static func _popcount(n: int) -> int:
	var total := 0
	while n:
		n &= n - 1
		total += 1
	return total
