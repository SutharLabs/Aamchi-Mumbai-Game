extends CanvasLayer

signal interact_pressed
signal jump_pressed
signal reset_pressed
signal pause_pressed
signal look_dragged(relative: Vector2)

const Controls := preload("res://startup/control_bindings.gd")
const PROMPT_WIDTH := 342.0

var touch_enabled := false
var pause_enabled := false
var move_axis := Vector2.ZERO
var brake_held := false
var _status_panel: PanelContainer
var _objective := Label.new()
var _condition := Label.new()
var _speed := Label.new()
var _prompt_row := HBoxContainer.new()
var _interact_key := Label.new()
var _prompt := Label.new()
var _pause_card: PanelContainer
var _pause_hint: Label
var _using_gamepad := false
var _touch_surface: Control
var _move_finger := -1
var _look_finger := -1
var _brake_finger := -1
var _stick_radius := 67.0
var _touch_driving := false


func _ready() -> void:
	touch_enabled = Controls.uses_touch_ui()
	var canvas := Control.new()
	add_child(canvas)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_panel = _card()
	_status_panel.position = Vector2(18, 18)
	canvas.add_child(_status_panel)
	var details := VBoxContainer.new()
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_theme_constant_override("separation", 4)
	_status_panel.add_child(details)
	_objective.name = "JobObjective"
	_objective.add_theme_color_override("font_color", Color("ffe0bc"))
	_objective.add_theme_font_size_override("font_size", 17)
	details.add_child(_objective)
	_condition.name = "PlayerCondition"
	_condition.add_theme_color_override("font_color", Color("ffb8a6"))
	_condition.add_theme_font_size_override("font_size", 17)
	details.add_child(_condition)
	_speed.add_theme_color_override("font_color", Color("deebef"))
	_speed.add_theme_font_size_override("font_size", 17)
	details.add_child(_speed)
	details.add_child(_prompt_row)
	_prompt_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_row.add_theme_constant_override("separation", 8)
	_interact_key.add_theme_color_override("font_color", Color("deebef"))
	_interact_key.add_theme_font_size_override("font_size", 17)
	_prompt_row.add_child(_interact_key)
	_prompt.add_theme_color_override("font_color", Color("ffd07a"))
	_prompt.add_theme_font_size_override("font_size", 17)
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prompt_row.add_child(_prompt)
	update_display(false, 0.0, "", "", false)
	if touch_enabled:
		_touch_surface = Control.new()
		canvas.add_child(_touch_surface)
		_touch_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_touch_surface.mouse_filter = Control.MOUSE_FILTER_STOP
		_touch_surface.gui_input.connect(_touch_input)
		_touch_surface.draw.connect(_draw_touch)
	elif pause_enabled:
		_pause_card = _card()
		_pause_card.name = "PauseHint"
		canvas.add_child(_pause_card)
		_pause_hint = Label.new()
		_pause_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_pause_hint.add_theme_font_size_override("font_size", 15)
		_pause_card.add_child(_pause_hint)
		_pause_card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_pause_card.offset_top = 18.0
		_pause_card.offset_right = -18.0
	refresh_bindings()


func set_gamepad_input(active: bool) -> void:
	if not touch_enabled and _using_gamepad != active:
		_using_gamepad = active
		refresh_bindings()


func refresh_bindings() -> void:
	if touch_enabled:
		return
	var device := Controls.GAMEPAD if _using_gamepad else Controls.KEYBOARD
	_interact_key.text = Controls.label("interact", device, true)
	if _status_panel.visible:
		_status_panel.reset_size.call_deferred()
	if _pause_card != null:
		_pause_hint.text = "%s  Pause" % Controls.label("pause_game", device, true)
		var minimum := _pause_card.get_combined_minimum_size()
		_pause_card.offset_left = -18.0 - maxf(minimum.x, 94.0)
		_pause_card.offset_bottom = 18.0 + minimum.y


