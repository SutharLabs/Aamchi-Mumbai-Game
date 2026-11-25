extends SceneTree

const Start := preload("res://startup/startup.tscn")
const Preferences := preload("res://startup/preferences.gd")
const Controls := preload("res://startup/control_bindings.gd")
const RanwarMap := preload("res://startup/ranwar_map.gd")
const World := preload("res://world/phase1_world.gd")
const Progress := preload("res://mission/mission_progress.gd")
var _failures := 0
var _checks := 0
var _capture_enabled := false
var app: Node


func _initialize() -> void:
	_capture_enabled = "--capture" in OS.get_cmdline_user_args()
	_run.call_deferred()


func _run() -> void:
	app = Start.instantiate()
	var storage := "user://menu-probe-%s.json" % OS.get_process_id()
	app.preferences.storage_path = storage
	app.mission_progress_directory = "user://menu-probe-%s" % OS.get_process_id()
	var legacy := FileAccess.open(storage, FileAccess.WRITE)
	legacy.store_string(JSON.stringify({
		"version": 1,
		"profiles": [{"id": "1", "name": "Player"}],
		"active_profile_id": "1",
		"settings": {"master_volume": 0.8, "look_sensitivity": 1.0, "fullscreen": false},
	}))
	legacy.close()
	root.add_child(app)
	await _settle()
	var touch_preview := Controls.uses_touch_ui()
	_expect(is_equal_approx(app.preferences.master_volume, 0.8) and Controls.label("interact", Controls.KEYBOARD) == "E", "existing saves keep settings and receive default controls")
	var title_options := ["New Game", "Character Creator", "Profiles", "Settings", "Controls", "Credits"]
	if not touch_preview:
		title_options.append("Quit to Desktop")
	_expect(_top_actions() == title_options, "title offers the shared actions in order and treats desktop Quit as platform-specific")
	_expect(app.gameplay == null and _has_label("आमची मुंबई"), "title shows Marathi identity before creating a game")
	_expect(root.gui_get_focus_owner() == _button("PlayButton"), "initial keyboard focus")
	_expect(Input.emulate_mouse_from_touch, "touch emulation enabled on title")
	await _capture("startup-home.png")
	_press("CreditsButton")
	await _settle()
	_expect(_has_label("Map data") and _has_label("Motion capture") and _has_label("Game engine") and _has_label("Devanagari type"), "credits cover map data, motion, engine and font")
	_expect(_has_button_text("Derived route layout") and _has_button_text("CC BY 4.0"), "actionable attribution")
	await _capture("startup-credits.png")
	_key(KEY_ESCAPE)
	await _settle()
	_expect(_button("PlayButton") != null, "Escape from credits returns home")
	_press("HelpButton")
	await _settle()
	_expect(_has_label("Controls") and _has_label("On foot") and _has_label("Driving"), "title Help opens the controls guide")
	_expect(_has_label("Left stick") if touch_preview else _has_label("WASD / arrows"), "Help lists the active platform controls")
	_expect(root.gui_get_focus_owner() == _button("BackButton"), "Help focuses the Back button")
	_press("BackButton")
	await _settle()
	_expect(_button("PlayButton") != null, "Help Back returns to the title")
	_press("ProfilesButton")
	await _settle()
	var field := app.menu.find_child("ProfileNameInput", true, false) as LineEdit
	field.text = "मीरा"
	_press("CreateProfileButton")
	await _settle()
	_expect(app.preferences.active_profile_name == "मीरा" and app.preferences.profiles.size() == 2, "create and select a Marathi profile name")
	field = app.menu.find_child("ProfileNameInput", true, false) as LineEdit
	field.text = "QA Tara"
	_press("RenameProfileButton")
	await _settle()
	_expect(app.preferences.active_profile_name == "QA Tara", "rename active profile")
	var selector := app.menu.find_child("ProfileSelector", true, false) as OptionButton
	selector.item_selected.emit(0)
	await _settle()
	_expect(app.preferences.active_profile_name == "Player", "switch to original profile")
	await _capture("startup-profiles.png")
	_press("BackButton")
	await _settle()
	_press("SettingsButton")
	await _settle()
	var volume := app.menu.find_child("MasterVolumeSlider", true, false) as HSlider
	var look := app.menu.find_child("LookSensitivitySlider", true, false) as HSlider
	var voice := app.menu.find_child("DialogueVolumeSlider", true, false) as HSlider
	var names := app.menu.find_child("SpeakerNamesToggle", true, false) as CheckButton
	var sizes := app.menu.find_child("SubtitleSize", true, false) as OptionButton
	var quality := app.menu.find_child("GraphicsQuality", true, false) as OptionButton
	_expect(_has_label("Gameplay") and _has_label("Controls") and _has_label("Audio") and _has_label("Display")
		and _has_label("Accessibility"), "settings have the five shared groups")
	_expect(app.preferences.subtitle_enabled and app.preferences.subtitle_speaker_names and not app.preferences.subtitle_large
		and is_equal_approx(app.preferences.dialogue_volume, 1.0), "old preferences receive readable default dialogue settings")
	volume.value = 0.65
	look.value = 1.35
	voice.value = 0.55
	names.button_pressed = false
	sizes.select(1)
	quality.select(1)
	_expect(is_equal_approx(app.preferences.dialogue_volume, 1.0) and app.preferences.subtitle_speaker_names,
		"edits remain staged until Apply Settings")
	_press("ApplySettingsButton")
	await _settle()
	_expect(is_equal_approx(app.preferences.master_volume, 0.65), "master volume applied")
	_expect(is_equal_approx(app.preferences.look_sensitivity, 1.35), "camera sensitivity applied")
	_expect(is_equal_approx(app.preferences.dialogue_volume, 0.55) and not app.preferences.subtitle_speaker_names
		and app.preferences.subtitle_large, "dialogue volume, speaker names and subtitle size apply together")
	_expect(root.msaa_3d == Viewport.MSAA_2X, "Medium graphics changes the actual viewport MSAA")
	_expect(FileAccess.file_exists(storage), "settings saved locally")
	var restored := Preferences.new()
	restored.storage_path = storage
	root.add_child(restored)
	_expect(restored.profiles.size() == 2 and restored.active_profile_name == "Player" and is_equal_approx(restored.look_sensitivity, 1.35), "profiles and settings reload from disk")
	_expect(restored.subtitle_large and not restored.subtitle_speaker_names and is_equal_approx(restored.dialogue_volume, 0.55),
		"dialogue settings survive reload")
	restored.queue_free()
	if app.preferences.supports_fullscreen and not touch_preview and DisplayServer.get_name() != "headless":
		var fullscreen := app.menu.find_child("FullscreenToggle", true, false) as CheckButton
		fullscreen.button_pressed = true
		_press("ApplySettingsButton")
		await _settle()
		_expect(root.mode == Window.MODE_FULLSCREEN, "fullscreen setting changes the native window")
		fullscreen.button_pressed = false
		_press("ApplySettingsButton")
		await _settle()
		_expect(root.mode == Window.MODE_WINDOWED, "windowed mode can be restored from settings")
		var vsync := app.menu.find_child("VSyncToggle", true, false) as CheckButton
		vsync.button_pressed = false
		_press("ApplySettingsButton")
		await _settle()
		_expect(DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED, "VSync changes the actual desktop window setting")
		vsync.button_pressed = true
		_press("ApplySettingsButton")
		await _settle()
	await _capture("startup-settings.png")
	_press("JumpToAccessibility")
	await _settle()
	var settings_scroll := app.menu.find_child("MenuScroll", true, false) as ScrollContainer
	_expect(settings_scroll.scroll_vertical > 400 and settings_scroll.get_global_rect().has_point(names.get_global_rect().get_center()),
		"Accessibility jumps directly to the subtitle options")
	_expect(_button("ApplySettingsButton").get_global_rect().position.y >= settings_scroll.get_global_rect().end.y,
		"Apply Settings remains visible while settings scroll")
	await _capture("startup-accessibility.png")
	_press("JumpToGameplay")
	await _settle()
	_expect(settings_scroll.scroll_vertical < 40, "Gameplay returns to the start of the settings page")
	if touch_preview:
		_expect(_button("ControlBindingsButton") == null, "touch settings do not expose desktop bindings")
		_expect(app.menu.find_child("FullscreenToggle", true, false) == null and app.menu.find_child("VSyncToggle", true, false) == null,
			"touch settings omit desktop-only window controls")
	else:
		await _check_control_bindings(storage)
	_press("BackButton")
	await _settle()
	if touch_preview:
		_key(KEY_ENTER)
	else:
		_joy_menu(JOY_BUTTON_DPAD_DOWN)
		await _settle()
		_expect(root.gui_get_focus_owner() == _button("AppearanceButton"), "gamepad navigates to Character Creator")
		_joy_menu(JOY_BUTTON_A)
		await _settle()
		_expect(app._avatar_creator != null and root.gui_get_focus_owner().name == &"GenderChoice",
			"gamepad opens Character Creator and focuses Gender")
		_joy_menu(JOY_BUTTON_B)
		await _settle()
		_expect(app._avatar_creator == null and root.gui_get_focus_owner() == _button("PlayButton"),
			"gamepad returns from Character Creator to the title")
		_joy_menu(JOY_BUTTON_A)
	await _settle()
	_expect(app.gameplay != null and not app.menu.visible, "keyboard activates Play" if touch_preview else "gamepad activates Play")
	if app.gameplay == null:
		quit(1)
		return
	app.gameplay.finish_arrival()
	await _physics_frames(5)
	_expect(not Input.emulate_mouse_from_touch, "touch emulation disabled in play")
	_expect(is_equal_approx(app.gameplay.look_sensitivity, 1.35), "saved sensitivity reaches game")
	var yaw: float = app.gameplay._yaw
	app.gameplay._apply_look(Vector2(50.0, 0.0))
	_expect(is_equal_approx(absf(angle_difference(yaw, app.gameplay._yaw)), 50.0 * 0.0031 * 1.35), "sensitivity scales the gameplay camera")
	var map_credit_found := false
	var controls_list_found := false
	for label: Label in app.gameplay.hud.find_children("*", "Label", true, false):
		map_credit_found = map_credit_found or label.text.contains("OpenStreetMap")
		controls_list_found = controls_list_found or label.text.contains("WASD") or label.text.contains("Left stick")
	_expect(not map_credit_found, "map credit stays off the normal driving HUD")
	_expect(not controls_list_found, "full controls stay off the gameplay HUD")
	if not touch_preview:
		var pause_hint := app.gameplay.hud.find_child("PauseHint", true, false) as PanelContainer
		_expect(pause_hint != null and pause_hint.size.x <= 110.0 and pause_hint.position.x > pause_hint.get_parent().size.x * 0.75, "desktop Pause hint stays compact at the top right")
		await _check_gamepad_gameplay()
	_key(KEY_ESCAPE)
	await _settle()
	_expect(paused and app.menu.visible and _button("ResumeButton") != null, "Escape pauses and opens menu")
	_expect(_top_actions() == ["Resume", "Map", "Settings", "Controls", "Main Menu"], "pause presents the same action order without an active job")
	_expect(_has_label(app.gameplay.player.display_name), "pause shows the protagonist's name")
	_expect(not app.gameplay.hud.visible, "pause menu hides the gameplay HUD")
	await _capture("startup-paused.png")
	_press("MapButton")
	await _settle()
	var map_view := app.menu.find_child("RanwarMap", true, false) as RanwarMap
	var world: Node3D = app.gameplay.world
	_expect(map_view != null and paused and map_view._roads.size() == world._roads.size()
		and map_view._footway.size() == world._gully.size(), "pause map shows the projected road and footway")
	_expect(map_view != null and map_view._position.is_equal_approx(map_view._north_up(app.gameplay.player.global_position)),
		"map shows the walking actor's paused position")
	_expect(root.gui_get_focus_owner() == _button("BackButton"), "map focuses Back")
	await _capture("startup-map.png")
	if touch_preview:
		_tap_menu_button(_button("BackButton"))
	else:
		_key(KEY_ESCAPE)
	await _settle()
	_expect(_button("ResumeButton") != null and paused, "Back returns to the paused menu")
	_press("HelpButton")
	await _settle()
	_expect(_has_label("Controls") and paused, "Help is reachable while paused")
	await _capture("startup-help.png")
	_key(KEY_ESCAPE)
	await _settle()
	_expect(_button("ResumeButton") != null and paused, "Escape closes Help before resuming play")
	_press("HelpButton")
	await _settle()
	_press("CreditsButton")
	await _settle()
	_expect(_has_label("Map data") and paused, "credits reachable from pause")
	_key(KEY_ESCAPE)
	await _settle()
	_expect(_has_label("Controls") and paused, "Back returns from Credits to the Controls page")
	_key(KEY_ESCAPE)
	await _settle()
	_press("ResumeButton")
	await _settle()
	_expect(not paused and not app.menu.visible and app.gameplay.hud.visible, "resume restores play and HUD")
	if app.gameplay.hud.touch_enabled:
		var hud: CanvasLayer = app.gameplay.hud
		hud.move_axis = Vector2.UP
		var touch := InputEventScreenTouch.new()
		touch.index = 6
		touch.position = hud._touch_surface.get_global_transform_with_canvas() * hud._pause_rect().get_center()
		touch.pressed = true
		root.push_input(touch, true)
		await _settle()
		_expect(paused and hud.move_axis == Vector2.ZERO, "touch Pause opens the menu and clears held gameplay input")
	else:
		_key(KEY_ESCAPE)
	await _settle()
	_press("MainMenuButton")
	await _settle()
	_expect(app.gameplay == null and app.menu.visible and not paused, "main menu disposes the level")
	title_options.push_front("Continue")
	_expect(_top_actions() == title_options and root.gui_get_focus_owner() == _button("ContinueButton"), "a saved arrival shows and focuses Continue")
	_press("PlayButton")
	await _settle()
	_expect(root.gui_get_focus_owner() == _button("CancelNewGameButton"), "starting over requires confirmation and focuses Cancel")
	_press("CancelNewGameButton")
	await _settle()
	_press("ContinueButton")
	await _settle()
	_expect(app.gameplay != null and app.gameplay._arrival_intro == null, "Continue resumes the existing arrival checkpoint")
	app._pause_game()
	await _settle()
	_press("MainMenuButton")
	await _settle()
	_press("PlayButton")
	await _settle()
	_expect(Progress.new("1", app.mission_progress_directory, 1).save_arrival(),
		"fixture simulates a newer arrival file after recovering older preferences")
	_press("ConfirmNewGameButton")
	await _settle()
	var legacy_arrival: String = app.mission_progress_directory.path_join("arrival-1.json")
	var newer_arrival: String = app.mission_progress_directory.path_join("arrival-1-1.json")
	_expect(app.gameplay != null and app.gameplay._arrival_intro != null and app.preferences.active_campaign_generation == 2
		and FileAccess.file_exists(legacy_arrival) and FileAccess.file_exists(newer_arrival),
		"New Game restarts the story in a fresh generation and preserves previous files")
	var new_campaign_preferences := Preferences.new()
	new_campaign_preferences.storage_path = storage
	root.add_child(new_campaign_preferences)
	_expect(new_campaign_preferences.active_campaign_generation == 2, "the selected New Game generation survives restart")
	new_campaign_preferences.queue_free()
	for path in [storage, storage + ".bak", storage + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_arrival))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(newer_arrival))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(app.mission_progress_directory))
	print("Startup smoke: %d failures in %d checks" % [_failures, _checks])
	quit(0 if _failures == 0 else 1)


