extends CanvasLayer

signal interact_pressed
signal reset_pressed
signal look_dragged(relative: Vector2)

var touch_enabled := false
var move_axis := Vector2.ZERO
var brake_held := false
var _mode := Label.new()
var _prompt := Label.new()
var _help := Label.new()
var _touch_surface: Control
var _move_finger := -1
var _look_finger := -1
var _brake_finger := -1
var _stick_radius := 67.0


func _ready() -> void:
	touch_enabled = OS.has_feature("mobile") or "--touch-preview" in OS.get_cmdline_user_args()
	var canvas := Control.new()
	add_child(canvas)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.position = Vector2(22, 20)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var decoration := StyleBoxFlat.new()
	decoration.bg_color = Color("132433e8")
	decoration.border_color = Color("d8a145")
	decoration.border_width_left = 4
	decoration.corner_radius_top_right = 8
	decoration.corner_radius_bottom_right = 8
	decoration.content_margin_left = 16.0
	decoration.content_margin_right = 17.0
	decoration.content_margin_top = 12.0
	decoration.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", decoration)
	canvas.add_child(panel)
	var details := VBoxContainer.new()
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_theme_constant_override("separation", 4)
	panel.add_child(details)
	var title := Label.new()
	title.text = "Aamchi Mumbai Game"
	title.add_theme_font_size_override("font_size", 25)
	details.add_child(title)
	_mode.add_theme_color_override("font_color", Color("b6c7d6"))
	_mode.add_theme_font_size_override("font_size", 16)
	details.add_child(_mode)
	_prompt.add_theme_color_override("font_color", Color("ffd07a"))
	_prompt.add_theme_font_size_override("font_size", 19)
	details.add_child(_prompt)
	_help.add_theme_color_override("font_color", Color("deebef"))
	_help.add_theme_font_size_override("font_size", 15)
	details.add_child(_help)
	var credit := Label.new()
	credit.text = "Map data © OpenStreetMap contributors"
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	credit.add_theme_font_size_override("font_size", 13)
	credit.add_theme_color_override("font_color", Color("e3eced"))
	credit.add_theme_color_override("font_outline_color", Color("10212c"))
	credit.add_theme_constant_override("outline_size", 5)
	canvas.add_child(credit)
	credit.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	credit.offset_left = -300
	credit.offset_right = -18
	credit.offset_top = 20
	update_display(false, 0.0, "Walk up to a parked vehicle", "")
	if touch_enabled:
		_touch_surface = Control.new()
		canvas.add_child(_touch_surface)
		_touch_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_touch_surface.mouse_filter = Control.MOUSE_FILTER_STOP
		_touch_surface.gui_input.connect(_touch_input)
		_touch_surface.draw.connect(_draw_touch)


func update_display(driving: bool, speed: float, prompt: String, vehicle_label: String) -> void:
	var mode := "Ranwar practice route  /  On foot"
	if driving:
		mode = "%s  /  %d km/h" % [vehicle_label, roundi(speed * 3.6)]
	if _mode.text != mode:
		_mode.text = mode
	if _prompt.text != prompt:
		_prompt.text = prompt
	var help := "WASD / Arrows  Move     Mouse  Look     E  Interact     R  Reset"
	if driving:
		help = "WASD / Arrows  Drive     Space  Brake     E  Exit when stopped     R  Reset"
	if touch_enabled:
		help = "Left stick  Drive     Right area  Look" if driving else "Left stick  Walk     Right area  Look"
	if _help.text != help:
		_help.text = help


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_move_finger = -1
		_look_finger = -1
		_brake_finger = -1
		move_axis = Vector2.ZERO
		brake_held = false
		if is_instance_valid(_touch_surface) and _touch_surface.is_inside_tree():
			_touch_surface.queue_redraw()


func _touch_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_touch(event.index, event.position)
		else:
			_end_touch(event.index)
	elif event is InputEventScreenDrag:
		if event.index == _move_finger:
			_update_stick(event.position)
		elif event.index == _look_finger:
			look_dragged.emit(event.relative)


func _start_touch(index: int, point: Vector2) -> void:
	if point.distance_to(_stick_center()) < 105.0 and _move_finger < 0:
		_move_finger = index
		_update_stick(point)
	elif _button_rect(0).has_point(point):
		interact_pressed.emit()
	elif _button_rect(1).has_point(point) and _brake_finger < 0:
		_brake_finger = index
		brake_held = true
		_touch_surface.queue_redraw()
	elif _button_rect(2).has_point(point):
		reset_pressed.emit()
	elif point.x > _touch_surface.size.x * 0.45 and _look_finger < 0:
		_look_finger = index


func _end_touch(index: int) -> void:
	if index == _move_finger:
		_move_finger = -1
		move_axis = Vector2.ZERO
	elif index == _look_finger:
		_look_finger = -1
	elif index == _brake_finger:
		_brake_finger = -1
		brake_held = false
	_touch_surface.queue_redraw()


func _update_stick(point: Vector2) -> void:
	var axis := (point - _stick_center()) / _stick_radius
	move_axis = axis.limit_length() if axis.length() > 0.12 else Vector2.ZERO
	_touch_surface.queue_redraw()


func _stick_center() -> Vector2:
	return Vector2(121.0, _touch_surface.size.y - 126.0)


func _button_rect(index: int) -> Rect2:
	return Rect2(_touch_surface.size.x - 148.0, _touch_surface.size.y - 79.0 - index * 67.0, 124.0, 53.0)


func _draw_touch() -> void:
	var center := _stick_center()
	_touch_surface.draw_circle(center, _stick_radius, Color("12232fc4"))
	_touch_surface.draw_arc(center, _stick_radius, 0.0, TAU, 36, Color("a3c4cab0"), 2.0, true)
	_touch_surface.draw_circle(center + move_axis * (_stick_radius - 16.0), 22.0, Color("6dc1cdeb"))
	var button_text := ["Interact", "Brake", "Reset"]
	var font := ThemeDB.fallback_font
	for index in range(button_text.size()):
		var bounds := _button_rect(index)
		var color := Color("466c70db") if index == 1 and brake_held else Color("14283ae0")
		_touch_surface.draw_rect(bounds, color)
		_touch_surface.draw_rect(bounds, Color("9bcdd4bc"), false, 1.5)
		var label_text: String = button_text[index]
		var text_width := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x
		var baseline := bounds.get_center() + Vector2(-text_width * 0.5, 7.0)
		_touch_surface.draw_string(font, baseline, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color.WHITE)
