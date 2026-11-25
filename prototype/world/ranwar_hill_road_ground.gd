extends RefCounted
## Visual-only curb finish for the BEST stop and its facing storefronts.

const Surfaces := preload("res://world/ranwar_surface_materials.gd")
const GUTTER_HEIGHT := 0.027
const CURB_HEIGHT := 0.14
const JOINT_COLOR := Color("77746b")
const TAR := Color("696762")


static func add_to(world: Node3D, start: Vector3, end: Vector3, stop: Vector3,
		half_width: float, materials: Dictionary) -> void:
	var along := (end - start).normalized()
	var across := Vector3(-along.z, 0.0, along.x)
	var anchor := (stop - start).dot(along)
	# Follow the same clear approach and end points as the existing sidewalk strip.
	var first := maxf(9.4, anchor - 29.0)
	var last := minf(start.distance_to(end) - 9.4, anchor + 4.0)
	if last - first < 5.0:
		return
	var holder := Node3D.new()
	holder.name = "HillRoadGroundFinish"
	holder.position = stop
	world.add_child(holder)
	var surface_start := start - stop
	var road := SurfaceTool.new()
	road.begin(Mesh.PRIMITIVE_TRIANGLES)
	var curb := SurfaceTool.new()
	curb.begin(Mesh.PRIMITIVE_TRIANGLES)
	curb.set_smooth_group(-1)
	var asphalt := (materials["asphalt"] as StandardMaterial3D).duplicate() as StandardMaterial3D
	var asphalt_tone := asphalt.albedo_color
	var frame := Basis(along, Vector3.UP, across)
	for side: float in [-1.0, 1.0]:
		_add_gutter(road, surface_start, frame, Vector2(first, last), half_width * side, asphalt_tone)
		var seam_distance := first + 0.35
		while seam_distance < last:
			var at := surface_start + along * seam_distance + across * side * (half_width + 0.12)
			_add_curb_joint(curb, at, frame, side)
			seam_distance += 0.91
	# A patched utility cut at the bus approach meets the worn edge without crossing a lane.
	var trench := clampf(anchor - 12.0, first + 2.4, last - 2.4)
	_add_trench(road, surface_start + along * trench + across * (half_width - 1.32), frame, asphalt_tone)
	asphalt.albedo_color = Color.WHITE
	asphalt.vertex_color_use_as_albedo = true
	asphalt.vertex_color_is_srgb = true
	_finish(holder, "HillRoadRoadWear", road, asphalt)
	_finish(holder, "HillRoadCurbJoints", curb, materials["frontage_kit"])


static func _add_gutter(surface: SurfaceTool, start: Vector3, frame: Basis, span: Vector2,
		edge: float, asphalt_tone: Color) -> void:
	var segments := maxi(1, ceili((span.y - span.x) / 1.35))
	for index in segments:
		var t0 := float(index) / segments
		var t1 := float(index + 1) / segments
		var row_a := _gutter_row(start + frame.x * lerpf(span.x, span.y, t0), frame.z, edge, t0)
		var row_b := _gutter_row(start + frame.x * lerpf(span.x, span.y, t1), frame.z, edge, t1)
		for strip in range(2):
			var inner := strip if edge > 0.0 else 2 - strip
			var outer := strip + 1 if edge > 0.0 else 1 - strip
			_add_road_triangle(surface, row_a[inner], row_b[inner], row_b[outer], asphalt_tone)
			_add_road_triangle(surface, row_a[inner], row_b[outer], row_a[outer], asphalt_tone)


static func _gutter_row(center: Vector3, across: Vector3, edge: float, progress: float) -> Array[Vector4]:
	var fade := smoothstep(0.0, 0.17, progress) * (1.0 - smoothstep(0.82, 1.0, progress))
	var variation := 0.65 + 0.18 * sin(progress * 31.0) + 0.10 * sin(progress * 71.0)
	var shoulder := 0.42 + 0.14 * sin(progress * 24.0) + 0.08 * cos(progress * 67.0)
	var row: Array[Vector4] = []
	for sample: Vector2 in [Vector2(shoulder, 1.0), Vector2(0.13, 1.0 - fade * (1.0 - variation)),
			Vector2(0.006, 1.0 - fade * (1.0 - variation * 0.91))]:
		var point := center + across * (edge - signf(edge) * sample.x)
		row.append(Vector4(point.x, GUTTER_HEIGHT, point.z, sample.y))
	return row


static func _add_trench(surface: SurfaceTool, center: Vector3, frame: Basis, asphalt_tone: Color) -> void:
	const OUTLINE: Array[Vector2] = [Vector2(-2.26, -0.36), Vector2(-0.84, -0.32),
		Vector2(1.06, -0.39), Vector2(2.03, -0.28), Vector2(2.14, 0.28),
		Vector2(1.22, 0.41), Vector2(-0.41, 0.29), Vector2(-2.21, 0.36)]
	var middle := Vector4(center.x, GUTTER_HEIGHT + 0.004, center.z, 0.80)
	for index in OUTLINE.size():
		var a := OUTLINE[index]
		var b := OUTLINE[(index + 1) % OUTLINE.size()]
		var outer_a := _trench_point(center, frame, a, 1.0)
		var outer_b := _trench_point(center, frame, b, 1.0)
		var inner_a := _trench_point(center, frame, a * 0.90, 0.68)
		var inner_b := _trench_point(center, frame, b * 0.90, 0.68)
		_add_road_triangle(surface, middle, inner_a, inner_b, asphalt_tone)
		_add_road_triangle(surface, inner_a, outer_a, outer_b, asphalt_tone)
		_add_road_triangle(surface, inner_a, outer_b, inner_b, asphalt_tone)


static func _trench_point(center: Vector3, frame: Basis, point: Vector2, tint: float) -> Vector4:
	var result := center + frame * Vector3(point.x, 0.0, point.y)
	return Vector4(result.x, GUTTER_HEIGHT + 0.004, result.z, tint)


static func _add_road_triangle(surface: SurfaceTool, a: Vector4, b: Vector4, c: Vector4, asphalt_tone: Color) -> void:
	for sample: Vector4 in [a, b, c]:
		var tone := asphalt_tone.lerp(TAR, (1.0 - sample.w) * 0.72)
		surface.set_color(tone)
		surface.set_uv(Vector2(sample.x, sample.z) / 2.5)
		surface.add_vertex(Vector3(sample.x, sample.y, sample.z))


static func _add_curb_joint(surface: SurfaceTool, at: Vector3, frame: Basis, side: float) -> void:
	var top := Vector3(at.x, CURB_HEIGHT + 0.0005, at.z)
	Surfaces.add_box(surface, top, Vector3(0.016, 0.002, 0.212), JOINT_COLOR, Surfaces.PLAIN, frame)
	var face := Vector3(at.x, 0.081, at.z) - frame.z * side * 0.111
	Surfaces.add_box(surface, face, Vector3(0.016, 0.105, 0.002), JOINT_COLOR, Surfaces.PLAIN, frame)


static func _finish(holder: Node3D, label: String, surface: SurfaceTool, material: Material) -> void:
	surface.generate_normals()
	surface.index()
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = surface.commit()
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(mesh)
