extends RefCounted
## Profile economy and the current session's condition and police response.

const Progress := preload("res://mission/mission_progress.gd")
const PARCEL_PAY := 500
const TREATMENT_PRICE := 60
const CLINIC_FEE := 100
const POLICE_FINE := 150
const MAX_HEALTH := 100.0
const REGEN_LIMIT := 50.0
const REST_DELAY := 7.0
const DETAIN_SECONDS := 2.4

var health := MAX_HEALTH
var wanted := 0
var parcel_completed := false
var lead_seen: bool:
	get:
		return _lead_seen
var cash: int:
	get:
		return maxi(0, (PARCEL_PAY if parcel_completed else 0) - _spent)

var _store: Progress
var _spent := 0
var _lead_seen := false
var _impact_cooldown := 0.0
var _rest_delay := 0.0
var _incident_cooldown := 0.0
var _quiet_seconds := 0.0
var _detain_time := 0.0


func _init(store: Progress) -> void:
	_store = store
	var saved := _store.load_career()
	_spent = saved.get("spent", 0)
	_lead_seen = saved.get("lead_seen", false)


func has_lead() -> bool:
	return parcel_completed and not _lead_seen


func record_lead() -> bool:
	if not has_lead() or not _store.save_career(_spent, true):
		return false
	_lead_seen = true
	return true


func charge(price: int) -> int:
	var fee := clampi(price, 0, cash)
	if fee == 0:
		return 0
	if not _store.save_career(_spent + fee, _lead_seen):
		return -1
	_spent += fee
	return fee


func treat() -> bool:
	if health >= MAX_HEALTH or health <= 0.0 or wanted > 0 or cash < TREATMENT_PRICE:
		return false
	if charge(TREATMENT_PRICE) != TREATMENT_PRICE:
		return false
	health = MAX_HEALTH
	return true


func damage(amount: float) -> void:
	if _impact_cooldown > 0.0 or health <= 0.0 or not is_finite(amount) or amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	_impact_cooldown = 0.85
	_rest_delay = REST_DELAY


func report_collision() -> bool:
	if _incident_cooldown > 0.0:
		return false
	wanted = mini(2, wanted + 1)
	_incident_cooldown = 2.0
	_quiet_seconds = 0.0
	return true


func step(delta: float, patrol_in_sight: bool, can_detain: bool) -> bool:
	_impact_cooldown = maxf(0.0, _impact_cooldown - delta)
	_incident_cooldown = maxf(0.0, _incident_cooldown - delta)
	_rest_delay = maxf(0.0, _rest_delay - delta)
	if health > 0.0 and health < REGEN_LIMIT and _rest_delay <= 0.0 and wanted == 0:
		health = move_toward(health, REGEN_LIMIT, 6.0 * delta)
	if wanted == 0:
		return false
	_quiet_seconds = 0.0 if patrol_in_sight else _quiet_seconds + delta
	_detain_time = _detain_time + delta if can_detain else 0.0
	if _quiet_seconds >= (18.0 if wanted == 1 else 27.0):
		clear_alert()
	return _detain_time >= DETAIN_SECONDS


func clear_alert() -> void:
	wanted = 0
	_quiet_seconds = 0.0
	_detain_time = 0.0


func respawn() -> void:
	health = MAX_HEALTH
	_impact_cooldown = 1.5
	_incident_cooldown = 1.5
	_rest_delay = 0.0
	clear_alert()
