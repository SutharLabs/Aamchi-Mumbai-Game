extends RefCounted
## Shallow street-facing fittings for the authored background lots near the BEST stop.

const Surfaces := preload("res://world/ranwar_surface_materials.gd")
const BASE := Color("827972")
const FRAME := Color("b3ad9a")
const GLASS := Color("4b6268")
const SHUTTERS: Array[Color] = [Color("6c7466"), Color("696c67"), Color("626e6a")]
const AWNINGS: Array[Color] = [Color("75483d"), Color("49646a"), Color("8a7453")]


static func create(height: float, variant: int, material: Material) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	# The road-facing wall is local Z = 0. All fittings sit outside the existing shell.
	Surfaces.add_box(surface, Vector3(0, 0.22, 0.04), Vector3(12.85, 0.44, 0.15), BASE, Surfaces.CONCRETE)
	var shop := variant % 3 != 1
	for x: float in [-4.25, 0.0, 4.25]:
		if shop:
			_shutter(surface, x, variant)
		else:
			_window(surface, Vector3(x, 1.64, 0), variant)
			if x == 0.0:
				# Add a recessed-looking residential door beside the window bay.
				Surfaces.add_box(surface, Vector3(1.57, 1.14, 0.065), Vector3(0.94, 2.28, 0.14), FRAME)
				Surfaces.add_box(surface, Vector3(1.57, 1.12, 0.152), Vector3(0.75, 2.08, 0.057), Color("68564a"))
	var accent := AWNINGS[variant % AWNINGS.size()]
	if shop:
		var awning := Basis(Vector3.RIGHT, 0.16)
		Surfaces.add_box(surface, Vector3(0, 2.97, 0.61), Vector3(11.85, 0.075, 1.26), accent,
			Surfaces.PLAIN, awning)
		Surfaces.add_box(surface, Vector3(0, 2.83, 1.20), Vector3(11.85, 0.19, 0.075), accent.darkened(0.10))
	else:
		Surfaces.add_box(surface, Vector3(1.57, 2.68, 0.39), Vector3(1.48, 0.15, 0.83), accent)
	var row := 4.25
	while row + 0.68 < height - 0.32:
		for column in range(3):
			var x := float(column - 1) * 4.23
			_window(surface, Vector3(x, row, 0), variant + column)
			if column == (variant % 3) and row < 5.0:
				Surfaces.add_box(surface, Vector3(x, row - 0.94, 0.30), Vector3(1.76, 0.13, 0.64), BASE,
					Surfaces.CONCRETE)
		row += 2.8
	var pipe_x := -5.9 if variant % 2 == 0 else 5.9
	Surfaces.add_box(surface, Vector3(pipe_x, height * 0.5, 0.12), Vector3(0.09, height - 0.19, 0.11),
		Color("63594b"))
	surface.set_material(material)
	surface.generate_normals()
	surface.index()
	return surface.commit()


static func _shutter(surface: SurfaceTool, x: float, variant: int) -> void:
	var color := SHUTTERS[variant % SHUTTERS.size()]
	Surfaces.add_box(surface, Vector3(x, 1.28, 0.055), Vector3(3.36, 2.56, 0.13), FRAME)
	Surfaces.add_box(surface, Vector3(x, 1.25, 0.139), Vector3(3.09, 2.34, 0.08), color)
	for slat in 8:
		Surfaces.add_box(surface, Vector3(x, 0.29 + float(slat) * 0.28, 0.182), Vector3(3.04, 0.025, 0.014),
			color.darkened(0.18))


static func _window(surface: SurfaceTool, center: Vector3, variant: int) -> void:
	var trim := FRAME.darkened(0.08 * float(variant % 3))
	Surfaces.add_box(surface, center + Vector3(0, 0, 0.065), Vector3(1.50, 1.38, 0.14), trim)
	Surfaces.add_box(surface, center + Vector3(0, 0, 0.147), Vector3(1.27, 1.16, 0.054),
		GLASS.darkened(0.10 * float(variant % 3)))
	Surfaces.add_box(surface, center + Vector3(0, 0, 0.183), Vector3(0.06, 1.17, 0.048), trim)
	Surfaces.add_box(surface, center + Vector3(0, 0.24, 0.182), Vector3(1.28, 0.045, 0.046), trim)
	Surfaces.add_box(surface, center + Vector3(0, -0.69, 0.15), Vector3(1.63, 0.12, 0.32), BASE, Surfaces.CONCRETE)
