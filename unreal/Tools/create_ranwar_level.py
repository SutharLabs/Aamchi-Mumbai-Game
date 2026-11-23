"""Build /Game/Ranwar/RanwarStreet from a verified Ranwar FBX exchange."""

from dataclasses import dataclass
import hashlib
import itertools
import json
import math
from pathlib import Path
import re
import sys

import unreal

LEVEL = "/Game/Ranwar/RanwarStreet"
GEOMETRY = "/Game/Ranwar/Geometry"
MATERIALS = "/Game/Ranwar/Materials"
TEXTURES = "/Game/Ranwar/Textures"
REGISTRATION_TOLERANCE_CM = 5.0


@dataclass(frozen=True)
class Axes:
    order: tuple
    signs: tuple

    def position(self, point):
        return tuple(100.0 * self.signs[i] * point[axis] for i, axis in enumerate(self.order))

    def extent(self, size):
        return tuple(100.0 * size[axis] for axis in self.order)


def safe_source(directory, relative):
    path = (directory / relative).resolve()
    if not path.is_relative_to(directory) or not path.is_file():
        raise ValueError(f"Missing or unexpected Ranwar exchange path: {relative}")
    return path


def validate_asset(asset, source):
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]+", asset["asset"]):
        raise ValueError(f"Invalid Ranwar asset name: {asset['asset']}")
    path = safe_source(source, asset["file"])
    if path.suffix.lower() != ".fbx":
        raise ValueError(f"Expected an FBX section: {path}")
    if hashlib.sha256(path.read_bytes()).hexdigest() != asset["sha256"]:
        raise ValueError(f"Ranwar section does not match the Blender receipt: {path}")
    return path


def mesh_task(source, name):
    options = unreal.FbxImportUI()
    options.set_editor_property("automated_import_should_detect_type", False)
    options.set_editor_property("mesh_type_to_import", unreal.FBXImportType.FBXIT_STATIC_MESH)
    options.set_editor_property("import_as_skeletal", False)
    # Import placeholder slots so FBX keeps their source material names.
    options.set_editor_property("import_materials", True)
    options.set_editor_property("import_textures", False)
    data = options.get_editor_property("static_mesh_import_data")
    data.set_editor_property("combine_meshes", True)
    data.set_editor_property("auto_generate_collision", False)
    data.set_editor_property("convert_scene_unit", True)
    data.set_editor_property("transform_vertex_to_absolute", True)
    data.set_editor_property("generate_lightmap_u_vs", False)
    data.set_editor_property("normal_import_method", unreal.FBXNormalImportMethod.FBXNIM_IMPORT_NORMALS)
    data.set_editor_property("vertex_color_import_option", unreal.VertexColorImportOption.REPLACE)
    task = import_task(source, GEOMETRY, name)
    task.set_editor_property("factory", unreal.FbxFactory())
    task.set_editor_property("options", options)
    return task


def import_task(source, destination, name):
    task = unreal.AssetImportTask()
    task.set_editor_property("filename", str(source))
    task.set_editor_property("destination_path", destination)
    task.set_editor_property("destination_name", name)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", True)
    task.set_editor_property("save", True)
    return task


def imported(task, asset_class):
    objects = [asset for asset in task.get_objects() if isinstance(asset, asset_class)]
    if len(objects) != 1:
        raise RuntimeError(f"Expected one {asset_class.__name__} from {task.get_editor_property('filename')}")
    return objects[0]


def tuples(bounds, axis):
    center = tuple((a + b) * 0.5 for a, b in zip(bounds["min"], bounds["max"]))
    extent = tuple((b - a) * 0.5 for a, b in zip(bounds["min"], bounds["max"]))
    return axis.position(center), axis.extent(extent)


def matches(actor, bounds, axes):
    center, extent = actor.get_actor_bounds(False)
    expected_center, expected_extent = tuples(bounds, axes)
    values = (center.x, center.y, center.z, extent.x, extent.y, extent.z)
    return all(abs(a - b) <= REGISTRATION_TOLERANCE_CM
               for a, b in zip(values, (*expected_center, *expected_extent)))


def determine_axes(ground, bounds):
    candidates = [
        Axes(order, (sx, sy, 1))
        for order in ((0, 1, 2), (1, 0, 2))
        for sx, sy in itertools.product((-1, 1), repeat=2)
    ]
    valid = [axis for axis in candidates if matches(ground, bounds, axis)]
    if len(valid) != 1:
        raise RuntimeError("Ground registration could not uniquely recover Unreal's FBX axes in centimetres.")
    return valid[0]


