extends GutTest

const CSV := "res://src/i18n/strings.csv"


func after_each() -> void:
	TranslationServer.set_locale("en")


func test_inks_match_the_spec() -> void:
	var expected := [
		"#b07d1c",
		"#6b5a4e",
		"#2f4a5c",
		"#5b3f8c",
		"#b5532a",
		"#3d6b4f",
		"#9c3d6b",
		"#7d6b4a",
		"#2a6a6e"
	]
	for d in range(1, 10):
		assert_eq(Animals.ink(d), Color(expected[d - 1]), "digit %d" % d)
	assert_eq(Animals.id(2), &"lobo_marino")
	assert_eq(Animals.initial(6), "Yc")


func _rows() -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var f := FileAccess.open(CSV, FileAccess.READ)
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() > 1:
			rows.append(row)
	return rows


func test_every_key_has_both_languages() -> void:
	var rows := _rows()
	assert_eq(Array(rows[0]), ["keys", "es", "en"])
	for row in rows:
		assert_eq(row.size(), 3, row[0])
		assert_ne(row[1].strip_edges(), "", "es " + row[0])
		assert_ne(row[2].strip_edges(), "", "en " + row[0])


func test_every_animal_has_name_and_fact_keys() -> void:
	var keys := {}
	for row in _rows():
		keys[row[0]] = true
	for d in range(1, 10):
		var id := String(Animals.id(d)).to_upper()
		assert_true(keys.has("ANIMAL_%s_NAME" % id), id)
		assert_true(keys.has("ANIMAL_%s_FACT" % id), id)


func test_spanish_uses_voseo() -> void:
	TranslationServer.set_locale("es")
	var help := tr("HELP_TEXT")
	assert_string_contains(help, "Tocá")
	assert_false(help.contains("Toca "), "no tuteo")
	TranslationServer.set_locale("en")
	assert_string_contains(tr("HELP_TEXT"), "Tap")


func test_device_locale_fallback_is_english() -> void:
	assert_eq(ProjectSettings.get_setting("internationalization/locale/fallback"), "en")
	TranslationServer.set_locale("pt_BR")
	assert_eq(tr("TOOL_UNDO"), "Undo")
	TranslationServer.set_locale("es_AR")
	assert_eq(tr("TOOL_UNDO"), "Deshacer")


func test_every_animal_has_a_texture() -> void:
	for d in range(1, 10):
		var simple := Animals.texture(d)
		assert_not_null(simple, str(d))
		assert_eq(simple.get_size(), Vector2(200, 196), str(d))
		assert_string_contains(simple.resource_path, "%s-simple.svg" % Animals.id(d))
		assert_not_null(Animals.texture(d, true), str(d))


func test_full_drawing_falls_back_to_simple() -> void:
	assert_string_contains(Animals.texture(3, true).resource_path, "pinguino-full.svg")
	assert_string_contains(Animals.texture(1, true).resource_path, "yaguarete-simple.svg")
