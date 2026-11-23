extends SubViewportContainer
## On-demand model of the north cable-stayed span. Dimensions in metres.

const DECK_HEIGHT := 28.0
const DECK_OFFSET := 12.25
const SPAN_END := 300.0
const DECK_START := 500.0

var _viewport: SubViewport
var _camera: Camera3D
var _angle := 0


func _ready() -> void:
	custom_minimum_size.y = 355.0
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport = SubViewport.new()
	_viewport.world_3d = World3D.new()
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_viewport.msaa_3d = Viewport.MSAA_2X
	add_child(_viewport)
	resized.connect(_queue_render)
	var bridge := Node3D.new()
	bridge.name = "BandraChannelSpan"
	_viewport.add_child(bridge)
	_build_bridge(bridge)
	_add_environment()
	_camera = Camera3D.new()
	_camera.name = "SpanCamera"
	_camera.fov = 44.0
	_camera.far = 3500.0
	_viewport.add_child(_camera)
	_camera.make_current()
	_set_view()


func rotate_view() -> void:
	_angle = (_angle + 1) % 3
	_set_view()
	_queue_render()


func _set_view() -> void:
	var views := [Vector3(176, 103, 640), Vector3(365, 118, 612), Vector3(-214, 141, -615)]
	_camera.position = views[_angle]
	_camera.look_at(Vector3(0, 41, 0))


func _queue_render() -> void:
	if _viewport != null:
		_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _build_bridge(bridge: Node3D) -> void:
	var concrete := _material(Color("b2bbc1"), 0.95)
	var fascia := _material(Color("84929e"), 0.80)
	var asphalt := _material(Color("4a535a"), 0.97)
	var cables := _material(Color("dce8ef"), 0.62)
	var road_paint := _material(Color("d3d9d6"), 0.86)
	for side: float in [-1.0, 1.0]:
		var deck := side * DECK_OFFSET
		_box(bridge, Vector3(0, DECK_HEIGHT - 1.92, deck), Vector3(DECK_START * 2, 3.84, 19.9), fascia)
		_box(bridge, Vector3(0, DECK_HEIGHT - 0.04, deck), Vector3(DECK_START * 2, 0.12, 18.8), asphalt)
		for edge: float in [-1.0, 1.0]:
			_box(bridge, Vector3(0, DECK_HEIGHT + 0.39, deck + edge * 9.7),
				Vector3(DECK_START * 2, 0.78, 0.55), concrete)
		for lane: float in [-4.3, 0.0, 4.3]:
			_box(bridge, Vector3(0, DECK_HEIGHT + 0.035, deck + lane), Vector3(DECK_START * 2, 0.045, 0.17), road_paint)
		_beam(bridge, Vector3(0, -3, side * 9.0), Vector3(0, 23, side * 21.8), Vector2(10.8, 9.5), concrete)
		_beam(bridge, Vector3(0, 21, side * 21.8), Vector3(0, 48, side * 20.4), Vector2(8.5, 7.0), concrete)
		_beam(bridge, Vector3(0, 46, side * 20.4), Vector3(0, 113, side * 3.3), Vector2(7.0, 5.4), concrete)
		for direction: float in [-1.0, 1.0]:
			for plane: float in [-1.0, 1.0]:
				for index in range(15):
					var reach := lerpf(46.0, 244.0, float(index) / 14.0)
					var height := lerpf(72.0, 116.0, float(index) / 14.0)
					var origin := Vector3(direction * 2.8, height, side * (2.9 + plane * 1.35))
					var end := Vector3(direction * reach, DECK_HEIGHT + 0.5, deck + plane * 8.70)
					_beam(bridge, origin, end, Vector2(0.24, 0.24), cables)
	_box(bridge, Vector3(0, 113, 0), Vector3(8.3, 14.0, 9.4), concrete)
	_box(bridge, Vector3(0, 22.6, 0), Vector3(13.4, 4.4, 47.0), fascia)
	for end: float in [-1.0, 1.0]:
		for distance: float in [SPAN_END, 351.0, 408.0, 465.0]:
			for side: float in [-1.0, 1.0]:
				_box(bridge, Vector3(end * distance, 11.34, side * DECK_OFFSET), Vector3(5.8, 25.0, 7.7), concrete)
				_box(bridge, Vector3(end * distance, 23.24, side * DECK_OFFSET), Vector3(8.6, 2.2, 16.4), fascia)


func _add_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("657f9d")
	sky_material.sky_horizon_color = Color("becad3")
	sky_material.ground_horizon_color = sky_material.sky_horizon_color
	sky_material.ground_bottom_color = Color("809ca8")
	var sky := Sky.new()
	sky.sky_material = sky_material
	var weather := Environment.new()
	weather.background_mode = Environment.BG_SKY
	weather.sky = sky
	weather.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	weather.ambient_light_color = Color("b2cee4")
	weather.ambient_light_energy = 0.63
	var atmosphere := WorldEnvironment.new()
	atmosphere.environment = weather
	_viewport.add_child(atmosphere)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-34, -54, 0)
	sun.light_color = Color("fff2db")
	sun.light_energy = 1.12
	_viewport.add_child(sun)

	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(4600, 4600)
	water.mesh = plane
	var sea := _material(Color("426d82"), 0.39)
	var waves := NoiseTexture2D.new()
	waves.as_normal_map = true
	waves.seamless = true
	var grain := FastNoiseLite.new()
	grain.frequency = 0.12
	waves.noise = grain
	sea.normal_enabled = true
	sea.normal_texture = waves
	sea.normal_scale = 0.35
	sea.uv1_scale = Vector3(48, 48, 1)
	waves.changed.connect(_queue_render)
	water.material_override = sea
	_viewport.add_child(water)


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _box(parent: Node3D, position: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var geometry := BoxMesh.new()
	geometry.size = dimensions
	instance.mesh = geometry
	instance.position = position
	instance.material_override = material
	parent.add_child(instance)
	return instance


func _beam(parent: Node3D, start: Vector3, end: Vector3, section: Vector2, material: Material) -> void:
	var beam := _box(parent, start.lerp(end, 0.5), Vector3(section.x, section.y, start.distance_to(end)), material)
	beam.look_at(end)
