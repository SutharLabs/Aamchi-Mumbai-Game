extends RefCounted
## Original low-cost paving and wall treatment for the existing Nagrana Lane corridor.

const Surfaces := preload("res://world/ranwar_surface_materials.gd")

const DRAIN := Color("535d5d")
const COVER := Color("687277")
const CONCRETE := Color("9f9989")
const PATCH := Color("8f897b")
const PLASTER := Color("bfb198")
const SKIRT := Color("8a8b7c")
const WALL_FACE := 1.371
const PAVING_HEIGHT := 0.047


static func add_panel(surface: SurfaceTool, from: Vector3, to: Vector3, across: Vector3,
		start_across: Vector3, end_across: Vector3) -> void:
	var joint_fraction := minf(0.025 / from.distance_to(to), 0.12)
	var joint_end := from.lerp(to, joint_fraction)
	var joint_across := start_across.lerp(end_across, joint_fraction)
	_paving(surface, joint_end, to, joint_across, end_across, -0.94, 0.94, CONCRETE)
	var repair_end := from.lerp(to, 0.28)
	_paving(surface, joint_end, repair_end, joint_across, start_across.lerp(end_across, 0.28),
		-0.88, -0.39, PATCH, 0.001)
	for side: float in [-1.0, 1.0]:
		var lo := minf(0.95 * side, 1.18 * side)
		var hi := maxf(0.95 * side, 1.18 * side)
		_paving(surface, from, to, start_across, end_across, lo, hi, DRAIN)
		_paving(surface, from.lerp(to, 0.21), from.lerp(to, 0.55),
			start_across.lerp(end_across, 0.21), start_across.lerp(end_across, 0.55),
			lo + 0.025, hi - 0.025, COVER, 0.002)
		var face_from := from + across * WALL_FACE * side
		var face_to := to + across * WALL_FACE * side
		if side < 0.0:
			var prior_from := face_from
			face_from = face_to
			face_to = prior_from
		_wall_band(surface, face_from, face_to, 0.0, 0.28, SKIRT)
		_wall_band(surface, face_from, face_to, 0.28, 1.37, PLASTER)


static func _paving(surface: SurfaceTool, from: Vector3, to: Vector3, start_across: Vector3,
		end_across: Vector3, low: float, high: float, color: Color, extra_height: float = 0.0) -> void:
	var lift := Vector3.UP * (PAVING_HEIGHT + extra_height)
	var finish := Surfaces.CONCRETE if color == CONCRETE or color == PATCH else Surfaces.PLAIN
	_quad(surface, from + start_across * low + lift, to + end_across * low + lift,
		to + end_across * high + lift, from + start_across * high + lift, color, finish)


static func _wall_band(surface: SurfaceTool, from: Vector3, to: Vector3, low: float, high: float, color: Color) -> void:
	_quad(surface, from + Vector3.UP * low, to + Vector3.UP * low,
		to + Vector3.UP * high, from + Vector3.UP * high, color, Surfaces.PLASTER)


static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		color: Color, finish: int) -> void:
	Surfaces.add_triangle(surface, a, b, c, color, finish)
	Surfaces.add_triangle(surface, a, c, d, color, finish)
