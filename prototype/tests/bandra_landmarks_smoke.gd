extends SceneTree

const Startup := preload("res://startup/startup.tscn")
const World := preload("res://world/phase1_world.gd")
const Landmarks := preload("res://world/bandra_landmarks.gd")
const LandmarksMap := preload("res://startup/district_services_map.gd")
const SeaLinkModel := preload("res://startup/sea_link_preview.gd")

var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var profile := "user://landmark-check-%d" % OS.get_process_id()
	var app := Startup.instantiate()
	app.preferences.storage_path = profile + ".json"
	app.mission_progress_directory = profile
	root.add_child(app)
	app.menu.play_requested.emit()
	await physics_frame
	await physics_frame
	var game: Node3D = app.gameplay
	var world: World = game.world
	var cross := world.get_node("WarodaWaysideCross") as Node3D
	var map_point: Vector3 = world.landmark_markers()[0]["position"]
	var original_point := world._project(Landmarks.WARODA_CROSS)
	_check(cross.position.is_equal_approx(map_point) and cross.position.distance_to(original_point) < 7.0,
		"Waroda wayside cross stays close to its mapped reference on the same road")
	_check(world._outside_carriageway(cross.position, World.SIDEWALK_WIDTH + 0.80),
		"the cross clears the carriageway and pavement")
	var hit := world.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(cross.global_position + Vector3.UP * 3.0, cross.global_position, 1))
	_check(hit.get("collider") == cross.get_node("Pedestal"), "the landmark has solid stonework")
	_check(_frontage_clear(world, cross.position), "the stonework is separate from surrounding frontages")
	_check(world.sea_link_route().size() == 22 and world.sea_link_route()[0].length() > 1200.0,
		"the bridge route retains its mapped projection beyond the Ranwar geometry")
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		_capture_cross(game, cross)
		await _save_capture("ranwar-waroda-cross.png")
	app._pause_game()
	await _settle()
	_press(app.menu, "MapButton")
	_press(app.menu, "BandraLandmarksButton")
	await _settle()
	var map := app.menu.find_child("BandraLandmarksMap", true, false) as LandmarksMap
	_check(map != null and map._pins.size() == 6 and map._bridge.size() == 22, "the landmarks page draws the map and bridge route")
	await _save_capture("ranwar-bandra-landmarks-map.png")
	_press(app.menu, "SeaLinkPreviewButton")
	await _settle()
	var model := app.menu.find_child("SeaLinkModel", true, false) as SeaLinkModel
	_check(model != null and model._viewport.get_node_or_null("BandraChannelSpan") != null
		and model._viewport.world_3d != root.world_3d, "opening the preview creates the bridge in a separate 3D world")
	_press(app.menu, "RotateSeaLinkButton")
	await _settle()
	_check(model._angle == 1, "changing view repositions the preview camera")
	await _save_capture("ranwar-bandra-sea-link.png")
	_check(app.menu.back_requested() and app.menu._page == &"landmarks"
		and app.menu.find_child("SeaLinkModel", true, false) == null, "Back releases the bridge preview and returns to landmarks")
	for file: String in [profile + ".json", profile + ".json.bak", profile.path_join("arrival-1.json"), profile]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("Bandra landmarks smoke: %d checks, %d failures." % [_checks, _failures])
	quit(1 if _failures else 0)


func _frontage_clear(world: World, position: Vector3) -> bool:
	var clearance := BoxShape3D.new()
	clearance.size = Vector3(3.0, 1.3, 3.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = clearance
	query.transform.origin = position + Vector3.UP * 0.88
	query.collision_mask = 1
	for intersection in world.get_world_3d().direct_space_state.intersect_shape(query):
		var collider := intersection["collider"] as Node
		if collider.get_parent().name != &"WarodaWaysideCross":
			return false
	return true


func _capture_cross(game: Node3D, cross: Node3D) -> void:
	var shot := Camera3D.new()
	game.add_child(shot)
	var toward_road := -cross.global_basis.z
	var beside := cross.global_basis.x
	shot.position = cross.position + toward_road * 8.0 + beside * 3.0 + Vector3.UP * 2.25
	shot.look_at(cross.global_position + Vector3.UP * 1.26)
	shot.make_current()
	game.hud.hide()


func _press(menu: Node, button_name: String) -> void:
	var button := menu.find_child(button_name, true, false) as Button
	if button == null:
		_check(false, "menu has " + button_name)
		return
	button.pressed.emit()


func _settle() -> void:
	for frame in range(8):
		await process_frame


func _save_capture(file: String) -> void:
	if DisplayServer.get_name() == "headless" or "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var directory := "user://" + file
	_check(root.get_texture().get_image().save_png(directory) == OK, "captured " + file)
	print(ProjectSettings.globalize_path(directory))


func _check(passed: bool, detail: String) -> void:
	_checks += 1
	if passed:
		print("PASS " + detail)
	else:
		_failures += 1
		push_error(detail)
