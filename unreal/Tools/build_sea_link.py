#!/usr/bin/env python3
"""Author, export and photograph the Bandra Channel bridge pilot with Blender."""

import hashlib
import json
import math
import random
import struct
import sys
import zlib
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector


SPAN = 300.0
DECK_CENTRES = (-11.25, 11.25)
CARRIAGEWAY_HALF = 7.0
DECK_HALF = 9.65
SEA_LEVEL = -24.8
PILE_CAP_LEVEL = -26.0
PYLON_TOP = 100.0

SOURCES = {
    "operator": "https://msrdc.in/Site/Common/ProjectListDetails.aspx?ID=66&MainId=18",
    "carriageway": "https://msrdc.in/Site/Upload/GR/3_RGSL%20RFP%20Vol%20III%20-%20Schedule%20-18-10-2013%20R8.pdf",
    "engineering_paper": "https://doi.org/10.2749/222137813808627587",
    "formwork_and_construction": "https://www.doka.com/en/references/asia/bandraworlisealink",
    "built_form": "https://www.hccindia.com/products/bridges-and-elevated-roads",
}


def extrude_section(section, first_x, last_x, centre_y):
    return [[(end, centre_y + y, z) for y, z in section] for end in (first_x, last_x)]


def chamfered_rect(cx, cy, z, half_x, half_y, chamfer):
    return [(cx + x, cy + y, z) for x, y in (
        (-half_x + chamfer, -half_y), (half_x - chamfer, -half_y),
        (half_x, -half_y + chamfer), (half_x, half_y - chamfer),
        (half_x - chamfer, half_y), (-half_x + chamfer, half_y),
        (-half_x, half_y - chamfer), (-half_x, -half_y + chamfer),
    )]


