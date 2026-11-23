extends SceneTree

const Startup := preload("res://startup/startup.tscn")
const Store := preload("res://mission/mission_progress.gd")
const Vehicle := preload("res://vehicle/phase1_vehicle.gd")

var _app: Node
var _directory := ""
var _settings := ""
var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var tag := "%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_directory = "user://ranwar-arrival-" + tag
	_settings = "user://ranwar-arrival-settings-" + tag + ".json"
	_app = Startup.instantiate()
	_app.preferences.storage_path = _settings
	_app.mission_progress_directory = _directory
	root.add_child(_app)
	_app.menu.play_requested.emit()
	await _frames(9)
	var game: Node3D = _app.gameplay
	var stop: Vector3 = game.world.arrival_position()
	_expect(game._first_arrival and game.player.global_position.distance_to(stop) < 0.5,
		"a new player arrives at the mapped BEST stop")
	_expect(Store.new("1", _directory).arrival_seen(), "first arrival is recorded durably for the profile")
	_expect(game.pedestrians.size() >= 6 and game._parking_poses.size() == 12,
		"the regular session includes sidewalk walkers and a mixed parked fleet")
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var capture := root.get_texture().get_image().save_png("user://ranwar-first-arrival.png")
		_expect(capture == OK, "captured the actual first-arrival view")

	var loan: Vehicle = game._loan_bike
	_expect(game._entry_prompt(loan).begins_with("Unlock"), "the loan bike offers key entry")
	await _place_alongside(loan)
	await _interact()
	_expect(game.active_vehicle == loan and game.career.wanted == 0, "the loan key permits entry without an alert")
	await _interact()
	_expect(not game.driving and game._entry_prompt(loan).begins_with("Mount"), "dismount preserves the unlocked state")

	var sedan := game.get_node("StopVehicle1") as Vehicle
	_expect(game._entry_prompt(sedan).begins_with("Steal"), "a private parked car offers theft")
	await _place_alongside(sedan, -1.0)
	await _interact()
	_expect(game.active_vehicle == sedan and game.career.wanted == 1, "a nearby pedestrian reports the theft")
	_expect("Theft reported" in game._message, "the police warning is delivered as feedback")
	game.career.clear_alert()
	game._reset_run()
	await _frames(6)

	var street: Vehicle = game.traffic.interaction_vehicles()[0]
	street.set_physics_process(false)
	street.reset_to(Transform3D(Basis.IDENTITY, Vector3(-38.0, 0.55, -18.0)))
	await _place_alongside(street)
	await _interact()
	_expect(game.active_vehicle == street and not game.traffic.interaction_vehicles().has(street),
		"a stopped civilian car transfers from traffic control to the player")
	_expect(not (street.get_node("SeatedDriver") as Node3D).visible and game.career.wanted == 1,
		"taking a civilian car frees its seat and the driver reports the theft")
	game.career.clear_alert()
	game._reset_run()
	await _frames(8)
	_expect(not is_instance_valid(street) and not game.driving, "recovery releases the temporary claimed car")

	_app.menu.main_menu_requested.emit()
	await process_frame
	_app.menu.play_requested.emit()
	await _frames(9)
	game = _app.gameplay
	_expect(not game._first_arrival and game.player.global_position.distance_to(game.PLAYER_START) < 0.5,
		"the same profile returns to normal Ranwar access on subsequent play")
	_expect(game.traffic.civilian_limit == 4 and game.traffic.interaction_vehicles().size() <= 4,
		"the expanded desktop traffic has a four-car civilian budget")
	_finish()


func _place_alongside(vehicle: Vehicle, side := 1.0) -> void:
	var game: Node3D = _app.gameplay
	var spot := vehicle.global_position + vehicle.global_basis.x * (2.3 * side)
	spot.y = 0.5
	game.player.global_position = spot
	game.player.velocity = Vector3.ZERO
	await _frames(4)


func _interact() -> void:
	_app.gameplay.hud.interact_pressed.emit()
	await _frames(5)


func _frames(count: int) -> void:
	for frame in count:
		await physics_frame


func _finish() -> void:
	for file in [_directory.path_join("arrival-1.json"), _settings, _settings + ".bak"]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_directory))
	print("Arrival and ownership smoke: %d failures in %d checks" % [_failures, _checks])
	quit(0 if _failures == 0 else 1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("PASS ", message)
	else:
		_failures += 1
		printerr("FAIL ", message)
