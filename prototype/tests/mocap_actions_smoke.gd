extends SceneTree

const Ranwar := preload("res://phase1.tscn")
const Reaction := preload("res://character/vehicle_impact_reaction.gd")
const OPEN_YARD := Vector3(-25.0, 0.03, -18.0)

var _game: Node3D
var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = Ranwar.instantiate()
	_game.ambient_traffic_enabled = false
	root.add_child(_game)
	var player: CharacterBody3D = _game.player
	await _place_at(OPEN_YARD)
	var motion: AnimationPlayer = player.visual.animation_player
	_expect(motion.has_animation(&"jump_takeoff") and motion.has_animation(&"jump_air")
		and motion.has_animation(&"jump_land"), "the live rig resolves all three captured jump clips")

	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	Input.parse_input_event(key)
	await _frames(3)
	key.pressed = false
	Input.parse_input_event(key)
	_expect(motion.assigned_animation == &"jump_takeoff" and not player.can_interact(),
		"Space starts recorded takeoff and gates interaction")
	await _frames(17)
	_expect(player.position.y > 0.35 and motion.assigned_animation == &"jump_air",
		"the Jolt capsule and skeleton use the airborne phase")
	await _capture("ranwar-mocap-jump.png", player.position + Vector3.UP * 0.9)
	await _frames(19)
	_expect(player.is_on_floor() and motion.assigned_animation == &"jump_land",
		"contact with the yard starts the recorded landing")
	await _frames(15)
	_expect(player.can_interact() and motion.assigned_animation == &"idle",
		"normal locomotion resumes after landing")

	if _game.hud.touch_enabled:
		var touch := InputEventScreenTouch.new()
		touch.pressed = true
		touch.index = 6
		touch.position = _game.hud._button_rect(1).get_center()
		_game.hud._touch_surface.gui_input.emit(touch)
	else:
		var pad := InputEventJoypadButton.new()
		pad.button_index = JOY_BUTTON_LEFT_SHOULDER
		pad.pressed = true
		Input.parse_input_event(pad)
		await _frames(1)
		pad.pressed = false
		Input.parse_input_event(pad)
	await _frames(17)
	_expect(player.position.y > 0.34 and motion.assigned_animation == &"jump_air",
		"touch Jump or gamepad LB enters the same airborne phase")
	await _frames(40)

	var ceiling := StaticBody3D.new()
	ceiling.position = Vector3(OPEN_YARD.x, 2.08, OPEN_YARD.z)
	var collision := CollisionShape3D.new()
	var slab := BoxShape3D.new()
	slab.size = Vector3(3.0, 0.22, 3.0)
	collision.shape = slab
	ceiling.add_child(collision)
	_game.add_child(ceiling)
	await _frames(3)
	player.request_jump()
	var max_height := -INF
	for index in range(52):
		await physics_frame
		max_height = maxf(max_height, player.position.y)
	_expect(max_height > 0.17 and max_height < 0.35 and player.is_on_floor(),
		"the jumping capsule hits an overhead obstacle and lands")
	ceiling.queue_free()
	await _frames(4)

	for index in range(2):
		await _place_at(OPEN_YARD)
		player.rotation.y = 0.0
		var clip := &"impacts/fall_forward" if index == 0 else &"impacts/fall_backward"
		player.receive_vehicle_impact(Vector3.FORWARD if index == 0 else Vector3.BACK, 13.0)
		await _frames(20)
		_expect(motion.assigned_animation == clip and motion.current_animation_position > 0.15,
			"knockback samples the recorded %s clip" % clip)
		await _frames(16)
		_expect(player._impact.state == Reaction.DOWN and not player.can_interact(),
			"the captured pose follows solid ground contact")
		await _frames(15)
		await _capture("ranwar-mocap-fall-%d.png" % index, player.position + Vector3.UP * 0.4)
		await _frames(150)
		_expect(not player.is_reacting() and motion.assigned_animation == &"idle",
			"the character recovers from %s" % clip)
	print("Motion action smoke: %d failures in %d checks" % [_failures, _checks])
	quit(0 if _failures == 0 else 1)


func _place_at(point: Vector3) -> void:
	_game.player.set_on_foot(true)
	_game.player.position = point
	await _frames(10)


func _capture(filename: String, center: Vector3) -> void:
	if DisplayServer.get_name() == "headless" or "--capture" not in OS.get_cmdline_user_args():
		return
	var original: Transform3D = _game.camera.global_transform
	_game.set_physics_process(false)
	_game.camera.position = center + Vector3(3.7, 1.4, 2.7)
	_game.camera.look_at(center)
	await RenderingServer.frame_post_draw
	_expect(root.get_texture().get_image().save_png("user://" + filename) == OK, "wrote " + filename)
	_game.camera.global_transform = original
	_game.set_physics_process(true)


func _frames(count: int) -> void:
	for index in range(count):
		await physics_frame


func _expect(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("PASS ", label)
	else:
		_failures += 1
		printerr("FAIL ", label)
