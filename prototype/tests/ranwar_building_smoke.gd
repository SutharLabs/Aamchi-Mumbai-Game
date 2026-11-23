extends SceneTree

const World := preload("res://world/phase1_world.gd")
const Walker := preload("res://player.gd")

var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := World.new()
	var player := Walker.new()
	root.add_child(world)
	root.add_child(player)
	await physics_frame
	await physics_frame

	var mapped := world.mapped_buildings
	_check(mapped.get_child_count() == 38, "38 selected OSM footprints supply real frontage shapes")
	_check(_road_and_lane_clear(world, mapped._footprints), "all mapped footprints clear the gameplay sidewalks and Nagrana Lane")
	var venues := world.building_entrances()
	_check(venues.size() == 2, "two mapped street sites have fully modeled, open ground-floor rooms")
	var capture := DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args()
	if capture:
		_add_capture_lighting()
	for venue: Dictionary in venues:
		await _test_venue(world, player, venue, capture)
	print("Ranwar building smoke: %d checks, %d failures." % [_checks, _failures])
	quit(1 if _failures else 0)


func _road_and_lane_clear(world: World, polygons: Array[PackedVector2Array]) -> bool:
	for polygon: PackedVector2Array in polygons:
		for edge in polygon.size():
			var a := polygon[edge]
			var b := polygon[(edge + 1) % polygon.size()]
			for sample in range(7):
				var xz := a.lerp(b, float(sample) / 6.0)
				var sample_position := Vector3(xz.x, 0.0, xz.y)
				if not world._outside_carriageway(sample_position, World.SIDEWALK_WIDTH + 0.37):
					return false
				if world._distance_to_path(sample_position, world._gully) < 3.0:
					return false
	return true


func _test_venue(world: World, player: Walker, venue: Dictionary, capture: bool) -> void:
	var outside: Vector3 = venue["outside"]
	var inside: Vector3 = venue["inside"]
	var center: Vector3 = venue["threshold"]
	var caption: String = venue["name"]
	var site := world.mapped_buildings.get_node("Footprint_%d" % int(venue["osm_way"]))
	var inward := (inside - outside).normalized()
	var beside := Vector3.UP.cross(inward)
	var ray_offset := Vector3.UP * 0.92 + beside * 1.68
	var physics := world.get_world_3d().direct_space_state
	var hit := physics.intersect_ray(PhysicsRayQueryParameters3D.create(outside + ray_offset, inside + ray_offset, 1))
	_check(hit.get("collider") == site, caption + " has solid wall beside the opening")
	var player_clearance := PhysicsRayQueryParameters3D.create(outside + Vector3.UP * 1.0, inside + Vector3.UP * 1.0, 1)
	_check(physics.intersect_ray(player_clearance).is_empty(), caption + " doorway is physically open")
	player.position = outside + Vector3.UP * 0.32
	player.velocity = Vector3.ZERO
	for frame in range(12):
		await physics_frame
	_check(await _walk(player, inside), caption + " can be entered with the real player capsule")
	if capture:
		await _capture(venue, player, center, inward)
	_check(await _walk(player, outside), caption + " allows walking back onto the street")


func _walk(player: Walker, target: Vector3) -> bool:
	player.running = true
	for frame in range(310):
		var difference := target - player.position
		difference.y = 0.0
		if difference.length() < 0.25:
			player.running = false
			player.direction = Vector3.ZERO
			return true
		player.direction = difference.normalized()
		await physics_frame
	player.running = false
	player.direction = Vector3.ZERO
	return false


func _add_capture_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -42, 0)
	sun.shadow_enabled = true
	root.add_child(sun)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("b4c2c8")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("d8e0de")
	environment.environment.ambient_light_energy = 0.47
	root.add_child(environment)


func _capture(venue: Dictionary, player: Walker, center: Vector3, inward: Vector3) -> void:
	var output := "user://ranwar-building-%d" % int(venue["osm_way"])
	var camera := Camera3D.new()
	camera.fov = 70.0
	root.add_child(camera)
	camera.position = center + inward * 0.75 + Vector3.UP * 2.06
	camera.look_at(player.position + Vector3.UP * 1.05)
	camera.make_current()
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(output + "-inside.png") == OK, "saved interior capture")
	camera.position = center - inward * 8.80 + Vector3.UP * 2.65
	camera.look_at(center + Vector3.UP * 2.0)
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(output + "-outside.png") == OK, "saved street capture")
	print(ProjectSettings.globalize_path(output))
	camera.queue_free()


func _check(passed: bool, detail: String) -> void:
	_checks += 1
	if passed:
		print("PASS " + detail)
	else:
		_failures += 1
		push_error(detail)
