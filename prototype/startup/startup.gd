extends Node

const Preferences := preload("res://startup/preferences.gd")
const Menu := preload("res://startup/menu.gd")
const Ranwar := preload("res://phase1.tscn")
const MissionProgress := preload("res://mission/mission_progress.gd")
const Career := preload("res://mission/ranwar_career.gd")

var preferences := Preferences.new()
var menu := Menu.new()
var gameplay: Node3D
var mission_progress_directory := "user://"
var _session_careers: Dictionary[String, Career] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(preferences)
	preferences.changed.connect(_apply_gameplay_preferences)
	menu.preferences = preferences
	var menu_layer := CanvasLayer.new()
	menu_layer.layer = 10
	add_child(menu_layer)
	menu_layer.add_child(menu)
	menu.play_requested.connect(_start_game)
	menu.resume_requested.connect(_resume_game)
	menu.main_menu_requested.connect(_return_to_title)
	menu.abandon_job_requested.connect(_abandon_job)
	menu.quit_requested.connect(get_tree().quit)
	_show_title()


func _input(event: InputEvent) -> void:
	if menu.capture_control_input(event):
		get_viewport().set_input_as_handled()
		return
	var menu_back := menu.visible and event.is_action_pressed(&"ui_cancel")
	var game_pause := gameplay != null and not get_tree().paused and event.is_action_pressed(&"pause_game", false, true)
	var gamepad_start: bool = (
		gameplay != null and get_tree().paused
		and event is InputEventJoypadButton
		and event.button_index == JOY_BUTTON_START and event.pressed
	)
	if game_pause or gamepad_start:
		gameplay.hud.set_gamepad_input(event is InputEventJoypadButton)
	if (menu_back or game_pause or gamepad_start) and _go_back():
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_node_ready():
		_go_back()


func _go_back() -> bool:
	if menu.visible and menu.back_requested():
		return true
	if gameplay == null:
		return false
	if get_tree().paused:
		_resume_game()
	else:
		_pause_game()
	return true


func _start_game() -> void:
	if gameplay != null:
		return
	gameplay = Ranwar.instantiate()
	gameplay.process_mode = Node.PROCESS_MODE_PAUSABLE
	gameplay.startup_pause_enabled = true
	var profile_id := preferences.active_profile_id
	gameplay.delivery_progress = MissionProgress.new(profile_id, mission_progress_directory)
	gameplay.career = _session_careers.get(profile_id)
	_apply_gameplay_preferences()
	gameplay.pause_requested.connect(_pause_game)
	add_child(gameplay)
	_session_careers[profile_id] = gameplay.career
	_resume_game()


func _pause_game() -> void:
	if gameplay == null or get_tree().paused:
		return
	gameplay.hud.clear_touch_input()
	gameplay.hud.hide()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.emulate_mouse_from_touch = true
	menu.show_pause(gameplay.player.display_name, gameplay.world._roads, gameplay.world._gully,
		gameplay._actor_position(), gameplay.story_target(), gameplay.delivery.can_abandon(), gameplay.session_status(),
		gameplay.world.facility_markers())


func _abandon_job() -> void:
	if gameplay != null and get_tree().paused and gameplay.delivery.can_abandon():
		gameplay.abandon_delivery()
		_resume_game()


func _resume_game() -> void:
	if gameplay == null:
		return
	menu.hide()
	gameplay.hud.refresh_bindings()
	gameplay.hud.show()
	Input.emulate_mouse_from_touch = false
	get_tree().paused = false
	if not gameplay.hud.touch_enabled and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _return_to_title() -> void:
	if gameplay != null:
		remove_child(gameplay)
		gameplay.queue_free()
		gameplay = null
	get_tree().paused = false
	_show_title()


func _show_title() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.emulate_mouse_from_touch = true
	menu.show_home()


func _apply_gameplay_preferences() -> void:
	if gameplay != null:
		gameplay.look_sensitivity = preferences.look_sensitivity
		gameplay.hud.set_live_map_enabled(preferences.live_map)
