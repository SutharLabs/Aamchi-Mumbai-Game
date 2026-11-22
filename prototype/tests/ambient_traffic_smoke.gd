extends SceneTree
## Real-scene regression for a first ambient loop, stopping, recovery, and reset.

const Scenario := preload("res://phase1.tscn")
const LAP_TICK_LIMIT := 17000
var failures := 0
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := Scenario.instantiate()
	root.add_child(game)
	await _ticks(4)
	var pilot: Node3D = game.traffic
	var car := pilot.get_node_or_null("TrafficCar") as CharacterBody3D
	_check(car != null and pilot.get_child_count() == 1, "one traffic car starts")
	if car == null:
		quit(1)
		return

	var start := car.global_position
	_check(start.distance_to(game.player.global_position) > 20.0 and start.distance_to(game.car.global_position) > 20.0,
		"traffic starts clear of the player and practice bays")
	_check(not game._parking_poses.has(car) and car.find_children("*", "Label3D", true, false).is_empty(),
		"traffic stays outside the player vehicle list and has no hover captions")
	await _ticks(240)
	_check(car.global_position.distance_to(start) > 13.0, "ambient car starts moving on its own")

	var crossing := car.global_position - car.global_basis.z * 5.0
	game.player.global_position = Vector3(crossing.x, 0.05, crossing.z)
	await _ticks(130)
	_check(car.get_speed_mps() < 0.08 and car.global_position.distance_to(game.player.global_position) > 2.35,
		"ambient car stops short of the player crossing")
	var waiting := car.global_position
	await _ticks(70)
	_check(car.global_position.distance_to(waiting) < 0.12, "ambient car holds while the lane is blocked")
	game.player.global_position = Vector3(0.0, 0.55, 5.0)
	await _ticks(100)
	_check(car.get_speed_mps() > 1.0 and car.global_position.distance_to(waiting) > 4.0,
		"ambient car resumes after the player clears the lane")

	var complete := false
	var stationary_ticks := 0
	for tick in range(LAP_TICK_LIMIT):
		await physics_frame
		if pilot._segment <= pilot._spawn_segment and car.global_position.distance_to(start) < 2.0:
			complete = true
			break
		stationary_ticks = stationary_ticks + 1 if car.get_speed_mps() < 0.1 else 0
		if stationary_ticks > 270:
			break
	_check(complete, "ambient car completes a lap and returns to its first lane")

	# Move the pilot along the lane before testing a blocked Reset destination.
	await _ticks(80)
	var spawn: Vector3 = pilot._spawn_pose.origin
	game.player.global_position = Vector3(spawn.x, 0.05, spawn.z)
	await _ticks(3)
	var before_reset := car.global_position
	pilot.reset()
	await _ticks(3)
	_check(car.global_position.distance_to(before_reset) < 0.45, "traffic Reset respects an occupied spawn")
	game._reset_run()
	await _ticks(4)
	_check(car.global_position.distance_to(start) < 0.15 and pilot.get_child_count() == 1,
		"player Reset returns the same traffic car after clearing the spawn")
	print("Ambient traffic smoke: ", failures, " failures (", checks, " checks)")
	quit(0 if failures == 0 else 1)


func _check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS " if ok else "FAIL ", label)
	if not ok:
		failures += 1


func _ticks(count: int) -> void:
	for tick in range(count):
		await physics_frame
