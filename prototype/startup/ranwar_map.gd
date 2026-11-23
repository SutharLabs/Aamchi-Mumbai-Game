extends Control
## North-up map shared by the pause screen and the live navigation card.

const World := preload("res://world/phase1_world.gd")
const BACKGROUND := Color("101d2b")
const BORDER := Color("405268")
const ROAD := Color("bbc9d0")
const FOOTWAY := Color("72d7c2")
const PLAYER := Color("f3c684")
const DESTINATION := Color("f4a261")
const FACILITY := Color("89b9ed")
const LIVE_RANGE_METERS := 180.0

var _roads: Array[PackedVector2Array] = []
var _footway := PackedVector2Array()
var _facilities := PackedVector2Array()
var _position := Vector2.ZERO
var _destination := Vector2.INF
var _heading := Vector2.UP
var live := false


func _ready() -> void:
	custom_minimum_size = Vector2(224.0, 142.0) if live else Vector2(0.0, 264.0)
	clip_contents = live
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_snapshot(roads: Array[PackedVector3Array], footway: PackedVector3Array, position: Vector3,
		destination: Vector3 = Vector3.INF) -> void:
	set_geometry(roads, footway)
	set_tracking(position, Vector3.ZERO, destination)


func set_geometry(roads: Array[PackedVector3Array], footway: PackedVector3Array,
		facilities: PackedVector3Array = PackedVector3Array()) -> void:
	_roads.clear()
	for road: PackedVector3Array in roads:
		_roads.append(_north_up_path(road))
	_footway = _north_up_path(footway)
	_facilities = _north_up_path(facilities)
	queue_redraw()


func set_tracking(actor_position: Vector3, forward: Vector3, destination: Vector3) -> void:
	if not actor_position.is_finite():
		return
	var next_position := _north_up(actor_position)
	var next_heading := _north_up(forward).normalized() if forward.is_finite() else Vector2.ZERO
	if next_heading.is_zero_approx():
		next_heading = _heading
	var next_destination := _north_up(destination) if destination.is_finite() else Vector2.INF
	if live and next_position.distance_squared_to(_position) < 0.0225 and next_heading.dot(_heading) > 0.9995 \
			and next_destination == _destination:
		return
	_position = next_position
	_heading = next_heading
	_destination = next_destination
	queue_redraw()


func _draw() -> void:
	var panel := Rect2(Vector2.ZERO, size)
	draw_rect(panel, BACKGROUND)
	draw_rect(panel, BORDER, false, 1.0)
	if _roads.is_empty() or size.x <= 72.0 or size.y <= 56.0:
		return
	if live:
		_draw_live()
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
	_draw_geometry(transform_to_panel, 5.0, 3.0, 6.0)

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


func _draw_live() -> void:
	var center := size * 0.5
	var scale_to_fit := minf(size.x, size.y) / LIVE_RANGE_METERS
	var transform_to_panel := Transform2D(Vector2.RIGHT * scale_to_fit,
		Vector2.DOWN * scale_to_fit, center - _position * scale_to_fit)
	_draw_geometry(transform_to_panel, 3.5, 2.0, 5.0)
	var inset := Rect2(Vector2(12.0, 12.0), size - Vector2(24.0, 24.0))
	for facility: Vector2 in _facilities:
		var point := transform_to_panel * facility
		if inset.has_point(point):
			draw_rect(Rect2(point - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), BACKGROUND)
			draw_rect(Rect2(point - Vector2(3.0, 3.0), Vector2(6.0, 6.0)), FACILITY)
	if _destination.is_finite():
		var travel := (transform_to_panel * _destination) - center
		var horizontal := inset.size.x * 0.5 / maxf(absf(travel.x), 1.0)
		var vertical := inset.size.y * 0.5 / maxf(absf(travel.y), 1.0)
		var pin := center + travel * minf(1.0, minf(horizontal, vertical))
		if pin.distance_squared_to(center) < 24.0 * 24.0:
			var approach := travel.normalized() if travel.length_squared() > 1.0 else Vector2(0.8, 0.6)
			pin = center + approach * 24.0
		var corners := PackedVector2Array([pin + Vector2(0.0, -6.0), pin + Vector2(6.0, 0.0),
			pin + Vector2(0.0, 6.0), pin + Vector2(-6.0, 0.0), pin + Vector2(0.0, -6.0)])
		draw_colored_polygon(corners.slice(0, 4), DESTINATION)
		draw_polyline(corners, BACKGROUND, 1.5, true)
	var across := _heading.orthogonal()
	var arrow := PackedVector2Array([center + _heading * 11.0, center - _heading * 7.0 + across * 6.0,
		center - _heading * 4.0, center - _heading * 7.0 - across * 6.0, center + _heading * 11.0])
	draw_colored_polygon(arrow.slice(0, 4), PLAYER)
	draw_polyline(arrow, BACKGROUND, 1.7, true)
	draw_rect(Rect2(size.x - 36.0, 6.0, 23.0, 39.0), Color("101d2be8"))
	_draw_north()


func _draw_geometry(transform_to_panel: Transform2D, road_width: float, path_width: float, dash_size: float) -> void:
	for road: PackedVector2Array in _roads:
		if road.size() >= 2:
			draw_polyline(transform_to_panel * road, ROAD, road_width, true)
	for index in range(1, _footway.size()):
		draw_dashed_line(transform_to_panel * _footway[index - 1], transform_to_panel * _footway[index],
			FOOTWAY, path_width, dash_size, true, true)


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
	return World.map_north_up(point)
