"""Place reviewed street models and ambient pedestrians in playable Ranwar."""

import json
import math
from dataclasses import dataclass

import unreal

from import_model_library import _embedded_glb_digest
from import_sandbar_ambient_scan import import_sandbar_ambient_scan


DESTINATION = "/Game/Ranwar/StreetLife"
MODELS = (
    "plastic_crate_02", "plastic_monobloc_chair_01", "planter_pot_clay",
    "wooden_crate_01", "rollershutter_window_03",
)
FAB_SIZES_CM = {
    "fab_wood_ladder": (9.51, 47.35, 241.79),
    "fab_canvas_sandbags": (85.54, 95.37, 41.17),
    "fab_coconut": (15.29, 20.62, 16.46),
}
OPTIONAL_MODELS = ("fab_dirty_plastic_crate", *FAB_SIZES_CM)
FAB_TAG = "RanwarFabStreetLife"
FAB_AWNING = "Canvas sunshade / mapped-913464162"
FACADE_CLEARANCE_CM = 8.0
SHOP_LAYOUT = (
    ("plastic_monobloc_chair_01", -3.4, 1.28, 12.0, 1.0),
    ("planter_pot_clay", -4.2, 0.63, 74.0, 1.30),
    ("plastic_crate_02", 3.7, 0.89, 18.0, 1.0),
    ("wooden_crate_01", 4.5, 0.86, -7.0, 0.88),
)
AWNING_LAYOUT = (
    ("planter_pot_clay", -1.20, 0.29, 35.0, 1.23),
    ("wooden_crate_01", 1.19, 0.46, 10.0, 0.86),
    ("plastic_crate_02", 1.51, 0.75, -23.0, 1.0),
)
PATROLS = (
    ("Opposite the BEST stop", ((338.0, -5.15, 0.12), (346.0, -4.85, 0.12)), 91.0, 0.28),
    ("Hill Road tower approach", ((295.0, -7.65, 0.12), (308.0, -7.17, 0.12)), 103.0, 0.62),
    ("Opposite the corner grocer", ((443.0, -149.0, 0.12), (452.0, -149.55, 0.12)), 88.0, 0.34),
)
# Nathan's exported toe direction is local +Y. The path heading uses +X.
NATHAN_YAW_OFFSET = -90.0
NATHAN_CLIP_SPEED = 140.0
METAHUMAN_CLIP_SPEED = 224.8


@dataclass(frozen=True)
class MetaHumanAppearance:
    actor_class: object
    idle: object
    walk: object
    gesture: object
    walk_clip_speed: float


def load_metahuman_cast():
    assets = unreal.get_editor_subsystem(unreal.EditorAssetSubsystem)

    def appearance(revision):
        folder = f"/Game/OmkarAssembled/{revision}/Omkar"
        blueprint = f"{folder}/BP_Omkar"
        idle_path = f"{folder}/Animations/OmkarIdle_MH"
        walk_path = f"{folder}/Animations/OmkarWalk_MH"
        if not all(assets.does_asset_exist(path) for path in (blueprint, idle_path, walk_path)):
            return None
        actor_class = assets.load_blueprint_class(blueprint)
        idle, walk = (assets.load_asset(path) for path in (idle_path, walk_path))
        if not actor_class or not all(isinstance(clip, unreal.AnimSequence) for clip in (idle, walk)):
            raise RuntimeError(f"The {revision} Ranwar cast assembly has an invalid actor class or locomotion clip.")
        if idle.get_editor_property("skeleton") != walk.get_editor_property("skeleton"):
            raise RuntimeError(f"The idle and walk for {revision} must use the same assembled skeleton.")
        gesture_path = f"{folder}/Animations/OmkarHandover_MH"
        gesture = assets.load_asset(gesture_path) if assets.does_asset_exist(gesture_path) else None
        if gesture and (not isinstance(gesture, unreal.AnimSequence)
                        or gesture.get_editor_property("skeleton") != idle.get_editor_property("skeleton")):
            raise RuntimeError(f"The handover for {revision} does not match its assembled skeleton.")
        measured = unreal.EditorAssetLibrary.get_metadata_tag(walk, "RanwarStanceSpeedCmPerSecond")
        walk_clip_speed = float(measured) if measured else METAHUMAN_CLIP_SPEED
        if not 100.0 <= walk_clip_speed <= 350.0:
            raise RuntimeError(f"The {revision} walk has an invalid measured stance speed.")
        return MetaHumanAppearance(actor_class, idle, walk, gesture, walk_clip_speed)

    male = appearance("r005")
    if male is None:
        return None
    rival = appearance("r004")
    if rival is None:
        raise RuntimeError("The private Ranwar cast requires the previous Omkar assembly for Vikram.")
    female = appearance("r006") or male
    return {"male": male, "female": female, "rival": rival}