def section_materials(mesh, loaded):
    slots = mesh.get_editor_property("static_materials")
    for index, slot in enumerate(slots):
        imported_name = str(slot.get_editor_property("imported_material_slot_name"))
        name = imported_name if imported_name in loaded else str(slot.get_editor_property("material_slot_name"))
        if name not in loaded:
            raise RuntimeError(f"Ranwar import lost the source material slot {imported_name} / {name}.")
        mesh.set_material(index, loaded[name])


def create_materials(source, manifest, asset_tools, assets):
    result = {}
    pending = []
    for name, descriptor in manifest.items():
        if not re.fullmatch(r"Ranwar_m\d+(?:_[A-Za-z]+)?", name):
            raise ValueError(f"Unexpected Ranwar material identifier: {name}")
        for field in ("albedo_file", "normal_file"):
            if descriptor[field]:
                path = safe_source(source, descriptor[field])
                pending.append((name, field, import_task(path, TEXTURES, path.stem)))
    asset_tools.import_asset_tasks([task for _, _, task in pending])
    textures = {(name, field): imported(task, unreal.Texture2D) for name, field, task in pending}
    editor = unreal.MaterialEditingLibrary

    for name, descriptor in manifest.items():
        asset_path = f"{MATERIALS}/{name}"
        material = assets.load_asset(asset_path) if assets.does_asset_exist(asset_path) else None
        if material is None:
            material = asset_tools.create_asset(name, MATERIALS, unreal.Material, unreal.MaterialFactoryNew())
        if material is None:
            raise RuntimeError(f"Could not create material {name}.")
        editor.delete_all_material_expressions(material)
        color = editor.create_material_expression(material, unreal.MaterialExpressionVertexColor, -520, 0)
        albedo = textures.get((name, "albedo_file"))
        if albedo is not None:
            texture = editor.create_material_expression(material, unreal.MaterialExpressionTextureSample, -520, 170)
            texture.set_editor_property("texture", albedo)
            multiply = editor.create_material_expression(material, unreal.MaterialExpressionMultiply, -230, 0)
            editor.connect_material_expressions(color, "", multiply, "A")
            editor.connect_material_expressions(texture, "", multiply, "B")
            color = multiply
        editor.connect_material_property(color, "", unreal.MaterialProperty.MP_BASE_COLOR)
        for prop, field, y in ((unreal.MaterialProperty.MP_ROUGHNESS, "roughness", 320),
                               (unreal.MaterialProperty.MP_METALLIC, "metallic", 470)):
            constant = editor.create_material_expression(material, unreal.MaterialExpressionConstant, -260, y)
            constant.set_editor_property("r", descriptor[field])
            editor.connect_material_property(constant, "", prop)
        normal = textures.get((name, "normal_file"))
        if normal is not None:
            normal.set_editor_property("compression_settings", unreal.TextureCompressionSettings.TC_NORMALMAP)
            normal.set_editor_property("srgb", False)
            normal.set_editor_property("flip_green_channel", True)
            assets.save_loaded_asset(normal)
            sample = editor.create_material_expression(material, unreal.MaterialExpressionTextureSample, -530, 610)
            sample.set_editor_property("texture", normal)
            sample.set_editor_property("sampler_type", unreal.MaterialSamplerType.SAMPLERTYPE_NORMAL)
            editor.connect_material_property(sample, "", unreal.MaterialProperty.MP_NORMAL)
        editor.recompile_material(material)
        if not assets.save_loaded_asset(material):
            raise RuntimeError(f"Could not save material {name}.")
        result[name] = material
    return result


def spawn(actors, cls, label, point=(0.0, 0.0, 0.0), rotation=None):
    actor = actors.spawn_actor_from_class(cls, unreal.Vector(*point), rotation or unreal.Rotator())
    if actor is None:
        raise RuntimeError(f"Could not spawn {label}.")
    actor.set_actor_label(label)
    return actor