class MeshParts:
    def __init__(self, label, material, *, smooth=False):
        self.label = label
        self.material = material
        self.smooth = smooth
        self.vertices = []
        self.faces = []

    def loft(self, rings):
        rings = list(rings)
        n = len(rings[0])
        first = len(self.vertices)
        self.vertices.extend(vertex for ring in rings for vertex in ring)
        self.faces.append(tuple(first + i for i in range(n - 1, -1, -1)))
        for row in range(len(rings) - 1):
            lower = first + row * n
            upper = lower + n
            for i in range(n):
                following = (i + 1) % n
                self.faces.append((lower + i, lower + following, upper + following, upper + i))
        last = first + (len(rings) - 1) * n
        self.faces.append(tuple(last + i for i in range(n)))

    def box(self, x, y, z, length, width, height):
        self.loft([(x + i * length * 0.5, y + j * width * 0.5, z + step * height * 0.5)
                   for i, j in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
                  for step in (-1, 1))

    def tube(self, start, end, radius, *, sides=8, end_radius=None):
        start, end = Vector(start), Vector(end)
        direction = (end - start).normalized()
        lateral = direction.cross(Vector((0, 0, 1)))
        if lateral.length < 0.1:
            lateral = direction.cross(Vector((0, 1, 0)))
        lateral.normalize()
        vertical = direction.cross(lateral)
        self.loft([[
            tuple(point + size * (lateral * math.cos(angle) + vertical * math.sin(angle)))
            for angle in (math.tau * i / sides for i in range(sides))
        ] for point, size in ((start, radius), (end, end_radius if end_radius is not None else radius))])

    def finish(self):
        mesh = bpy.data.meshes.new(self.label)
        mesh.from_pydata(self.vertices, [], self.faces)
        mesh.update()
        normals = bmesh.new()
        normals.from_mesh(mesh)
        bmesh.ops.recalc_face_normals(normals, faces=list(normals.faces))
        normals.to_mesh(mesh)
        normals.free()
        for face in mesh.polygons:
            face.use_smooth = self.smooth and face.loop_total == 4
        # World-aligned metres give tiling materials usable UVs after FBX import.
        uv = mesh.uv_layers.new(name="Surface metres")
        for face in mesh.polygons:
            major_axis = max(range(3), key=lambda axis: abs(face.normal[axis]))
            u_axis, v_axis = ((1, 2), (0, 2), (0, 1))[major_axis]
            for index in face.loop_indices:
                vertex = mesh.vertices[mesh.loops[index].vertex_index].co
                uv.data[index].uv = (vertex[u_axis] / 4.0, vertex[v_axis] / 4.0)
        obj = bpy.data.objects.new(self.label, mesh)
        bpy.context.scene.collection.objects.link(obj)
        mesh.materials.append(self.material)
        return obj


def material(name, color, roughness, metallic=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = mat.diffuse_color
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    return mat


def procedural_surface(mat, color_low, color_high, scale, grain, strength, distance):
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    shader = nodes.get("Principled BSDF")
    coordinates = nodes.new("ShaderNodeTexCoord")
    if color_low is not None:
        variation = nodes.new("ShaderNodeTexNoise")
        variation.inputs["Scale"].default_value = scale
        variation.inputs["Detail"].default_value = 2.6
        links.new(coordinates.outputs["Object"], variation.inputs["Vector"])
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.color_ramp.elements[0].position = 0.23
        ramp.color_ramp.elements[0].color = (*color_low, 1)
        ramp.color_ramp.elements[1].position = 0.82
        ramp.color_ramp.elements[1].color = (*color_high, 1)
        links.new(variation.outputs["Fac"], ramp.inputs["Fac"])
        links.new(ramp.outputs["Color"], shader.inputs["Base Color"])
    fine = nodes.new("ShaderNodeTexNoise")
    fine.inputs["Scale"].default_value = grain
    fine.inputs["Detail"].default_value = 2.0
    links.new(coordinates.outputs["Object"], fine.inputs["Vector"])
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = strength
    bump.inputs["Distance"].default_value = distance
    links.new(fine.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], shader.inputs["Normal"])


def make_materials():
    definitions = {
        "asphalt": ("BridgeAsphalt", (0.076, 0.073, 0.071), 0.92, 0),
        "concrete": ("BridgeConcrete", (0.40, 0.37, 0.32), 0.86, 0),
        "paint": ("BridgePaint", (0.67, 0.64, 0.54), 0.68, 0),
        "steel": ("BridgeSteel", (0.26, 0.28, 0.27), 0.38, 0.55),
        "cable": ("BridgeCable", (0.64, 0.60, 0.50), 0.45, 0.04),
        "joint": ("BridgeJoint", (0.075, 0.068, 0.059), 0.82, 0.10),
        "lens": ("BridgeLens", (0.72, 0.63, 0.40), 0.41, 0.15),
    }
    return {label: material(*values) for label, values in definitions.items()}


def colour_tile(path, seed, base, amplitude):
    """Write a small tileable original colour image with full-width spatial frequencies."""
    size = 512
    rng = random.Random(seed)
    bands = []
    for cells, weight in ((4, 0.52), (16, 0.28), (64, 0.14), (128, 0.06)):
        knots = [[rng.uniform(-1, 1) for _ in range(cells)] for _ in range(cells)]
        samples = []
        for index in range(size):
            lower, fraction = divmod(index * cells, size)
            proportion = fraction / size
            proportion = proportion * proportion * (3 - 2 * proportion)
            samples.append((lower, (lower + 1) % cells, proportion))
        bands.append((weight, knots, samples))

    rows = bytearray()
    for y in range(size):
        rows.append(0)
        for x in range(size):
            density = 0.095 * rng.uniform(-1, 1)
            for weight, knots, samples in bands:
                x0, x1, dx = samples[x]
                y0, y1, dy = samples[y]
                lower = knots[y0][x0] * (1 - dx) + knots[y0][x1] * dx
                upper = knots[y1][x0] * (1 - dx) + knots[y1][x1] * dx
                density += weight * (lower * (1 - dy) + upper * dy)
            rows.extend(max(0, min(255, round(channel + density * amplitude))) for channel in base)

    def block(kind, contents):
        return (struct.pack(">I", len(contents)) + kind + contents
                + struct.pack(">I", zlib.crc32(kind + contents)))

    header = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + block(b"IHDR", header) + block(b"sRGB", b"\x00")
                     + block(b"IDAT", zlib.compress(rows, 8)) + block(b"IEND", b""))
    return path


def make_surface_images(output_dir, mats):
    images = []
    for label, seed, colour, amplitude in (
        ("concrete", 402, (168, 162, 151), 33),
        ("asphalt", 836, (71, 69, 66), 29),
    ):
        path = colour_tile(output_dir / f"sea-link-{label}.png", seed, colour, amplitude)
        image = bpy.data.images.load(str(path), check_existing=True)
        nodes, links = mats[label].node_tree.nodes, mats[label].node_tree.links
        texture = nodes.new("ShaderNodeTexImage")
        texture.image = image
        links.new(texture.outputs["Color"], nodes.get("Principled BSDF").inputs["Base Color"])
        images.append(path)
    return images


