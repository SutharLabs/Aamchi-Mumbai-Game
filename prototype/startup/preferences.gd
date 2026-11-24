extends Node

signal changed

const Controls := preload("res://startup/control_bindings.gd")
const MAX_PROFILE_NAME_LENGTH := 32
const MAX_PROFILES := 12
const MIN_LOOK_SENSITIVITY := 0.25
const MAX_LOOK_SENSITIVITY := 2.0
const _SCHEMA_VERSION := 1
const _MAX_FILE_BYTES := 64 * 1024
const _MAX_PROFILE_ID := 2147483647

var storage_path := "user://preferences.json"

var profiles: Array[Dictionary]:
	get:
		return _state["profiles"].duplicate(true)
var active_profile_id: String:
	get:
		return _state["active_profile_id"]
var active_profile_name: String:
	get:
		for profile: Dictionary in _state["profiles"]:
			if profile["id"] == active_profile_id:
				return profile["name"]
		return "Player"
var master_volume: float:
	get:
		return _state["settings"]["master_volume"]
var fullscreen: bool:
	get:
		return _state["settings"]["fullscreen"]
var look_sensitivity: float:
	get:
		return _state["settings"]["look_sensitivity"]
var live_map: bool:
	get:
		return _state["settings"]["live_map"]
var dialogue_volume: float:
	get:
		return _state["settings"]["dialogue_volume"]
var subtitle_enabled: bool:
	get:
		return _state["settings"]["subtitle_enabled"]
var subtitle_speaker_names: bool:
	get:
		return _state["settings"]["subtitle_speaker_names"]
var subtitle_large: bool:
	get:
		return _state["settings"]["subtitle_large"]
var graphics_quality: int:
	get:
		return _state["settings"]["graphics_quality"]
var vsync: bool:
	get:
		return _state["settings"]["vsync"]
var active_campaign_generation: int:
	get:
		return _state["campaign_generations"].get(active_profile_id, 0)
var supports_fullscreen: bool:
	get:
		return OS.has_feature("pc") and not OS.has_feature("web")

var _state: Dictionary = _default_state()
var _has_saved_state := false
var _has_newer_schema := false


func _ready() -> void:
	if _valid_storage_path():
		var primary := _read_document(storage_path)
		var version: Variant = primary.get("version")
		_has_newer_schema = _is_number(version) and version > _SCHEMA_VERSION
		var saved := _normalize(primary)
		if saved.is_empty():
			saved = _normalize(_read_document(storage_path + ".bak"))
		if not saved.is_empty():
			_state = saved
			_has_saved_state = true
	Controls.apply(_state["control_bindings"])
	_apply_settings()


func create_profile(display_name: String) -> Error:
	var name_value := _valid_name(display_name)
	if name_value.is_empty():
		return ERR_INVALID_PARAMETER
	var next_profiles := profiles
	if _name_exists(next_profiles, name_value):
		return ERR_ALREADY_EXISTS
	if next_profiles.size() >= MAX_PROFILES:
		return ERR_OUT_OF_MEMORY
	var next_id := 1
	for profile in next_profiles:
		next_id = maxi(next_id, int(profile["id"]) + 1)
	if next_id > _MAX_PROFILE_ID:
		return ERR_OUT_OF_MEMORY
	var id := str(next_id)
	next_profiles.append({"id": id, "name": name_value})
	var next_state := _state.duplicate(true)
	next_state["profiles"] = next_profiles
	next_state["active_profile_id"] = id
	return _commit(next_state)


func rename_profile(id: String, display_name: String) -> Error:
	var name_value := _valid_name(display_name)
	if name_value.is_empty():
		return ERR_INVALID_PARAMETER
	var next_profiles := profiles
	var index := _find_profile(next_profiles, id)
	if index < 0:
		return ERR_DOES_NOT_EXIST
	if next_profiles[index]["name"] == name_value:
		return OK
	if _name_exists(next_profiles, name_value, id):
		return ERR_ALREADY_EXISTS
	next_profiles[index]["name"] = name_value
	var next_state := _state.duplicate(true)
	next_state["profiles"] = next_profiles
	return _commit(next_state)


func select_profile(id: String) -> Error:
	if id == active_profile_id:
		return OK
	if _find_profile(_state["profiles"], id) < 0:
		return ERR_DOES_NOT_EXIST
	var next_state := _state.duplicate(true)
	next_state["active_profile_id"] = id
	return _commit(next_state)


func start_new_campaign(generation: int) -> Error:
	if generation <= active_campaign_generation or generation > _MAX_PROFILE_ID:
		return ERR_INVALID_PARAMETER
	var next_state := _state.duplicate(true)
	next_state["campaign_generations"][active_profile_id] = generation
	return _commit(next_state)


