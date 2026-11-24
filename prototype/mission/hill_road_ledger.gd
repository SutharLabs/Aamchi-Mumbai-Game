extends Node3D
## Two walk-up handoffs at the existing mapped shop interiors.

const Career := preload("res://mission/ranwar_career.gd")
const Progress := preload("res://mission/mission_progress.gd")
const DeliveryRoute := preload("res://mission/ranwar_delivery_route.gd")
const Visual := preload("res://character/locomotion_visual.gd")
const TEA_ROOM := 360291657
const GROCER := 357472313
const NAME := "The Hill Road Ledger"
const REACH := 1.8
const INCOMPATIBLE := "Ledger save belongs to another version or profile."
const SAVE_ERROR := "The ledger checkpoint could not be saved. Try again."
const PICKUP_LINE := "asha-ledger-pickup"
const HANDOFF_LINE := "grocer-ledger-handoff"

var state := Progress.LEDGER_COLLECT
var _progress: Progress
var _career: Career
var _pickup: Dictionary = {}
var _handoff: Dictionary = {}
var _save_incompatible := false
var _marker: MeshInstance3D
var _contacts_added := false


func setup(progress: Progress, career: Career, venues: Array[Dictionary]) -> void:
	_progress = progress
	_career = career
	for venue: Dictionary in venues:
		match venue.get("osm_way"):
			TEA_ROOM: _pickup = venue
			GROCER: _handoff = venue
	state = progress.load_ledger_checkpoint()
	_save_incompatible = progress.has_incompatible_ledger()
	_marker = DeliveryRoute.make_marker("LedgerMarker")
	add_child(_marker)
	_refresh_completion()


func target() -> Vector3:
	if _save_incompatible or not _eligible() or state == Progress.LEDGER_COMPLETED:
		return Vector3.INF
	var venue := _pickup if state == Progress.LEDGER_COLLECT else _handoff
	return venue.get("inside", Vector3.INF)


func objective(position: Vector3) -> String:
	if _save_incompatible and _eligible():
		return INCOMPATIBLE
	var destination := target()
	if not destination.is_finite():
		return ""
	var instruction := "Meet Asha at Hill Road Tea Room" if state == Progress.LEDGER_COLLECT \
		else "Carry the ledger to Chapel Corner Grocer"
	var distance := Vector2(position.x - destination.x, position.z - destination.z).length()
	return "%s  ·  %d m" % [instruction, roundi(distance)]


func prompt_for(position: Vector3) -> String:
	var destination := target()
	if not destination.is_finite() or position.distance_squared_to(destination) > REACH * REACH:
		return ""
	var query := PhysicsRayQueryParameters3D.create(position + Vector3.UP, destination + Vector3.UP, 1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		return ""
	return "Take the ledger copy from Asha" if state == Progress.LEDGER_COLLECT else "Hand the ledger copy to the grocer"


func interact() -> String:
	if not target().is_finite():
		return ""
	var saved_state := _progress.load_ledger_checkpoint()
	if saved_state != state:
		state = saved_state
		_refresh_completion()
		return ""
	var next := Progress.LEDGER_HANDOFF if state == Progress.LEDGER_COLLECT else Progress.LEDGER_COMPLETED
	if not _save(next):
		return _save_error()
	return PICKUP_LINE if state == Progress.LEDGER_HANDOFF else HANDOFF_LINE


func can_abandon() -> bool:
	return state == Progress.LEDGER_HANDOFF and target().is_finite()


func abandon() -> String:
	if not can_abandon():
		return ""
	return "Ledger job abandoned. Collect a fresh copy from Asha." if _save(Progress.LEDGER_COLLECT) else _save_error()


func _save(next: StringName) -> bool:
	var saved := _progress.save_ledger_checkpoint(next)
	state = next if saved else _progress.load_ledger_checkpoint()
	_save_incompatible = _progress.has_incompatible_ledger()
	_refresh_completion()
	return saved


func _save_error() -> String:
	return INCOMPATIBLE if _save_incompatible else SAVE_ERROR


func _refresh_completion() -> void:
	_career.ledger_completed = state == Progress.LEDGER_COMPLETED
	refresh_target()


func refresh_target() -> void:
	var destination := target()
	_marker.visible = destination.is_finite()
	if _marker.visible:
		_marker.position = destination + Vector3.UP * 0.055
	if not _contacts_added and _eligible():
		_contacts_added = true
		_add_contact(_pickup, "Asha", Color("756677"), true)
		_add_contact(_handoff, "Chapel Corner Grocer", Color("6a857a"), false)


func _eligible() -> bool:
	return _career.parcel_completed and _career.lead_seen


func _add_contact(venue: Dictionary, person_name: String, shirt: Color, wears_kurta: bool) -> void:
	if venue.is_empty():
		return
	var doorway: Vector3 = venue["threshold"]
	var center: Vector3 = venue["inside"]
	var toward_door := (doorway - center).normalized()
	var contact := StaticBody3D.new()
	contact.name = person_name
	contact.collision_layer = 2
	contact.collision_mask = 0
	# Stand beside the marker so the door-to-counter path remains clear.
	contact.position = center - toward_door * 0.72 + Vector3.UP.cross(toward_door) * 0.76 + Vector3.UP * 0.028
	contact.rotation.y = atan2(-toward_door.x, -toward_door.z)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.68
	collision.shape = capsule
	collision.position.y = capsule.height * 0.5
	contact.add_child(collision)
	var actor := Visual.new()
	actor.name = "CharacterVisual"
	actor.shirt_color = shirt
	actor.wears_kurta_with_dupatta = wears_kurta
	actor.wears_overshirt = not wears_kurta
	actor.kurta_hair_style = 2
	contact.add_child(actor)
	add_child(contact)
