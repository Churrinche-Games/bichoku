class_name EngineFixtures
extends RefCounted
## The web engine's outputs (tools/fixtures/make_engine_fixtures.mjs), for parity tests.

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var text := FileAccess.get_file_as_string("res://tests/engine/fixtures.json")
		_data = JSON.parse_string(text)
	return _data


static func grid(values: Array) -> PackedInt32Array:
	var out := PackedInt32Array()
	for v: Variant in values:
		out.append(int(v))
	return out