def add_metahuman_pedestrian(actors, spawn, appearance, label, point, rotation=None):
    actor = spawn(actors, unreal.RanwarAmbientPedestrian, label, (point.x, point.y, point.z), rotation)
    actor.set_editor_property("meta_human_class", appearance.actor_class)
    actor.set_editor_property("walk_animation", appearance.walk)
    actor.set_editor_property("idle_animation", appearance.idle)
    actor.set_editor_property("walk_clip_speed", appearance.walk_clip_speed)
    return actor


def _import_models(source, import_task, imported, *, required=MODELS, optional=OPTIONAL_MODELS):
    directory = (source / "street-life").resolve()
    if not directory.is_dir():
        return {}
    if not directory.is_relative_to(source):
        raise ValueError("Street-life source directory resolves outside the Ranwar exchange.")
    manifest = json.loads((directory / "manifest.json").read_text(encoding="utf-8"))
    names = [*required, *(name for name in optional if name in manifest)]
    assets = unreal.get_editor_subsystem(unreal.EditorAssetSubsystem)
    tasks = []
    for name in names:
        path = (directory / f"{name}.glb").resolve()
        if not path.is_relative_to(directory) or _embedded_glb_digest(path) != manifest[name]["sha256"]:
            raise ValueError(f"Street-life GLB does not match the verified intake: {name}.")
        tasks.append(import_task(path, f"{DESTINATION}/{name}", name))
    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks(tasks)
    meshes = {}
    for name, task in zip(names, tasks, strict=True):
        mesh = imported(task, unreal.StaticMesh)
        count = mesh.get_num_triangles(0)
        if not 0 < count <= 4500:
            raise RuntimeError(f"Unexpected street-life triangle count for {name}: {count}.")
        if name in FAB_SIZES_CM:
            extent = mesh.get_bounds().box_extent
            size = (*sorted((2.0 * extent.x, 2.0 * extent.y)), 2.0 * extent.z)
            if any(abs(actual - expected) > max(3.0, 0.15 * expected)
                   for actual, expected in zip(size, FAB_SIZES_CM[name], strict=True)):
                raise RuntimeError(f"Unexpected Fab size in Unreal centimetres for {name}: {size}.")
        if not assets.save_directory(f"{DESTINATION}/{name}"):
            raise RuntimeError(f"Could not save street-life asset {name}.")
        meshes[name] = mesh
        unreal.log(f"Ranwar street-life mesh: {name}, {count} triangles.")
    return meshes


def _yaw(vector):
    return math.degrees(math.atan2(vector.y, vector.x))


def _horizontal_unit(vector):
    length = math.hypot(vector.x, vector.y)
    if length < 0.01:
        raise ValueError("Street-life frontage has no usable horizontal direction.")
    return unreal.Vector(vector.x / length, vector.y / length, 0.0)


def _place_mesh(actors, spawn, mesh, label, base, yaw, scale, ground=None, *,
                pitch=0.0, roll=0.0, ground_tolerance=None):
    actor = spawn(actors, unreal.StaticMeshActor, label, (base.x, base.y, base.z + 0.15),
                  unreal.Rotator(yaw=yaw, pitch=pitch, roll=roll))
    component = actor.static_mesh_component
    component.set_static_mesh(mesh)
    component.set_collision_profile_name("NoCollision")
    actor.set_actor_scale3d(unreal.Vector(scale, scale, scale))
    center, extent = actor.get_actor_bounds(False)
    if ground is not None:
        surface = ground(actor, label, base)
        if ground_tolerance is not None and abs(surface.z - base.z) > ground_tolerance:
            raise RuntimeError(f"Unexpected support height for {label}: {surface.z:.2f} cm.")
        base = surface
    bottom = center - unreal.Vector(0.0, 0.0, extent.z)
    actor.set_actor_location(actor.get_actor_location() + base - bottom + unreal.Vector(0.0, 0.0, 0.15),
                             False, False)
    return actor


