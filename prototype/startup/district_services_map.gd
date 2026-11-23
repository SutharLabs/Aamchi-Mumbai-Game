extends Control
## North-up district context. Numbered callouts retain the corresponding geographic dots.

const World := preload("res://world/phase1_world.gd")
const PAPER := Color("122132")
const GRID := Color("2b4054")
const FRAME := Color("597187")
const ROAD := Color("c9e3e2")
const LABEL := Color("f4f3e9")
const ON_MAP := Color("f6c882")
const NEARBY := Color("8ec6e9")
const BRIDGE := Color("84d6c7")
const GRID_STEP := 500.0

var _roads: Array[PackedVector2Array] = []
var _pins := PackedVector2Array()
var _playable: Array[bool] = []
var _bridge := PackedVector2Array()


func _ready() -> void:
	custom_minimum_size.y = 256.0
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_data(roads: Array[PackedVector3Array], facilities: Array[Dictionary],
		bridge: PackedVector3Array = PackedVector3Array()) -> void:
	_roads.clear()
	for road: PackedVector3Array in roads:
		var path := PackedVector2Array()
		for point: Vector3 in road:
			path.append(World.map_north_up(point))
		_roads.append(path)
	_pins.clear()
	_playable.clear()
	for facility: Dictionary in facilities:
		_pins.append(World.map_north_up(facility["position"]))
		_playable.append(facility["playable"])
	_bridge.clear()
	for point: Vector3 in bridge:
		_bridge.append(World.map_north_up(point))
	queue_redraw()


func _draw() -> void:
	var frame := Rect2(Vector2.ZERO, size)
	draw_rect(frame, PAPER)
	draw_rect(frame, FRAME, false, 1.0)
	if _pins.is_empty() or size.x < 112.0 or size.y < 100.0:
		return
	var bounds := Rect2(_pins[0], Vector2.ZERO)
	for point: Vector2 in _pins:
		bounds = bounds.expand(point)
	for path: PackedVector2Array in _roads:
		for point: Vector2 in path:
			bounds = bounds.expand(point)
	for point: Vector2 in _bridge:
		bounds = bounds.expand(point)
	var inner := frame.grow(-34.0)
	var scale_to_fit := minf(inner.size.x / maxf(bounds.size.x, 1.0), inner.size.y / maxf(bounds.size.y, 1.0))
	var map_transform := Transform2D(Vector2.RIGHT * scale_to_fit, Vector2.DOWN * scale_to_fit,
		inner.get_center() - bounds.get_center() * scale_to_fit)
	_draw_grid(inner, bounds, map_transform)
	if _bridge.size() >= 2:
		draw_polyline(map_transform * _bridge, BRIDGE, 3.0, true)
	for path: PackedVector2Array in _roads:
		if path.size() >= 2:
			draw_polyline(map_transform * path, ROAD, 2.6, true)
	_draw_pins(map_transform, frame.grow(-14.0))
	_draw_scale(inner, scale_to_fit)


func _draw_grid(inner: Rect2, bounds: Rect2, map_transform: Transform2D) -> void:
	for line: int in range(ceili(bounds.position.x / GRID_STEP), floori(bounds.end.x / GRID_STEP) + 1):
		var x := (map_transform * Vector2(line * GRID_STEP, 0.0)).x
		draw_line(Vector2(x, inner.position.y), Vector2(x, inner.end.y), GRID, 1.0, true)
	for line: int in range(ceili(bounds.position.y / GRID_STEP), floori(bounds.end.y / GRID_STEP) + 1):
		var y := (map_transform * Vector2(0.0, line * GRID_STEP)).y
		draw_line(Vector2(inner.position.x, y), Vector2(inner.end.x, y), GRID, 1.0, true)


func _draw_pins(map_transform: Transform2D, pin_area: Rect2) -> void:
	var numbered := PackedVector2Array()
	var places := map_transform * _pins
	for index: int in range(places.size()):
		var point := places[index]
		var badge := _place_badge(point, numbered, places, pin_area, index)
		var ink := ON_MAP if _playable[index] else NEARBY
		draw_line(point, badge, ink, 1.0, true)
		draw_circle(point, 2.5, ink, true, -1.0, true)
		draw_circle(badge, 10.0, PAPER, true, -1.0, true)
		draw_circle(badge, 9.0, ink, false, 1.6, true)
		var number := str(index + 1)
		var font := get_theme_default_font()
		var text_width := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12).x
		draw_string(font, badge + Vector2(-0.5 * text_width, 4.0), number, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, LABEL)
		numbered.append(badge)


func _place_badge(point: Vector2, used: PackedVector2Array, places: PackedVector2Array,
		pin_area: Rect2, index: int) -> Vector2:
	for radius: float in [20.0, 36.0, 52.0]:
		for step: int in range(8):
			var angle := TAU * float(step + index * 3) / 8.0
			var candidate := point + Vector2.from_angle(angle) * radius
			if pin_area.has_point(candidate) and _clear_of(candidate, used, 22.0) and _clear_of(candidate, places, 12.0):
				return candidate
	return point


func _clear_of(candidate: Vector2, points: PackedVector2Array, clearance: float) -> bool:
	for point: Vector2 in points:
		if point.distance_squared_to(candidate) < clearance * clearance:
			return false
	return true


func _draw_scale(inner: Rect2, scale_to_fit: float) -> void:
	var bar_start := Vector2(inner.position.x, size.y - 17.0)
	var bar_end := bar_start + Vector2(GRID_STEP * scale_to_fit, 0.0)
	draw_line(bar_start, bar_end, LABEL, 1.3, true)
	for end: Vector2 in [bar_start, bar_end]:
		draw_line(end - Vector2(0.0, 2.5), end + Vector2(0.0, 2.5), LABEL, 1.3, true)
	draw_string(get_theme_default_font(), bar_end + Vector2(7.0, 4.0), "500 m", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, LABEL)
	var north := Vector2(size.x - 24.0, 29.0)
	draw_string(get_theme_default_font(), north - Vector2(4.5, 5.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, LABEL)
	draw_line(north + Vector2(0.0, 11.0), north, LABEL, 1.3, true)
	draw_polyline(PackedVector2Array([north + Vector2(-3.0, 5.0), north, north + Vector2(3.0, 5.0)]), LABEL, 1.3, true)
