extends RefCounted
## Tracks the parcel run independently of its world markers and save file.

signal state_changed

const MISSION_ID := &"ranwar_parcel_run"
const OFFER := &"offer"
const PICKUP := &"pickup"
const DROPOFF := &"dropoff"
const FAILED := &"failed"
const COMPLETED := &"completed"

var state: StringName:
	get:
		return _state

var checkpoint: StringName:
	get:
		return _checkpoint

var _state := OFFER
var _checkpoint := OFFER


func interact() -> void:
	match _state:
		OFFER:
			_transition(PICKUP, PICKUP)
		PICKUP:
			_transition(DROPOFF, DROPOFF)
		DROPOFF:
			_transition(COMPLETED, COMPLETED)
		FAILED:
			_transition(_checkpoint, _checkpoint)


func fail() -> void:
	if _state == PICKUP or _state == DROPOFF:
		_transition(FAILED, _checkpoint)


func cancel() -> void:
	if _state != COMPLETED:
		_transition(OFFER, OFFER)


func snapshot() -> Dictionary:
	return {
		"mission_id": String(MISSION_ID),
		"state": String(_state),
		"checkpoint": String(_checkpoint),
	}


func restore(data: Dictionary) -> bool:
	if not valid_snapshot(data):
		return false
	_transition(StringName(data["state"]), StringName(data["checkpoint"]))
	return true


static func valid_snapshot(data: Dictionary) -> bool:
	# Accept only the fields and state pairs this mission actually persists.
	if data.size() != 3:
		return false
	var mission: Variant = data.get("mission_id")
	var saved_state: Variant = data.get("state")
	var saved_checkpoint: Variant = data.get("checkpoint")
	if typeof(mission) != TYPE_STRING or typeof(saved_state) != TYPE_STRING or typeof(saved_checkpoint) != TYPE_STRING:
		return false
	if mission != String(MISSION_ID):
		return false
	if saved_state == String(FAILED):
		return saved_checkpoint == String(PICKUP) or saved_checkpoint == String(DROPOFF)
	return saved_state == saved_checkpoint and saved_state in [
		String(OFFER), String(PICKUP), String(DROPOFF), String(COMPLETED),
	]


func _transition(next_state: StringName, next_checkpoint: StringName) -> void:
	if _state == next_state and _checkpoint == next_checkpoint:
		return
	_state = next_state
	_checkpoint = next_checkpoint
	state_changed.emit()