def _clear_facade_position(world, anchor, outward, half_width, half_depth, minimum_depth, heights):
    """Keep the full rotated footprint on the street side of the solid facade."""
    lateral = unreal.Vector(-outward.y, outward.x, 0.0)
    plane = 0.0
    for offset in (-half_width, 0.0, half_width):
        for height in heights:
            point = anchor + lateral * offset + unreal.Vector(0.0, 0.0, height)
            hit = unreal.SystemLibrary.line_trace_single_for_objects(
                world, point + outward * 155.0, point - outward * 90.0,
                [unreal.ObjectTypeQuery.ECC_WORLD_STATIC], True, [], unreal.DrawDebugTrace.NONE,
            )
            if hit is not None:
                blocked, starts_inside, _, _, _, surface, _, normal, *_ = hit.to_tuple()
                if blocked and not starts_inside and normal.x * outward.x + normal.y * outward.y > 0.5:
                    offset_from_anchor = (surface.x - anchor.x) * outward.x + (surface.y - anchor.y) * outward.y
                    plane = max(plane, offset_from_anchor)
    return anchor + outward * max(minimum_depth, plane + half_depth + FACADE_CLEARANCE_CM)


def _ground_prop_extents(mesh, skew, scale):
    bounds = mesh.get_bounds().box_extent
    angle = math.radians(skew)
    along = abs(math.cos(angle)) * bounds.x + abs(math.sin(angle)) * bounds.y
    depth = abs(math.sin(angle)) * bounds.x + abs(math.cos(angle)) * bounds.y
    return along * scale, depth * scale


def _around_frontage(actors, spawn, world, meshes, label, point, outward, layout, ground):
    lateral = unreal.Vector(-outward.y, outward.x, 0.0)
    for name, along, distance, yaw, scale in layout:
        actual = name
        if name == "plastic_crate_02" and "fab_dirty_plastic_crate" in meshes:
            actual = "fab_dirty_plastic_crate"
        mesh = meshes[actual]
        anchor = point + lateral * (along * 100.0)
        width, depth = _ground_prop_extents(mesh, yaw, scale)
        height = mesh.get_bounds().box_extent.z * scale
        location = _clear_facade_position(world, anchor, outward, width, depth,
                                          distance * 100.0, (22.0, max(32.0, height)))
        _place_mesh(actors, spawn, mesh, f"{label} / {actual}", location,
                    _yaw(lateral) + yaw, scale, ground)


def _frontage(axes, door):
    threshold = unreal.Vector(*axes.position(door["threshold"]))
    outside = unreal.Vector(*axes.position(door["outside"]))
    return threshold, _horizontal_unit(outside - threshold)


def _fab_prop(actors, spawn, mesh, site, item, position, yaw, scale, ground=None, **rotation):
    label = f"Fab street life / {site} / {item}"
    actor = _place_mesh(actors, spawn, mesh, label, position, yaw, scale, ground, **rotation)
    actor.set_editor_property("tags", [FAB_TAG])


def _fab_ladder(actors, spawn, world, mesh, site, wall, outward, along, ground):
    lateral = unreal.Vector(-outward.y, outward.x, 0.0)
    anchor = wall + lateral * (along * 100.0)
    bounds = mesh.get_bounds().box_extent
    lean = 10.0
    radians = math.radians(lean)
    half_width = max(bounds.x, bounds.y)
    half_depth = min(bounds.x, bounds.y) * math.cos(radians) + bounds.z * math.sin(radians)
    # Probe high enough to catch upper facade projections beyond the foot of the ladder.
    position = _clear_facade_position(world, anchor, outward, half_width, half_depth, 35.0, (26.0, 110.0, 225.0))
    # Roll around a width in local X, or pitch around a width in local Y.
    if bounds.x > bounds.y:
        _fab_prop(actors, spawn, mesh, site, "maintenance ladder", position, _yaw(lateral), 1.0,
                  ground, roll=lean, ground_tolerance=30.0)
    else:
        _fab_prop(actors, spawn, mesh, site, "maintenance ladder", position, _yaw(outward), 1.0,
                  ground, pitch=lean, ground_tolerance=30.0)
    unreal.log(f"Ranwar ladder at {site}: frontage offset {(position - anchor).length():.1f} cm, "
               f"placement {position.x:.1f}, {position.y:.1f}, {position.z:.1f}.")