def add_geometry(actors, asset_tools, assets, source, manifest, materials):
    descriptors = [*manifest["parts"], manifest["collision"]]
    tasks = [mesh_task(validate_asset(part, source), part["asset"]) for part in descriptors]
    asset_tools.import_asset_tasks(tasks)
    sections = {}
    for part, task in zip(descriptors, tasks):
        mesh = imported(task, unreal.StaticMesh)
        actor = spawn(actors, unreal.StaticMeshActor, part["asset"])
        component = actor.static_mesh_component
        if part is manifest["collision"]:
            setup = mesh.get_editor_property("body_setup")
            if setup is None:
                raise RuntimeError("Unreal did not create a BodySetup for the collision mesh.")
            setup.set_editor_property("collision_trace_flag", unreal.CollisionTraceFlag.CTF_USE_COMPLEX_AS_SIMPLE)
            setup.set_editor_property("double_sided_geometry", True)
            mesh.set_editor_property("body_setup", setup)
            mesh.set_editor_property("customized_collision", True)
            component.set_static_mesh(mesh)
            component.set_collision_profile_name("BlockAll")
            component.set_cast_shadow(False)
            component.set_visibility(False)
        else:
            section_materials(mesh, materials)
            component.set_static_mesh(mesh)
            component.set_collision_profile_name("NoCollision")
        if not assets.save_loaded_asset(mesh):
            raise RuntimeError(f"Could not save {part['asset']}.")
        sections[part["asset"]] = (actor, part["bounds_m"])
    ground, bounds = sections["Ground"]
    axes = determine_axes(ground, bounds)
    for name, (actor, bounds) in sections.items():
        if not matches(actor, bounds, axes):
            raise RuntimeError(f"Imported bounds are out of registration for {name}.")
    return axes


def populate(actors, axes, manifest):
    mode = getattr(unreal, "RanwarGameMode", None)
    landmark_class = getattr(unreal, "RanwarLandmark", None)
    if mode is None or landmark_class is None:
        raise RuntimeError("Build the native MumbaiPilot editor module before creating the Ranwar level.")
    sun = spawn(actors, unreal.DirectionalLight, "Bandra sunlight", rotation=unreal.Rotator(pitch=-43, yaw=-41))
    sun.light_component.set_mobility(unreal.ComponentMobility.MOVABLE)
    sun.light_component.set_editor_property("atmosphere_sun_light", True)
    sun.light_component.set_editor_property("intensity", 28000.0)
    sky = spawn(actors, unreal.SkyLight, "Bandra skylight")
    sky.light_component.set_mobility(unreal.ComponentMobility.MOVABLE)
    sky.light_component.set_editor_property("real_time_capture", True)
    spawn(actors, unreal.SkyAtmosphere, "Bandra daylight")

    start_x, start_y, start_z = axes.position(manifest["player_start"]["feet"])
    forward_x, forward_y, _ = axes.position(manifest["player_start"]["forward"])
    yaw = math.degrees(math.atan2(forward_y, forward_x))
    start = (start_x, start_y, start_z + 92.0)
    rotation = unreal.Rotator(yaw=yaw)
    spawn(actors, unreal.PlayerStart, "St Peter's Church BEST stop", start, rotation)
    for marker in manifest["markers"]:
        actor = spawn(actors, landmark_class, marker["name"], axes.position(marker["position"]))
        actor.set_editor_property("display_name", unreal.Text(marker["name"]))
        actor.set_editor_property("details", unreal.Text(marker["details"]))
    add_parcel_route(actors, axes, manifest, yaw)
    add_traffic(actors, axes, manifest)
    unreal.get_editor_subsystem(unreal.UnrealEditorSubsystem).set_level_viewport_camera_info(
        unreal.Vector(start_x - forward_x * 4.1, start_y - forward_y * 4.1, start_z + 185),
        unreal.Rotator(pitch=-12.0, yaw=yaw),
    )


def add_parcel_route(actors, axes, manifest, heading):
    route = spawn(actors, unreal.RanwarRoute, "Ranwar Parcel Run")
    feet = unreal.Vector(*axes.position(manifest["player_start"]["feet"]))
    forward_x, forward_y, _ = axes.position(manifest["player_start"]["forward"])
    forward = unreal.Vector(forward_x / 100.0, forward_y / 100.0, 0.0)
    # Godot's right side of the westbound arrival route, transformed into Unreal axes.
    source_x, source_y, _ = manifest["player_start"]["forward"]
    across_x, across_y, _ = axes.position((-source_y, source_x, 0.0))
    across = unreal.Vector(across_x / 100.0, across_y / 100.0, 0.0)
    guide = feet + forward * 1710.0
    route.set_editor_property("guide_stop", guide)
    right = unreal.Vector(-forward.y, forward.x, 0.0)
    bus = feet - forward * 272.0 + right * 140.0 - unreal.Vector(0.0, 0.0, 50.0)
    add_arrival_prop(actors, "BestBus", "Bandra BEST arrival coach", bus, heading, False)
    add_arrival_prop(actors, "Anjali", "Anjali", guide, heading + 180.0, True)
    add_arrival_prop(actors, "Pedestrian", "Sameer", feet + forward * 2300.0, heading + 180.0, True)
    # The Godot job-board coordinates (-9, 0, 5) convert to (-5, 9, 0) in the exchange.
    route.set_editor_property("job_board", unreal.Vector(*axes.position((-5.0, 9.0, 0.0))))
    footway = [unreal.Vector(*axes.position(point)) for point in manifest["footway"]]

    def inset(start, next_point, distance):
        delta = next_point - start
        length = math.sqrt(delta.x ** 2 + delta.y ** 2 + delta.z ** 2)
        return start + delta * min(1.0, distance / length) if length else start

    route.set_editor_property("parcel_pickup", inset(footway[-1], footway[-2], 1300.0))
    route.set_editor_property("parcel_dropoff", inset(footway[0], footway[1], 1000.0))
    route.set_editor_property("road_heading", heading)
    route.set_editor_property("loan_bays", [feet + forward * offset + across * 285.0 for offset in (1300.0, 2000.0, 2700.0)])

    # Same paved bay footprint used by the original Ranwar parking planner.
    yard_coordinates = [(x, z) for z in (-15.0, -24.0) for x in (-48.0, -32.0, -24.0, -16.0, -8.0)]
    route.set_editor_property("yard_bays", [unreal.Vector(*axes.position((-z, -x, 0.55))) for x, z in yard_coordinates])
    yard_x, yard_y, _ = axes.position((1.0, 0.0, 0.0))
    route.set_editor_property("yard_heading", math.degrees(math.atan2(yard_y, yard_x)))


