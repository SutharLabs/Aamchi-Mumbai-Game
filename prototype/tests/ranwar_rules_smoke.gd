extends SceneTree

const Game := preload("res://phase1.gd")
const Progress := preload("res://mission/mission_progress.gd")
const Delivery := preload("res://mission/ranwar_delivery.gd")
const Career := preload("res://mission/ranwar_career.gd")

var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var directory := "user://ranwar-rules-%d" % OS.get_process_id()
	var progress := Progress.new("1", directory)
	_expect(progress.save_arrival(), "test profile has completed the arrival")
	var game := Game.new()
	game.ambient_traffic_enabled = false
	game.delivery_progress = progress
	root.add_child(game)
	await _frames(8)
	var edges := game.world.district_edges
	_expect(edges.gate_positions.size() == 4, "mapped exits have four approach gates")
	for gate_name in ["HillRoadWestboundGate", "HillRoadEastboundGate", "ChapelRoadGate", "BazarRoadGate"]:
		var gate := edges.get_node_or_null(gate_name) as Node3D
		_expect(gate != null and _gate_collision(game, gate), "approach is closed by a solid " + gate_name)
	var west := edges.get_node_or_null("HillRoadWestboundGate") as Node3D
	if west == null:
		_finish(directory)
		return

	game.delivery.interact()
	var job := game.delivery.flow.snapshot()
	_expect(game.delivery.flow.state == Delivery.PICKUP, "parcel job enters its checkpoint")
	game.career.parcel_completed = true
	game.career.damage(15.0)
	game.career.report_theft(false)
	var approach := west.global_basis.z
	var foot_start := west.global_position - approach * 5.0
	game.player.global_position = foot_start + Vector3.UP * 0.03
	game.player.velocity = Vector3.ZERO
	game._yaw = atan2(-approach.x, -approach.z)
	await _frames(8)
	Input.action_press(&"move_forward")
	await _frames(320)
	Input.action_release(&"move_forward")
	await _frames(5)
	var exit := game.player.global_position
	_expect(approach.dot(west.global_position - exit) > 0.45
		and exit.distance_to(west.global_position) < 1.1, "walk input stops at the barrier without a reset")
	var objective := game.hud.find_child("JobObjective", true, false) as Label
	_expect(objective != null and "Pick up parcel" in objective.text and "Road closed" in objective.text,
		"the closure notice appears beside the current job objective")
	_expect(game.delivery.flow.snapshot() == job and game.career.wanted == 1
		and game.career.health == 85.0 and game.career.cash == Career.PARCEL_PAY,
		"the closed road preserves mission, health, alert and money")
	await _capture()
	Input.action_press(&"move_back")
	await _frames(114)
	Input.action_release(&"move_back")
	await _frames(12)
	var safe_foot := game.player.global_position
	_expect(safe_foot.distance_to(exit) > 1.6, "the approach remains open in the return direction")

	game.player.global_position.y = -12.0
	await _frames(6)
	_expect(game.player.global_position.distance_to(safe_foot) < 0.35
		and game.delivery.flow.snapshot() == job and game.career.wanted == 1
		and game.career.health == 85.0 and game.career.cash == Career.PARCEL_PAY,
		"fall enforces a nearby return with no clinic or mission penalty")

	var car_pad := west.global_position - approach * 11.0 + Vector3.UP * 0.55
	game.car.reset_to(Transform3D(Basis(Vector3.UP, game._yaw), car_pad))
	game.player.set_on_foot(false)
	game.active_vehicle = game.car
	game.car.set_driver_active(true)
	game.car._damage = 0.35
	await _frames(25)
	_expect(game.car.test_move(game.car.global_transform, approach * 18.0), "the same closure blocks car movement")
	var safe_car := game.car.global_position
	var parked_pose := game.car._home_transform
	game.car.global_position.x = -600.0
	await _frames(6)
	_expect(game.driving and game.car.global_position.distance_to(safe_car) < 0.35
		and game.car.condition_percent() == 65 and game.car._home_transform == parked_pose,
		"an escaped car returns locally without losing its driver, damage or parking pose")
	_expect(game.delivery.flow.snapshot() == job and game.career.wanted == 1
		and game.career.health == 85.0 and game.career.cash == Career.PARCEL_PAY,
		"vehicle return preserves the job and career state")
	game._request_reset()
	await _frames(7)
	_expect(not game.driving and game.delivery.flow.state == Delivery.FAILED
		and game.career.wanted == 0 and game.career.cash == Career.PARCEL_PAY - Career.POLICE_FINE,
		"an explicit Recover still applies existing job and detention rules")
	_finish(directory)


func _gate_collision(game: Game, gate: Node3D) -> bool:
	var center := gate.global_position + Vector3.UP * 0.75
	var along := gate.global_basis.z * 1.5
	var ray := PhysicsRayQueryParameters3D.create(center - along, center + along, 1)
	return game.get_world_3d().direct_space_state.intersect_ray(ray).get("collider") == gate.get_node("ConcreteBarrier")


func _capture() -> void:
	if DisplayServer.get_name() == "headless" or "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var path := "user://ranwar-road-closure.png"
	_expect(root.get_texture().get_image().save_png(path) == OK, "captured the live closure and HUD")
	print(ProjectSettings.globalize_path(path))


func _frames(count: int) -> void:
	for index in count:
		await physics_frame


func _expect(passed: bool, detail: String) -> void:
	_checks += 1
	if passed:
		print("PASS " + detail)
	else:
		_failures += 1
		printerr("FAIL " + detail)


func _finish(directory: String) -> void:
	var folder := DirAccess.open(directory)
	if folder != null:
		for name: String in folder.get_files():
			folder.remove(name)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("Ranwar rules smoke: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
