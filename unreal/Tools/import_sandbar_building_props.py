"""Place reviewed SandbarCity building assets with Ranwar's DirectX 11 materials."""

import math

import unreal


ROOF = "/Game/Sketchfab/Roof"
AWNING = "/Game/Sketchfab/Awning/Awning/StaticMeshes/Awning"
DESTINATION = "/Game/Ranwar/Materials/SandbarBuildings"
MESH_DESTINATION = "/Game/Ranwar/Geometry/Sandbar"
PROPS = {
    "Condenser": f"{ROOF}/SM_Condenser",
    "HVAC": f"{ROOF}/SM_HVAC",
    "IndustrialAC": f"{ROOF}/SM_IndustrialAC",
    "SatDish": f"{ROOF}/SM_SatDish",
    "VentChimney": f"{ROOF}/SM_VentChimney",
    "VentUnitC": f"{ROOF}/SM_VentUnitC",
    "Awning": AWNING,
}
SOURCE_DIRECTORIES = tuple(
    f"/Game/Sketchfab/{name}/{name}"
    for name in ("Condenser", "HVAC", "IndustrialAC", "SatDish", "RoofVentKit", "Awning")
)
DECALS = {
    variant: f"/Game/Decals/Textures/T_Decal_Leaking{variant}"
    for variant in ("012A", "016A", "017A", "019A")
}


def _load(assets, path, asset_type):
    asset = assets.load_asset(path) if assets.does_asset_exist(path) else None
    if not isinstance(asset, asset_type):
        raise RuntimeError(f"SandbarCity package missing or mistyped: {path}. Run the staging script.")
    return asset


def _material(assets, name):
    path = f"{DESTINATION}/{name}"
    if assets.does_asset_exist(path):
        return _load(assets, path, unreal.Material)
    material = unreal.AssetToolsHelpers.get_asset_tools().create_asset(
        name, DESTINATION, unreal.Material, unreal.MaterialFactoryNew()
    )
    if material is None:
        raise RuntimeError(f"Could not create {path}.")
    return material


def _save_material(assets, material):
    unreal.MaterialEditingLibrary.recompile_material(material)
    if not assets.save_loaded_asset(material):
        raise RuntimeError(f"Could not save material {material.get_path_name()}.")
    return material


def _texture_sample(material, texture, y):
    sample = unreal.MaterialEditingLibrary.create_material_expression(
        material, unreal.MaterialExpressionTextureSample, -420, y
    )
    sample.set_editor_property("texture", texture)
    return sample


def _constant(material, value, y):
    node = unreal.MaterialEditingLibrary.create_material_expression(
        material, unreal.MaterialExpressionConstant, -420, y
    )
    node.set_editor_property("r", value)
    return node


def _override_material(assets, source, name):
    if not isinstance(source, unreal.MaterialInstanceConstant):
        raise RuntimeError(f"Missing source material instance for {name}. Run the staging script.")

    editor = unreal.MaterialEditingLibrary
    inputs = unreal.MaterialProperty
    # Read instance overrides directly so parent defaults never stand in for missing source maps.
    textures = {
        str(value.get_editor_property("parameter_info").get_editor_property("name")):
        value.get_editor_property("parameter_value")
        for value in source.get_editor_property("texture_parameter_values")
    }
    base = textures.get("BaseColorTexture", textures.get("DiffuseTexture"))
    normal = textures.get("NormalTexture")
    packed = textures.get("MetallicRoughnessTexture")
    if not isinstance(base, unreal.Texture2D) or not isinstance(normal, unreal.Texture2D):
        raise RuntimeError(f"Missing color or normal map for {source.get_path_name()}. Run the staging script.")
    if "MetallicRoughnessTexture" in textures and not isinstance(packed, unreal.Texture2D):
        raise RuntimeError(f"Missing packed surface map for {source.get_path_name()}. Run the staging script.")

    material = _material(assets, name)
    editor.delete_all_material_expressions(material)
    editor.connect_material_property(_texture_sample(material, base, 0), "RGB", inputs.MP_BASE_COLOR)
    editor.connect_material_property(_texture_sample(material, normal, 180), "RGB", inputs.MP_NORMAL)
    if isinstance(packed, unreal.Texture2D):
        sample = _texture_sample(material, packed, 360)
        editor.connect_material_property(sample, "G", inputs.MP_ROUGHNESS)
        editor.connect_material_property(sample, "B", inputs.MP_METALLIC)
    else:
        editor.connect_material_property(_constant(material, 0.64, 360), "", inputs.MP_ROUGHNESS)
        editor.connect_material_property(_constant(material, 0.0, 460), "", inputs.MP_METALLIC)
    return _save_material(assets, material)


def _heading(axes, forward):
    x, y, _ = axes.position(forward)
    if not math.isfinite(x) or not math.isfinite(y) or (x == 0.0 and y == 0.0):
        raise ValueError(f"Invalid SandbarCity building-facing vector: {forward}.")
    return math.degrees(math.atan2(y, x))


def _position(axes, point):
    position = axes.position(point)
    if not all(math.isfinite(value) for value in position):
        raise ValueError(f"Invalid SandbarCity building position: {point}.")
    return position


def _positive(value, name):
    if not math.isfinite(value) or value <= 0.0:
        raise ValueError(f"Invalid SandbarCity {name}: {value}.")
    return value


