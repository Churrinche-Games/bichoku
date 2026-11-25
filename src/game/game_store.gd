class_name GameStore
extends RefCounted
## Everything Bichoku keeps between sessions, in one versioned file (the kit's SaveStore): the game
## in progress, the best time per difficulty and the settings. Undo history and the selection are
## not kept, as on the web version.

const VERSION := 1
## language: "" follows the device (see KitLanguage). Music is off by default.
const DEFAULT_SETTINGS := {
	"animals_left": true,
	"mark_clashes": true,
	"show_numbers": false,
	"language": "",
	"music": true,
	"effects": true,
	"muted": false,
}

var _store: SaveStore
var _data: Dictionary


func _init(path: String = "user://bichoku.json") -> void:
	_store = SaveStore.new(path, VERSION)
	_data = _store.load_data(_defaults())


static func _defaults() -> Dictionary:
	var best := {}
	for d in Difficulty.ALL:
		best[String(d)] = 0
	return {
		"game":
		{
			"difficulty": "",
			"seed": 0,
			"puzzle": [0],
			"solution": [0],
			"values": [0],
			"notes": [0],
			"hints_used": 0,
			"elapsed_ms": 0,
			"won": false,
		},
		"best": best,
		"settings": DEFAULT_SETTINGS.duplicate(),
	}


func save_game(s: GameState) -> void:
	_data.game = {
		"difficulty": String(s.difficulty),
		"seed": s.seed,
		"puzzle": Array(s.puzzle),
		"solution": Array(s.solution),
		"values": Array(s.values),
		"notes": Array(s.notes),
		"hints_used": s.hints_used,
		"elapsed_ms": s.elapsed_ms,
		"won": s.won,
	}
	_save()


## The saved game, or null when there is none or it doesn't make sense.
func load_game() -> GameState:
	var g: Dictionary = _data.game
	var difficulty := StringName(g.difficulty)
	if difficulty not in Difficulty.ALL:
		return null
	for key in ["puzzle", "solution", "values", "notes"]:
		if (g[key] as Array).size() != 81:
			return null
	var s := GameState.create(
		PackedInt32Array(g.puzzle), PackedInt32Array(g.solution), difficulty, g.seed
	)
	s.values = PackedInt32Array(g.values)
	s.notes = PackedInt32Array(g.notes)
	s.hints_used = g.hints_used
	s.elapsed_ms = g.elapsed_ms
	s.won = g.won
	return s


func clear_game() -> void:
	_data.game = _defaults().game
	_save()


## Records a won game; true when it set a new best (only games solved without hints count).
func record_win(s: GameState) -> bool:
	if not s.won or not Rules.counts_for_best(s):
		return false
	var key := String(s.difficulty)
	var best: int = _data.best.get(key, 0)
	if best and best <= s.elapsed_ms:
		return false
	_data.best[key] = s.elapsed_ms
	_save()
	return true


## Best time in ms, 0 when there is none yet.
func best_ms(d: StringName) -> int:
	return _data.best.get(String(d), 0)


## The saved settings, with defaults for any key an older save lacks.
func settings() -> Dictionary:
	var s := DEFAULT_SETTINGS.duplicate()
	s.merge(_data.settings, true)
	return s


func set_setting(key: String, value: Variant) -> void:
	_data.settings[key] = value
	_save()


## Starting another game would throw this one away: ask first, unless it's won or nothing was entered.
static func needs_confirm_to_discard(s: GameState) -> bool:
	if s.won:
		return false
	for c in s.values.size():
		if s.values[c] and not s.puzzle[c]:
			return true
	return false


func _save() -> void:
	var err := _store.save_data(_data)
	if err != OK:
		push_warning("Bichoku: could not save (%s)" % error_string(err))