def _fab_sacks(actors, spawn, world, mesh, site, wall, outward, along, depth, skew, scale, ground):
    lateral = unreal.Vector(-outward.y, outward.x, 0.0)
    anchor = wall + lateral * (along * 100.0)
    half_width, half_depth = _ground_prop_extents(mesh, skew, scale)
    position = _clear_facade_position(world, anchor, outward, half_width, half_depth, depth * 100.0, (20.0, 37.0))
    _fab_prop(actors, spawn, mesh, site, "canvas sacks", position, _yaw(lateral) + skew, scale,
              ground, ground_tolerance=30.0)


def _fab_crate_coconuts(actors, spawn, mesh, site):
    name = f"{site} / wooden_crate_01"
    crate = next((actor for actor in actors.get_all_level_actors() if actor.get_actor_label() == name), None)
    if not isinstance(crate, unreal.StaticMeshActor):
        raise RuntimeError(f"Missing wooden display crate at {site}.")
    crate_mesh = crate.static_mesh_component.get_editor_property("static_mesh")
    bounds = crate_mesh.get_bounds().box_extent
    long_axis = crate.get_actor_forward_vector() if bounds.x > bounds.y else crate.get_actor_right_vector()
    center, extent = crate.get_actor_bounds(False)
    # Measured crate-lid surface is 1.12 cm below the highest corner at its placed scale.
    lid = center + unreal.Vector(0.0, 0.0, extent.z - 1.12)
    for index, (offset, yaw, scale) in enumerate(((-16.0, 17.0, 0.97), (17.0, 68.0, 0.90)), 1):
        _fab_prop(actors, spawn, mesh, site, f"crate coconut {index}", lid + long_axis * offset, yaw, scale)


def _fab_counter_coconuts(actors, spawn, mesh, site, threshold, outward, ground):
    lateral = unreal.Vector(-outward.y, outward.x, 0.0)
    # Side display is centred 2.51 m off the door axis at a 0.90 m surface height.
    positions = ((-2.64, 1.55, 24.0, 0.99), (-2.36, 1.70, -18.0, 0.94),
                 (-2.58, 1.88, 58.0, 0.94), (-2.39, 2.10, 116.0, 0.90))
    for index, (along, depth, yaw, scale) in enumerate(positions, 1):
        position = threshold + lateral * (along * 100.0) - outward * (depth * 100.0)
        position += unreal.Vector(0.0, 0.0, 90.0)
        _fab_prop(actors, spawn, mesh, site, f"counter coconut {index}", position, yaw, scale,
                  ground, ground_tolerance=2.0)


def add_ranwar_fab_props(actors, spawn, world, axes, manifest, meshes, ground):
    """Place the approved optional intake after the original street props."""
    ladder = meshes.get("fab_wood_ladder")
    sacks = meshes.get("fab_canvas_sandbags")
    coconut = meshes.get("fab_coconut")
    if ladder is None and sacks is None and coconut is None:
        return

    for door in manifest["doors"]:
        site = door["name"]
        threshold, outward = _frontage(axes, door)
        if door["osm_way"] == 360291657:
            if ladder is not None:
                _fab_ladder(actors, spawn, world, ladder, site, threshold, outward, -5.86, ground)
            if sacks is not None:
                _fab_sacks(actors, spawn, world, sacks, site, threshold, outward, 5.66, 0.68, 9.0, 0.93, ground)
            if coconut is not None:
                _fab_crate_coconuts(actors, spawn, coconut, site)
        elif door["osm_way"] == 357472313:
            if sacks is not None:
                _fab_sacks(actors, spawn, world, sacks, site, threshold, outward, 2.22, 0.89, -12.0, 0.86, ground)
            if coconut is not None:
                _fab_counter_coconuts(actors, spawn, coconut, site, threshold, outward, ground)

    entry = next((row for row in manifest.get("building_props", ()) if row["label"] == FAB_AWNING), None)
    if entry is not None:
        x, y, _ = axes.position(entry["position"])
        forward = _horizontal_unit(unreal.Vector(*axes.position(entry["forward"])))
        outward = unreal.Vector(-forward.y, forward.x, 0.0)
        wall = unreal.Vector(x, y, 0.0) - outward * 48.0
        if ladder is not None:
            _fab_ladder(actors, spawn, world, ladder, FAB_AWNING, wall, outward, 2.10, ground)
        if sacks is not None:
            _fab_sacks(actors, spawn, world, sacks, FAB_AWNING, wall, outward, -2.30, 0.75, 21.0, 0.88, ground)