def _native_mesh(assets, key, source_path, source):
    slots = source.get_editor_property("static_materials")
    if not slots:
        raise RuntimeError(f"No source material slots on SandbarCity {key}.")
    materials = [
        _override_material(assets, slot.get_editor_property("material_interface"), f"SB_{key}_{index}")
        for index, slot in enumerate(slots)
    ]
    path = f"{MESH_DESTINATION}/SB_{key}"
    mesh = (assets.load_asset(path) if assets.does_asset_exist(path)
            else assets.duplicate_asset(source_path, path))
    if not isinstance(mesh, unreal.StaticMesh):
        raise RuntimeError(f"Could not create Ranwar mesh {path} from {source_path}.")
    if len(mesh.get_editor_property("static_materials")) != len(materials):
        raise RuntimeError(f"Ranwar mesh {path} does not match the SandbarCity material slots.")
    for index, material in enumerate(materials):
        mesh.set_material(index, material)
    # Retain the source geometry while replacing every runtime reference to its Substrate materials.
    if not assets.save_loaded_asset(mesh, only_if_is_dirty=False):
        raise RuntimeError(f"Could not save Ranwar mesh {path}.")
    return mesh


def add_sandbar_building_props(actors, spawn, axes, manifest):
    rows = manifest.get("building_props", ())
    if not rows:
        return
    assets = unreal.get_editor_subsystem(unreal.EditorAssetSubsystem)
    requested = {row["asset"]: PROPS[row["asset"]] for row in rows}
    if not (any(assets.does_asset_exist(path) for path in PROPS.values()) or
            any(assets.does_directory_exist(path) for path in SOURCE_DIRECTORIES)):
        unreal.log("SandbarCity building props skipped because the optional source assets are absent.")
        return

    sources = {key: _load(assets, path, unreal.StaticMesh) for key, path in requested.items()}
    meshes = {key: _native_mesh(assets, key, path, sources[key]) for key, path in requested.items()}

    for row in rows:
        key = row["asset"]
        mesh = meshes[key]
        scale = _positive(row["scale"], "mesh scale")
        position = _position(axes, row["position"])
        point = unreal.Vector(*position)
        actor = spawn(
            actors, unreal.StaticMeshActor, row["label"], position,
            unreal.Rotator(yaw=_heading(axes, row["forward"])),
        )
        component = actor.static_mesh_component
        component.set_static_mesh(mesh)
        component.set_collision_profile_name("NoCollision")
        actor.set_actor_scale3d(unreal.Vector(scale, scale, scale))
        center, extent = actor.get_actor_bounds(False)
        base = center - unreal.Vector(0.0, 0.0, extent.z)
        actor.set_actor_location(point + (point - base), False, False)
        unreal.log(
            f"SandbarCity building prop: {row['label']}, {key} LOD0 {sources[key].get_num_triangles(0)} triangles, "
            f"scale {scale:.2f}, centered base at {position} cm."
        )


def _decal_material(assets, variant, texture):
    material = _material(assets, f"SB_Leaking{variant}")
    material.set_editor_property("material_domain", unreal.MaterialDomain.MD_DEFERRED_DECAL)
    material.set_editor_property("blend_mode", unreal.BlendMode.BLEND_TRANSLUCENT)
    editor = unreal.MaterialEditingLibrary
    editor.delete_all_material_expressions(material)
    sample = _texture_sample(material, texture, 130)
    tint = editor.create_material_expression(material, unreal.MaterialExpressionConstant3Vector, -420, -80)
    tint.set_editor_property("constant", unreal.LinearColor(0.15, 0.13, 0.10, 1.0))
    opacity = editor.create_material_expression(material, unreal.MaterialExpressionMultiply, -160, 130)
    editor.connect_material_expressions(sample, "A", opacity, "A")
    editor.connect_material_expressions(_constant(material, 0.53, 290), "", opacity, "B")
    editor.connect_material_property(tint, "", unreal.MaterialProperty.MP_BASE_COLOR)
    editor.connect_material_property(opacity, "", unreal.MaterialProperty.MP_OPACITY)
    return _save_material(assets, material)


def add_sandbar_weather_decals(actors, spawn, axes, manifest):
    rows = manifest.get("building_decals", ())
    if not rows:
        return
    assets = unreal.get_editor_subsystem(unreal.EditorAssetSubsystem)
    requested = {row["variant"]: DECALS[row["variant"]] for row in rows}
    if not any(assets.does_asset_exist(path) for path in DECALS.values()):
        unreal.log("SandbarCity weather decals skipped because the optional source textures are absent.")
        return

    textures = {key: _load(assets, path, unreal.Texture2D) for key, path in requested.items()}
    materials = {variant: _decal_material(assets, variant, texture) for variant, texture in textures.items()}
    for index, row in enumerate(rows, 1):
        position = _position(axes, row["position"])
        rotation = unreal.Rotator(yaw=_heading(axes, row["outward"]))
        label = f"SandbarCity rain streak {index:03d}"
        decal = spawn(actors, unreal.DecalActor, label, position, rotation)
        component = decal.get_component_by_class(unreal.DecalComponent)
        width = _positive(row["width"], "decal width")
        height = _positive(row["height"], "decal height")
        component.set_editor_property("decal_size", unreal.Vector(12.0, width * 50.0, height * 50.0))
        component.set_decal_material(materials[row["variant"]])
    unreal.log(f"SandbarCity weather decals: placed {len(rows)} wall-projected rain streaks.")
