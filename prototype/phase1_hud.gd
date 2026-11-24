extends CanvasLayer

signal interact_pressed
signal jump_pressed
signal reset_pressed
signal pause_pressed
signal look_dragged(relative: Vector2)

const Controls := preload("res://startup/control_bindings.gd")
const MapView := preload("res://startup/ranwar_map.gd")
const StatusView := preload("res://startup/player_status.gd")
const PROMPT_WIDTH := 342.0
const OBJECTIVE_WIDTH := 372.0
const HUD_MARGIN := 24.0
const TOUCH_DOCK_CLEARANCE := 225.0
const TOUCH_RUN_ENTER := 0.92
const TOUCH_RUN_EXIT := 0.83

var touch_enabled := false
var pause_enabled := false
var move_axis := Vector2.ZERO
var run_held := false
var brake_held := false
var _objective_panel: PanelContainer
var _speed_panel: PanelContainer
var _prompt_panel: PanelContainer
var _objective := Label.new()
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
var _canvas: Control
var _navigation_dock: VBoxContainer
var _live_map := MapView.new()
var _player_status := StatusView.new()
var _live_map_enabled := true
var _arrival_intro := false


func _ready() -> void:
	touch_enabled = Controls.uses_touch_ui()
	_canvas = Control.new()
	add_child(_canvas)
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_navigation_dock()
	_objective_panel = _card(true)
	_objective_panel.name = "ObjectiveCard"
	_canvas.add_child(_objective_panel)
	var details := VBoxContainer.new()
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_theme_constant_override("separation", 4)
	_objective_panel.add_child(details)
	var district := Label.new()
	district.text = "RANWAR / BANDRA WEST"
	district.add_theme_color_override("font_color", Color("f3c684"))
	district.add_theme_font_size_override("font_size", 13)
	details.add_child(district)
	_objective.name = "JobObjective"
	_objective.add_theme_color_override("font_color", Color("f9f1e3"))
	_objective.add_theme_font_size_override("font_size", 18)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(_objective)
	_speed_panel = _card()
	_speed_panel.name = "SpeedCard"
	_canvas.add_child(_speed_panel)
	_speed.add_theme_color_override("font_color", Color("deebef"))
	_speed.add_theme_font_size_override("font_size", 17)
	_speed_panel.add_child(_speed)
	_prompt_panel = _card()
	_prompt_panel.name = "InteractionCard"
	_canvas.add_child(_prompt_panel)
	_prompt_panel.add_child(_prompt_row)
	_prompt_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_row.add_theme_constant_override("separation", 10)
	var hint := PanelContainer.new()
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var key_background := StyleBoxFlat.new()
	key_background.bg_color = Color("f3c684")
	key_background.set_corner_radius_all(4)
	key_background.content_margin_left = 7.0
	key_background.content_margin_right = 7.0
	hint.add_theme_stylebox_override("panel", key_background)
	_interact_key.add_theme_color_override("font_color", Color("1b1410"))
	_interact_key.add_theme_font_size_override("font_size", 15)
	hint.add_child(_interact_key)
	_prompt_row.add_child(hint)
	_prompt.add_theme_color_override("font_color", Color("f9f1e3"))
	_prompt.add_theme_font_size_override("font_size", 17)
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prompt_row.add_child(_prompt)
	_canvas.resized.connect(_layout_hud_cards)
	_objective_panel.minimum_size_changed.connect(func(): _layout_hud_cards.call_deferred())
	_prompt_panel.minimum_size_changed.connect(func(): _layout_hud_cards.call_deferred())
	update_display(false, 0.0, "", "", false)
	if touch_enabled:
		_touch_surface = Control.new()
		_canvas.add_child(_touch_surface)
		_touch_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_touch_surface.mouse_filter = Control.MOUSE_FILTER_STOP
		_touch_surface.gui_input.connect(_touch_input)
		_touch_surface.draw.connect(_draw_touch)
	elif pause_enabled:
		_pause_card = _card()
		_pause_card.name = "PauseHint"
		_canvas.add_child(_pause_card)
		_pause_hint = Label.new()
		_pause_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_pause_hint.add_theme_font_size_override("font_size", 15)
		_pause_card.add_child(_pause_hint)
		_pause_card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_pause_card.offset_top = 18.0
		_pause_card.offset_right = -18.0
	refresh_bindings()


