extends SceneTree

const Startup := preload("res://startup/startup.tscn")
const Delivery := preload("res://mission/ranwar_delivery.gd")
const Progress := preload("res://mission/mission_progress.gd")
const Route := preload("res://mission/hill_road_ledger.gd")
const MapView := preload("res://startup/ranwar_map.gd")
const World := preload("res://world/phase1_world.gd")

var _app: Node
var _game: Node3D
var _directory := ""
var _preferences := ""
var _failures := 0
var _checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var tag := str(OS.get_process_id()) + "-" + str(Time.get_ticks_usec())
	_directory = "user://hill-ledger-test-" + tag
	_preferences = "user://hill-ledger-settings-" + tag + ".json"
	var store := Progress.new("1", _directory)
	var parcel := Delivery.new()
	parcel.interact()
	parcel.interact()
	parcel.interact()
	_check(store.save_snapshot(parcel.snapshot()) and store.save_career(60, false), "legacy parcel and career fixtures are valid")
	_check(not store.save_ledger_checkpoint(Progress.LEDGER_COMPLETED), "the ledger cannot complete before collection")
	_app = Startup.instantiate()
	_app.mission_progress_directory = _directory
	_app.preferences.storage_path = _preferences
	root.add_child(_app)
	await _open_game()
	if _game == null:
		_finish()
		return
	_check(_game.career.cash == 440 and _game.career.has_lead() and not _game.ledger.target().is_finite(),
		"legacy cash remains and Asha waits for Mira’s lead")
	await _place(_game._mira.global_position + Vector3.LEFT * 1.1)
	await _interact()
	var tea := _entrance(Route.TEA_ROOM)
	var grocer := _entrance(Route.GROCER)
	_check(_game.career.lead_seen and _game.story_target().is_equal_approx(tea["inside"])
		and _game.ledger.get_node_or_null("Asha") != null, "Mira unlocks Asha inside the existing tea room")
	await _place(tea["outside"])
	await _interact()
	_check(_game.ledger.state == Progress.LEDGER_COLLECT and _game.ledger.prompt_for(_game.player.global_position).is_empty(),
		"interacting from the street leaves the ledger uncollected")
	_check(await _walk_path(PackedVector3Array([tea["threshold"], tea["inside"]])), "Omkar walks from the street into Hill Road Tea Room")
	_check(_game.ledger.prompt_for(_game.player.global_position).begins_with("Take the ledger"), "the pickup prompt is available inside")
	var save_path := _directory.path_join("ledger-progress-1.json")
	_check(DirAccess.make_dir_absolute(save_path) == OK, "prepare a blocked checkpoint write")
	await _interact()
	_check(_game.ledger.state == Progress.LEDGER_COLLECT and _game.career.cash == 440,
		"a failed checkpoint write leaves the pickup available and wallet intact")
	_check(DirAccess.remove_absolute(save_path) == OK, "clear the blocked-write fixture")
	await _interact()
	_check(_game.ledger.state == Progress.LEDGER_HANDOFF and store.load_ledger_checkpoint() == Progress.LEDGER_HANDOFF
		and _game.career.cash == 440, "collecting the ledger saves the grocer handoff without paying early")
	if "--voice" in OS.get_cmdline_user_args():
		_check(_game.dialogue._player.playing and _game.dialogue._caption.text.begins_with("Asha:"), "Asha’s line plays with a subtitle")
	await _capture("ledger-asha.png", "Asha")
	_game.hud.reset_pressed.emit()
	await _frames(7)
	_check(_game.ledger.state == Progress.LEDGER_HANDOFF and _game.career.cash == 440,
		"Recover returns Omkar to safety with the saved ledger copy")
	await _app_pause()
	_press("MapButton")
	await _frames(4)
	var map := _app.menu.find_child("RanwarMap", true, false) as MapView
	_check(is_instance_valid(map) and map._destination.is_equal_approx(map._north_up(grocer["inside"])),
		"paused map routes the carried copy to Chapel Corner Grocer")
	_press("BackButton")
	await _frames(4)
	_press("MainMenuButton")
	await _frames(5)
	await _open_game()
	_check(_game.ledger.state == Progress.LEDGER_HANDOFF and _game.story_target().is_equal_approx(grocer["inside"]),
		"Continue restores the carried copy and the grocer’s target")
	await _app_pause()
	_check(is_instance_valid(_app.menu.find_child("AbandonJobButton", true, false)), "pause can abandon the ledger only while carrying it")
	_press("AbandonJobButton")
	await _frames(7)
	_check(not paused and _game.ledger.state == Progress.LEDGER_COLLECT and _game.career.cash == 440
		and FileAccess.file_exists(save_path) and store.load_ledger_checkpoint() == Progress.LEDGER_COLLECT,
		"abandon saves the return to Asha without paying or changing spending")
	await _place(tea["inside"])
	await _interact()
	_check(_game.ledger.state == Progress.LEDGER_HANDOFF and _game.career.cash == 440, "Asha can issue a fresh copy after abandonment")
	var route := _shop_route(tea, grocer)
	_check(await _walk_path(route, route.size() - 3),
		"Omkar traverses Hill Road, St Peter’s Road and Waroda on foot, using Jump at the grocer-side curb")
	_check(_game.ledger.prompt_for(_game.player.global_position).begins_with("Hand the ledger"), "the grocer handoff is reachable on foot")
	await _interact()
	var receipt := FileAccess.get_file_as_string(save_path + Progress.RECEIPT_SUFFIX)
	_check(_game.ledger.state == Progress.LEDGER_COMPLETED and _game.career.cash == 840 and not _game.story_target().is_finite()
		and not receipt.is_empty() and not _game.can_abandon_delivery(), "the handoff records one ₹400 reward, preserves spending and clears the marker")
	var objective := _game.hud.find_child("JobObjective", true, false) as Label
	_check(not _game.world.district_edges.notice_at(_game.player.global_position).is_empty()
		and is_instance_valid(objective) and objective.text.is_empty(), "a nearby road gate does not warn players inside the grocer")
	if "--voice" in OS.get_cmdline_user_args():
		_check(_game.dialogue._player.playing and _game.dialogue._caption.text.begins_with("Grocer:"), "the grocer’s line plays with a subtitle")
	await _capture("ledger-grocer.png", "Chapel Corner Grocer")
	await _interact()
	_check(_game.career.cash == 840 and FileAccess.get_file_as_string(save_path + Progress.RECEIPT_SUFFIX) == receipt,
		"repeating the handoff cannot change the receipt or pay again")
	_check(not store.save_ledger_checkpoint(Progress.LEDGER_HANDOFF), "a stale pickup cannot roll back the completion")
	await _app_pause()
	_press("MainMenuButton")
	await _frames(5)
	await _open_game()
	_check(_game.career.cash == 840 and _game.ledger.state == Progress.LEDGER_COMPLETED and _game.career.lead_seen,
		"completed ledger and prior parcel progress reload together")
	_check(Progress.new("2", _directory).load_ledger_checkpoint() == Progress.LEDGER_COLLECT
		and Progress.new("1", _directory, 1).load_ledger_checkpoint() == Progress.LEDGER_COLLECT,
		"other profiles and a New Game generation cannot inherit the ledger")
	_finish()


