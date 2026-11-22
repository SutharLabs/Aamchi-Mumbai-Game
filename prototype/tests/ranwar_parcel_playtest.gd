extends SceneTree

const Start := preload("res://startup/startup.tscn")
const Delivery := preload("res://mission/ranwar_delivery.gd")
const Route := preload("res://mission/ranwar_delivery_route.gd")
const Progress := preload("res://mission/mission_progress.gd")
const Career := preload("res://mission/ranwar_career.gd")
const Game := preload("res://phase1.gd")
const RanwarMap := preload("res://startup/ranwar_map.gd")

var _app: Node
var _game: Node3D
var _checks := 0
var _failures := 0
var _test_directory := ""
var _settings := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var suffix := "%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_test_directory = "user://parcel-playtest-" + suffix
	_settings = "user://parcel-playtest-settings-" + suffix + ".json"
	_app = Start.instantiate()
	_app.mission_progress_directory = _test_directory
	_app.preferences.storage_path = _settings
	root.add_child(_app)
	await _play()
	_expect(_game != null, "title Play enters the mission-enabled scene")
	if _game == null:
		_finish()
		return

	await _interact()
	_expect(_game.delivery.flow.state == Delivery.OFFER, "interaction away from the job board leaves the offer available")
	await _place_player(_game.delivery.target())
	await _interact()
	_expect(_game.delivery.flow.state == Delivery.PICKUP and _game.delivery.can_abandon(), "on-foot interaction at the board starts the parcel run")
	var pickup: Vector3 = _game.delivery.target()
	await _capture("ranwar-parcel-hud.png")
	await _pause()
	_press("MapButton")
	await _settle_menu()
	var map_view := _app.menu.find_child("RanwarMap", true, false) as RanwarMap
	_expect(map_view != null and map_view._destination.is_equal_approx(map_view._north_up(pickup)), "pause map shows the active pickup target")
	await _capture("ranwar-parcel-map.png")
	_press("BackButton")
	await _settle_menu()
	_press("ResumeButton")
	await _frames(6)

	await _check_vehicle_handoffs(pickup)
	var footway: PackedVector3Array = _game.world._gully
	var reached_hill: bool = await _traverse(footway, pickup)
	_expect(reached_hill, "Omkar traverses Nagrana from Waroda toward Hill Road through both bollard gaps")
	await _interact()
	_expect(_game.delivery.flow.state == Delivery.DROPOFF, "physical arrival at Hill Road permits the pickup")
	var dropoff: Vector3 = _game.delivery.target()

	await _title()
	_expect(_app.gameplay == null, "Main menu disposes the active level")
	await _play()
	_expect(_game.delivery.flow.state == Delivery.DROPOFF and _game.delivery.target().is_equal_approx(dropoff), "reopening Play restores the dropoff checkpoint")
	await _recover()
	_expect(_game.delivery.flow.state == Delivery.FAILED and _game.delivery.flow.checkpoint == Delivery.DROPOFF, "world recovery interrupts the job and keeps the dropoff checkpoint")
	await _title()
	await _play()
	_expect(_game.delivery.flow.state == Delivery.FAILED, "the retry state survives exit to title and reopen")
	await _place_player(_game.delivery.target())
	await _interact()
	_expect(_game.delivery.flow.state == Delivery.DROPOFF and _game.delivery.target().is_equal_approx(dropoff), "retry at the board restores the collected parcel")

	var return_path := footway.duplicate()
	return_path.reverse()
	var reached_waroda: bool = await _traverse(return_path, dropoff)
	_expect(reached_waroda, "Omkar traverses Nagrana from Hill Road toward Waroda through both bollard gaps")
	await _interact()
	_expect(_game.delivery.flow.state == Delivery.COMPLETED and not _game.delivery.target().is_finite(), "walking handoff completes the job and removes the objective")
	_expect(_game.career.cash == Career.PARCEL_PAY and _game.career.has_lead()
		and _game.story_target().is_equal_approx(_game._mira.global_position), "completion pays once and directs the player to Mira")
	var receipt: Dictionary = _game.delivery.flow.snapshot()
	await _interact()
	_expect(_game.delivery.flow.snapshot() == receipt and not _game.delivery.can_abandon(), "repeat interaction leaves the single receipt intact")
	await _title()
	await _play()
	_expect(_game.delivery.flow.state == Delivery.COMPLETED and _game.delivery.flow.snapshot() == receipt, "completion receipt survives return to title and reopening the level")
	_expect(_game.career.cash == Career.PARCEL_PAY, "the payout survives reload without being issued twice")

	await _title()
	_press("ProfilesButton")
	await _settle_menu()
	var field := _app.menu.find_child("ProfileNameInput", true, false) as LineEdit
	field.text = "Parcel QA"
	_press("CreateProfileButton")
	await _settle_menu()
	_expect(_app.preferences.active_profile_id == "2", "a new profile can be created and selected from the title")
	_press("BackButton")
	await _settle_menu()
	await _play()
	_expect(_game.delivery.flow.state == Delivery.OFFER, "the new profile begins with its own unstarted offer")
	_expect(_game.career.cash == 0 and not _game.career.has_lead(), "a separate profile has neither the payout nor the lead")
	await _place_player(_game.delivery.target())
	await _interact()
	await _pause()
	_expect(_button("AbandonJobButton") != null, "pause offers Abandon job while the parcel run is active")
	_press("AbandonJobButton")
	await _settle_menu()
	_expect(_game.delivery.flow.state == Delivery.OFFER and not _game.delivery.can_abandon(), "abandon returns the job to its initial offer")
	await _title()
	await _play()
	_expect(_game.delivery.flow.state == Delivery.OFFER, "abandon persists across level reload")
	await _title()
	var newer_path := _test_directory.path_join("mission-progress-2.json")
	var newer_save := JSON.stringify({"version": Progress.VERSION + 1, "profile_id": "2", "mission": receipt})
	var fixture := FileAccess.open(newer_path, FileAccess.WRITE)
	_expect(fixture != null, "unsupported version fixture can be written")
	if fixture != null:
		fixture.store_string(newer_save)
		fixture.close()
	await _play()
	await _place_player(Route.BOARD)
	var objective := _game.hud.find_child("JobObjective", true, false) as Label
	_expect(objective != null and objective.text == Route.INCOMPATIBLE_SAVE and not _game.delivery.target().is_finite(),
		"unsupported save shows specific help and hides the job marker")
	await _interact()
	_expect(FileAccess.get_file_as_string(newer_path) == newer_save, "interacting cannot replace the newer save")
	await _title()
	_press("ProfilesButton")
	await _settle_menu()
	var selector := _app.menu.find_child("ProfileSelector", true, false) as OptionButton
	selector.item_selected.emit(0)
	await _settle_menu()
	_press("BackButton")
	await _settle_menu()
	await _play()
	_expect(_game.delivery.flow.snapshot() == receipt, "the original profile keeps its receipt after the other profile abandons")
	await _check_career()
	_finish()