def add_civil_deck(asphalt, concrete, paint, joints, steel):
    girder = [
        (-DECK_HALF, -0.19), (-DECK_HALF, -0.53), (-7.95, -0.89), (-4.70, -4.45),
        (-3.65, -4.8), (3.65, -4.8), (4.70, -4.45), (7.95, -0.89),
        (DECK_HALF, -0.53), (DECK_HALF, -0.19),
    ]
    barrier = [
        (-0.34, -0.01), (-0.34, 0.24), (-0.20, 0.67), (-0.12, 1.02),
        (0.13, 1.02), (0.26, 0.12), (0.26, -0.01),
    ]
    for centre_y in DECK_CENTRES:
        # Fourteen metres of traffic lanes have paved apron shoulders on both sides.
        asphalt.box(0, centre_y, -0.105, 2 * SPAN, 15.9, 0.21)
        asphalt.box(0, centre_y, -0.12, 2 * SPAN, 2 * DECK_HALF, 0.20)
        concrete.loft(extrude_section(girder, -SPAN, SPAN, centre_y))
        for side in (-1, 1):
            y = centre_y + side * (DECK_HALF - 0.30)
            section = [(side * offset, height) for offset, height in barrier]
            concrete.loft(extrude_section(section, -SPAN, SPAN, y))
            steel.tube((-SPAN, y, 1.10), (SPAN, y, 1.10), 0.045)
            paint.box(0, centre_y + side * CARRIAGEWAY_HALF, 0.008, 599.6, 0.18, 0.016)
        for median in (-3.5, 0, 3.5):
            for x in range(-294, 298, 12):
                paint.box(x, centre_y + median, 0.008, 4.0, 0.145, 0.016)
        for x in (-299.76, -249.9, 249.9, 299.76):
            joints.box(x, centre_y, 0.011, 0.15, 15.8, 0.022)
        for x in (-250, 250):
            concrete.loft(chamfered_rect(x, centre_y, z, lx, ly, cut) for z, lx, ly, cut in (
                (SEA_LEVEL - 5, 3.2, 5.0, 0.60), (SEA_LEVEL - 0.5, 3.2, 5.0, 0.60),
                (SEA_LEVEL + 1.2, 2.0, 2.8, 0.55), (-10.0, 2.0, 2.7, 0.50),
                (-5.2, 3.1, 4.9, 0.8), (-4.8, 3.1, 4.9, 0.8),
            ))


def add_pylons(concrete, cables, joints):
    for centre_y in DECK_CENTRES:
        concrete.loft(chamfered_rect(0, centre_y, z, lx, ly, cut) for z, lx, ly, cut in (
            (SEA_LEVEL - 5, 13, 10.8, 1.5), (PILE_CAP_LEVEL, 13, 10.8, 1.5),
            (SEA_LEVEL + 0.1, 12.4, 10.4, 1.4),
        ))
        for side_x in (-1, 1):
            for side_y in (-1, 1):
                concrete.loft(chamfered_rect(side_x * x, centre_y + side_y * y, z, lx, ly, edge)
                              for z, x, y, lx, ly, edge in (
                    (PILE_CAP_LEVEL, 9.1, 7.6, 2.95, 2.1, 0.70),
                    (-18, 7.9, 7.8, 2.90, 2.05, 0.68),
                    (-7, 6.25, 8.7, 2.78, 1.92, 0.61),
                    (0, 5.2, 9.1, 2.67, 1.75, 0.58),
                    (16, 4.15, 7.55, 2.52, 1.70, 0.53),
                    (34, 3.05, 5.40, 2.42, 1.64, 0.50),
                    (48, 2.1, 3.67, 2.36, 1.57, 0.47),
                    (59, 1.22, 2.22, 2.29, 1.50, 0.44),
                    (66, 0.85, 1.48, 2.21, 1.42, 0.42),
                ))
        concrete.loft(chamfered_rect(0, centre_y, z, lx, ly, edge)
                      for z, lx, ly, edge in (
            (58, 2.35, 2.89, 0.55), (64, 2.95, 3.08, 0.58), (72, 2.90, 2.72, 0.48),
            (88, 2.70, 2.42, 0.42), (99.5, 2.42, 2.08, 0.38), (PYLON_TOP, 2.35, 2.02, 0.35),
        ))
        for side_x in (-1, 1):
            for side_y in (-1, 1):
                # The 26 individual anchors in each quadrant are a visual sampling.
                for index in range(26):
                    ratio = index / 25
                    deck = Vector((side_x * (38 + 207 * ratio), centre_y + side_y * 8.85, 0.82))
                    tower = Vector((side_x * (2.90 - 0.52 * ratio),
                                    centre_y + side_y * (2.88 - ratio * 0.86), 61 + ratio * 37.9))
                    direction = (tower - deck).normalized()
                    cables.tube(deck, tower, 0.082 + 0.021 * ratio, sides=8)
                    joints.tube(deck, deck + direction * 1.08, 0.164, sides=8, end_radius=0.138)
                    joints.tube(tower - direction * 0.72, tower, 0.126, sides=8)


