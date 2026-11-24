extends Node3D

const Walker := preload("res://player.gd")
const Bus := preload("res://world/arrival_bus.gd")
const ARRIVE := 1.50
const STEP_OUT := 2.30
const ON_PAVEMENT := 4.30
const DEPART := 5.10
const COMPLETE := 7.20

var elapsed := 0.0
var _bus := Bus.new()
var _player: Walker
var _stop: Vector3
var _yaw: float
var _forward: Vector3
var _curb: Vector3
var _dock: Vector3


func setup(player: Walker, destination: Vector3, yaw: float) -> void:
	_player = player
	_stop = destination
	_yaw = yaw
	_forward = Vector3.FORWARD.rotated(Vector3.UP, yaw)
	_curb = Vector3(_forward.z, 0.0, -_forward.x)
	_dock = _stop - _forward * absf(Bus.FRONT_STEP.z) - _curb * 3.0
	_dock.y = 0.025
	_bus.rotation.y = _yaw
	_bus.position = _dock - _forward * 7.0
	add_child(_bus)
	_player.set_on_foot(false)


func advance(delta: float, camera: Camera3D) -> bool:
	elapsed = minf(elapsed + delta, COMPLETE)
	var approach := clampf(elapsed / ARRIVE, 0.0, 1.0)
	var leaving := clampf((elapsed - DEPART) / (COMPLETE - DEPART), 0.0, 1.0)
	_bus.global_position = _dock + _forward * (-7.0 * (1.0 - approach) ** 2 + 11.0 * leaving ** 2)
	var opening := smoothstep(ARRIVE, STEP_OUT, elapsed)
	var closing := smoothstep(ON_PAVEMENT, DEPART, elapsed)
	_bus.set_door_open(opening * (1.0 - closing))
	var feet := _stop
	feet.y = 0.15
	var focus := _dock + _forward * (absf(Bus.FRONT_STEP.z) + 0.2) + _curb * 1.36
	if elapsed >= STEP_OUT:
		if not _player.visible:
			_player.show()
			_player.visual.animation_player.active = true
		var fraction := smoothstep(STEP_OUT, ON_PAVEMENT, elapsed)
		var step := _dock + _forward * absf(Bus.FRONT_STEP.z) + _curb * 1.18
		step.y = _dock.y + Bus.FRONT_STEP.y
		_player.global_position = step.lerp(feet, fraction)
		var direction := _curb.lerp(_forward, smoothstep(ON_PAVEMENT - 0.65, ON_PAVEMENT, elapsed))
		_player.rotation.y = atan2(-direction.x, -direction.z)
		_player.visual.set_ground_speed(1.05 if fraction < 1.0 else 0.0)
		focus = _player.global_position
	var look := focus + Vector3.UP * 1.15 - _curb * (1.0 - leaving) * 0.55
	camera.global_position = feet + _forward * 5.9 + _curb * 0.40 + Vector3.UP * 2.05
	camera.look_at(look)
	return elapsed >= COMPLETE


func subtitle() -> String:
	if elapsed < STEP_OUT:
		return "Bandra West, Mumbai\nOmkar Shirodkar steps into a city he barely knows."
	return ""
