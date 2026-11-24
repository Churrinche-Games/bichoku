class_name Mulberry32
extends RefCounted
## Seeded random numbers, identical to the web version's mulberry32, so a seed gives the same puzzle.
## JavaScript works on 32-bit integers here; values are kept in [0, 2^32) with MASK.

const MASK := 0xFFFFFFFF

var _a: int


func _init(seed: int) -> void:
	_a = seed & MASK


## Math.imul: the low 32 bits of a * b, computed in 16-bit halves so 64-bit ints never overflow.
static func imul(a: int, b: int) -> int:
	var a_hi := (a >> 16) & 0xFFFF
	var a_lo := a & 0xFFFF
	var b_hi := (b >> 16) & 0xFFFF
	var b_lo := b & 0xFFFF
	return (a_lo * b_lo + (((a_hi * b_lo + a_lo * b_hi) & 0xFFFF) << 16)) & MASK


func next_float() -> float:
	_a = (_a + 0x6D2B79F5) & MASK
	var t := _a
	t = imul(t ^ (t >> 15), t | 1)
	t = (t ^ ((t + imul(t ^ (t >> 7), t | 61)) & MASK)) & MASK
	return float((t ^ (t >> 14)) & MASK) / 4294967296.0


## A shuffled copy (Fisher-Yates from the end, as on the web).
static func shuffle(items: Array, rng: Mulberry32) -> Array:
	var out := items.duplicate()
	for i in range(out.size() - 1, 0, -1):
		var j := int(floor(rng.next_float() * (i + 1)))
		var tmp: Variant = out[i]
		out[i] = out[j]
		out[j] = tmp
	return out