func _build_navigation_dock() -> void:
	_navigation_dock = VBoxContainer.new()
	_navigation_dock.name = "NavigationDock"
	_navigation_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_navigation_dock.add_theme_constant_override("separation", 6)
	_canvas.add_child(_navigation_dock)
	_live_map.name = "LiveMap"
	_live_map.live = true
	_navigation_dock.add_child(_live_map)
	_live_map.visible = _live_map_enabled
	_player_status.name = "PlayerStatus"
	_navigation_dock.add_child(_player_status)
	_canvas.resized.connect(_layout_navigation_dock)
	_navigation_dock.resized.connect(_layout_navigation_dock)
	_navigation_dock.minimum_size_changed.connect(func() -> void: _layout_navigation_dock.call_deferred())
	_layout_navigation_dock.call_deferred()


func _layout_navigation_dock() -> void:
	_navigation_dock.size = _navigation_dock.get_combined_minimum_size()
	var bottom := TOUCH_DOCK_CLEARANCE if touch_enabled else HUD_MARGIN
	_navigation_dock.position = _canvas.size - _navigation_dock.size - Vector2(HUD_MARGIN, bottom)


func set_live_map_enabled(enabled: bool) -> void:
	_live_map_enabled = enabled
	_live_map.visible = enabled


func set_arrival_intro(active: bool) -> void:
	_arrival_intro = active
	_navigation_dock.visible = not active
	clear_touch_input()


func set_map_geometry(roads: Array[PackedVector3Array], footway: PackedVector3Array,
		points: PackedVector3Array = PackedVector3Array()) -> void:
	_live_map.set_geometry(roads, footway, points)


func update_live_map(actor_position: Vector3, forward: Vector3, destination: Vector3 = Vector3.INF) -> void:
	if _live_map_enabled:
		_live_map.set_tracking(actor_position, forward, destination)


func update_player_status(health: float, wanted: int, cash: int, vehicle: int = -1) -> void:
	_player_status.set_values(health, wanted, cash, vehicle)


func set_gamepad_input(active: bool) -> void:
	if not touch_enabled and _using_gamepad != active:
		_using_gamepad = active
		refresh_bindings()


func refresh_bindings() -> void:
	if touch_enabled:
		return
	var device := Controls.GAMEPAD if _using_gamepad else Controls.KEYBOARD
	_interact_key.text = Controls.label("interact", device, true)
	_layout_hud_cards.call_deferred()
	if _pause_card != null:
		_pause_hint.text = "%s  Pause" % Controls.label("pause_game", device, true)
		var minimum := _pause_card.get_combined_minimum_size()
		_pause_card.offset_left = -18.0 - maxf(minimum.x, 94.0)
		_pause_card.offset_bottom = 18.0 + minimum.y


func _card(accented := false) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var decoration := StyleBoxFlat.new()
	decoration.bg_color = Color("11202ff0")
	decoration.border_color = Color("f3c684") if accented else Color("405268")
	decoration.border_width_left = 3 if accented else 1
	decoration.border_width_right = 0 if accented else 1
	decoration.border_width_top = 0 if accented else 1
	decoration.border_width_bottom = 0 if accented else 1
	decoration.set_corner_radius_all(6)
	decoration.content_margin_left = 12.0
	decoration.content_margin_right = 12.0
	decoration.content_margin_top = 7.0
	decoration.content_margin_bottom = 7.0
	panel.add_theme_stylebox_override("panel", decoration)
	return panel