func _top_actions() -> Array[String]:
	var actions: Array[String] = []
	for item: Node in app.menu._content.get_children():
		if item is Button:
			actions.append(item.text)
	return actions


func _check_control_bindings(storage: String) -> void:
	_press("ControlBindingsButton")
	await _settle()
	_expect(_has_label("Control bindings") and _button("Bind_interact") != null, "Settings opens keyboard bindings")
	_press("Bind_interact")
	_key(KEY_W)
	_expect(_has_label("Already assigned to Forward. Choose another input."), "conflicting keyboard input is rejected")
	_key(KEY_ESCAPE)
	_expect(_button("Bind_interact").text == "E", "Escape cancels capture without leaving settings")
	_press("Bind_interact")
	_key(KEY_F)
	_expect(_button("Bind_interact").text == "F" and Controls.label("interact", Controls.GAMEPAD) == "A", "keyboard rebinding preserves the gamepad input")
	_press("GamepadBindingsButton")
	await _settle()
	_press("Bind_brake")
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 0.15)
	_expect(_button("Bind_brake").text == "Waiting for input…", "gamepad capture ignores analog drift")
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	_expect(_button("Bind_brake").text == "LT", "gamepad accepts an analog trigger binding")
	_press("RestoreBindingsButton")
	await _settle()
	_expect(_button("Bind_brake").text == "LB" and Controls.label("interact", Controls.KEYBOARD) == "F", "restoring one device preserves the other device")
	_press("Bind_brake")
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	var restored := Preferences.new()
	restored.storage_path = storage
	root.add_child(restored)
	_expect(Controls.label("interact", Controls.KEYBOARD) == "F" and Controls.label("brake", Controls.GAMEPAD) == "LT", "both control bindings reload from disk")
	restored.queue_free()
	_key(KEY_ESCAPE)
	await _settle()
	_expect(_button("ApplySettingsButton") != null, "bindings Back returns to Settings")
	_press("BackButton")
	await _settle()
	_press("HelpButton")
	await _settle()
	_expect(_has_label("F") and _has_label("LT") and _has_label("Gamepad"), "Help shows effective bindings for both devices")
	_press("BackButton")
	await _settle()
	_press("SettingsButton")
	await _settle()