func _check_career() -> void:
	await _place_player(_game._mira.global_position + Vector3.LEFT * 1.2)
	await _interact()
	_expect(_game.career.lead_seen and not _game.story_target().is_finite(), "talking to Mira logs the lead and removes its marker")

	var wall := _game.world.get_node("ImpactWall") as Node3D
	await _place_player(_game.car.global_position + Vector3.BACK * 2.45)
	await _interact()
	var damage_before: float = _game.career.health
	_game.car.reset_to(Transform3D(Basis.IDENTITY, wall.position + Vector3(0.0, -0.15, 11.0)))
	await _accelerate(110)
	_expect(_game.driving and _game.career.health < damage_before and _game.career.wanted == 0,
		"a physical wall impact damages the player without reporting a collision with a person")
	var injured_health: float = _game.career.health
	await _title()
	await _play()
	_expect(is_equal_approx(_game.career.health, injured_health), "returning to the title does not heal the same session")
	await _place_player(Game.FIRST_AID)
	await _interact()
	_expect(_game.career.health == Career.MAX_HEALTH and _game.career.cash == 440, "first aid heals and spends the ₹60 price")
	await _frames(60)
	_game.career.damage(200.0)
	await _frames(6)
	_expect(not _game.driving and _game.career.health == Career.MAX_HEALTH and _game.career.cash == 340,
		"incapacitation respawns on foot and debits the clinic fee")

	await _frames(96)
	await _place_player(_game.car.global_position + Vector3.BACK * 2.45)
	await _interact()
	_game.car.reset_to(Transform3D(Basis.IDENTITY, Vector3(-42.0, 0.55, -18.0)))
	var pedestrian: Node3D = _game._mira
	pedestrian.set_physics_process(false)
	pedestrian.global_position = Vector3(-42.0, 0.07, -31.0)
	await _frames(3)
	await _accelerate(110)
	pedestrian.set_physics_process(true)
	_expect(_game.career.wanted >= 1, "a physical collision with a pedestrian triggers a police response")
	await _title()
	await _play()
	_expect(_game.career.wanted >= 1, "returning to the title does not clear the alert")
	await _pause()
	await _capture("ranwar-player-status.png")
	_press("ResumeButton")
	await _frames(4)
	await _recover()
	_expect(not _game.driving and _game.career.wanted == 0 and _game.career.cash == 190,
		"recovering while wanted records detention and the fine")
	await _title()
	await _play()
	_expect(_game.career.cash == 190 and _game.career.lead_seen and _game.career.wanted == 0, "spending and story survive reload")

	await _frames(96)
	_game._yaw = PI
	_game.career.report_collision()
	var patrol: Node3D
	for tick in 110:
		await physics_frame
		patrol = _game.traffic.police_vehicle()
		if patrol != null:
			break
	_expect(patrol != null, "an active session alert dispatches a visible patrol actor")
	if patrol != null:
		# Hold the vehicle stationary to isolate the roadside detention timer.
		patrol.set_physics_process(false)
		await _place_player(patrol.global_position + patrol.global_basis.x * 3.0 - Vector3.UP * patrol.global_position.y)
		await _frames(160)
		_expect(_game.career.wanted == 0 and _game.career.cash == 40 and _game.traffic.police_vehicle() == null,
			"remaining stopped beside the real patrol triggers detention, debits the fine and clears the car")