def add_arrival_prop(actors, package, label, position, heading, solid):
    asset_path = f"/Game/Ranwar/Arrival/{package}.{package}"
    mesh = unreal.load_asset(asset_path)
    if not isinstance(mesh, unreal.StaticMesh):
        raise RuntimeError(f"Could not load the imported arrival asset {asset_path}.")
    actor = spawn(actors, unreal.StaticMeshActor, label, (position.x, position.y, position.z), unreal.Rotator(yaw=heading))
    component = actor.static_mesh_component
    component.set_static_mesh(mesh)
    component.set_collision_profile_name("BlockAll" if solid else "NoCollision")
    if package == "Anjali":
        component.set_collision_response_to_channel(
            unreal.CollisionChannel.ECC_VISIBILITY, unreal.CollisionResponseType.ECR_IGNORE,
        )


def add_traffic(actors, axes, manifest):
    traffic = spawn(actors, unreal.RanwarTraffic, "Ranwar left-hand traffic")
    # Hill Road westbound, St Peter's Road both ways, Waroda eastbound and Waroda west both ways.
    roads = []
    for descriptor, directions in zip(manifest["roads"], (2, 3, 2, 3), strict=True):
        road = unreal.RanwarTrafficRoad()
        road.set_editor_property("points", [unreal.Vector(*axes.position(point)) for point in descriptor["points"]])
        road.set_editor_property("width", 100.0 * descriptor["width_m"])
        road.set_editor_property("directions", directions)
        roads.append(road)
    traffic.set_editor_property("roads", roads)


def main():
    project = Path(unreal.Paths.convert_relative_path_to_full(unreal.Paths.project_dir())).resolve()
    source = project.parent / "builds" / "local" / "unreal-ranwar"
    manifest = json.loads(safe_source(source, "ranwar-level.json").read_text(encoding="utf-8"))
    if manifest["schema"] != 1 or len(manifest["doors"]) != 2 or len(manifest["roads"]) != 4:
        raise ValueError("Incomplete Ranwar level exchange.")
    assets = unreal.get_editor_subsystem(unreal.EditorAssetSubsystem)
    if assets.does_asset_exist(LEVEL):
        raise RuntimeError(f"{LEVEL} already exists. Move the generated map before rebuilding it.")
    sys.path.insert(0, str(project / "Tools"))
    from import_omkar import import_omkar
    from import_ranwar_arrival import import_ranwar_arrival
    from import_ranwar_vehicles import import_ranwar_vehicles

    import_omkar(safe_source(source, "omkar.glb"))
    import_ranwar_vehicles(source / "vehicles")
    import_ranwar_arrival(source / "arrival")

    editor = unreal.EditorLoadingAndSavingUtils
    world = editor.new_blank_map(False)
    if world is None:
        raise RuntimeError("Could not create a blank Unreal map.")
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    materials = create_materials(source, manifest["materials"], asset_tools, assets)
    axes = add_geometry(actors, asset_tools, assets, source, manifest, materials)
    populate(actors, axes, manifest)
    if not editor.save_map(world, LEVEL):
        raise RuntimeError(f"Could not save {LEVEL}.")
    unreal.log(f"Saved {LEVEL} with {len(manifest['parts'])} FBX sections and {manifest['osm_attribution']}.")


if __name__ == "__main__":
    main()