func _card() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var decoration := StyleBoxFlat.new()
	decoration.bg_color = Color("132433e8")
	decoration.set_corner_radius_all(5)
	decoration.content_margin_left = 10.0
	decoration.content_margin_right = 10.0
	decoration.content_margin_top = 5.0
	decoration.content_margin_bottom = 5.0
	panel.add_theme_stylebox_override("panel", decoration)
	return panel


func update_display(driving: bool, speed: float, prompt: String, vehicle_label: String, can_interact: bool,
		objective: String = "", condition: String = "") -> void:
	if touch_enabled and driving != _touch_driving:
		_touch_driving = driving
		_brake_finger = -1
		brake_held = false
		_touch_surface.queue_redraw()
	var speed_text := "%s  ·  %d km/h" % [vehicle_label, roundi(speed * 3.6)] if driving else ""
	var show_key := can_interact and not touch_enabled
	var changed := (_speed.text != speed_text or _prompt.text != prompt or _interact_key.visible != show_key
		or _objective.text != objective or _condition.text != condition)
	if _speed.text != speed_text:
		_speed.text = speed_text
	if _objective.text != objective:
		_objective.text = objective
	if _condition.text != condition:
		_condition.text = condition
	if _prompt.text != prompt:
		_prompt.text = prompt
		var font := _prompt.get_theme_font("font")
		var font_size := _prompt.get_theme_font_size("font_size")
		var text_width := font.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		_prompt.custom_minimum_size.x = minf(ceilf(text_width) + 1.0, PROMPT_WIDTH)
	_speed.visible = driving
	_objective.visible = not objective.is_empty()
	_condition.visible = not condition.is_empty()
	_prompt_row.visible = not prompt.is_empty()
	_interact_key.visible = show_key
	_status_panel.visible = driving or _prompt_row.visible or _objective.visible or _condition.visible
	if changed and _status_panel.visible:
		_status_panel.reset_size.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		clear_touch_input()


func clear_touch_input() -> void:
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
	if pause_enabled and _pause_rect().has_point(point):
		pause_pressed.emit()
	elif point.distance_to(_stick_center()) < 105.0 and _move_finger < 0:
		_move_finger = index
		_update_stick(point)
	elif _button_rect(0).has_point(point):
		interact_pressed.emit()
	elif _button_rect(1).has_point(point) and _brake_finger < 0:
		if _touch_driving:
			_brake_finger = index
			brake_held = true
			_touch_surface.queue_redraw()
		else:
			jump_pressed.emit()
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


func _pause_rect() -> Rect2:
	return Rect2(_touch_surface.size.x - 148.0, 20.0, 124.0, 53.0)


func _draw_touch() -> void:
	var center := _stick_center()
	_touch_surface.draw_circle(center, _stick_radius, Color("12232fc4"))
	_touch_surface.draw_arc(center, _stick_radius, 0.0, TAU, 36, Color("a3c4cab0"), 2.0, true)
	_touch_surface.draw_circle(center + move_axis * (_stick_radius - 16.0), 22.0, Color("6dc1cdeb"))
	var button_text := ["Interact", "Brake" if _touch_driving else "Jump", "Reset"]
	for index in range(button_text.size()):
		var color := Color("466c70db") if index == 1 and brake_held else Color("14283ae0")
		_draw_touch_button(_button_rect(index), button_text[index], color)
	if pause_enabled:
		_draw_touch_button(_pause_rect(), "Pause", Color("14283ae0"))


func _draw_touch_button(bounds: Rect2, label_text: String, color: Color) -> void:
	var font := ThemeDB.fallback_font
	_touch_surface.draw_rect(bounds, color)
	_touch_surface.draw_rect(bounds, Color("9bcdd4bc"), false, 1.5)
	var text_width := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x
	var baseline := bounds.get_center() + Vector2(-text_width * 0.5, 7.0)
	_touch_surface.draw_string(font, baseline, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color.WHITE)