func set_settings(volume: float, use_fullscreen: bool, sensitivity: float, show_live_map: Variant = null) -> Error:
	return update_settings({
		"master_volume": volume,
		"fullscreen": use_fullscreen,
		"look_sensitivity": sensitivity,
		"live_map": live_map if show_live_map == null else show_live_map,
	})


func update_settings(changes: Dictionary) -> Error:
	var next_settings: Dictionary = _state["settings"].duplicate()
	for key: Variant in changes:
		var value: Variant = changes[key]
		match key:
			"master_volume", "dialogue_volume":
				if not _number_in_range(value, 0.0, 1.0):
					return ERR_INVALID_PARAMETER
			"look_sensitivity":
				if not _number_in_range(value, MIN_LOOK_SENSITIVITY, MAX_LOOK_SENSITIVITY):
					return ERR_INVALID_PARAMETER
			"graphics_quality":
				if not value is int or value < 0 or value > 2:
					return ERR_INVALID_PARAMETER
			"fullscreen", "vsync", "live_map", "subtitle_enabled", "subtitle_speaker_names", "subtitle_large":
				if not value is bool:
					return ERR_INVALID_PARAMETER
				if key in ["fullscreen", "vsync"] and not supports_fullscreen:
					continue
			_:
				return ERR_INVALID_PARAMETER
		next_settings[key] = value
	if next_settings == _state["settings"]:
		return OK
	var next_state := _state.duplicate(true)
	next_state["settings"] = next_settings
	return _commit(next_state)


func set_control_binding(action: String, device: String, input_event: InputEvent) -> Error:
	if not _state["control_bindings"].has(device) or action not in Controls.actions_for(device):
		return ERR_INVALID_PARAMETER
	if Controls.input_device(input_event) != device:
		return ERR_INVALID_PARAMETER
	var event := Controls.custom_event(device, Controls.binding_data(input_event))
	if event == null or (action == "pause_game" and event is InputEventJoypadMotion):
		return ERR_INVALID_PARAMETER
	if not Controls.conflict(action, device, event).is_empty():
		return ERR_ALREADY_EXISTS
	var next_state := _state.duplicate(true)
	next_state["control_bindings"][device][action] = Controls.binding_data(event)
	return _commit(next_state)


func reset_control_bindings(device: String) -> Error:
	var bindings: Dictionary = _state["control_bindings"]
	if not bindings.has(device):
		return ERR_INVALID_PARAMETER
	if bindings[device].is_empty():
		return OK
	var next_state := _state.duplicate(true)
	next_state["control_bindings"][device] = {}
	return _commit(next_state)


func _default_state() -> Dictionary:
	var entries: Array[Dictionary] = [{"id": "1", "name": "Player"}]
	return {
		"version": _SCHEMA_VERSION,
		"profiles": entries,
		"active_profile_id": "1",
		"campaign_generations": {},
		"settings": {
			"master_volume": 1.0,
			"dialogue_volume": 1.0,
			"fullscreen": false,
			"graphics_quality": 0,
			"vsync": true,
			"look_sensitivity": 1.0,
			"live_map": true,
			"subtitle_enabled": true,
			"subtitle_speaker_names": true,
			"subtitle_large": false,
		},
		"control_bindings": Controls.defaults(),
	}


func _normalize(raw: Dictionary) -> Dictionary:
	if raw.is_empty() or raw.get("version", _SCHEMA_VERSION) != _SCHEMA_VERSION:
		return {}
	var saved_profiles: Variant = raw.get("profiles", [])
	var saved_settings: Variant = raw.get("settings", {})
	if not saved_profiles is Array or not saved_settings is Dictionary:
		return {}
	var entries: Array[Dictionary] = []
	for entry: Variant in saved_profiles:
		if not entry is Dictionary or not entry.get("id") is String or not entry.get("name") is String:
			continue
		var id: String = entry["id"]
		var name_value := _valid_name(entry["name"])
		if not _valid_profile_id(id) or name_value.is_empty():
			continue
		if _find_profile(entries, id) >= 0 or _name_exists(entries, name_value):
			continue
		entries.append({"id": id, "name": name_value})
		if entries.size() == MAX_PROFILES:
			break
	if entries.is_empty() and not saved_profiles.is_empty():
		return {}
	var normalized := _default_state()
	if not entries.is_empty():
		normalized["profiles"] = entries
	var selected: Variant = raw.get("active_profile_id")
	if selected is String and _find_profile(normalized["profiles"], selected) >= 0:
		normalized["active_profile_id"] = selected
	else:
		normalized["active_profile_id"] = normalized["profiles"][0]["id"]
	var generations: Variant = raw.get("campaign_generations")
	if generations is Dictionary:
		for entry: Dictionary in normalized["profiles"]:
			var generation: Variant = generations.get(entry["id"])
			if _number_in_range(generation, 1, _MAX_PROFILE_ID) and generation == int(generation):
				normalized["campaign_generations"][entry["id"]] = int(generation)
	var settings: Dictionary = normalized["settings"]
	settings["master_volume"] = _bounded_number(saved_settings.get("master_volume"), 1.0, 0.0, 1.0)
	settings["dialogue_volume"] = _bounded_number(saved_settings.get("dialogue_volume"), 1.0, 0.0, 1.0)
	settings["look_sensitivity"] = _bounded_number(
		saved_settings.get("look_sensitivity"), 1.0, MIN_LOOK_SENSITIVITY, MAX_LOOK_SENSITIVITY)
	settings["graphics_quality"] = int(_bounded_number(saved_settings.get("graphics_quality"), 0.0, 0.0, 2.0))
	for key: String in ["fullscreen", "vsync", "live_map", "subtitle_enabled", "subtitle_speaker_names", "subtitle_large"]:
		if saved_settings.get(key) is bool:
			settings[key] = saved_settings[key]
	normalized["control_bindings"] = Controls.normalized(raw.get("control_bindings"))
	return normalized


