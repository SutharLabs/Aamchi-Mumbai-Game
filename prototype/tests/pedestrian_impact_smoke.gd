extends SceneTree

const Ranwar := preload("res://phase1.tscn")
const Reaction := preload("res://character/vehicle_impact_reaction.gd")

var _game: Node3D
var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = Ranwar.instantiate()
	_game.ambient_traffic_enabled = false
	root.add_child(_game)
	await _frames(8)
	var pedestrian: CharacterBody3D = _game.pedestrians[0]
	var point := Vector3(-42.0, 0.05, -36.0)
	await _prepare_hit(pedestrian, point, Vector3.FORWARD)
	_game.car.set_controls(0.32, 0.0, false)
	await _wait_for_reaction(pedestrian, 275)
	_expect(pedestrian._impact.state == Reaction.STAGGER, "a moderate car impact causes a stagger")
	_game.car.set_driver_active(false)
	await _frames(45)
	_expect(not pedestrian.is_reacting() and pedestrian.global_position.z < point.z - 0.23,
		"moderate knockback moves with contact direction and recovers upright")

	await _prepare_hit(pedestrian, point, Vector3.FORWARD)
	_game.car.set_controls(1.0, 0.0, false)
	await _wait_for_reaction(pedestrian, 180)
	_expect(pedestrian._impact.state == Reaction.FALLING and _game.car.impact_velocity.z < -8.5,
		"harder collision enters the fall with the measured approach")
	_game.car.set_driver_active(false)
	await _frames(35)
	_expect(pedestrian._impact.state == Reaction.DOWN and pedestrian.global_position.z < point.z - 1.1,
		"hard contact travels farther and settles on the floor")
	_expect(absf(pedestrian._collider.basis.y.dot(Vector3.UP)) < 0.2
		and not pedestrian._collider.disabled and pedestrian.collision_layer != 0,
		"the downed pedestrian keeps a solid horizontal capsule")
	var grounded := pedestrian.global_position.y
	_expect(grounded > -0.08 and grounded < 0.24, "the fallen body settles at street grade")
	await _capture_fall(pedestrian)
	await _frames(165)
	_expect(not pedestrian.is_reacting() and pedestrian.visual.animation_player.active
		and pedestrian.visual.basis.is_equal_approx(Basis.IDENTITY), "the pedestrian stands and resumes the normal animation controller")

	# The wall contact sweep must still stop a person moved by an impulse.
	pedestrian.global_position = Vector3(-50.0, 0.05, -64.0)
	pedestrian.receive_vehicle_impact(Vector3.FORWARD, 18.0)
	await _frames(85)
	_expect(pedestrian.global_position.z > -67.6, "knockback respects the solid practice wall")
	_game._reset_run()
	_expect(not pedestrian.is_reacting() and pedestrian._collider.basis.is_equal_approx(Basis.IDENTITY),
		"world recovery clears an active reaction and restores the upright collider")

	await _prepare_hit(_game.player, Vector3(-40.0, 0.05, -28.0), Vector3.RIGHT)
	_game.car.set_controls(1.0, 0.0, false)
	await _wait_for_reaction(_game.player, 180)
	_expect(_game.player.is_reacting() and _game.car.impact_velocity.x > 8.5,
		"an on-foot player hit from the side receives the same directional response")
	_game._reset_run()
	_expect(not _game.player.is_reacting() and _game.player.visual.animation_player.active, "player recovery restores controls and animation")
	print("Pedestrian impact smoke: %d failures in %d checks" % [_failures, _checks])
	quit(0 if _failures == 0 else 1)


func _prepare_hit(person: CharacterBody3D, point: Vector3, direction: Vector3) -> void:
	_game._reset_run()
	person.global_position = point
	person.velocity = Vector3.ZERO
	if person != _game.player:
		person.begin_conversation(point + direction, 30.0)
	var yaw := atan2(-direction.x, -direction.z)
	_game.car.reset_to(Transform3D(Basis(Vector3.UP, yaw), point - direction * 17.0 + Vector3.UP * 0.50))
	_game.car.set_driver_active(true)
	await _frames(8)


func _wait_for_reaction(person: CharacterBody3D, limit: int) -> void:
	for tick in limit:
		await physics_frame
		if person.is_reacting():
			return


func _capture_fall(person: Node3D) -> void:
	if DisplayServer.get_name() == "headless" or "--capture" not in OS.get_cmdline_user_args():
		return
	var previous: Transform3D = _game.camera.global_transform
	_game.set_physics_process(false)
	_game.camera.global_position = person.global_position + Vector3(3.8, 2.5, 2.8)
	_game.camera.look_at(person.global_position + Vector3.UP * 0.40)
	await RenderingServer.frame_post_draw
	var path := "user://ranwar-pedestrian-impact.png"
	_expect(root.get_texture().get_image().save_png(path) == OK, "wrote a rendered preview of the fall")
	_game.camera.global_transform = previous
	_game.set_physics_process(true)


func _frames(count: int) -> void:
	for tick in count:
		await physics_frame


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("PASS ", message)
	else:
		_failures += 1
		printerr("FAIL ", message)
