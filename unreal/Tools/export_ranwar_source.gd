extends SceneTree
## Headless exchange of the actual Ranwar world scene and its static collision.

const World := preload("res://world/phase1_world.gd")

var _visuals: Array[Dictionary] = []
var _collision := PackedVector3Array()
var _materials: Dictionary = {}
var _source_materials: Dictionary = {}


func _initialize() -> void:
	_export.call_deferred()


func _export() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("Usage: Godot --headless --path prototype --script <export_ranwar_source.gd> -- <output.json>")
		quit(2)
		return
	var world := World.new()
	root.add_child(world)
	_capture(world)
	var arrival := world.arrival_position()
	var forward := Vector3.FORWARD.rotated(Vector3.UP, world.arrival_yaw())
	var entries: Array[Dictionary] = []
	for shop in world.building_entrances():
		entries.append({"name": shop["name"], "threshold": _vector(shop["threshold"]),
			"outside": _vector(shop["outside"]), "inside": _vector(shop["inside"]), "osm_way": shop["osm_way"]})
	var markers: Array[Dictionary] = [{
		"name": "St Peter's Church BEST stop",
		"position": _vector(arrival + forward * 2.1),
		"details": "Omkar arrives on Hill Road in Bandra West. Follow Hill Road into Ranwar.",
	}, {
		"name": "Map and asset credits",
		"position": _vector(arrival - forward * 4.3),
		"details": "© OpenStreetMap contributors, ODbL. Indian street shop by nayan pachori, CC BY 4.0.",
	}]
	for marker in world.landmark_markers():
		if marker["playable"]:
			var marker_position: Vector3 = marker["position"]
			markers.append({"name": marker["label"], "position": _vector(_roadside_position(world, marker_position)),
				"details": marker["kind"] + " in present-day Bandra West."})
	for entry in entries:
		markers.append({"name": entry["name"], "position": entry["outside"],
			"details": "Walk through the open entrance to explore the ground floor."})
	var launch := {"feet": _vector(arrival), "forward": _vector(forward)}
	var routes: Array[Dictionary] = []
	for index in world._roads.size():
		routes.append({"name": World.ROAD_NAMES[index], "width_m": World.ROAD_WIDTHS[index],
			"points": _vectors(world._roads[index])})
	var data := {"schema": 1, "basis": "Godot x-right, y-up, -z-forward, metres",
		"render_meshes": _visuals, "collision_triangles": _vectors(_collision), "materials": _materials,
		"player_start": launch, "doors": entries, "markers": markers, "roads": routes,
		"footway": _vectors(world._gully), "osm_attribution": "© OpenStreetMap contributors, ODbL 1.0"}
	var output := ProjectSettings.globalize_path(args[0])
	var directory_error := DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		printerr("Could not create export directory: ", directory_error)
		quit(1)
		return
	var stream := FileAccess.open(output, FileAccess.WRITE)
	if stream == null:
		printerr("Could not open export path: ", output, " ", FileAccess.get_open_error())
		quit(1)
		return
	stream.store_string(JSON.stringify(data))
	stream.close()
	if _visuals.size() < 35 or _collision.size() < 120 or entries.size() != 2:
		printerr("Incomplete Ranwar scene exchange.")
		quit(1)
		return
	print("Ranwar source exported: %d mesh surfaces, %d collision triangles, %d landmarks, %d doors." %
		[_visuals.size(), _collision.size() / 3, markers.size(), entries.size()])
	quit()


func _roadside_position(world: Node3D, position: Vector3) -> Vector3:
	var closest := position
	var best_distance := INF
	for road_index in world._roads.size():
		var points: PackedVector3Array = world._roads[road_index]
		for index in points.size() - 1:
			var nearest := Geometry3D.get_closest_point_to_segment(position, points[index], points[index + 1])
			var distance := nearest.distance_squared_to(position)
			if distance < best_distance:
				best_distance = distance
				var sideways := (position - nearest).normalized()
				closest = nearest + sideways * (World.ROAD_WIDTHS[road_index] * 0.5 + 0.9)
	closest.y = World.SIDEWALK_HEIGHT
	return closest


func _capture(node: Node) -> void:
	if node is MeshInstance3D:
		_capture_mesh(node)
	elif node is CollisionShape3D and not node.disabled:
		_capture_shape(node)
	elif node is CollisionPolygon3D and not node.disabled:
		_capture_prism(node.global_transform, node.polygon, node.depth)
	for child in node.get_children():
		_capture(child)