func _check_gamepad_gameplay() -> void:
	var game := app.gameplay as Node3D
	var start: Vector3 = game.player.position
	_joy_axis(JOY_AXIS_LEFT_Y, -0.65)
	await _physics_frames(24)
	_joy_axis(JOY_AXIS_LEFT_Y, 0.0)
	_expect(game.player.position.distance_to(start) > 0.15, "gamepad left stick moves Omkar")
	var yaw: float = game._yaw
	_joy_axis(JOY_AXIS_RIGHT_X, 0.80)
	await _physics_frames(12)
	_joy_axis(JOY_AXIS_RIGHT_X, 0.0)
	_expect(absf(angle_difference(yaw, game._yaw)) > 0.1, "gamepad right stick pans the gameplay camera")
	game.player.position = Vector3(game.car.position.x, game.player.position.y, game.car.position.z + 2.7)
	await _physics_frames(3)
	await _joy_game(JOY_BUTTON_A)
	_expect(game.driving and game.active_vehicle == game.car, "gamepad Interact enters the car")
	_joy_axis(JOY_AXIS_LEFT_Y, -1.0)
	_joy_axis(JOY_AXIS_LEFT_X, 0.35)
	await _physics_frames(24)
	_expect(game.car.get_speed_mps() > 1.3 and absf(game.car.rotation.y) > 0.01, "gamepad stick accelerates and steers")
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await _physics_frames(22)
	_expect(game.car.get_speed_mps() < 0.2, "rebound trigger brakes while the gamepad throttle is held")
	_joy_axis(JOY_AXIS_LEFT_Y, 0.0)
	_joy_axis(JOY_AXIS_LEFT_X, 0.0)
	_joy_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	_joy_menu(JOY_BUTTON_START)
	await _settle()
	_press("MapButton")
	await _settle()
	var driving_map := app.menu.find_child("RanwarMap", true, false) as RanwarMap
	_expect(driving_map != null and game.driving
		and driving_map._position.is_equal_approx(driving_map._north_up(game.car.global_position)),
		"map follows the active car while driving")
	_joy_menu(JOY_BUTTON_B)
	await _settle()
	_joy_menu(JOY_BUTTON_B)
	await _settle()
	await _joy_game(JOY_BUTTON_A)
	_expect(not game.driving, "gamepad Interact exits after stopping")
	await _joy_game(JOY_BUTTON_Y)
	_expect(game.player.position.distance_to(World.PLAYER_START) < 0.2, "gamepad reset returns Omkar to the practice yard")
	_joy_menu(JOY_BUTTON_START)
	await _settle()
	_expect(paused and app.menu.visible, "gamepad Start opens Pause")
	_joy_menu(JOY_BUTTON_B)
	await _settle()
	_expect(not paused and not app.menu.visible, "gamepad B resumes play")
	game.player.position = Vector3(game.car.position.x, game.player.position.y, game.car.position.z + 2.7)
	await _physics_frames(3)
	await _key_game(KEY_E)
	_expect(not game.driving, "the overwritten keyboard action no longer enters the car")
	await _key_game(KEY_F)
	_expect(game.driving, "rebound keyboard Interact enters the car")
	await _joy_game(JOY_BUTTON_Y)


