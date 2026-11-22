extends RefCounted

const KEYBOARD := "keyboard"
const GAMEPAD := "gamepad"
const ACTION_LABELS := {
	"move_forward": "Forward",
	"move_back": "Back / reverse",
	"move_left": "Move / steer left",
	"move_right": "Move / steer right",
	"look_up": "Look up",
	"look_down": "Look down",
	"look_left": "Look left",
	"look_right": "Look right",
	"run": "Jog",
	"interact": "Interact",
	"brake": "Brake",
	"recover": "Reset",
	"pause_game": "Pause",
}
const MOVE_ACTIONS := ["move_forward", "move_back", "move_left", "move_right"]
const LOOK_ACTIONS := ["look_up", "look_down", "look_left", "look_right"]
const BUTTON_LABELS := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "View", JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-pad Up", JOY_BUTTON_DPAD_DOWN: "D-pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-pad Left", JOY_BUTTON_DPAD_RIGHT: "D-pad Right",
}
const AXIS_LABELS := {
	JOY_AXIS_LEFT_X: ["Left stick left", "Left stick right"],
	JOY_AXIS_LEFT_Y: ["Left stick up", "Left stick down"],
	JOY_AXIS_RIGHT_X: ["Right stick left", "Right stick right"],
	JOY_AXIS_RIGHT_Y: ["Right stick up", "Right stick down"],
	JOY_AXIS_TRIGGER_LEFT: ["LT", "LT"],
	JOY_AXIS_TRIGGER_RIGHT: ["RT", "RT"],
}


static func uses_touch_ui() -> bool:
	return OS.has_feature("mobile") or "--touch-preview" in OS.get_cmdline_user_args()


static func defaults() -> Dictionary:
	return {KEYBOARD: {}, GAMEPAD: {}}


static func actions_for(device: String) -> Array[String]:
	var actions: Array[String] = []
	for action: String in ACTION_LABELS:
		if device != KEYBOARD or not action.begins_with("look_"):
			actions.append(action)
	return actions


static func input_device(event: InputEvent) -> String:
	if event is InputEventKey:
		return KEYBOARD
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return GAMEPAD
	return ""


static func binding_data(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"key": event.physical_keycode}
	if event is InputEventJoypadButton:
		return {"button": event.button_index}
	if event is InputEventJoypadMotion:
		return {"axis": event.axis, "direction": -1 if event.axis_value < 0.0 else 1}
	return {}


static func custom_event(device: String, binding: Dictionary) -> InputEvent:
	if device == KEYBOARD:
		var key := _whole_number(binding.get("key"))
		if key <= KEY_NONE or key in [KEY_ESCAPE, KEY_UNKNOWN] or OS.get_keycode_string(key).is_empty():
			return null
		var event := InputEventKey.new()
		event.device = -1
		event.physical_keycode = key as Key
		return event
	if device != GAMEPAD:
		return null
	if binding.has("button"):
		var button := _whole_number(binding.get("button"))
		if not BUTTON_LABELS.has(button) or button == JOY_BUTTON_B:
			return null
		var event := InputEventJoypadButton.new()
		event.device = -1
		event.button_index = button as JoyButton
		return event
	var axis := _whole_number(binding.get("axis"))
	var direction := _whole_number(binding.get("direction"))
	if not AXIS_LABELS.has(axis) or absi(direction) != 1:
		return null
	if axis >= JOY_AXIS_TRIGGER_LEFT and direction < 0:
		return null
	var event := InputEventJoypadMotion.new()
	event.device = -1
	event.axis = axis as JoyAxis
	event.axis_value = float(direction)
	return event


static func normalized(value: Variant) -> Dictionary:
	var controls := defaults()
	if not value is Dictionary:
		return controls
	for device: String in controls:
		var bindings: Variant = value.get(device)
		if not bindings is Dictionary:
			continue
		for action: String in actions_for(device):
			var binding: Variant = bindings.get(action)
			if binding is Dictionary:
				var event := custom_event(device, binding)
				if event != null and not (action == "pause_game" and event is InputEventJoypadMotion):
					controls[device][action] = binding_data(event)
		if not _unique(controls[device], device):
			controls[device] = {}
	return controls


static func conflict(action: String, device: String, event: InputEvent) -> String:
	var candidate := binding_data(event)
	for other: String in actions_for(device):
		if other == action:
			continue
		for bound: InputEvent in InputMap.action_get_events(other):
			if input_device(bound) == device and binding_data(bound) == candidate:
				return ACTION_LABELS[other]
	return ""


static func apply(controls: Dictionary) -> void:
	for action: String in ACTION_LABELS:
		Input.action_release(action)
		InputMap.action_erase_events(action)
		for device: String in controls:
			for event: InputEvent in _events(action, device, controls[device]):
				InputMap.action_add_event(action, event)


static func label(action: String, device: String, first_only := false) -> String:
	var labels: Array[String] = []
	for event: InputEvent in InputMap.action_get_events(action):
		if input_device(event) != device:
			continue
		labels.append(_event_label(event))
		if first_only:
			break
	return " / ".join(labels)


static func direction_label(actions: Array, device: String) -> String:
	var labels: Array[String] = []
	for action: String in actions:
		labels.append(label(action, device))
	if labels == ["W / Up", "S / Down", "A / Left", "D / Right"]:
		return "WASD / arrows"
	if labels == ["Left stick up", "Left stick down", "Left stick left", "Left stick right"]:
		return "Left stick"
	if labels == ["Right stick up", "Right stick down", "Right stick left", "Right stick right"]:
		return "Right stick"
	return ", ".join(labels)


static func _events(action: String, device: String, overrides: Dictionary) -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	if overrides.has(action):
		var event := custom_event(device, overrides[action])
		if event != null:
			events.append(event)
			return events
	var settings: Dictionary = ProjectSettings.get_setting("input/" + action, {})
	for event: InputEvent in settings.get("events", []):
		if input_device(event) == device:
			events.append(event)
	return events


static func _unique(overrides: Dictionary, device: String) -> bool:
	var seen: Array[Dictionary] = []
	for action: String in actions_for(device):
		for event: InputEvent in _events(action, device, overrides):
			var binding := binding_data(event)
			if binding in seen:
				return false
			seen.append(binding)
	return true


static func _event_label(event: InputEvent) -> String:
	if event is InputEventKey:
		var code: Key = event.physical_keycode
		if DisplayServer.get_name() != "headless":
			var local_key := DisplayServer.keyboard_get_keycode_from_physical(code)
			if local_key != KEY_NONE:
				code = local_key
		return "Esc" if code == KEY_ESCAPE else OS.get_keycode_string(code)
	if event is InputEventJoypadButton:
		return BUTTON_LABELS.get(event.button_index, "Button %d" % event.button_index)
	return AXIS_LABELS[event.axis][0 if event.axis_value < 0.0 else 1]


static func _whole_number(value: Variant) -> int:
	if value is int or value is float:
		var number := float(value)
		if is_finite(number) and absf(number) <= 0x7fffff and number == floorf(number):
			return int(number)
	return -100
