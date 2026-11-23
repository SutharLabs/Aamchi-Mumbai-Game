extends SceneTree

const Car := preload("res://vehicle/phase1_car.gd")
const CLEAN_POSE := Transform3D(Basis.IDENTITY, Vector3(0.0, 0.55, 0.0))

var _car: Car
var _wall: StaticBody3D
var _checks := 0
var _failures := 0
var _last_wall_impact := 0.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var yard := Node3D.new()
	root.add_child(yard)
	_lighting(yard)
	_add_solid(yard, Vector3(0.0, -0.18, 0.0), Vector3(70.0, 0.36, 70.0), Color("727877"))
	_wall = _add_solid(yard, Vector3(0.0, 0.72, -20.0), Vector3(5.0, 1.44, 0.8), Color("a6937d"))
	_car = Car.new()
	_car.reset_to(CLEAN_POSE)
	_car.impacted.connect(_observe_wall_impact)
	yard.add_child(_car)
	await _frames(12)
	var shell: MeshInstance3D = _car.get_node("WheelArchedBody")
	var clean_shell := shell.mesh
	var clean_headlamp_tris := _car._front_lenses.mesh.get_faces().size()
	_check(_car.condition_percent() == 100 and not _car._scrapes.visible, "the hatchback starts with clean panels")
	await _capture(yard, "ranwar-car-before.png")

	_car.set_driver_active(true)
	_car.set_controls(1.0, 0.0, false)
	await _drive_until_damage()
	_check(_car.position.z > -18.0 and _last_wall_impact >= 10.0, "a powered frontal wall impact reports the pre-contact speed and stays solid")
	_check(_car.condition_percent() <= 65 and _car._panel_damage[Car.DamageZone.FRONT] > 0.5
		and _car._panel_damage[Car.DamageZone.REAR] == 0.0, "the hard hit damages the nose and lowers condition")
	_check(shell.mesh != clean_shell and _car._scrapes.visible
		and _car._front_lenses.mesh.get_faces().size() < clean_headlamp_tris, "the nose mesh wrinkles, scuffs and loses an impacted lamp")
	_check(_car._chassis.shape.size.z < Car.CHASSIS_SIZE.z - 0.10 and _car._chassis.position.z > 0.05,
		"the crumpled nose also shortens the solid chassis from the front")
	await _capture(yard, "ranwar-car-after.png")

	_car.set_driver_active(false)
	_car.position = Vector3(18.0, 0.55, 0.0)
	await _frames(48)
	var damaged_speed := await _accelerated_speed()
	_car.reset_to(Transform3D(Basis.IDENTITY, Vector3(18.0, 0.55, 0.0)))
	_check(_car.condition_percent() == 100 and shell.mesh == clean_shell and not _car._scrapes.visible
		and _car._front_lenses.mesh.get_faces().size() == clean_headlamp_tris
		and _car._chassis.shape.size.is_equal_approx(Car.CHASSIS_SIZE), "recovery restores the stock mesh, lamps, collider and condition")
	await _frames(8)
	var clean_speed := await _accelerated_speed()
	_check(damaged_speed < clean_speed * 0.8, "damage reduces effective acceleration")

	_wall.position = Vector3(0.0, 0.72, 8.0)
	_car.reset_to(CLEAN_POSE)
	await _frames(8)
	_car.set_controls(-1.0, 0.0, false)
	await _drive_until_damage()
	_check(_car._panel_damage[Car.DamageZone.REAR] > 0.0 and _car._panel_damage[Car.DamageZone.FRONT] == 0.0
		and _car.condition_percent() < 100, "a fast reverse hit leaves rear-only damage")

	_wall.position = Vector3(0.0, 0.72, -5.0)
	_car.reset_to(CLEAN_POSE)
	await _frames(8)
	_car.set_controls(0.13, 0.0, false)
	await _frames(170)
	_check(_car.position.z < -2.4 and _car.condition_percent() == 100 and shell.mesh == clean_shell,
		"a low-speed parking contact leaves the body intact")

	_wall.position.z = -25.0
	_car.reset_to(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(16.0, 0.55, 0.0)))
	await _frames(4)
	var parked := Car.new()
	parked.reset_to(CLEAN_POSE)
	yard.add_child(parked)
	await _frames(8)
	_car.set_controls(1.0, 0.0, false)
	await _drive_until_damage()
	await _frames(12)
	_check(_car._panel_damage[Car.DamageZone.FRONT] > 0.25 and parked._panel_damage[Car.DamageZone.RIGHT] > 0.12
		and parked._panel_damage[Car.DamageZone.LEFT] == 0.0, "a real two-car collision deforms the striking nose and the parked right panel")
	_check(parked.position.x < -0.10 and parked.condition_percent() < 100,
		"the struck parked car receives bounded motion and lasting damage")
	_car.set_driver_active(false)
	_car.position.x += 8.0
	await _capture(yard, "ranwar-car-side-damage.png", parked, Vector3(3.8, 1.3, -2.8))

	print("Vehicle damage smoke: %d failures (%d checks)" % [_failures, _checks])
	quit(0 if _failures == 0 else 1)


func _drive_until_damage() -> void:
	for tick in 220:
		await physics_frame
		if _car.condition_percent() < 100:
			return


func _accelerated_speed() -> float:
	_car.set_driver_active(true)
	_car.set_controls(1.0, 0.0, false)
	await _frames(43)
	return _car.get_speed_mps()


func _observe_wall_impact(car: CharacterBody3D, collider: Object, closing_speed: float) -> void:
	if collider == _wall and car.impact_velocity.is_finite():
		_last_wall_impact = closing_speed


func _frames(count: int) -> void:
	for tick in count:
		await physics_frame


func _lighting(yard: Node3D) -> void:
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("b1c9d9")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("dce8f0")
	world.environment.ambient_light_energy = 0.63
	yard.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-41.0, 26.0, 0.0)
	sun.light_energy = 0.95
	yard.add_child(sun)


func _add_solid(yard: Node3D, at: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var solid := StaticBody3D.new()
	solid.position = at
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	solid.add_child(shape)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	visual.material_override = material
	solid.add_child(visual)
	yard.add_child(solid)
	return solid


func _capture(yard: Node3D, file: String, target: Car = null, offset := Vector3(2.65, 1.41, -3.15)) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		return
	if target == null:
		target = _car
	var original := target.global_transform
	target.set_physics_process(false)
	target.global_transform = CLEAN_POSE
	var camera := Camera3D.new()
	yard.add_child(camera)
	camera.position = target.position + offset
	camera.look_at(target.position + Vector3.UP * 0.20)
	camera.fov = 48.0
	camera.make_current()
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png("user://" + file) == OK, "%s captured" % file)
	target.global_transform = original
	target.set_physics_process(true)
	camera.queue_free()


func _check(ok: bool, label: String) -> void:
	_checks += 1
	print("PASS " if ok else "FAIL ", label)
	if not ok:
		_failures += 1
