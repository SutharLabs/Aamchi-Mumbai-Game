extends Node3D

const MINUTES_PER_DAY := 1440.0
const DAWN := 360.0
const LIGHTING_STEP := 0.25
const DEFAULT_MINUTES := 630.0

var minutes_per_second := 1.0
var _minutes := DEFAULT_MINUTES
var _lighting_elapsed := 0.0
var _environment := Environment.new()
var _sky_material := ProceduralSkyMaterial.new()
var _sun := DirectionalLight3D.new()
var _night_fill := DirectionalLight3D.new()


func _ready() -> void:
	name = "DistrictDaylight"
	var sky := Sky.new()
	sky.sky_material = _sky_material
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	_sky_material.sun_angle_max = 13.0
	_environment.background_mode = Environment.BG_SKY
	_environment.sky = sky
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.ambient_light_sky_contribution = 0.0
	_environment.fog_enabled = true
	_environment.fog_sky_affect = 0.0
	_environment.fog_sun_scatter = 0.06
	var lighting := WorldEnvironment.new()
	lighting.name = "WorldEnvironment"
	lighting.environment = _environment
	add_child(lighting)
	_sun.name = "Sun"
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	_sun.directional_shadow_split_1 = 0.20
	_sun.directional_shadow_max_distance = 68.0
	_sun.directional_shadow_fade_start = 0.82
	add_child(_sun)
	_night_fill.name = "NightFill"
	_night_fill.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	_night_fill.light_color = Color("718abf")
	_night_fill.rotation_degrees = Vector3(-40.0, 135.0, 0.0)
	add_child(_night_fill)
	_update_lighting()


func _process(delta: float) -> void:
	if minutes_per_second <= 0.0:
		return
	_minutes = fposmod(_minutes + delta * minutes_per_second, MINUTES_PER_DAY)
	_lighting_elapsed += delta
	if _lighting_elapsed >= LIGHTING_STEP:
		_lighting_elapsed = 0.0
		_update_lighting()


func set_time_minutes(value: float) -> void:
	if not is_finite(value):
		return
	_minutes = fposmod(value, MINUTES_PER_DAY)
	if is_node_ready():
		_update_lighting()


func clock_label() -> String:
	var whole_minutes := floori(_minutes)
	return "%02d:%02d" % [floori(_minutes / 60.0), whole_minutes % 60]


func _update_lighting() -> void:
	var daylight_phase := TAU * (_minutes - DAWN) / MINUTES_PER_DAY
	var elevation := sin(daylight_phase)
	var daylight := smoothstep(-0.04, 0.50, elevation)
	var twilight := smoothstep(-0.17, 0.03, elevation) * (1.0 - smoothstep(0.06, 0.38, elevation))
	_sky_material.sky_top_color = Color("28324f").lerp(Color("698ca8"), daylight)
	_sky_material.sky_horizon_color = Color("515870").lerp(Color("c9d1c9"), daylight).lerp(Color("c4866c"), twilight)
	_sky_material.ground_horizon_color = _sky_material.sky_horizon_color
	_sky_material.ground_bottom_color = Color("323749").lerp(Color("8a8578"), daylight)
	_environment.ambient_light_color = Color("898fb6").lerp(Color("c7d9e4"), daylight)
	_environment.ambient_light_energy = lerpf(0.47, 0.67, daylight)
	_environment.fog_light_color = Color("384861").lerp(Color("a4b4c0"), daylight)
	_environment.fog_density = lerpf(0.0007, 0.0015, daylight)
	_sun.rotation_degrees = Vector3(-50.0 * elevation, -36.0 + (_minutes - DEFAULT_MINUTES) * 0.18, 0.0)
	_sun.light_energy = 1.01 * daylight
	_sun.light_color = Color("fff8ee").lerp(Color("f9ae78"), twilight)
	_sun.shadow_enabled = daylight > 0.18 and not OS.has_feature("mobile")
	_night_fill.light_energy = 0.32 * (1.0 - daylight)
