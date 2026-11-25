extends SceneTree

const Start := preload("res://startup/startup.tscn")
const Preferences := preload("res://startup/preferences.gd")
const Progress := preload("res://mission/mission_progress.gd")
const Controls := preload("res://startup/control_bindings.gd")
const IRA := {"gender": "woman", "hair": "braid", "outfit": "traditional"}
const OMKAR := {"gender": "man", "hair": "swept", "outfit": "kurta"}

var _app: Node
var _failures := 0
var _checks := 0
var _storage := "user://avatar-probe-%d.json" % OS.get_process_id()
var _progress_folder := "user://avatar-probe-%d" % OS.get_process_id()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var legacy := FileAccess.open(_storage, FileAccess.WRITE)
	legacy.store_string(JSON.stringify({"version": 1, "profiles": [{"id": "1", "name": "Player"}]}))
	legacy.close()
	_app = Start.instantiate()
	_app.preferences.storage_path = _storage
	_app.mission_progress_directory = _progress_folder
	root.add_child(_app)
	await _frames()
	_expect(_app.preferences.active_avatar_options.is_empty(), "existing profile keeps the original default")
	_expect(_app.preferences.set_avatar_options({"gender": "woman", "hair": 5, "outfit": "unknown"}) == ERR_INVALID_PARAMETER,
		"invalid choice IDs are rejected")
	_activate(_app.menu, "AppearanceButton")
	await _frames()
	var creator: Control = _app._avatar_creator
	_expect(creator != null and not _app.menu.visible, "Character Creator opens from the title")
	if creator == null:
		quit(1)
		return
	var hair := creator.find_child("HairChoice", true, false) as OptionButton
	var outfit := creator.find_child("OutfitChoice", true, false) as OptionButton
	_expect(hair.item_count == 6 and outfit.item_count == 3, "six hairstyles and three outfits are available")
	hair.show_popup()
	await _frames()
	_expect(hair.get_popup().visible, "hairstyle list opens")
	_app._go_back()
	_expect(not hair.get_popup().visible and _app._avatar_creator == creator, "Back closes the list before leaving the creator")
	_choose(creator, "HairChoice", 2)
	_choose(creator, "OutfitChoice", 2)
	await _frames()
	_expect(creator._preview_character.avatar_options == OMKAR, "live Omkar preview uses selected hair and outfit")
	await _capture("avatar-creator-omkar")
	var facing: float = creator._preview_turn.rotation.y
	_press(creator, "RotateLeftButton")
	_expect(not is_equal_approx(creator._preview_turn.rotation.y, facing), "preview turns to inspect the hairstyle")
	_choose(creator, "GenderChoice", 1)
	_choose(creator, "HairChoice", 4)
	_choose(creator, "OutfitChoice", 0)
	await _frames()
	_expect(creator._preview_character.avatar_options == IRA and hair.item_count == 6 and outfit.item_count == 3,
		"Ira has the selected hair and outfit with all six hairstyles available")
	_expect(_app.preferences.active_avatar_options.is_empty(), "editing the preview leaves the profile untouched")
	_press(creator, "BackButton")
	await _frames()
	_expect(_app._avatar_creator == null and _app.preferences.active_avatar_options.is_empty(), "Back discards pending choices")
	var progress := Progress.new("1", _progress_folder)
	_expect(progress.save_arrival(), "seed an isolated arrival checkpoint before updating appearance")
	_app.menu.show_home()
	await _frames()
	_press(_app.menu, "AppearanceButton")
	await _frames()
	creator = _app._avatar_creator
	_choose(creator, "GenderChoice", 1)
	_choose(creator, "HairChoice", 4)
	_choose(creator, "OutfitChoice", 0)
	await _frames()
	await _capture("avatar-creator-ira")
	_press(creator, "PreviewZoomButton")
	await _frames()
	_expect(creator._preview_camera.position.z > -1.0, "Face view moves the camera closer")
	await _capture("avatar-creator-ira-face")
	_activate(creator, "ApplyButton")
	await _frames()
	_expect(_app._avatar_creator == null and _app.preferences.active_avatar_options == IRA, "Apply saves the selected appearance")
	var prefs := Preferences.new()
	prefs.storage_path = _storage
	root.add_child(prefs)
	_expect(prefs.active_avatar_options == IRA, "appearance reloads from a separate preferences instance")
	prefs.queue_free()
	_expect(_app.preferences.create_profile("QA Other") == OK and _app.preferences.active_avatar_options.is_empty(),
		"new profile has independent appearance")
	_expect(_app.preferences.set_avatar_options(OMKAR) == OK and _app.preferences.select_profile("1") == OK
		and _app.preferences.active_avatar_options == IRA, "switching profile restores its selected appearance")
	_expect(progress.arrival_seen() and _app.preferences.active_campaign_generation == 0, "Apply preserves the existing checkpoint")
	_app.menu.show_home()
	await _frames()
	_press(_app.menu, "ContinueButton")
	await _frames(8)
	var game: Node = _app.gameplay
	_expect(game.player.display_name == "Ira Shirodkar" and game.player.visual.avatar_options == IRA,
		"Continue creates Ira in the selected outfit")
	_expect(game._arrival_intro == null and progress.arrival_seen(), "appearance is independent of campaign progress")
	_expect(game.player.visual.animation_player.current_animation == &"idle", "configured character uses established locomotion")
	_expect(game.dialogue.speak("prakash-dabba") > 0.0 and game.dialogue._line.contains("Ira")
		and game.dialogue._player.stream != null, "a contact addresses the selected protagonist by name")
	game.dialogue.stop()
	await _capture("avatar-ira-in-ranwar")
	game._seat_player_in_car(game.car)
	_expect(game._player_car_driver.avatar_options == IRA and game._player_car_driver.visible,
		"car uses the chosen appearance")
	for vehicle: Node in [game.rickshaw, game.motorcycle, game.scooter]:
		vehicle.set_driver_active(true)
		var occupant: Node3D = vehicle._rider_model if vehicle.is_two_wheeler else vehicle._driver
		_expect(occupant.avatar_options == IRA and occupant.is_visible_in_tree(), "%s uses the chosen appearance" % vehicle.vehicle_label)
		vehicle.set_driver_active(false)
	_app._return_to_title()
	await _frames()
	_expect(_app.preferences.select_profile("2") == OK and _app.preferences.set_avatar_options(IRA) == OK,
		"select Ira on the fresh profile")
	_app.menu.show_home()
	await _frames()
	_press(_app.menu, "PlayButton")
	await _frames(8)
	game = _app.gameplay
	_expect(game._arrival_intro != null and game._arrival_intro.subtitle().contains("Ira Shirodkar"),
		"the fresh campaign introduces Ira by name")
	game._update_arrival_intro(1.6)
	_expect(game.dialogue._speaker == "Ira" and game.dialogue._player.playing, "the arrival plays Ira's voice")
	_app._return_to_title()
	await _frames()
	var directory := DirAccess.open(_progress_folder)
	if directory != null:
		for filename: String in directory.get_files():
			directory.remove(filename)
		DirAccess.remove_absolute(_progress_folder)
	for path: String in [_storage, _storage + ".bak"]:
		DirAccess.remove_absolute(path)
	print("Character creator smoke: %d failures in %d checks" % [_failures, _checks])
	quit(0 if _failures == 0 else 1)


func _choose(parent: Control, node_name: String, index: int) -> void:
	var button := parent.find_child(node_name, true, false) as OptionButton
	button.select(index)
	button.item_selected.emit(index)


func _press(parent: Control, node_name: String) -> void:
	var button := parent.find_child(node_name, true, false) as Button
	if button == null:
		_expect(false, "missing action %s" % node_name)
		return
	button.pressed.emit()


func _activate(parent: Control, node_name: String) -> void:
	if not Controls.uses_touch_ui():
		_press(parent, node_name)
		return
	var button := parent.find_child(node_name, true, false) as Button
	if button == null:
		_expect(false, "missing touch action %s" % node_name)
		return
	for pressed: bool in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.position = button.get_viewport_transform() * button.get_global_transform() * (button.size * 0.5)
		touch.pressed = pressed
		Input.parse_input_event(touch)
		Input.flush_buffered_events()


func _frames(count := 5) -> void:
	for index in range(count):
		await process_frame


func _capture(filename: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var path := "user://%s.png" % filename
	_expect(root.get_texture().get_image().save_png(path) == OK, "capture %s" % filename)
	print("Capture %s" % ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)