func _open_game() -> void:
	_press("ContinueButton")
	await _frames(9)
	_game = _app.gameplay
	_check(is_instance_valid(_game), "Continue enters the saved gameplay scene")
	if is_instance_valid(_game):
		_game.traffic.set_physics_process(false)


func _app_pause() -> void:
	if _game.hud.touch_enabled:
		_game.hud.pause_pressed.emit()
	else:
		_app._pause_game()
	await _frames(4)


func _entrance(way: int) -> Dictionary:
	for door: Dictionary in _game.world.building_entrances():
		if door["osm_way"] == way:
			return door
	return {}


func _shop_route(tea: Dictionary, grocer: Dictionary) -> PackedVector3Array:
	var hill: PackedVector3Array = _game.world._roads[0]
	var church: PackedVector3Array = _game.world._roads[1]
	var waroda: PackedVector3Array = _game.world._roads[2]
	var points := PackedVector3Array([tea["threshold"], tea["outside"], _project_on_road(tea["outside"], hill)])
	points.append_array(hill.slice(3))
	points.append_array(church.slice(1))
	var crossing := _project_on_road(grocer["outside"], waroda)
	var sidewalk: Vector3 = grocer["outside"]
	points.append(crossing)
	points.append(crossing.move_toward(sidewalk, World.ROAD_WIDTHS[2] * 0.5 - 0.8))
	points.append(grocer["outside"])
	points.append(grocer["threshold"])
	points.append(grocer["inside"])
	return points


