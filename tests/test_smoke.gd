extends GutTest


func test_kit_is_vendored() -> void:
	assert_ne(ChurrincheKit.VERSION, "")


func test_main_scene_loads() -> void:
	var scene := load(ProjectSettings.get_setting("application/run/main_scene")) as PackedScene
	assert_not_null(scene)
	var main := scene.instantiate()
	main.store_path = "user://test_smoke/store.json"
	add_child_autofree(main)
	assert_not_null(main)
