extends "./export_ranwar_vehicles.gd"
## Bake the existing arrival coach and two civilian looks for Unreal.

const Bus := preload("res://world/arrival_bus.gd")
const Civilian := preload("res://character/locomotion_visual.gd")
const UNREAL_AXES := Basis(Vector3.UP, -PI / 2.0)


func _export() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() != 1 or not arguments[0].is_absolute_path():
		printerr("Pass one absolute arrival output directory after --.")
		quit(ERR_INVALID_PARAMETER)
		return
	var output := arguments[0]
	var result := DirAccess.make_dir_recursive_absolute(output)
	if result == OK:
		result = _write_mesh(_bake_bus(), "BestBus", output)
	if result == OK:
		result = _write_mesh(_bake_civilian(Color("8b513c"), false), "Anjali", output)
	if result == OK:
		result = _write_mesh(_bake_civilian(Color("587e77"), true), "Pedestrian", output)
	if result != OK:
		printerr("Ranwar arrival export failed: ", error_string(result))
	quit(result)


func _bake_bus() -> ArrayMesh:
	var bus := Bus.new()
	root.add_child(bus)
	bus.set_door_open(1.0)
	var parts: Array[Dictionary] = []
	_collect_visible_parts(bus, Transform3D(UNREAL_AXES, Vector3.ZERO), parts)
	# Godot's original coach already has a ground-level origin at its wheels.
	var mesh := _combine_parts("BestBus", parts, 0.0)
	bus.free()
	return mesh


func _bake_civilian(shirt: Color, overshirt: bool) -> ArrayMesh:
	var actor := Civilian.new()
	actor.shirt_color = shirt
	actor.wears_overshirt = overshirt
	root.add_child(actor)
	actor.animation_player.seek(0.32, true)
	actor.skeleton.force_update_all_bone_transforms()
	var body := actor.get_node("ClothedBody") as MeshInstance3D
	var arrays := body.mesh.surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	const INFLUENCES := 4
	var transforms: Array[Transform3D] = []
	for bind in body.skin.get_bind_count():
		var bone := body.skin.get_bind_bone(bind)
		transforms.append(actor.skeleton.get_bone_global_pose(bone) * body.skin.get_bind_pose(bind))
	var ground_y := INF
	for index in positions.size():
		var position := Vector3.ZERO
		var normal := Vector3.ZERO
		var tangent := Vector3.ZERO
		var source_tangent := Vector3(tangents[4 * index], tangents[4 * index + 1], tangents[4 * index + 2])
		for influence in INFLUENCES:
			var slot := index * INFLUENCES + influence
			var weight := weights[slot]
			if weight > 0.0:
				var pose := transforms[bones[slot]]
				position += weight * (pose * positions[index])
				normal += weight * (pose.basis * normals[index])
				tangent += weight * (pose.basis * source_tangent)
		positions[index] = UNREAL_AXES * position
		normals[index] = (UNREAL_AXES * normal).normalized()
		var rotated := (UNREAL_AXES * tangent).slide(normals[index]).normalized()
		tangents[4 * index] = rotated.x
		tangents[4 * index + 1] = rotated.y
		tangents[4 * index + 2] = rotated.z
		ground_y = minf(ground_y, positions[index].y)
	for index in positions.size():
		positions[index].y -= ground_y
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_BONES] = null
	arrays[Mesh.ARRAY_WEIGHTS] = null
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	result.surface_set_material(0, body.get_active_material(0))
	actor.free()
	return result


func _write_mesh(mesh: ArrayMesh, asset_name: String, output: String) -> Error:
	if mesh == null or mesh.get_surface_count() == 0:
		return ERR_INVALID_DATA
	if mesh.get_surface_count() == 1:
		var finish := mesh.surface_get_material(0).duplicate() as Material
		finish.resource_name = asset_name + "_Civilian"
		mesh.surface_set_material(0, finish)
	var visual := MeshInstance3D.new()
	visual.name = asset_name
	visual.mesh = mesh
	mesh.resource_name = asset_name
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