func _accelerate(frames: int) -> void:
	Input.action_press(&"move_forward")
	await _frames(frames)
	Input.action_release(&"move_forward")
	await _frames(4)


func _check_vehicle_handoffs(pickup: Vector3) -> void:
	var path: PackedVector3Array = _game.world._gully
	var direction := (path[-2] - path[-1]).normalized()
	var pickup_basis := Basis(Vector3.UP, atan2(-direction.x, -direction.z))
	for vehicle: Node3D in [_game.car, _game.rickshaw, _game.motorcycle, _game.scooter]:
		var parked := vehicle.global_transform
		await _place_player(parked.origin + Vector3.BACK * 2.45)
		await _interact()
		var entered: bool = _game.active_vehicle == vehicle
		_expect(entered, "Interacting takes control of the %s" % vehicle.vehicle_label)
		if not entered:
			continue
		# Stage the active vehicle at the objective to exercise interaction priority.
		vehicle.reset_to(Transform3D(pickup_basis, pickup + Vector3.UP * 0.55))
		await _frames(4)
		var in_range := vehicle.global_position.distance_to(pickup) < 1.8
		await _interact()
		_expect(in_range and _game.delivery.flow.state == Delivery.PICKUP, "the %s cannot collect a parcel while driving" % vehicle.vehicle_label)
		vehicle.reset_to(parked)
		await _frames(4)
		if _game.driving:
			await _interact()


