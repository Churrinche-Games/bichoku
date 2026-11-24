class_name Sheet
extends Control
## A simple modal panel over the screen (help, settings, win, confirm). The kit theme replaces the
## look later; the structure stays.

var _box: VBoxContainer


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	panel.add_child(margin)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 20)
	margin.add_child(_box)


func add_title(text: String) -> Label:
	var label := add_text(text)
	label.add_theme_font_size_override("font_size", 40)
	return label


func add_text(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(496, 0)
	_box.add_child(label)
	return label


func add_check(text: String, value: bool, on_toggle: Callable) -> CheckButton:
	var check := CheckButton.new()
	check.text = text
	check.button_pressed = value
	check.custom_minimum_size = Vector2(0, 96)
	check.toggled.connect(on_toggle)
	_box.add_child(check)
	return check


## A button that runs on_press and then closes the sheet.
func add_button(text: String, on_press: Callable = Callable()) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 96)
	button.pressed.connect(
		func() -> void:
			close()
			if on_press.is_valid():
				on_press.call()
	)
	_box.add_child(button)
	return button


func close() -> void:
	if is_inside_tree():
		get_parent().remove_child(self)
	queue_free()