func _project_on_road(point: Vector3, polyline: PackedVector3Array) -> Vector3:
	var closest := polyline[0]
	for index in polyline.size() - 1:
		var candidate := Geometry3D.get_closest_point_to_segment(point, polyline[index], polyline[index + 1])
		if candidate.distance_squared_to(point) < closest.distance_squared_to(point):
			closest = candidate
	return closest


func _walk_path(path: PackedVector3Array, curb_index := -1) -> bool:
	var previous := Engine.time_scale
	Engine.time_scale = 3.0
	Input.action_press(&"run")
	var reached := true
	for index in path.size():
		if index == curb_index:
			_game.hud.jump_pressed.emit()
		if not await _walk_to(path[index]):
			reached = false
			break
	_game.hud.move_axis = Vector2.ZERO
	Input.action_release(&"run")
	Engine.time_scale = previous
	await _frames(7)
	return reached


func _walk_to(point: Vector3) -> bool:
	var start: Vector3 = _game.player.global_position
	for index in range(ceili(point.distance_to(start) * 20.0) + 110):
		var offset: Vector3 = point - _game.player.global_position
		offset.y = 0.0
		if offset.length_squared() < 0.19 ** 2:
			return true
		var local := Basis(Vector3.UP, -_game._yaw) * offset.normalized()
		_game.hud.move_axis = Vector2(local.x, local.z) * minf(offset.length() * 2.2, 1.0)
		await physics_frame
	printerr("Blocked walking to ", point, " from ", _game.player.global_position)
	return false


func _place(point: Vector3) -> void:
	_game.player.global_position = point + Vector3.UP * 0.06
	_game.player.reset_physics_interpolation()
	_game.player.velocity = Vector3.ZERO
	await _frames(8)


func _interact() -> void:
	if _game.hud.touch_enabled:
		_game.hud.interact_pressed.emit()
		await _frames(5)
	else:
		Input.action_press(&"interact")
		await _frames(3)
		Input.action_release(&"interact")
		await _frames(2)


func _capture(filename: String, contact_name: String) -> void:
	if DisplayServer.get_name() == "headless" or "--capture" not in OS.get_cmdline_user_args():
		return
	var contact := _game.ledger.get_node_or_null(contact_name) as Node3D
	if is_instance_valid(contact):
		var direction: Vector3 = contact.global_position - _game.player.global_position
		_game._yaw = atan2(-direction.x, -direction.z)
		_game._update_camera(0.0)
	await RenderingServer.frame_post_draw
	var subtitle: Control = _game.dialogue._card
	var status: Control = _game.hud._prompt_panel
	_check(subtitle.visible and status.visible and not subtitle.get_global_rect().intersects(status.get_global_rect()),
		"voice subtitle and transaction status use separate screen space")
	_check(root.get_texture().get_image().save_png("user://" + filename) == OK, "saved " + filename)


func _press(name: String) -> void:
	var action := _app.menu.find_child(name, true, false) as Button
	if is_instance_valid(action):
		action.pressed.emit()
	else:
		_check(false, "menu action available: " + name)


func _frames(count: int) -> void:
	for index in count:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("PASS ", message)
	else:
		_failures += 1
		printerr("FAIL ", message)


func _finish() -> void:
	for filename: String in DirAccess.get_files_at(_directory):
		DirAccess.remove_absolute(_directory.path_join(filename))
	DirAccess.remove_absolute(_directory)
	for path: String in [_preferences, _preferences + ".bak"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	print("Hill Road Ledger playtest: %d checks, %d failures." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
