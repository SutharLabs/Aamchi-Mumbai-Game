"""Prepare a native Renderpeople pedestrian for Ranwar's optional ambient dressing."""

import unreal


SOURCE = "/Game/City/People/Nathan"
DESTINATION = "/Game/Ranwar/Characters/SandbarAmbient"
MESH_SOURCE = f"{SOURCE}/SK_Ped_Nathan"
WALK_SOURCE = f"{SOURCE}/SK_Ped_Nathan_Anim"
SKELETON_SOURCE = f"{SOURCE}/SK_Ped_Nathan_Skeleton"
MATERIAL_SOURCE = f"{SOURCE}/rp_nathan_animated_003_mat_001"
COLOR_SOURCE = f"{SOURCE}/rp_nathan_animated_003_mat_baseColor"
MESH_PATH = f"{DESTINATION}/Nathan"
COLOR_PATH = f"{DESTINATION}/NathanBaseColor"
MATERIAL_NAME = "NathanMaterial"


def _load(assets, path, expected_type):
    result = assets.load_asset(path) if assets.does_asset_exist(path) else None
    if not isinstance(result, expected_type):
        raise RuntimeError(f"Missing or incorrect SandbarCity package {path}. Run the Nathan staging script.")
    return result


def _get_or_duplicate(assets, source, target, expected_type):
    if assets.does_asset_exist(target):
        return _load(assets, target, expected_type)
    result = assets.duplicate_asset(source, target)
    if not isinstance(result, expected_type):
        raise RuntimeError(f"Could not create Ranwar derivative {target}.")
    return result


def _save(assets, asset):
    if not assets.save_loaded_asset(asset, only_if_is_dirty=False):
        raise RuntimeError(f"Could not save Ranwar derivative {asset.get_path_name()}.")


def _surface(assets):
    texture = _get_or_duplicate(assets, COLOR_SOURCE, COLOR_PATH, unreal.Texture2D)
    texture.set_editor_property("max_texture_size", 1024)
    texture.set_editor_property("virtual_texture_streaming", False)
    texture.set_editor_property("compression_settings", unreal.TextureCompressionSettings.TC_DEFAULT)
    texture.set_editor_property("srgb", True)
    _save(assets, texture)

    path = f"{DESTINATION}/{MATERIAL_NAME}"
    if assets.does_asset_exist(path):
        material = _load(assets, path, unreal.Material)
    else:
        material = unreal.AssetToolsHelpers.get_asset_tools().create_asset(
            MATERIAL_NAME, DESTINATION, unreal.Material, unreal.MaterialFactoryNew()
        )
        if not isinstance(material, unreal.Material):
            raise RuntimeError(f"Could not make {path}.")
    material.set_editor_property("used_with_skeletal_mesh", True)
    editor = unreal.MaterialEditingLibrary
    editor.delete_all_material_expressions(material)
    sample = editor.create_material_expression(material, unreal.MaterialExpressionTextureSample, -360, 0)
    sample.set_editor_property("texture", texture)
    editor.connect_material_property(sample, "RGB", unreal.MaterialProperty.MP_BASE_COLOR)
    rough = editor.create_material_expression(material, unreal.MaterialExpressionConstant, -360, 180)
    rough.set_editor_property("r", 0.76)
    editor.connect_material_property(rough, "", unreal.MaterialProperty.MP_ROUGHNESS)
    editor.recompile_material(material)
    _save(assets, material)
    return material


def import_sandbar_ambient_scan():
    """Return the optimized skeletal mesh and matching walk, or None in a public checkout."""
    assets = unreal.get_editor_subsystem(unreal.EditorAssetSubsystem)
    if not any(assets.does_asset_exist(path) for path in
               (MESH_SOURCE, WALK_SOURCE, SKELETON_SOURCE, MATERIAL_SOURCE, COLOR_SOURCE)):
        unreal.log("SandbarCity Nathan is optional and is absent. Retaining Ranwar's existing pedestrians.")
        return None

    source = _load(assets, MESH_SOURCE, unreal.SkeletalMesh)
    walk = _load(assets, WALK_SOURCE, unreal.AnimSequence)
    skeleton = _load(assets, SKELETON_SOURCE, unreal.Skeleton)
    _load(assets, MATERIAL_SOURCE, unreal.MaterialInstanceConstant)
    _load(assets, COLOR_SOURCE, unreal.Texture2D)
    if source.get_editor_property("skeleton") != skeleton or walk.get_editor_property("skeleton") != skeleton:
        raise RuntimeError("SandbarCity Nathan and its walk must use the same reviewed skeleton.")
    duration = walk.get_play_length()
    if abs(duration - 10.375) > 0.01:
        raise RuntimeError(f"Unexpected SandbarCity Nathan walk duration: {duration:.3f} s.")

    mesh = _get_or_duplicate(assets, MESH_SOURCE, MESH_PATH, unreal.SkeletalMesh)
    materials = mesh.get_editor_property("materials")
    if len(materials) != 1 or mesh.get_editor_property("skeleton") != skeleton:
        raise RuntimeError("Ranwar's Nathan derivative must retain one material slot and the native skeleton.")
    slot = materials[0]
    slot.set_editor_property("material_interface", _surface(assets))
    mesh.set_editor_property("materials", [slot])
    _save(assets, mesh)
    unreal.log(f"SandbarCity ambient Nathan: native skeleton and {duration:.3f}s walk, color capped at 1024.")
    return mesh, walk


def add_sandbar_ambient_scan(actors, spawn, point, yaw, label="Ambient pedestrian", animate=False):
    """Place a visual ambient actor at world-centimetre feet, with optional looping walk."""
    prepared = import_sandbar_ambient_scan()
    if prepared is None:
        return None
    mesh, walk = prepared
    actor = spawn(actors, unreal.SkeletalMeshActor, label, (point.x, point.y, point.z), unreal.Rotator(yaw=yaw))
    component = actor.get_component_by_class(unreal.SkeletalMeshComponent)
    component.set_skeletal_mesh_asset(mesh)
    component.set_collision_profile_name("NoCollision")
    data = component.get_editor_property("animation_data")
    data.set_editor_property("anim_to_play", walk)
    data.set_editor_property("saved_looping", True)
    data.set_editor_property("saved_playing", animate)
    data.set_editor_property("saved_position", 0.38)
    component.set_editor_property("animation_data", data)
    component.set_animation_mode(unreal.AnimationMode.ANIMATION_SINGLE_NODE)
    origin, extent = actor.get_actor_bounds(False)
    base = origin - unreal.Vector(0.0, 0.0, extent.z)
    actor.set_actor_location(point + (point - base), False, False)
    return actor