func _physics_frames(count: int) -> void:
	for index in range(count):
		await physics_frame


func _joy_event(button: JoyButton, pressed: bool) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	return event


func _joy_menu(button: JoyButton) -> void:
	root.push_input(_joy_event(button, true))
	root.push_input(_joy_event(button, false))


func _joy_game(button: JoyButton) -> void:
	Input.parse_input_event(_joy_event(button, true))
	Input.flush_buffered_events()
	await _physics_frames(3)
	Input.parse_input_event(_joy_event(button, false))
	Input.flush_buffered_events()
	await _physics_frames(2)


func _joy_axis(axis: JoyAxis, strength: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = strength
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _settle() -> void:
	for i in range(5):
		await process_frame


func _capture(name: String) -> void:
	if not _capture_enabled or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var path := "user://" + name
	var status := root.get_texture().get_image().save_png(path)
	_expect(status == OK, "write screenshot " + name)


func _button(node_name: String) -> Button:
	return app.menu.find_child(node_name, true, false) as Button


func _press(node_name: String) -> void:
	var button := _button(node_name)
	if button != null:
		button.pressed.emit()
	else:
		_expect(false, "missing action " + node_name)


func _tap_menu_button(button: Button) -> void:
	if button == null:
		_expect(false, "missing touch target")
		return
	for pressed: bool in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.position = button.get_viewport_transform() * button.get_global_transform() * (button.size * 0.5)
		touch.pressed = pressed
		Input.parse_input_event(touch)
		Input.flush_buffered_events()


func _key(key: Key) -> void:
	for pressed: bool in [true, false]:
		root.push_input(_key_event(key, pressed))


func _key_game(key: Key) -> void:
	Input.parse_input_event(_key_event(key, true))
	Input.flush_buffered_events()
	await _physics_frames(3)
	Input.parse_input_event(_key_event(key, false))
	Input.flush_buffered_events()
	await _physics_frames(2)


func _key_event(key: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	return event


func _has_label(text: String) -> bool:
	for label: Label in app.menu.find_children("*", "Label", true, false):
		if label.text == text:
			return true
	return false


func _has_button_text(text: String) -> bool:
	for button: Button in app.menu.find_children("*", "Button", true, false):
		if button.text == text:
			return true
	return false


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + description)
	else:
		print("PASS: " + description)