def add_ranwar_street_life(actors, spawn, axes, manifest, source, ground, import_task, imported):
    meshes = _import_models(source, import_task, imported)
    if not meshes:
        return
    world = unreal.get_editor_subsystem(unreal.UnrealEditorSubsystem).get_editor_world()
    for door in manifest["doors"]:
        threshold, outward = _frontage(axes, door)
        _around_frontage(actors, spawn, world, meshes, door["name"], threshold, outward, SHOP_LAYOUT, ground)
    shutter = meshes["rollershutter_window_03"]
    awnings = [row for row in manifest.get("building_props", ()) if row["asset"] == "Awning"]
    for index, row in enumerate(awnings):
        x, y, _ = axes.position(row["position"])
        forward = _horizontal_unit(unreal.Vector(*axes.position(row["forward"])))
        outward = unreal.Vector(-forward.y, forward.x, 0.0)
        wall = unreal.Vector(x, y, 0.0) - outward * 48.0
        _place_mesh(actors, spawn, shutter, f"Closed window / {row['label']}",
                    wall + outward * 9.0 + unreal.Vector(0.0, 0.0, 104.0),
                    _yaw(forward) + 180.0, 0.89)
        if index % 2 == 0:
            _around_frontage(actors, spawn, world, meshes, row["label"], wall, outward, AWNING_LAYOUT, ground)
    add_ranwar_fab_props(actors, spawn, world, axes, manifest, meshes, ground)
    unreal.log(f"Ranwar street life: {len(awnings)} facade modules and "
               f"{2 * len(SHOP_LAYOUT) + ((len(awnings) + 1) // 2) * len(AWNING_LAYOUT)} ground props.")


def add_ranwar_ambient_pedestrians(actors, spawn, axes, ground, cast):
    prepared = import_sandbar_ambient_scan() if cast is None else None
    if prepared is None and cast is None:
        return
    for (label, route, speed, progress), role in zip(PATROLS, ("female", "male", "female"), strict=True):
        ends = [unreal.Vector(*axes.position(point)) for point in route]
        initial = ends[0]
        actor_label = f"Ambient walker / {label}"
        if cast:
            actor = add_metahuman_pedestrian(actors, spawn, cast[role], actor_label, initial)
            actor.set_editor_property("tags", ["RanwarMetaHumanWalker"])
        else:
            mesh, walk = prepared
            actor = spawn(actors, unreal.RanwarAmbientPedestrian, actor_label, (initial.x, initial.y, initial.z))
            actor.get_editor_property("skeletal_mesh").set_skeletal_mesh_asset(mesh)
            origin, extent = actor.get_actor_bounds(False)
            actor.set_editor_property("mesh_z_offset", initial.z - (origin.z - extent.z))
            actor.set_editor_property("mesh_yaw_offset", NATHAN_YAW_OFFSET)
            actor.set_editor_property("walk_clip_speed", NATHAN_CLIP_SPEED)
            actor.set_editor_property("walk_animation", walk)
        start, end = ends
        points = [ground(actor, f"{label} route sample {i}", start + (end - start) * (i / 12.0))
                  for i in range(13)]
        actor.set_editor_property("walk_speed", speed)
        actor.set_editor_property("initial_progress", progress)
        actor.set_editor_property("path_points", points)
    unreal.log(f"Ranwar street life: {len(PATROLS)} ambient pavement routes.")
