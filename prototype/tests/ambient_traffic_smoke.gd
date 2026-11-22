extends SceneTree
## Exercises the Ranwar loop, guarded reset, and bounded off-screen population.

const Scenario := preload("res://phase1.tscn")
const Hatchback := preload("res://vehicle/phase1_car.gd")
const CarDriver := preload("res://vehicle/phase1_car_driver.gd")
const LAP_TICK_LIMIT := 17000
var failures := 0
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _check_disabled_traffic()
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
	_check(_driver_fits(car), "the pilot has a visible right-hand driver gripping the wheel")
	_check(game.car.get_node_or_null("SeatedDriver") == null, "parked player car has no ambient occupant")
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
		if pilot._drivers[0].segment <= pilot._spawn_segment and car.global_position.distance_to(start) < 2.0:
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
	_check(car.global_position.distance_to(start) < 0.15 and pilot.get_child_count() <= 2,
		"player Reset returns the same traffic car after clearing the spawn")
	await _check_local_population(game, pilot)
	await _check_police_dispatch(game, pilot)
	print("Ambient traffic smoke: ", failures, " failures (", checks, " checks)")
	quit(0 if failures == 0 else 1)


func _check_disabled_traffic() -> void:
	var game := Scenario.instantiate()
	game.ambient_traffic_enabled = false
	root.add_child(game)
	await _ticks(3)
	game._reset_run()
	await _ticks(3)
	_check(game.traffic.is_inside_tree() and game.traffic.get_child_count() == 0,
		"disabling traffic leaves a reset-safe empty controller")
	game.queue_free()
	await _ticks(1)


func _check_local_population(game: Node3D, pilot: Node3D) -> void:
	# Keep a fixed observer so the same lane candidate can be tested across runs.
	game.set_physics_process(false)
	var observer: Camera3D = game.camera
	observer.global_position = Vector3(650.0, 3.0, 650.0)
	observer.look_at(observer.global_position + Vector3.RIGHT)
	await _ticks(35)
	_check(pilot.get_child_count() == 1, "a distant observer retains the single baseline pilot")

	observer.global_position = Vector3(0.0, 3.0, 5.0)
	observer.look_at(observer.global_position + Vector3.BACK)
	await _ticks(35)
	var local := pilot.get_node_or_null("LocalTrafficCar") as CharacterBody3D
	_check(local != null and pilot.get_child_count() == 2, "a nearby eligible lane spawns one additional car")
	if local == null:
		return
	var seated := local.get_node_or_null("SeatedDriver")
	_check(_driver_fits(local), "the additional car spawns with its own seated driver")
	var distance := observer.global_position.distance_to(local.global_position)
	var primary: Node3D = pilot.get_node("TrafficCar")
	_check(distance >= 84.0 and distance <= 181.0 and primary.global_position.distance_to(local.global_position) >= 29.0
		and not observer.is_position_in_frustum(local.global_position), "the additional car starts away from the observer, the pilot, and the visible view")

	observer.global_position = local.global_position + Vector3(0, 3, 250.0)
	observer.look_at(local.global_position)
	await _ticks(35)
	_check(is_instance_valid(local) and pilot.get_child_count() <= 2, "visible distant traffic remains loaded")
	observer.look_at(observer.global_position + Vector3.BACK)
	await _ticks(35)
	_check(not is_instance_valid(local) and pilot.get_child_count() <= 2, "distant traffic retires offscreen under the two-car cap")
	_check(not is_instance_valid(seated), "traffic retirement frees the driver's rig with its car")


func _check_police_dispatch(game: Node3D, traffic: Node3D) -> void:
	var observer: Camera3D = game.camera
	var target := Vector3(0.0, 0.0, 5.0)
	observer.global_position = Vector3(0.0, 3.0, 5.0)
	observer.look_at(observer.global_position + Vector3.BACK)
	_check(traffic.police_vehicle() == null, "free roam starts without a patrol car")
	traffic.set_police_alert(2, target)
	await _ticks(45)
	var patrol := traffic.get_node_or_null("PatrolCar") as Hatchback
	_check(patrol != null and traffic.police_vehicle() == patrol and traffic._drivers.size() <= 2,
		"an alert dispatches one patrol in addition to the bounded civilians")
	if patrol == null:
		return
	var start := patrol.global_position
	var distance := start.distance_to(target)
	_check(distance > 20.0 and distance < 125.0 and not observer.is_position_in_frustum(start),
		"the patrol joins a nearby mapped lane outside the gameplay view")
	_check(_driver_fits(patrol) and patrol.get_node_or_null("PatrolLightbase") != null
		and not game._parking_poses.has(patrol), "the marked patrol has a driver and stays out of the player entry list")
	await _ticks(95)
	_check(patrol.global_position.distance_to(start) > 2.0 and patrol.get_speed_mps() > 0.5,
		"the patrol moves under its own controller")
	var roadside := patrol.global_position + patrol.global_basis * Vector3(4.0, 0.0, -5.0)
	traffic.set_police_alert(2, roadside)
	await _ticks(50)
	_check(patrol.get_speed_mps() > 0.5 and patrol.get_speed_mps() < 3.4,
		"the active patrol slows for an encounter with a nearby roadside player")
	observer.global_position = patrol.global_position + Vector3(0.0, 4.0, 90.0)
	observer.look_at(patrol.global_position)
	traffic.set_police_alert(0, target)
	await _ticks(65)
	_check(is_instance_valid(patrol), "a cleared patrol stays visible until it can retire offscreen")
	observer.look_at(observer.global_position + Vector3.BACK)
	await _ticks(65)
	_check(not is_instance_valid(patrol) and traffic.police_vehicle() == null, "a cleared patrol retires outside the view")
	observer.global_position = Vector3(0.0, 3.0, 5.0)
	observer.look_at(observer.global_position + Vector3.BACK)
	traffic.set_police_alert(1, target)
	await _ticks(45)
	_check(traffic.police_vehicle() != null, "a new alert can dispatch another patrol")
	traffic.reset()
	await _ticks(35)
	_check(traffic.police_vehicle() == null and traffic.get_node_or_null("PatrolCar") == null,
		"world recovery clears the patrol and its driver")


func _driver_fits(car: Node3D) -> bool:
	var occupant := car.get_node_or_null("SeatedDriver") as CarDriver
	if occupant == null or not occupant.is_visible_in_tree() or not is_equal_approx(occupant.position.x, Hatchback.FRONT_SEAT_OFFSET):
		return false
	if not occupant.find_children("*", "CollisionObject3D", true, false).is_empty():
		return false
	var rig := occupant.skeleton
	var head := occupant.transform * rig.get_bone_global_pose(rig.find_bone("Head")).origin
	if head.y < 0.89 or head.y > 1.05 or head.z < -0.47 or head.z > 0.22:
		return false
	for side: float in [-1.0, 1.0]:
		var label := "LeftHand" if side < 0.0 else "RightHand"
		var hand := occupant.transform * rig.get_bone_global_pose(rig.find_bone(label)).origin
		var grip := Hatchback.STEERING_POSE * Vector3(side * CarDriver.WHEEL_GRIP.x, CarDriver.WHEEL_GRIP.y, CarDriver.WHEEL_GRIP.z)
		if hand.distance_to(grip) > 0.055:
			return false
	return true


func _check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS " if ok else "FAIL ", label)
	if not ok:
		failures += 1


func _ticks(count: int) -> void:
	for tick in range(count):
		await physics_frame