def add_mast_lights(steel, joints, lens):
    for centre_y in DECK_CENTRES:
        y = centre_y + (-8.32 if centre_y < 0.0 else 8.32)
        toward_road = 1 if y < 0 else -1
        for x in range(-286, 287, 28):
            if abs(x) <= 14:
                continue
            points = [(x, y, 0), (x, y, 7.5), (x, y + toward_road * 0.18, 8.16),
                      (x, y + toward_road * 0.61, 8.63), (x, y + toward_road * 1.43, 8.80)]
            joints.box(x, y, 0.14, 0.51, 0.47, 0.28)
            radii = (0.14, 0.092, 0.082, 0.071, 0.055)
            for index in range(len(points) - 1):
                steel.tube(points[index], points[index + 1], radii[index], end_radius=radii[index + 1])
            housing_y = y + toward_road * 1.47
            steel.box(x, housing_y, 8.81, 0.27, 0.63, 0.11)
            lens.box(x, housing_y, 8.747, 0.21, 0.52, 0.03)


def build_bridge(mats):
    parts = {
        "deck": MeshParts("DeckAsphalt", mats["asphalt"]),
        "girders": MeshParts("DeckGirdersAndPiers", mats["concrete"]),
        "paint": MeshParts("RoadMarkings", mats["paint"]),
        "joints": MeshParts("RoadJointsAndAnchors", mats["joint"]),
        "steel": MeshParts("RailAndLightSteel", mats["steel"], smooth=True),
        "towers": MeshParts("MainPylons", mats["concrete"]),
        "cables": MeshParts("StayCables", mats["cable"], smooth=True),
        "lenses": MeshParts("StreetLightLens", mats["lens"]),
    }
    add_civil_deck(parts["deck"], parts["girders"], parts["paint"], parts["joints"], parts["steel"])
    add_pylons(parts["towers"], parts["cables"], parts["joints"])
    add_mast_lights(parts["steel"], parts["joints"], parts["lenses"])
    return [piece.finish() for piece in parts.values()]


def render_previews(output_dir, mats):
    procedural_surface(mats["concrete"], None, None, 0, 15, 0.26, 0.035)
    procedural_surface(mats["asphalt"], None, None, 0, 21, 0.47, 0.032)
    sea = material("PreviewSea", (0.025, 0.10, 0.115), 0.27, 0.13)
    procedural_surface(sea, (0.018, 0.060, 0.064), (0.049, 0.142, 0.164), 0.055, 1.18, 0.64, 0.28)
    bpy.ops.mesh.primitive_plane_add(size=24000, location=(0, 0, SEA_LEVEL))
    bpy.context.object.data.materials.append(sea)
    scene = bpy.context.scene
    scene.world = bpy.data.worlds.new("Preview maritime daylight")
    scene.world.use_nodes = True
    nodes, links = scene.world.node_tree.nodes, scene.world.node_tree.links
    sky = nodes.new("ShaderNodeTexSky")
    sky_types = {item.identifier for item in sky.bl_rna.properties["sky_type"].enum_items}
    for sky_type in ("MULTIPLE_SCATTERING", "NISHITA", "HOSEK_WILKIE"):
        if sky_type in sky_types:
            sky.sky_type = sky_type
            break
    if hasattr(sky, "sun_elevation"):
        sky.sun_elevation = math.radians(26)
        sky.sun_rotation = math.radians(238)
        sky.sun_disc = False
        sky.altitude = 0.05
    if hasattr(sky, "dust_density"):
        sky.dust_density = 1.72
    background = nodes.get("Background")
    links.new(sky.outputs["Color"], background.inputs["Color"])
    background.inputs["Strength"].default_value = 0.27

    direction = Vector((0.54, 0.70, -0.46))
    bpy.ops.object.light_add(type="SUN")
    sun = bpy.context.object
    sun.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    sun.data.energy = 2.35
    sun.data.angle = math.radians(0.9)
    sun.data.color = (1, 0.83, 0.64)

    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.data.clip_end = 30000
    scene.camera = camera
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 48
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 1500
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.exposure = -0.32
    images = []
    for name, position, target, lens in (
        ("sea-link-main-span.png", (-110, -505, 235), (0, 0, 28), 31),
        ("sea-link-road-level.png", (-227, -14.8, 2.4), (12, -10.5, 24), 23),
    ):
        camera.location = position
        camera.rotation_euler = (Vector(target) - camera.location).to_track_quat("-Z", "Y").to_euler()
        camera.data.lens = lens
        path = output_dir / name
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        images.append(path)
    return images