func update_display(driving: bool, speed: float, prompt: String, vehicle_label: String, can_interact: bool,
		objective: String = "") -> void:
	if touch_enabled and driving != _touch_driving:
		_touch_driving = driving
		_brake_finger = -1
		brake_held = false
		run_held = false
		_touch_surface.queue_redraw()
	var speed_text := "%s  ·  %d km/h" % [vehicle_label, roundi(speed * 3.6)] if driving else ""
	var show_key := can_interact and not touch_enabled
	var hint := _interact_key.get_parent() as PanelContainer
	var changed := (_speed.text != speed_text or _prompt.text != prompt or hint.visible != show_key
		or _objective.text != objective)
	if _speed.text != speed_text:
		_speed.text = speed_text
	if _objective.text != objective:
		_objective.text = objective
	if _prompt.text != prompt:
		_prompt.text = prompt
	_speed_panel.visible = driving
	_objective_panel.visible = not objective.is_empty()
	_prompt_panel.visible = not prompt.is_empty()
	hint.visible = show_key
	if changed:
		_layout_hud_cards.call_deferred()


func _layout_hud_cards() -> void:
	var objective_width := minf(OBJECTIVE_WIDTH, _canvas.size.x * 0.48)
	var prompt_width := minf(PROMPT_WIDTH, maxf(_canvas.size.x - (410.0 if touch_enabled else 120.0), 160.0))
	_size_wrapped_label(_objective, objective_width)
	_size_wrapped_label(_prompt, prompt_width)
	_objective_panel.size = _objective_panel.get_combined_minimum_size()
	_objective_panel.position = Vector2(HUD_MARGIN, HUD_MARGIN)
	_speed_panel.size = _speed_panel.get_combined_minimum_size()
	var above := _objective_panel.size.y + 6.0 if _objective_panel.visible else 0.0
	_speed_panel.position = Vector2(HUD_MARGIN, HUD_MARGIN + above)
	_prompt_panel.size = _prompt_panel.get_combined_minimum_size()
	_prompt_panel.position = Vector2((_canvas.size.x - _prompt_panel.size.x) * 0.5,
		_canvas.size.y - _prompt_panel.size.y - HUD_MARGIN)


func _size_wrapped_label(label: Label, width: float) -> void:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var text_width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	label.custom_minimum_size.x = minf(ceilf(text_width) + 1.0, width)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		clear_touch_input()


func clear_touch_input() -> void:
	_move_finger = -1
	_look_finger = -1
	_brake_finger = -1
	move_axis = Vector2.ZERO
	run_held = false
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
	elif _arrival_intro:
		if _button_rect(0).has_point(point):
			interact_pressed.emit()
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
		run_held = false
	elif index == _look_finger:
		_look_finger = -1
	elif index == _brake_finger:
		_brake_finger = -1
		brake_held = false
	_touch_surface.queue_redraw()


func _update_stick(point: Vector2) -> void:
	var axis := (point - _stick_center()) / _stick_radius
	var magnitude := axis.length()
	move_axis = axis.limit_length() if magnitude > 0.12 else Vector2.ZERO
	var run_threshold := TOUCH_RUN_EXIT if run_held else TOUCH_RUN_ENTER
	run_held = not _touch_driving and magnitude >= run_threshold
	_touch_surface.queue_redraw()


func _stick_center() -> Vector2:
	return Vector2(121.0, _touch_surface.size.y - 126.0)


func _button_rect(index: int) -> Rect2:
	return Rect2(_touch_surface.size.x - 148.0, _touch_surface.size.y - 79.0 - index * 67.0, 124.0, 53.0)


func _pause_rect() -> Rect2:
	return Rect2(_touch_surface.size.x - 148.0, 20.0, 124.0, 53.0)


func _draw_touch() -> void:
	if _arrival_intro:
		_draw_touch_button(_button_rect(0), "Skip intro", Color("14283ae0"))
		if pause_enabled:
			_draw_touch_button(_pause_rect(), "Pause", Color("14283ae0"))
		return
	var center := _stick_center()
	_touch_surface.draw_circle(center, _stick_radius, Color("12232fc4"))
	var rim := Color("f1cf91") if run_held else Color("a3c4cab0")
	_touch_surface.draw_arc(center, _stick_radius, 0.0, TAU, 36, rim, 3.0 if run_held else 2.0, true)
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
