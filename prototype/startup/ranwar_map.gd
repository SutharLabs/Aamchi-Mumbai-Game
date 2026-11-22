extends Control
## North-up snapshot of the projected roads and the paused actor.

const World := preload("res://world/phase1_world.gd")
const BACKGROUND := Color("101d2b")
const BORDER := Color("405268")
const ROAD := Color("bbc9d0")
const FOOTWAY := Color("72d7c2")
const PLAYER := Color("f3c684")
const DESTINATION := Color("f4a261")

var _roads: Array[PackedVector2Array] = []
var _footway := PackedVector2Array()
var _position := Vector2.ZERO
var _destination := Vector2.INF


func _ready() -> void:
	custom_minimum_size.y = 264.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_snapshot(roads: Array[PackedVector3Array], footway: PackedVector3Array, position: Vector3,
		destination: Vector3 = Vector3.INF) -> void:
	_roads.clear()
	for road: PackedVector3Array in roads:
		_roads.append(_north_up_path(road))
	_footway = _north_up_path(footway)
	_position = _north_up(position)
	_destination = _north_up(destination) if destination.is_finite() else Vector2.INF
	queue_redraw()


func _draw() -> void:
	var panel := Rect2(Vector2.ZERO, size)
	draw_rect(panel, BACKGROUND)
	draw_rect(panel, BORDER, false, 1.0)
	if _roads.is_empty() or size.x <= 72.0 or size.y <= 56.0:
		return

	var bounds := Rect2(_position, Vector2.ZERO)
	for road: PackedVector2Array in _roads:
		for point: Vector2 in road:
			bounds = bounds.expand(point)
	for point: Vector2 in _footway:
		bounds = bounds.expand(point)
	if _destination.is_finite():
		bounds = bounds.expand(_destination)
	var content := Rect2(Vector2(24.0, 34.0), size - Vector2(72.0, 56.0))
	var scale_to_fit := minf(content.size.x / maxf(bounds.size.x, 1.0), content.size.y / maxf(bounds.size.y, 1.0))
	var transform_to_panel := Transform2D(
		Vector2.RIGHT * scale_to_fit,
		Vector2.DOWN * scale_to_fit,
		content.get_center() - bounds.get_center() * scale_to_fit)
	for road: PackedVector2Array in _roads:
		if road.size() >= 2:
			draw_polyline(transform_to_panel * road, ROAD, 5.0, true)
	for index in range(1, _footway.size()):
		draw_dashed_line(transform_to_panel * _footway[index - 1], transform_to_panel * _footway[index], FOOTWAY, 3.0, 6.0, true, true)

	var marker := transform_to_panel * _position
	if _destination.is_finite():
		var pin := transform_to_panel * _destination
		if pin.distance_squared_to(marker) < 17.0 * 17.0:
			var offset := Vector2(18.0 if marker.x < size.x * 0.5 else -18.0,
				14.0 if marker.y < size.y * 0.5 else -14.0)
			draw_line(pin, marker + offset, DESTINATION, 1.0, true)
			pin = marker + offset
		var outline := PackedVector2Array([pin + Vector2(0.0, -8.0), pin + Vector2(8.0, 0.0),
			pin + Vector2(0.0, 8.0), pin + Vector2(-8.0, 0.0), pin + Vector2(0.0, -8.0)])
		draw_colored_polygon(outline.slice(0, 4), DESTINATION)
		draw_polyline(outline, BACKGROUND, 2.0, true)
	draw_circle(marker, 9.0, BACKGROUND, true, -1.0, true)
	draw_circle(marker, 6.0, PLAYER, true, -1.0, true)
	_draw_north()


func _draw_north() -> void:
	var tip := Vector2(size.x - 25.0, 29.0)
	draw_line(tip + Vector2(0.0, 13.0), tip, ROAD, 2.0, true)
	draw_line(tip + Vector2(-4.0, 6.0), tip, ROAD, 2.0, true)
	draw_line(tip + Vector2(4.0, 6.0), tip, ROAD, 2.0, true)
	draw_string(get_theme_default_font(), tip + Vector2(-5.0, -7.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, ROAD)


func _north_up_path(path: PackedVector3Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point: Vector3 in path:
		points.append(_north_up(point))
	return points


func _north_up(point: Vector3) -> Vector2:
	var east_to_forward := World.AXIS_FORWARD
	return Vector2(
		point.x * east_to_forward.y - point.z * east_to_forward.x,
		point.x * east_to_forward.x + point.z * east_to_forward.y)
