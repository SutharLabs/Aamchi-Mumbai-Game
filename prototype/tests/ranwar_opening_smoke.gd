extends SceneTree

const Startup := preload("res://startup/startup.tscn")
const Intro := preload("res://mission/ranwar_arrival_intro.gd")
const Parking := preload("res://world/ranwar_parking.gd")
const Store := preload("res://mission/mission_progress.gd")

var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var tag := "user://ranwar-opening-%d" % OS.get_process_id()
	var app := Startup.instantiate()
	app.preferences.storage_path = tag + ".json"
	app.mission_progress_directory = tag
	root.add_child(app)
	app.menu.play_requested.emit()
	await _frames(36)
	var game: Node3D = app.gameplay
	var opening := game._arrival_intro as Intro
	_expect(opening != null and not game.player.active and not game.player.visible,
		"first Play starts on the arriving bus and holds player controls")
	_expect(not Store.new("1", tag).arrival_seen(), "the introduction is recorded only when complete or skipped")
	await _frames(148)
	_expect(game._arrival_intro == opening and opening.elapsed > Intro.STEP_OUT
		and game.player.visible and not game.player.active,
		"Omkar is animated stepping down onto the bus-stop pavement")
	_expect(game.player.visual.animation_player.current_animation == &"walk",
		"the disembark uses the skinned walking animation")
	_expect(opening._bus._doors[1].position.z - opening._bus._doors[0].position.z > 1.4,
		"the curb-side doors visibly open before the player steps outside")
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		_expect(root.get_texture().get_image().save_png("user://ranwar-bus-arrival.png") == OK,
			"captured the first-arrival bus and disembarking Omkar")
	await _frames(280)
	_expect(game._arrival_intro == null and game.player.active
		and game.player.global_position.distance_to(game.world.arrival_position()) < 0.6,
		"the full intro returns movement and the camera at the mapped stop")
	_expect(Store.new("1", tag).arrival_seen(), "full completion records the introduction")
	_expect(game._arrival_guide != null and game.story_target().is_finite(), "Anjali and the first job objective are available")
	_check_parking(game)

	app.menu.main_menu_requested.emit()
	await process_frame
	app.menu.play_requested.emit()
	await _frames(5)
	_expect(app.gameplay._arrival_intro == null, "the same profile can return directly to gameplay")
	app.menu.main_menu_requested.emit()
	await process_frame
	_expect(app.preferences.create_profile("Second arrival") == OK, "created another playtest profile")
	app.menu.play_requested.emit()
	await _frames(28)
	game = app.gameplay
	_expect(game._arrival_intro != null, "another profile sees the opening")
	game.hud.interact_pressed.emit()
	await _frames(5)
	_expect(game._arrival_intro == null and Store.new("2", tag).arrival_seen()
		and game.player.active, "the normal Interact action skips and records the intro")
	remove_app_files(app, tag)
	print("Ranwar opening smoke: %d checks, %d failures." % [_checks, _failures])
	quit(1 if _failures else 0)


func _check_parking(game: Node3D) -> void:
	var current: Array[Vector3] = []
	for pose: Transform3D in game._parking_poses.values():
		current.append(pose.origin)
	_expect(current.size() == 12 and current.all(func(spot: Vector3) -> bool:
		return spot.distance_to(game.world.arrival_position()) >= 11.0 and spot.distance_to(game.PLAYER_START) >= 11.0),
		"twelve vehicles park away from both player start points")
	var rng := RandomNumberGenerator.new()
	var curb: Vector3 = game.world.arrival_position()
	var yaw: float = game.world.arrival_yaw()
	rng.seed = 431
	var first := Parking.plan(curb, yaw, rng)
	rng.seed = 432
	var second := Parking.plan(curb, yaw, rng)
	_expect(first != second, "two session seeds produce different parking assignments")
	var clearance := BoxShape3D.new()
	clearance.size = Vector3(2.4, 1.6, 4.8)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = clearance
	query.collision_mask = 1
	var conflicts := PackedStringArray()
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	for seed in range(19):
		rng.seed = seed
		var poses := Parking.plan(curb, yaw, rng)
		var unique := {}
		for pose in poses:
			unique[pose.origin] = true
			query.transform = Transform3D(pose.basis, pose.origin + Vector3.UP * 0.65)
			var hits := space.intersect_shape(query, 1)
			if not hits.is_empty():
				var other: Node = hits[0]["collider"]
				var detail := "%s %s" % [pose.origin, other.name]
				if not conflicts.has(detail):
					conflicts.append(detail)
		if unique.size() != poses.size():
			conflicts.append("duplicate bay in a session")
	_expect(conflicts.is_empty(), "random parking never overlaps a solid or allocates a bay twice " + ", ".join(conflicts))


func remove_app_files(app: Node, path: String) -> void:
	root.remove_child(app)
	app.free()
	for item: String in [path + ".json", path + ".json.bak", path.path_join("arrival-1.json"),
			path.path_join("arrival-2.json"), path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(item))


func _frames(count: int) -> void:
	for index in count:
		await physics_frame


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("PASS ", message)
	else:
		_failures += 1
		printerr("FAIL ", message)
