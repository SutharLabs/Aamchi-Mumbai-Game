extends SceneTree

const Startup := preload("res://startup/startup.tscn")
const Preferences := preload("res://startup/preferences.gd")
const Controls := preload("res://startup/control_bindings.gd")
const DistrictView := preload("res://startup/district_services_map.gd")
const MapView := preload("res://startup/ranwar_map.gd")
const StatusView := preload("res://startup/player_status.gd")

var _app: Node
var _storage := ""
var _failures := 0
var _checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_storage = "user://live-hud-probe-%d.json" % OS.get_process_id()
	var legacy := FileAccess.open(_storage, FileAccess.WRITE)
	legacy.store_string(JSON.stringify({
		"version": 1,
		"profiles": [{"id": "1", "name": "Playtest"}],
		"active_profile_id": "1",
		"settings": {"master_volume": 0.8, "look_sensitivity": 1.0, "fullscreen": false},
	}))
	legacy.close()
	_app = Startup.instantiate()
	_app.preferences.storage_path = _storage
	_app.mission_progress_directory = "user://live-hud-missions-%d" % OS.get_process_id()
	root.add_child(_app)
	await _settle()
	_expect(_app.preferences.live_map, "an existing profile defaults to the live map")
	_press("PlayButton")
	await _settle()
	var game: Node3D = _app.gameplay
	game.finish_arrival()
	await _settle()
	var hud: CanvasLayer = game.hud
	var map := hud.find_child("LiveMap", true, false) as MapView
	var status := hud.find_child("PlayerStatus", true, false) as StatusView
	_expect(map.is_visible_in_tree() and map._roads.size() == game.world._roads.size(), "live map shows the playable road geometry")
	_expect(status._health == 100 and status._wanted == 0 and status._vehicle == -1, "on foot the HUD shows player state")
	var actor_before := map._position
	game.player.global_position += Vector3.RIGHT * 4.0
	await _settle()
	_expect(map._position.distance_to(actor_before) >= 3.0 and map._position.distance_to(map._north_up(game._actor_position())) < 0.16,
		"walking position updates the minimap")
	var dock := hud.find_child("NavigationDock", true, false) as Control
	_expect(dock.position.x > dock.get_parent_control().size.x * 0.70 and dock.position.y > dock.get_parent_control().size.y * 0.20,
		"the dock stays toward the lower right")
	if Controls.uses_touch_ui():
		_expect(dock.position.y + dock.size.y < hud._button_rect(2).position.y, "the map and status clear the mobile buttons")
	else:
		_expect(is_equal_approx(dock.position.y + dock.size.y, dock.get_parent_control().size.y - 24.0), "the desktop dock hugs the bottom edge")
	game.player.set_on_foot(false)
	game.active_vehicle = game.car
	game.car.set_driver_active(true)
	game.car._damage = 0.52
	game.career.health = 27.0
	game.career.wanted = 2
	await _settle()
	_expect(map._position.distance_to(map._north_up(game.car.global_position)) < 0.16
		and map._heading.dot(map._north_up(-game.car.global_basis.z).normalized()) > 0.9995,
		"live map follows the occupied vehicle and its heading")
	_expect(status.is_visible_in_tree() and status._health == 27 and status._wanted == 2
		and status._cash == game.career.cash and status._vehicle == 48,
		"status represents health, alert, cash and vehicle condition distinctly")
	game.set_physics_process(false)
	await _capture()

	_app._pause_game()
	await _settle()
	_press("MapButton")
	await _settle()
	_press("DistrictServicesButton")
	await _settle()
	var district := _app.menu.find_child("DistrictServicesMap", true, false) as DistrictView
	_expect(district != null and district._pins.size() == game.world.facility_markers().size(),
		"the pause map opens the service markers for the current district")
	_press("BackButton")
	await _settle()
	_expect(_app.menu.find_child("RanwarMap", true, false) is MapView, "District services returns to the local map")
	_press("BackButton")
	await _settle()
	_press("SettingsButton")
	await _settle()
	var toggle := _app.menu.find_child("LiveMapToggle", true, false) as CheckButton
	_expect(toggle != null and toggle.button_pressed, "Settings exposes a default-on live map")
	toggle.button_pressed = false
	_press("ApplySettingsButton")
	await _settle()
	_expect(not _app.preferences.live_map and not map.visible, "applying Settings disables live tracking")
	var restored := Preferences.new()
	restored.storage_path = _storage
	root.add_child(restored)
	_expect(not restored.live_map, "the toggle survives reloading the preferences file")
	_expect(restored.set_settings(0.65, false, 1.35) == OK and not restored.live_map,
		"changing other preferences preserves the saved toggle")
	root.remove_child(restored)
	restored.free()
	_press("BackButton")
	await _settle()
	_press("ResumeButton")
	await _settle()
	_expect(not map.is_visible_in_tree() and status.is_visible_in_tree(), "switching off the map retains HUD meters in play")
	_app._pause_game()
	await _settle()
	_press("SettingsButton")
	await _settle()
	toggle = _app.menu.find_child("LiveMapToggle", true, false) as CheckButton
	toggle.button_pressed = true
	_press("ApplySettingsButton")
	await _settle()
	_press("BackButton")
	await _settle()
	_press("ResumeButton")
	await _settle()
	_expect(map.is_visible_in_tree(), "turning the live map on restores it on Resume")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_storage))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_storage + ".bak"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_app.mission_progress_directory.path_join("arrival-1.json")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_app.mission_progress_directory))
	print("Live HUD smoke: %d failures (%d checks)" % [_failures, _checks])
	quit(0 if _failures == 0 else 1)


func _capture() -> void:
	if DisplayServer.get_name() == "headless" or "--capture" not in OS.get_cmdline_user_args():
		return
	var label := "touch" if Controls.uses_touch_ui() else "desktop"
	var output := "user://ranwar-live-hud-%s.png" % label
	await RenderingServer.frame_post_draw
	_expect(root.get_texture().get_image().save_png(output) == OK, "capture the rendered HUD")
	print("Screenshot: " + ProjectSettings.globalize_path(output))


func _press(name: String) -> void:
	var button := _app.menu.find_child(name, true, false) as Button
	if button != null:
		button.pressed.emit()
	else:
		_expect(false, "expected menu button " + name)


func _settle() -> void:
	for index in 6:
		await process_frame


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("PASS ", message)
	else:
		_failures += 1
		printerr("FAIL ", message)
