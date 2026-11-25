"""Build FBX street sections from the engine-independent Ranwar scene export."""

import argparse
import base64
from collections import defaultdict
from dataclasses import dataclass, field
import hashlib
import json
import math
from pathlib import Path
import re
import shutil
import sys

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

FINISHES = ("Plain", "Plaster", "Concrete", "Clay", "Timber")
SANDBAR_FINISHES = {
    "TowerConcrete": "Concrete", "WeatheredPlaster": "Plaster",
    "MineralStucco": "Plaster", "PavementConcrete": "Concrete",
}
TILE_SIZE_METRES = 128.0


@dataclass
class Section:
    points: list = field(default_factory=list)
    normals: list = field(default_factory=list)
    faces: list = field(default_factory=list)
    surface_materials: list = field(default_factory=list)
    corner_colors: list = field(default_factory=list)
    corner_uvs: list = field(default_factory=list)
    face_keys: set = field(default_factory=set)


def exchange_position(point):
    """Rotate Godot's right-handed coordinates into Blender's Z-up frame."""
    x, y, z = point
    return -z, -x, y


def source_uv(point, normal, scale):
    x, y, z = point
    direction = tuple(abs(component) for component in normal)
    if direction[1] >= max(direction[0], direction[2]):
        return x * scale[0], -z * scale[1]
    if direction[0] > direction[2]:
        return z * scale[0], y * scale[1]
    return x * scale[0], y * scale[1]


def dimensions(points):
    return {
        "min": [min(point[axis] for point in points) for axis in range(3)],
        "max": [max(point[axis] for point in points) for axis in range(3)],
    }


def section_name(surface):
    if surface["name"] == "GroundSurface":
        return "Ground"
    a = math.floor(-surface["center"][2] / TILE_SIZE_METRES)
    b = math.floor(-surface["center"][0] / TILE_SIZE_METRES)
    return f"Street_{'N' if a < 0 else 'P'}{abs(a)}_{'N' if b < 0 else 'P'}{abs(b)}"


def write_texture(record, field, root, target):
    relative = record.get(field, "")
    source = (root / relative).resolve() if relative else None
    if source is not None and not source.is_relative_to(root / "prototype"):
        raise ValueError(f"Texture points outside the game source: {relative}")
    embedded_key = "embedded" if field == "texture" else "embedded_normal"
    if not relative and not record.get(embedded_key):
        return ""
    if not relative:
        target.write_bytes(base64.b64decode(record[embedded_key], validate=True))
    elif source.suffix.lower() == ".png":
        shutil.copyfile(source, target)
    else:
        image = bpy.data.images.load(str(source), check_existing=False)
        if not image.pixels[:1]:
            raise ValueError(f"Blender could not decode source texture {relative}")
        image.filepath_raw = str(target)
        image.file_format = "PNG"
        image.save()
        bpy.data.images.remove(image)
    return target.relative_to(target.parent.parent).as_posix()


def build_materials(source, root, textures):
    materials = {}
    for key, record in source.items():
        if not re.fullmatch(r"m\d+", key):
            raise ValueError(f"Unexpected material identifier: {key}")
        if record["batch"]:
            for index, finish in enumerate(FINISHES):
                materials[f"Ranwar_{key}_{finish}"] = {
                    "texture": record["finish_maps"][index - 1] if index else "",
                    "roughness": 0.92,
                    "metallic": 0.0,
                }
            for variant, finish in SANDBAR_FINISHES.items():
                materials[f"Ranwar_{key}_{variant}"] = materials[f"Ranwar_{key}_{finish}"].copy()
        else:
            materials[f"Ranwar_{key}"] = record.copy()
    for key, record in materials.items():
        record["albedo_file"] = write_texture(record, "texture", root, textures / f"{key}_Color.png")
        record["normal_file"] = write_texture(record, "normal", root, textures / f"{key}_Normal.png")
        record.pop("embedded", None)
        record.pop("embedded_normal", None)
        record.pop("texture", None)
        record.pop("normal", None)
    return materials


