extends GutTest
## The app shows its own icon and a paper splash, never Godot's.


func test_project_icon_is_the_brand_icon() -> void:
	assert_eq(ProjectSettings.get_setting("application/config/icon"), "res://src/brand/icon.svg")
	assert_not_null(load("res://src/brand/icon.svg"))


func test_boot_splash_is_plain_paper() -> void:
	assert_false(ProjectSettings.get_setting("application/boot_splash/show_image"))
	assert_eq(ProjectSettings.get_setting("application/boot_splash/bg_color"), BoardView.PAPER)
