class_name Difficulty
extends RefCounted
## The three levels: by clue count for now, and how many hints each allows.

const EASY := &"easy"
const MEDIUM := &"medium"
const HARD := &"hard"
const ALL: Array[StringName] = [EASY, MEDIUM, HARD]

const _MIN_CLUES := {EASY: 40, MEDIUM: 32, HARD: 0}
const _HINTS := {EASY: 3, MEDIUM: 2, HARD: 1}


## Clues the generator stops at (0 = remove as many as it can).
static func min_clues(d: StringName) -> int:
	return _MIN_CLUES[d]


static func hints(d: StringName) -> int:
	return _HINTS[d]