def append_surface(section, spec, material):
    offset = len(section.points)
    source_points = spec["vertices"]
    section.points.extend(exchange_position(point) for point in source_points)
    normals = spec["normals"]
    section.normals.extend(exchange_position(normal) for normal in normals)
    if not normals:
        section.normals.extend((0.0, 0.0, 1.0) for _ in source_points)
    indices = spec["indices"] or range(len(source_points))
    color_data = spec["colors"]
    uv = spec["uv"]
    finish_data = spec["uv2"]
    key = f"Ranwar_{spec['material']}"
    default = material["color"]
    world_uv = spec["world_uv_scale"]
    mapped = spec["name"].startswith("Footprint_")
    building = mapped or spec["name"] == "Frontage" or spec.get("label") in {"Facade", "HillRoadStreetFront"}
    tower = mapped and any(point[1] > 15.0 for point in source_points)
    style = sum(round(point) for point in spec["center"]) % 3
    if mapped:
        style = int(spec["name"].removeprefix("Footprint_")) % 3

    if len(indices) % 3:
        raise ValueError(f"Non-triangle geometry for {spec['name']}")
    for start in range(0, len(indices), 3):
        # The scene's clockwise outward faces become Blender counterclockwise triangles.
        tri = (indices[start], indices[start + 2], indices[start + 1])
        source_triangle = [source_points[index] for index in tri]
        a, b, c = map(Vector, source_triangle)
        surface_normal = (b - a).cross(c - a)
        key_points = triangle_key(source_triangle)
        if len(set(key_points)) != 3 or key_points in section.face_keys or surface_normal.length_squared < 1e-12:
            continue
        section.face_keys.add(key_points)
        direction = surface_normal.normalized()
        section.faces.append(tuple(offset + index for index in tri))
        finish = round(finish_data[tri[0]][0]) if material["batch"] and finish_data else 0
        finish_name = FINISHES[finish]
        vertical = abs(direction.y) < 0.25
        if vertical and building and finish_name == "Plaster":
            finish_name = "MineralStucco" if style == 0 else "WeatheredPlaster"
        elif vertical and tower and finish_name == "Concrete":
            finish_name = "TowerConcrete"
        elif spec["name"] == "HillRoadGroundFinish" and finish_name == "Concrete" and abs(direction.y) > 0.9:
            finish_name = "PavementConcrete"
        section.surface_materials.append(f"{key}_{finish_name}" if material["batch"] else key)
        for index in tri:
            section.corner_colors.append(color_data[index] if color_data else default)
            if world_uv[0]:
                section.corner_uvs.append(source_uv(source_points[index], direction, world_uv))
            elif uv:
                section.corner_uvs.append((uv[index][0], 1.0 - uv[index][1]))
            else:
                section.corner_uvs.append((0.0, 0.0))


