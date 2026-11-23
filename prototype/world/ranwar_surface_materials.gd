extends RefCounted
## Shared scene paint, meter-scale photo mapping and batched detail materials.

const PLAIN := 0
const PLASTER := 1
const CONCRETE := 2
const CLAY := 3
const TIMBER := 4

const ASPHALT_TILE := preload("res://world/textures/asphalt.webp")
const ASPHALT_NORMAL := preload("res://world/textures/asphalt_normal.png")
const CONCRETE_TILE := preload("res://world/textures/concrete.webp")
const CONCRETE_NORMAL := preload("res://world/textures/concrete_normal.png")
const PLASTER_TILE := preload("res://world/textures/plaster.webp")
const PLASTER_NORMAL := preload("res://world/textures/plaster_normal.png")
const CLAY_TILE := preload("res://world/textures/clay_tile.webp")
const TIMBER_TILE := preload("res://world/textures/timber.webp")
const GRAVEL_TILE := preload("res://world/textures/gravel.webp")
const DETAIL_SHADER := preload("res://world/ranwar_surface_detail.gdshader")


static func apply_box(material: StandardMaterial3D, key: String) -> void:
	match key:
		"asphalt", "bay":
			_apply_tile(material, ASPHALT_TILE, 3.0, ASPHALT_NORMAL, 0.33)
			material.albedo_color = Color("d4d6d2") if key == "asphalt" else Color("adb7b7")
		"paving", "curb", "gully":
			_apply_tile(material, CONCRETE_TILE, 2.0, CONCRETE_NORMAL, 0.43)
			if key != "curb":
				material.albedo_color = Color("e6d8bc") if key == "paving" else Color("dcd5c7")
		"cream", "ochre", "mint", "rose", "blue":
			_apply_tile(material, PLASTER_TILE, 3.0, PLASTER_NORMAL, 0.40)
		"roof":
			_apply_tile(material, CLAY_TILE, 4.0)
			material.albedo_color = Color("ccc3b6")
		"ground":
			_apply_tile(material, GRAVEL_TILE, 2.1)
			material.albedo_color = Color("c4bbab")


static func make_batch() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = DETAIL_SHADER
	material.set_shader_parameter(&"plaster_tile", PLASTER_TILE)
	material.set_shader_parameter(&"concrete_tile", CONCRETE_TILE)
	material.set_shader_parameter(&"clay_tile", CLAY_TILE)
	material.set_shader_parameter(&"timber_tile", TIMBER_TILE)
	return material


static func add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		color: Color, finish: int) -> void:
	var scale := 1.0
	match finish:
		PLASTER: scale = 1.0 / 3.0
		CONCRETE: scale = 0.5
		CLAY: scale = 0.25
		TIMBER: scale = 1.0 / 1.8
	var normal := (b - a).cross(c - a).abs()
	surface.set_color(color)
	surface.set_uv2(Vector2(float(finish), 0.0))
	for point: Vector3 in [a, b, c]:
		var uv := Vector2(point.x, -point.y)
		if normal.y >= normal.x and normal.y >= normal.z:
			uv = Vector2(point.x, point.z)
		elif normal.x > normal.z:
			uv = Vector2(point.z, -point.y)
		surface.set_uv(uv * scale)
		surface.add_vertex(point)


static func _apply_tile(material: StandardMaterial3D, albedo: Texture2D, width: float,
		normal: Texture2D = null, strength: float = 0.0) -> void:
	material.albedo_texture = albedo
	material.uv1_world_triplanar = true
	material.uv1_triplanar = true
	material.uv1_triplanar_sharpness = 8.0
	material.uv1_scale = Vector3.ONE / width
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if normal != null:
		material.normal_enabled = true
		material.normal_texture = normal
		material.normal_scale = strength
