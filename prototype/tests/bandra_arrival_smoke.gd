extends SceneTree

const World := preload("res://world/phase1_world.gd")

var _failures := 0
var _checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := World.new()
	root.add_child(world)
	await physics_frame
	await physics_frame
	var sites := world.facility_markers()
	var start := world.arrival_position()
	var forward := Vector3.FORWARD.rotated(Vector3.UP, world.arrival_yaw())
	var stop_point: Vector3 = sites[0]["position"]
	var shelter := world.get_node("StPetersStopPlatform") as StaticBody3D
	_check(sites.size() == 8 and sites[0]["playable"] and sites[0]["id"] == &"st_peters_stop",
		"district map contains the verified playable arrival stop and seven district references")
	_check(shelter.position.distance_to(stop_point) < 15.0 and start.distance_to(shelter.position) < 5.0,
		"spawn and shelter stay near the mapped stop")
	_check(forward.dot((World.PLAYER_START - start).normalized()) > 0.9, "player faces west along Hill Road")
	var above_pavement := start + Vector3.UP * 0.25
	var floor_hit := _ray(world, above_pavement, start - Vector3.UP)
	_check(not floor_hit.is_empty() and is_equal_approx(floor_hit["position"].y, World.SIDEWALK_HEIGHT),
		"spawn stands above solid pavement")
	_check(_ray(world, above_pavement, above_pavement + forward * 8.0).is_empty(),
		"westbound pedestrian approach is clear of stop and frontage colliders")
	var post := world.get_node("StPetersStopPost") as StaticBody3D
	var post_hit := _ray(world, post.position - forward * 0.22, post.position + forward * 0.22)
	_check(post_hit.get("collider") == post, "shelter posts have collision")
	print("Bandra arrival smoke: %d checks, %d failures." % [_checks, _failures])
	quit(1 if _failures else 0)


func _ray(world: World, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	return world.get_world_3d().direct_space_state.intersect_ray(query)


func _check(passed: bool, detail: String) -> void:
	_checks += 1
	if not passed:
		_failures += 1
		push_error(detail)