def add_polygons(name, section, materials):
    data = bpy.data.meshes.new(name)
    data.from_pydata(section.points, (), section.faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    if not materials:
        return obj
    index_by_material = {}
    for key in dict.fromkeys(section.surface_materials):
        mat = bpy.data.materials.get(key) or bpy.data.materials.new(key)
        index_by_material[key] = len(data.materials)
        data.materials.append(mat)
    uv = data.uv_layers.new(name="UVMap")
    colors = data.color_attributes.new(name="RanwarColor", type="BYTE_COLOR", domain="CORNER")
    for index, polygon in enumerate(data.polygons):
        polygon.use_smooth = True
        polygon.material_index = index_by_material[section.surface_materials[index]]
        for corner in polygon.loop_indices:
            uv.data[corner].uv = section.corner_uvs[corner]
            colors.data[corner].color_srgb = section.corner_colors[corner]
    data.normals_split_custom_set_from_vertices(section.normals)
    return obj


def triangle_key(points):
    # One-tenth millimetre absorbs floating-point differences between adjacent scene meshes.
    return tuple(sorted(tuple(round(axis * 10000.0) for axis in point) for point in points))


def write_fbx(path, obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    status = bpy.ops.export_scene.fbx(
        filepath=str(path),
        use_selection=True,
        object_types={"MESH"},
        axis_forward="-Y",
        axis_up="Z",
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_UNITS",
        mesh_smooth_type="FACE",
        colors_type="SRGB",
    )
    if status != {"FINISHED"}:
        raise RuntimeError(f"FBX export failed: {path}")


def check_fbx(path, bounds, triangles, color_required):
    before = set(bpy.data.objects)
    if bpy.ops.import_scene.fbx(filepath=str(path)) != {"FINISHED"}:
        raise RuntimeError(f"FBX reimport failed: {path}")
    objects = [obj for obj in bpy.data.objects if obj not in before and obj.type == "MESH"]
    if len(objects) != 1:
        raise RuntimeError(f"Expected a single reimported mesh: {path}")
    obj = objects[0]
    restored = dimensions([obj.matrix_world @ vertex.co for vertex in obj.data.vertices])
    face_count = len(obj.data.polygons)
    if any(abs(actual - expected) > 0.015 for edge in ("min", "max")
           for actual, expected in zip(restored[edge], bounds[edge])) or face_count != triangles:
        raise RuntimeError(f"Mismatched FBX round-trip: {path}. Bounds {restored} vs {bounds}, "
                           f"triangles {face_count} vs {triangles}.")
    if color_required and (not obj.data.color_attributes or not obj.data.uv_layers):
        raise RuntimeError(f"FBX did not retain vertex color or UV data: {path}")
    bpy.data.objects.remove(obj, do_unlink=True)


def export_section(output, name, section, materials=None):
    obj = add_polygons(name, section, materials)
    path = output / f"{name}.fbx"
    bounds = dimensions(section.points)
    write_fbx(path, obj)
    bpy.data.objects.remove(obj, do_unlink=True)
    check_fbx(path, bounds, len(section.faces), bool(materials))
    return {
        "asset": name, "file": path.name, "bounds_m": bounds,
        "triangles": len(section.faces),
        "materials": list(dict.fromkeys(section.surface_materials)),
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }


def read_collision(points):
    if len(points) % 3:
        raise ValueError("Collision input must contain full triangles")
    section = Section()
    index_lookup = {}
    for start in range(0, len(points), 3):
        tri = tuple(exchange_position(points[start + index]) for index in (0, 2, 1))
        key_points = triangle_key(tri)
        normal = (Vector(tri[1]) - Vector(tri[0])).cross(Vector(tri[2]) - Vector(tri[0]))
        if len(set(key_points)) != 3 or key_points in section.face_keys or normal.length_squared < 1e-12:
            continue
        section.face_keys.add(key_points)
        indices = tuple(index_lookup.setdefault(point, len(index_lookup)) for point in tri)
        section.faces.append(indices)
    section.points = list(index_lookup)
    return section


def verify_traversal(collision, start, doors):
    tree = BVHTree.FromPolygons(collision.points, collision.faces, all_triangles=True)
    up = Vector((0.0, 0.0, 1.0))
    feet = Vector(exchange_position(start["feet"]))
    floor, _, _, _ = tree.ray_cast(feet + up * 0.1, -up, 1.0)
    if floor is None:
        raise ValueError("Exported Ranwar arrival does not have floor support.")
    for door in doors:
        a, b = (Vector(exchange_position(door[key])) for key in ("outside", "inside"))
        travel = b - a
        for height in (0.35, 1.05, 1.60):
            blocked, _, _, _ = tree.ray_cast(a + up * height, travel.normalized(), travel.length)
            if blocked is not None:
                raise ValueError(f"Exported collision blocks the {door['name']} entrance at {height:.2f} m.")


def segment_nearest(point, start, end):
    span = end - start
    t = max(0.0, min(1.0, (point - start).dot(span) / span.length_squared))
    return start + span * t


def fits_roof(point, edges, margin):
    crossings = sum(
        (a.y > point.y) != (b.y > point.y) and
        point.x < a.x + (point.y - a.y) * (b.x - a.x) / (b.y - a.y)
        for a, b in edges
    )
    return crossings % 2 and all(
        (segment_nearest(point, a, b) - point).length >= margin for a, b in edges
    )


def building_dressing(sites, roads):
    # Physical extents of the selected conventional Sandbar meshes, in metres.
    roofs = (("Condenser", 0.83, 0.83, 0.96), ("SatDish", 1.27, 1.30, 0.72),
             ("HVAC", 2.99, 1.64, 0.74), ("VentChimney", 1.50, 1.40, 0.72),
             ("IndustrialAC", 2.00, 1.20, 0.82), ("VentUnitC", 4.80, 3.00, 0.65))
    streets = [(Vector((a[0], a[2])), Vector((b[0], b[2])))
               for road in roads for a, b in zip(road["points"], road["points"][1:]) if a != b]
    props, decals = [], []
    awnings = 0
    for index, site in enumerate(sites):
        points = list(map(Vector, site["polygon"]))
        edges = [(a, b) for a, b in zip(points, points[1:] + points[:1]) if a != b]
        height = site["height"]
        center = sum(points, Vector((0.0, 0.0))) / len(points)
        winding = 1 if sum(a.x * b.y - a.y * b.x for a, b in edges) > 0 else -1
        frontage = []
        for a, b in edges:
            middle = (a + b) * 0.5
            direction = (b - a).normalized()
            outward = Vector((direction.y, -direction.x)) * winding
            nearest = min((segment_nearest(middle, *street) for street in streets),
                          key=lambda point: (point - middle).length_squared)
            approach = nearest - middle
            if approach.dot(outward) > 1.0 and (b - a).length >= 3.5:
                frontage.append((approach.length, a, b, outward))
        if not frontage:
            continue
        distance, a, b, outward = min(frontage, key=lambda item: item[0])
        direction = (b - a).normalized()
        # Keep local positive Y pointing toward the street for front-facing props.
        if Vector((-direction.y, direction.x)).dot(outward) < 0.0:
            direction = -direction
        middle = (a + b) * 0.5
        asset, width, depth, scale = roofs[index % len(roofs)]
        margin = math.hypot(width, depth) * scale * 0.5 + 0.32
        reserved = list(site["reserved"])
        if height >= 15.0:
            reserved.append((center.x, center.y, 2.4))
        candidates = [middle.lerp(center, ratio) + direction * offset
                      for ratio in (0.48, 0.77, 1.0) for offset in (0.0, -2.6, 2.6, -4.6, 4.6)]
        for point in candidates:
            if fits_roof(point, edges, margin) and all(
                (point - Vector((rx, rz))).length >= radius + margin for rx, rz, radius in reserved
            ):
                props.append({"asset": asset, "label": f"Roof {asset} / {site['id']}",
                              "position": exchange_position((point.x, height + 0.025, point.y)),
                              "forward": exchange_position((direction.x, 0, direction.y)), "scale": scale})
                break
        if distance > 24.0 or site["adapted_front"]:
            continue
        if awnings < 8 and index % 3 == 2 and (b - a).length >= 6.0 and 5.0 < height < 15.0:
            point = a.lerp(b, 0.29) + outward * 0.48
            props.append({"asset": "Awning", "label": f"Canvas sunshade / {site['id']}",
                          "position": exchange_position((point.x, 2.77, point.y)),
                          "forward": exchange_position((direction.x, 0, direction.y)), "scale": 0.40})
            awnings += 1
        if index % 2 == 0 or height >= 15.0:
            point = a.lerp(b, 0.11 + 0.025 * (index % 3)) + outward * 0.015
            band = min(height - 0.80, 2.55 + (2.55 if height >= 15.0 else 0.0))
            decals.append({"variant": ("012A", "016A", "017A", "019A")[(index // 2) % 4],
                           "position": exchange_position((point.x, band, point.y)),
                           "outward": exchange_position((outward.x, 0, outward.y)),
                           "width": 0.47 + (index % 3) * 0.12, "height": 1.65})
    return props, decals


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--repo-root", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    data = json.loads(args.source.read_text(encoding="utf-8"))
    if data.get("schema") != 1 or not data.get("render_meshes") or not data.get("collision_triangles"):
        raise ValueError("Unsupported or empty Ranwar source export")

    output = args.output.resolve()
    textures = output / "Textures"
    textures.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0
    materials = build_materials(data["materials"], args.repo_root.resolve(), textures)
    sections = defaultdict(Section)
    for surface in data["render_meshes"]:
        append_surface(sections[section_name(surface)], surface, data["materials"][surface["material"]])
    assets = [export_section(output, name, sections[name], materials) for name in sorted(sections)]
    collision_source = read_collision(data["collision_triangles"])
    verify_traversal(collision_source, data["player_start"], data["doors"])
    collision = export_section(output, "RanwarCollision", collision_source)
    building_props, building_decals = building_dressing(data.get("building_sites", []), data["roads"])
    manifest = {
        "schema": 1,
        "asset_frame": "Blender +x forward, +y left, +z up, metres",
        "source_sha256": hashlib.sha256(args.source.read_bytes()).hexdigest(),
        "parts": assets, "collision": collision, "materials": materials,
        "building_props": building_props, "building_decals": building_decals,
        "player_start": {
            "feet": exchange_position(data["player_start"]["feet"]),
            "forward": exchange_position(data["player_start"]["forward"]),
        },
        "markers": [{**marker, "position": exchange_position(marker["position"])} for marker in data["markers"]],
        "doors": [{**door, **{field: exchange_position(door[field]) for field in ("threshold", "inside", "outside")}}
                  for door in data["doors"]],
        "roads": [{**road, "points": list(map(exchange_position, road["points"]))} for road in data["roads"]],
        "footway": list(map(exchange_position, data["footway"])),
        "osm_attribution": data["osm_attribution"],
        "visual_triangles": sum(asset["triangles"] for asset in assets),
        "collision_triangles": collision["triangles"],
        "traversal_checks": "arrival floor and three ray heights at each of the two shop doors passed",
    }
    pending = output / "ranwar-level.tmp"
    pending.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    pending.replace(output / "ranwar-level.json")
    print(
        f"Verified {len(assets)} visual FBX sections, {manifest['visual_triangles']} visual triangles, "
        f"{manifest['collision_triangles']} collision triangles and {len(manifest['markers'])} landmarks."
    )
    print(f"Planned {len(building_props)} Sandbar building props and {len(building_decals)} rain streaks.")


if __name__ == "__main__":
    main()