func _valid_name(value: String) -> String:
	if value.length() > MAX_PROFILE_NAME_LENGTH:
		return ""
	for index in range(value.length()):
		var code := value.unicode_at(index)
		if code < 32 or (code >= 127 and code <= 159) or code == 0x2028 or code == 0x2029:
			return ""
		# Directional overrides and invisible separators can mask duplicate names.
		if (code >= 0x202A and code <= 0x202E) or (code >= 0x2066 and code <= 0x2069) or code == 0x200B:
			return ""
	return value.strip_edges()


func _valid_profile_id(id: String) -> bool:
	if id.length() > 10 or not id.is_valid_int():
		return false
	var value := int(id)
	return value > 0 and value <= _MAX_PROFILE_ID and str(value) == id


func _find_profile(entries: Array[Dictionary], id: String) -> int:
	for index in range(entries.size()):
		if entries[index]["id"] == id:
			return index
	return -1


func _name_exists(entries: Array[Dictionary], display_name: String, except_id := "") -> bool:
	for profile in entries:
		var existing: String = profile["name"]
		if profile["id"] != except_id and existing.nocasecmp_to(display_name) == 0:
			return true
	return false


func _is_number(value: Variant) -> bool:
	return value is int or value is float


func _number_in_range(value: Variant, low: float, high: float) -> bool:
	return _is_number(value) and is_finite(float(value)) and value >= low and value <= high


func _bounded_number(value: Variant, fallback: float, low: float, high: float) -> float:
	if not _is_number(value) or not is_finite(float(value)):
		return fallback
	return clampf(float(value), low, high)


func _valid_storage_path() -> bool:
	var filename := storage_path.get_file()
	return storage_path == "user://" + filename and filename.is_valid_filename() and filename.ends_with(".json")


func _read_document(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() == 0 or file.get_length() > _MAX_FILE_BYTES:
		return {}
	var payload := file.get_buffer(file.get_length())
	file.close()
	var parser := JSON.new()
	if parser.parse(payload.get_string_from_utf8()) != OK or not parser.data is Dictionary:
		return {}
	return parser.data


func _commit(next_state: Dictionary) -> Error:
	if not _valid_storage_path():
		return ERR_INVALID_PARAMETER
	if _has_newer_schema:
		return ERR_UNAVAILABLE
	# Keep the last valid state available if the primary file cannot be read later.
	if _has_saved_state:
		var backup_error := _write_atomic(storage_path + ".bak", _state)
		if backup_error != OK:
			return backup_error
	var error := _write_atomic(storage_path, next_state)
	if error != OK:
		return error
	if _state["control_bindings"] != next_state["control_bindings"]:
		Controls.apply(next_state["control_bindings"])
	_state = next_state
	_has_saved_state = true
	_apply_settings()
	changed.emit()
	return OK


func _write_atomic(path: String, value: Dictionary) -> Error:
	var target := ProjectSettings.globalize_path(path)
	var temporary := "%s.%d.%d.tmp" % [target, OS.get_process_id(), get_instance_id()]
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var stored := file.store_string(JSON.stringify(value) + "\n")
	file.flush()
	var error := file.get_error()
	file.close()
	if not stored and error == OK:
		error = ERR_FILE_CANT_WRITE
	if error == OK:
		error = DirAccess.rename_absolute(temporary, target)
	if error != OK:
		DirAccess.remove_absolute(temporary)
	return error


func _apply_settings() -> void:
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_volume_db(master, linear_to_db(maxf(master_volume, 0.0001)))
		AudioServer.set_bus_mute(master, master_volume == 0.0)
	get_window().msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][graphics_quality]
	if supports_fullscreen and DisplayServer.get_name() != "headless":
		var window := get_window()
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED, window.get_window_id())
		var in_fullscreen := window.mode == Window.MODE_FULLSCREEN or window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN
		if fullscreen != in_fullscreen:
			window.mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