def export_model(output_dir, bridge, mats):
    bpy.ops.object.select_all(action="DESELECT")
    for feature in bridge:
        feature.select_set(True)
    bpy.context.view_layer.objects.active = bridge[0]
    fbx = output_dir / "sea-link-main-span.fbx"
    glb = output_dir / "sea-link-main-span.glb"
    if bpy.ops.export_scene.fbx(filepath=str(fbx), use_selection=True, object_types={"MESH"},
                                axis_forward="-Y", axis_up="Z", apply_unit_scale=True,
                                apply_scale_options="FBX_SCALE_UNITS", add_leaf_bones=False,
                                mesh_smooth_type="FACE", use_mesh_modifiers=True,
                                path_mode="COPY", embed_textures=True) != {"FINISHED"}:
        raise RuntimeError("Bandra deck FBX export failed")
    if bpy.ops.export_scene.gltf(filepath=str(glb), export_format="GLB",
                                 use_selection=True, export_yup=True) != {"FINISHED"}:
        raise RuntimeError("Bandra deck GLB export failed")
    stats = {
        "name": "Bandra-Worli Sea Link, Bandra Channel pilot",
        "source_axes": "+X along the deck, +Y across carriageways, +Z up, units metres",
        "fbx_export_axes": "-Y forward, +Z up, unit metadata enabled",
        "glb_export_axes": "glTF +Y up",
        "units": "metres",
        "bounds_source_m": mesh_bounds(bridge),
        "asphalt_surface_z_m": 0,
        "preview_water_z_m": SEA_LEVEL,
        "lane_bounds_y_m": [[centre - CARRIAGEWAY_HALF, centre + CARRIAGEWAY_HALF] for centre in DECK_CENTRES],
        "expansion_joint_span_m": 2 * SPAN,
        "structural_span_m": 500,
        "pylon_height_from_cap_m": PYLON_TOP - PILE_CAP_LEVEL,
        "material_slots": [material.name for material in mats.values()],
        "mesh_objects": len(bridge),
        "triangles": sum(len(obj.data.loop_triangles) for obj in bridge),
        "sources": SOURCES,
        "roundtrip_bounds_m": {
            "fbx": reimport_bounds(fbx, bpy.ops.import_scene.fbx),
            "glb": reimport_bounds(glb, bpy.ops.import_scene.gltf),
        },
        "export_files": {},
    }
    for roundtrip in stats["roundtrip_bounds_m"].values():
        for bound in ("min", "max"):
            if any(abs(test - source) > 0.01 for test, source in zip(roundtrip[bound], stats["bounds_source_m"][bound])):
                raise RuntimeError("Round-trip export moved bridge geometry or changed its units")
    for path in (fbx, glb):
        stats["export_files"][path.name] = dict(bytes=path.stat().st_size,
                                               sha256=hashlib.sha256(path.read_bytes()).hexdigest())
    return stats


def mesh_bounds(meshes):
    points = [obj.matrix_world @ vertex.co for obj in meshes for vertex in obj.data.vertices]
    return {name: [round(extreme(point[axis] for point in points), 4) for axis in range(3)]
            for name, extreme in (("min", min), ("max", max))}


def reimport_bounds(path, import_operation):
    existing = set(bpy.context.scene.objects)
    if import_operation(filepath=str(path)) != {"FINISHED"}:
        raise RuntimeError(f"Could not read exported bridge {path.name}")
    new_objects = set(bpy.context.scene.objects) - existing
    try:
        return mesh_bounds([obj for obj in new_objects if obj.type == "MESH"])
    finally:
        for obj in new_objects:
            bpy.data.objects.remove(obj, do_unlink=True)


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if len(args) != 1:
        raise SystemExit("Usage: blender -b --python-exit-code 1 --python build_sea_link.py -- <output_directory>")
    output_dir = Path(args[0]).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    materials = make_materials()
    surface_images = make_surface_images(output_dir, materials)
    bridge = build_bridge(materials)
    for obj in bridge:
        obj.data.calc_loop_triangles()
    stats = export_model(output_dir, bridge, materials)
    previews = render_previews(output_dir, materials)
    for path in [*previews, *surface_images]:
        stats["export_files"][path.name] = dict(bytes=path.stat().st_size,
                                               sha256=hashlib.sha256(path.read_bytes()).hexdigest())
    (output_dir / "sea-link-main-span.json").write_text(json.dumps(stats, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
