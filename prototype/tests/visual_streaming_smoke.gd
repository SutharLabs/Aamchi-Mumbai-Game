extends SceneTree

const World := preload("res://world/phase1_world.gd")
const VisualChunks := preload("res://world/ranwar_visual_chunks.gd")

var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := World.new()
	root.add_child(world)
	var visuals := world.get_node("BackgroundFrontageVisuals") as VisualChunks
	var streaming := "--stream-visual-chunks" in OS.get_cmdline_user_args()
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.position = World.PLAYER_START
	camera.make_current()
	await physics_frame
	await physics_frame
	var initial := world.visual_residency_stats()
	_check(initial.total_chunks > 1 and initial.active_meshes > 0, "stock world registers multiple chunk groups and loads nearby scenery")
	_check(initial.mode == ("streamed" if streaming else "resident"), "selected visual mode is active")
	if streaming and initial.active_meshes > 0:
		await _check_streaming(world, visuals, camera)
	elif not streaming:
		_check(initial.total_chunks == initial.active_chunks and initial.total_meshes == initial.active_meshes,
			"resident baseline instantiates every background mesh")
		camera.position = Vector3(150, 3, -570)
		await _settle()
		_check(world.visual_residency_stats() == initial, "camera cuts leave resident baseline counts intact")
	print("Visual streaming smoke (%s): %d checks, %d failures. %s" % [initial.mode, _checks, _failures, JSON.stringify(world.visual_residency_stats())])
	quit(1 if _failures else 0)


func _check_streaming(world: World, visuals: VisualChunks, camera: Camera3D) -> void:
	var initial := world.visual_residency_stats()
	_check(initial.active_meshes < initial.total_meshes, "distant visuals are absent at game start")
	var group := visuals.get_child(0) as Node3D
	var group_name := group.name
	var group_id := group.get_instance_id()
	var wall := group.get_node("Facade") as MeshInstance3D
	var wall_position := wall.position
	var mesh_ref: WeakRef = weakref(wall.mesh)
	var bounds := Rect2()
	for chunk: VisualChunks.Chunk in visuals._chunks.values():
		if chunk.node == group:
			bounds = chunk.bounds
			break
	var facing := -1.0 if bounds.get_center().x < 0.0 else 1.0
	var edge := bounds.position.x if facing < 0.0 else bounds.end.x
	var wall_collider := _ray_collider(world, wall_position)
	_check(wall_collider != null, "initial wall has real world collision")
	camera.position = Vector3(edge + facing * (VisualChunks.LOAD_DISTANCE + 16.0), 3, bounds.get_center().y)
	await _settle()
	_check(is_instance_id_valid(group_id), "distance hysteresis retains the same active chunk")
	camera.position.x = edge + facing * (VisualChunks.UNLOAD_DISTANCE + 16.0)
	await _settle()
	_check(not is_instance_id_valid(group_id) and mesh_ref.get_ref() == null, "unloading frees the chunk and its unreferenced mesh")
	_check(wall_collider != null and _ray_collider(world, wall_position) == wall_collider, "an unloaded visual retains the same collision body")
	camera.position = Vector3(bounds.get_center().x, 3, bounds.get_center().y)
	await _settle()
	var rebuilt := visuals.get_node_or_null(NodePath(group_name)) as Node3D
	var rebuilt_wall := rebuilt.get_node_or_null("Facade") as MeshInstance3D if rebuilt else null
	_check(rebuilt_wall != null and rebuilt_wall.position.is_equal_approx(wall_position), "a camera cut rebuilds nearby meshes at their original poses")
	var road_start: Vector3 = world._roads[0][0]
	var next_intersection: Vector3 = world._roads[0][-1]
	camera.position = road_start
	await _settle()
	var missing_nearby := false
	var drive := next_intersection - road_start
	var steps := ceili(drive.length() / 0.8)
	for step in range(steps):
		camera.position = road_start.lerp(next_intersection, float(step + 1) / float(steps))
		await process_frame
		var focus := Vector2(camera.position.x, camera.position.z)
		for chunk: VisualChunks.Chunk in visuals._chunks.values():
			if chunk.node == null and focus.distance_to(focus.clamp(chunk.bounds.position, chunk.bounds.end)) < 48.0:
				missing_nearby = true
	_check(not missing_nearby, "48 m/s camera traversal keeps chunks resident within 48 m")
	camera.position = World.PLAYER_START
	await _settle()
	_check(world.visual_residency_stats().active_meshes > 0 and world.lane_graph.loop_for_road(3).size() > 2,
		"a return to spawn preloads scenery and the ambient route is available")


func _ray_collider(world: World, point: Vector3) -> StaticBody3D:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 20, point - Vector3.UP, 1)
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or not is_equal_approx(hit.position.y, point.y * 2.0):
		return null
	return hit.get("collider") as StaticBody3D


func _settle() -> void:
	await process_frame
	await process_frame
	await physics_frame


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if ok:
		print("PASS ", label)
	else:
		_failures += 1
		printerr("FAIL ", label)
