extends SceneTree
## Export the original, unoccupied Godot vehicle bodies for Unreal's static meshes.

const Fleet := preload("res://vehicle/ranwar_fleet.gd")
const VEHICLES := {
	"Hatchback": &"hatch",
	"Rickshaw": &"rickshaw",
	"Motorcycle": &"commuter",
	"Scooter": &"scooter",
}


func _initialize() -> void:
	_export.call_deferred()


func _export() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() != 1 or not arguments[0].is_absolute_path():
		printerr("Pass one absolute output directory after --.")
		quit(ERR_INVALID_PARAMETER)
		return
	var output := arguments[0]
	var result := DirAccess.make_dir_recursive_absolute(output)
	if result == OK:
		for asset_name: String in VEHICLES:
			result = _export_vehicle(asset_name, VEHICLES[asset_name], output)
			if result != OK:
				break
	if result != OK:
		printerr("Ranwar vehicle export failed: ", error_string(result))
	quit(result)


func _export_vehicle(asset_name: String, kind: StringName, output: String) -> Error:
	var vehicle := Fleet.create(kind)
	root.add_child(vehicle)
	# Unreal Interchange maps glTF (X,Y,Z) to (X,Z,Y). Move the Godot vehicle's
	# -Z nose to glTF +X, and its +X right side to glTF +Z.
	var axis_conversion := Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3.ZERO)
	var parts: Array[Dictionary] = []
	_collect_visible_parts(vehicle, axis_conversion, parts)
	if parts.is_empty():
		vehicle.free()
		return ERR_INVALID_DATA
	var ground_y := INF
	for part: Dictionary in parts:
		var transform: Transform3D = part.transform
		var positions: PackedVector3Array = part.arrays[Mesh.ARRAY_VERTEX]
		for position: Vector3 in positions:
			ground_y = minf(ground_y, (transform * position).y)
	var mesh := _combine_parts(asset_name, parts, ground_y)
	vehicle.free()
	if mesh == null or mesh.get_surface_count() == 0:
		return ERR_INVALID_DATA
	var visual := MeshInstance3D.new()
	visual.name = asset_name
	visual.mesh = mesh
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var result := document.append_from_scene(visual, state)
	var path := output.path_join(asset_name + ".glb")
	if result == OK:
		result = document.write_to_filesystem(state, path)
	visual.free()
	if result == OK:
		print(asset_name, ": ", mesh.get_surface_count(), " material sections, ", mesh.get_aabb().size, " m, ", path)
	return result


func _collect_visible_parts(node: Node3D, parent: Transform3D, parts: Array[Dictionary]) -> void:
	if not node.visible:
		return
	var transform := parent * node.transform
	var visual := node as MeshInstance3D
	if visual != null and visual.mesh != null:
		for surface_index in visual.mesh.get_surface_count():
			parts.append({
				"arrays": visual.mesh.surface_get_arrays(surface_index),
				"material": visual.get_active_material(surface_index),
				"transform": transform,
			})
	for child: Node in node.get_children():
		if child is Node3D:
			_collect_visible_parts(child, transform, parts)


func _combine_parts(asset_name: String, parts: Array[Dictionary], ground_y: float) -> ArrayMesh:
	var surfaces: Dictionary[Material, SurfaceTool] = {}
	var offsets: Dictionary[Material, int] = {}
	for part: Dictionary in parts:
		var arrays: Array = part.arrays
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var material := part.material as StandardMaterial3D
		if material == null or vertices.is_empty() or normals.size() != vertices.size():
			printerr("Ranwar vehicle mesh part is missing its original material, vertices, or normals.")
			return null
		if not surfaces.has(material):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			var finish := material.duplicate() as StandardMaterial3D
			finish.resource_name = "%s_Finish_%02d" % [asset_name, surfaces.size()]
			surface.set_material(finish)
			surfaces[material] = surface
			offsets[material] = 0
		var surface: SurfaceTool = surfaces[material]
		var vertex_offset: int = offsets[material]
		var transform: Transform3D = part.transform
		var normal_basis := transform.basis.inverse().transposed()
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		for vertex_index in vertices.size():
			var vertex := transform * vertices[vertex_index]
			vertex.y -= ground_y
			surface.set_normal((normal_basis * normals[vertex_index]).normalized())
			surface.set_uv(uvs[vertex_index] if vertex_index < uvs.size() else Vector2.ZERO)
			surface.add_vertex(vertex)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if indices.is_empty():
			for vertex_index in vertices.size():
				surface.add_index(vertex_offset + vertex_index)
		else:
			for vertex_index: int in indices:
				surface.add_index(vertex_offset + vertex_index)
		offsets[material] += vertices.size()
	var mesh := ArrayMesh.new()
	mesh.resource_name = asset_name
	for surface: SurfaceTool in surfaces.values():
		surface.commit(mesh)
	return mesh