func _capture_mesh(instance: MeshInstance3D) -> void:
	if instance.mesh == null or not instance.is_visible_in_tree():
		return
	var transform := instance.global_transform
	var normal_basis := transform.basis.inverse().transposed()
	for index in instance.mesh.get_surface_count():
		if instance.mesh is ArrayMesh and (instance.mesh as ArrayMesh).surface_get_primitive_type(index) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arrays := instance.mesh.surface_get_arrays(index)
		if arrays.is_empty():
			continue
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if points.is_empty():
			continue
		var normal_data := PackedVector3Array()
		var source_normals: Variant = arrays[Mesh.ARRAY_NORMAL]
		if source_normals != null:
			for normal: Vector3 in source_normals:
				normal_data.append((normal_basis * normal).normalized())
		var material := instance.get_active_material(index)
		var key := _register_material(material)
		for vertex in points.size():
			points[vertex] = transform * points[vertex]
		var uv_scale := Vector2.ZERO
		if material is StandardMaterial3D and material.uv1_world_triplanar:
			uv_scale = Vector2(material.uv1_scale.x, material.uv1_scale.y)
		_visuals.append({
			"name": str(instance.get_parent().name), "center": _vector(transform.origin),
			"vertices": _vectors(points), "normals": _vectors(normal_data),
			"indices": [] if arrays[Mesh.ARRAY_INDEX] == null else Array(arrays[Mesh.ARRAY_INDEX]),
			"uv": _uvs(arrays[Mesh.ARRAY_TEX_UV]), "uv2": _uvs(arrays[Mesh.ARRAY_TEX_UV2]),
			"colors": _colors(arrays[Mesh.ARRAY_COLOR]), "material": key,
			"world_uv_scale": [uv_scale.x, uv_scale.y],
		})


func _register_material(material: Material) -> String:
	var material_id := material.get_instance_id() if material != null else 0
	if _source_materials.has(material_id):
		return _source_materials[material_id]
	var key := "m%d" % _materials.size()
	var description := {"name": "neutral", "color": [0.7, 0.7, 0.7, 1.0], "roughness": 0.9,
		"metallic": 0.0, "texture": "", "normal": "", "batch": false}
	if material is StandardMaterial3D:
		description["name"] = material.resource_name
		description["color"] = _rgba(material.albedo_color)
		description["roughness"] = material.roughness
		description["metallic"] = material.metallic
		description["texture"] = _texture_file(material.albedo_texture)
		description["normal"] = _texture_file(material.normal_texture if material.normal_enabled else null)
		# Embedded textures are serialized once so the prop retains its licensed texture set.
		if material.albedo_texture != null and description["texture"].is_empty():
			description["embedded"] = Marshalls.raw_to_base64(material.albedo_texture.get_image().save_png_to_buffer())
		if material.normal_enabled and material.normal_texture != null and description["normal"].is_empty():
			description["embedded_normal"] = Marshalls.raw_to_base64(material.normal_texture.get_image().save_png_to_buffer())
	elif material is ShaderMaterial:
		description["batch"] = true
		description["name"] = "RanwarFinish"
		var finish_maps: Array[String] = []
		for uniform: String in ["plaster_tile", "concrete_tile", "clay_tile", "timber_tile"]:
			finish_maps.append(_texture_file(material.get_shader_parameter(uniform) as Texture2D))
		description["finish_maps"] = finish_maps
	_materials[key] = description
	_source_materials[material_id] = key
	return key


func _texture_file(texture: Texture2D) -> String:
	if texture == null:
		return ""
	var path := texture.resource_path
	if path.begins_with("res://") and "::" not in path and FileAccess.file_exists(path):
		return "prototype/" + path.trim_prefix("res://")
	return ""


func _capture_shape(node: CollisionShape3D) -> void:
	var shape := node.shape
	if shape is BoxShape3D:
		var half: Vector3 = shape.size * 0.5
		_capture_prism(node.global_transform,
			PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
				Vector2(half.x, half.y), Vector2(-half.x, half.y)]), shape.size.z)
	elif shape is ConcavePolygonShape3D:
		for point: Vector3 in shape.get_faces():
			_collision.append(node.global_transform * point)
	elif shape is WorldBoundaryShape3D:
		# Substitute the finite visible ground rectangle for the infinite ideal plane.
		var frame := Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(90.0, -0.50, -245.0))
		_capture_prism(frame, PackedVector2Array([Vector2(-210, -350), Vector2(210, -350),
			Vector2(210, 350), Vector2(-210, 350)]), 1.0)


func _capture_prism(frame: Transform3D, polygon: PackedVector2Array, depth: float) -> void:
	var points_a := PackedVector3Array()
	var points_b := PackedVector3Array()
	for vertex: Vector2 in polygon:
		points_a.append(frame * Vector3(vertex.x, vertex.y, depth * 0.5))
		points_b.append(frame * Vector3(vertex.x, vertex.y, -depth * 0.5))
	var triangles := Geometry2D.triangulate_polygon(polygon)
	for index in range(0, triangles.size(), 3):
		var a := triangles[index]
		var b := triangles[index + 1]
		var c := triangles[index + 2]
		_collision.append_array(PackedVector3Array([points_a[a], points_a[c], points_a[b],
			points_b[a], points_b[b], points_b[c]]))
	for a in points_a.size():
		var b := (a + 1) % points_a.size()
		_collision.append_array(PackedVector3Array([points_a[a], points_a[b], points_b[b],
			points_a[a], points_b[b], points_b[a]]))


func _vector(point: Vector3) -> Array[float]:
	return [point.x, point.y, point.z]


func _vectors(points: PackedVector3Array) -> Array[Array]:
	var result: Array[Array] = []
	for point in points:
		result.append(_vector(point))
	return result


func _uvs(points: Variant) -> Array[Array]:
	var result: Array[Array] = []
	if points != null:
		for point: Vector2 in points:
			result.append([point.x, point.y])
	return result


func _rgba(color: Color) -> Array[float]:
	return [color.r, color.g, color.b, color.a]


func _colors(colors: Variant) -> Array[Array]:
	var result: Array[Array] = []
	if colors != null:
		for color: Color in colors:
			result.append(_rgba(color))
	return result
