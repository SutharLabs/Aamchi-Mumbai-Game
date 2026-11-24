extends Control
## Bounded, readable indicators for the current player and occupied vehicle.

const WIDTH := 224.0
const MAX_ALERT := 2
const BACKGROUND := Color("11202ff0")
const BORDER := Color("405268")
const TEXT := Color("deebef")
const MUTED := Color("bfc9d4")
const HEALTH := Color("72d7c2")
const INJURED := Color("ffab92")
const AMBER := Color("f4c27c")
const TRACK := Color("273e50")

var _health := -1
var _wanted := 0
var _cash := -1
var _vehicle := -1
var _panel := StyleBoxFlat.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.x = WIDTH
	_panel.bg_color = BACKGROUND
	_panel.border_color = BORDER
	_panel.set_border_width_all(1)
	_panel.set_corner_radius_all(6)
	resized.connect(queue_redraw)
	hide()


func set_values(health: float, wanted: int, cash: int, vehicle: int) -> void:
	var next_health := clampi(ceili(health), 0, 100) if is_finite(health) and health >= 0.0 else -1
	var next_wanted := clampi(wanted, 0, MAX_ALERT)
	var next_vehicle := mini(vehicle, 100) if vehicle >= 0 else -1
	if _health == next_health and _wanted == next_wanted and _cash == cash and _vehicle == next_vehicle:
		return
	_health = next_health
	_wanted = next_wanted
	_cash = cash
	_vehicle = next_vehicle
	var player_height := 69.0 if _health >= 0 else 0.0
	var vehicle_height := 39.0 if _vehicle >= 0 else 0.0
	custom_minimum_size.y = player_height + vehicle_height
	visible = custom_minimum_size.y > 0.0
	queue_redraw()


func _draw() -> void:
	draw_style_box(_panel, Rect2(Vector2.ZERO, size))
	var content_right := size.x - 12.0
	var baseline := 21.0
	if _health >= 0:
		_draw_meter("Health", _health, baseline, HEALTH if _health > 30 else INJURED)
		if _cash >= 0:
			draw_string(ThemeDB.fallback_font, Vector2(12.0, 55.0), "₹%s" % _cash,
				HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, TEXT)
		var police_color := AMBER if _wanted > 0 else MUTED
		var police_label := "Police %d/%d" % [_wanted, MAX_ALERT] if _wanted > 0 else "Police clear"
		_draw_right(police_label, content_right - 26.0, 55.0, 14, police_color)
		for index in MAX_ALERT:
			var pip := Vector2(content_right - 16.0 + index * 11.0, 50.0)
			draw_colored_polygon(PackedVector2Array([pip + Vector2.UP * 4.0, pip + Vector2.RIGHT * 4.0,
				pip + Vector2.DOWN * 4.0, pip + Vector2.LEFT * 4.0]), police_color if index < _wanted else TRACK)
		baseline += 69.0
	if _vehicle >= 0:
		if _health >= 0:
			draw_line(Vector2(12.0, 68.0), Vector2(content_right, 68.0), BORDER)
		_draw_meter("Vehicle condition", _vehicle, baseline - 4.0, AMBER)


func _draw_meter(label: String, value: int, baseline: float, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(12.0, baseline), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, MUTED)
	_draw_right("%d%%" % value, size.x - 12.0, baseline, 14, TEXT)
	var track := Rect2(12.0, baseline + 7.0, size.x - 24.0, 6.0)
	draw_rect(track, TRACK)
	track.size.x *= value / 100.0
	if track.size.x > 0.0:
		draw_rect(track, color)


func _draw_right(label: String, edge: float, baseline: float, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	draw_string(font, Vector2(edge - width, baseline), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