func _traverse(path: PackedVector3Array, destination: Vector3) -> bool:
	# Start at one road mouth, then use the normal gameplay walking controller.
	# The simulation runs faster to shorten headless test time.
	await _place_player(path[0])
	var previous_time_scale := Engine.time_scale
	Engine.time_scale = 3.0
	Input.action_press(&"run")
	var reached := true
	for index in range(1, path.size()):
		reached = await _walk_to(path[index])
		if not reached:
			break
	if reached:
		reached = await _walk_to(destination)
	_game.hud.move_axis = Vector2.ZERO
	Input.action_release(&"run")
	Engine.time_scale = previous_time_scale
	await _frames(8)
	return reached


func _walk_to(point: Vector3) -> bool:
	var start: Vector3 = _game.player.global_position
	for tick in range(ceili(start.distance_to(point) * 20.0) + 90):
		var offset: Vector3 = point - _game.player.global_position
		offset.y = 0.0
		if offset.length_squared() < 0.14 ** 2:
			return true
		var relative := Basis(Vector3.UP, -_game._yaw) * offset.normalized()
		_game.hud.move_axis = Vector2(relative.x, relative.z) * minf(offset.length() * 2.5, 1.0)
		await physics_frame
	printerr("Blocked walking to ", point, " from ", _game.player.global_position)
	return false


func _place_player(position: Vector3) -> void:
	_game.player.global_position = position + Vector3.UP * 0.06
	_game.player.velocity = Vector3.ZERO
	await _frames(8)


func _interact() -> void:
	if _game.hud.touch_enabled:
		_game.hud.interact_pressed.emit()
		await _frames(5)
		return
	await _tap(&"interact")


func _recover() -> void:
	if _game.hud.touch_enabled:
		_game.hud.reset_pressed.emit()
		await _frames(5)
		return
	await _tap(&"recover")


func _pause() -> void:
	if _game.hud.touch_enabled:
		_game.hud.pause_pressed.emit()
	else:
		var event := InputEventAction.new()
		event.action = &"pause_game"
		event.pressed = true
		root.push_input(event, true)
	await _settle_menu()


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await _frames(3)
	Input.action_release(action)
	await _frames(3)


func _play() -> void:
	_press("PlayButton")
	await _settle_menu()
	_game = _app.gameplay
	await _frames(12)


func _title() -> void:
	if not paused:
		await _pause()
	_press("MainMenuButton")
	await _settle_menu()


func _button(button_name: String) -> Button:
	return _app.menu.find_child(button_name, true, false) as Button


func _press(button_name: String) -> void:
	var button := _button(button_name)
	if button == null:
		_expect(false, "%s is available" % button_name)
		return
	button.pressed.emit()


func _settle_menu() -> void:
	await process_frame
	await process_frame


func _capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless" or "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var path := "user://" + filename
	_expect(root.get_texture().get_image().save_png(path) == OK, "%s captured" % filename)
	print("Preview: ", ProjectSettings.globalize_path(path))


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame


func _finish() -> void:
	# The test uses two isolated numeric profiles and a separate settings file.
	for id in ["1", "2"]:
		var path := _test_directory.path_join("mission-progress-%s.json" % id)
		_remove_fixture(path)
		_remove_fixture(path + ".bak")
		_remove_fixture(path + Progress.RECEIPT_SUFFIX)
		var career_path := _test_directory.path_join("career-progress-%s.json" % id)
		_remove_fixture(career_path)
		_remove_fixture(career_path + ".bak")
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_test_directory)):
		_expect(DirAccess.remove_absolute(ProjectSettings.globalize_path(_test_directory)) == OK, "isolated mission fixtures removed")
	_remove_fixture(_settings)
	_remove_fixture(_settings + ".bak")
	print("Ranwar parcel playtest: %d failures in %d checks" % [_failures, _checks])
	quit(0 if _failures == 0 else 1)


func _remove_fixture(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("PASS ", message)
	else:
		_failures += 1
		printerr("FAIL ", message)
