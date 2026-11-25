"""Import the original Ranwar character rigs and matched animation clips."""

import json
import re
import struct
from pathlib import Path

import unreal

from import_model_library import _embedded_glb_digest

DESTINATION = "/Game/Ranwar/Characters/Omkar"
MESH_NAME = "Omkar"
CLIP_NAMES = {"idle": "OmkarIdle", "walk": "OmkarWalk", "run": "OmkarRun"}
CONTACT_DESTINATION = "/Game/Ranwar/Characters/Contacts"
CONTACTS = ("Ravi", "Kavita")
KAVITA_PONYTAIL = "KavitaFabPonytail"
KAVITA_PONYTAIL_FILE = "Kavita-Fab-Ponytail.glb"
KAVITA_PONYTAIL_SHA256 = "76443cc400030a97d2440355e355f1f5f0622292d9d90a4f129d6920ef6fe36a"
KAVITA_HAIR_FOLDER = f"{CONTACT_DESTINATION}/{KAVITA_PONYTAIL}"
KAVITA_HAIR_MATERIAL = "MI_KavitaPonytailMask"


def _clip_key(asset, clip_names):
    name = asset.get_name().casefold()
    words = re.findall(r"[a-z]+", name)
    matches = [key for key in clip_names if key in words or name.endswith(key)]
    return matches[0] if len(matches) == 1 else None


def _expected_package(destination, name):
    return f"{destination}/{name}"


def _rename(assets, asset, destination, expected_name):
    package = _expected_package(destination, expected_name)
    if asset.get_path_name().split(".", 1)[0] != package:
        if not assets.rename_loaded_asset(asset, package):
            raise RuntimeError(f"Could not rename {asset.get_name()} to {expected_name}.")


def _verify_skeleton(mesh, clips, name):
    if not isinstance(mesh, unreal.SkeletalMesh) or any(
        not isinstance(clip, unreal.AnimSequence) for clip in clips.values()
    ):
        raise RuntimeError(f"{name} needs a skeletal mesh and its animation sequences.")
    skeleton = mesh.get_editor_property("skeleton")
    if skeleton is None or any(
        clip.get_editor_property("skeleton") != skeleton for clip in clips.values()
    ):
        raise RuntimeError(f"The imported {name} mesh and sequences need a shared skeleton.")


def _import_glb(source, destination, options=None):
    # get_objects() waits for the Interchange import to complete.
    task = unreal.AssetImportTask()
    task.set_editor_property("filename", str(source))
    task.set_editor_property("destination_path", destination)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", False)
    task.set_editor_property("save", False)
    if options is not None:
        task.set_editor_property("options", options)
    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    return task.get_objects() or []


def _import_character(source, destination, mesh_name, clip_names):
    source = Path(source).resolve(strict=True)
    if source.suffix.casefold() != ".glb":
        raise ValueError(f"Expected a GLB source for {mesh_name}, received {source}.")

    assets = unreal.get_editor_subsystem(unreal.EditorAssetSubsystem)
    expected = [mesh_name, *clip_names.values()]
    existing = [assets.does_asset_exist(_expected_package(destination, name)) for name in expected]
    if all(existing):
        _verify_skeleton(
            assets.load_asset(_expected_package(destination, mesh_name)),
            {key: assets.load_asset(_expected_package(destination, name)) for key, name in clip_names.items()},
            mesh_name,
        )
        unreal.log(f"Using existing {mesh_name} gameplay assets.")
        return
    if any(existing):
        raise RuntimeError(f"The {mesh_name} gameplay folder contains only part of the expected import.")

    imported = _import_glb(source, destination)
    meshes = [asset for asset in imported if isinstance(asset, unreal.SkeletalMesh)]
    clips = {}
    for asset in imported:
        if isinstance(asset, unreal.AnimSequence):
            key = _clip_key(asset, clip_names)
            if key in clips:
                raise RuntimeError(f"Two imported {mesh_name} animations match {key}.")
            if key is not None:
                clips[key] = asset
    if len(meshes) != 1 or set(clips) != set(clip_names):
        names = ", ".join(asset.get_name() for asset in imported)
        raise RuntimeError(f"{mesh_name} import needs one mesh and {tuple(clip_names)}. Found {names}.")

    _verify_skeleton(meshes[0], clips, mesh_name)
    _rename(assets, meshes[0], destination, mesh_name)
    for key, name in clip_names.items():
        _rename(assets, clips[key], destination, name)
    if not assets.save_directory(destination):
        raise RuntimeError(f"Could not save the imported {mesh_name} gameplay assets.")
    unreal.log(f"Imported {mesh_name} gameplay mesh and {tuple(clip_names)} clips.")


def import_omkar(source):
    _import_character(source, DESTINATION, MESH_NAME, CLIP_NAMES)


def import_parcel_contacts(directory):
    for name in CONTACTS:
        _import_character(
            directory / f"{name}.glb", f"{CONTACT_DESTINATION}/{name}", name,
            {"breath": f"{name}Breath", "gesture": f"{name}Gesture"},
        )


    import_kavita_ponytail(directory)


def _joint_names(source):
    with source.open("rb") as stream:
        header = stream.read(20)
        _, _, _, length, _ = struct.unpack("<4sIII4s", header)
        scene = json.loads(stream.read(length))
    (skin,) = scene["skins"]
    return tuple(scene["nodes"][index]["name"] for index in skin["joints"])


def _material_names(slot):
    names = [slot.get_editor_property(key) for key in ("material_slot_name", "imported_material_slot_name")]
    material = slot.get_editor_property("material_interface")
    if material is not None:
        names.append(material.get_name())
    return {re.sub("[^a-z0-9]", "", str(name).casefold()) for name in names}


def _make_kavita_hair_material(texture):
    tools = unreal.AssetToolsHelpers.get_asset_tools()
    material = tools.create_asset(KAVITA_HAIR_MATERIAL, KAVITA_HAIR_FOLDER,
                                  unreal.Material, unreal.MaterialFactoryNew())
    if material is None:
        raise RuntimeError("Could not create the native Kavita ponytail material.")
    material.set_editor_property("blend_mode", unreal.BlendMode.BLEND_MASKED)
    material.set_editor_property("two_sided", True)
    material.set_editor_property("opacity_mask_clip_value", 0.19)
    if texture.get_editor_property("compression_no_alpha"):
        texture.set_editor_property("compression_no_alpha", False)

    editor = unreal.MaterialEditingLibrary
    editor.set_base_material_usage(material, unreal.MaterialUsage.MATUSAGE_SKELETAL_MESH, True)
    expression = editor.create_material_expression(material, unreal.MaterialExpressionTextureSample, -360, 0)
    expression.set_editor_property("texture", texture)
    for output, property_ in (("RGB", unreal.MaterialProperty.MP_BASE_COLOR),
                              ("A", unreal.MaterialProperty.MP_OPACITY_MASK)):
        if not editor.connect_material_property(expression, output, property_):
            raise RuntimeError(f"Could not connect Kavita ponytail material output {output}.")
    for index, (value, property_) in enumerate(((0.82, unreal.MaterialProperty.MP_ROUGHNESS),
                                               (0.19, unreal.MaterialProperty.MP_SPECULAR))):
        constant = editor.create_material_expression(material, unreal.MaterialExpressionConstant, -360, 270 + 100 * index)
        constant.set_editor_property("r", value)
        if not editor.connect_material_property(constant, "", property_):
            raise RuntimeError(f"Could not connect Kavita ponytail material property {property_}.")
    editor.recompile_material(material)
    return material


def _verify_kavita_variant(mesh, canonical):
    if (not isinstance(mesh, unreal.SkeletalMesh)
            or mesh.get_editor_property("skeleton") != canonical.get_editor_property("skeleton")):
        raise RuntimeError("Kavita's ponytail mesh must use her original contact skeleton.")
    (body_slot,) = canonical.get_editor_property("materials")
    body = body_slot.get_editor_property("material_interface")
    slots = mesh.get_editor_property("materials")
    assigned = [slot.get_editor_property("material_interface") for slot in slots]
    if len(assigned) != 2 or body is None or assigned.count(body) != 1:
        paths = [material.get_path_name() if material else None for material in assigned]
        expected = body.get_path_name() if body else None
        raise RuntimeError(f"Kavita needs the original body material {expected} and a separate hair slot: {paths}.")
    hair = next(material for material in assigned if material != body)
    if (not isinstance(hair, unreal.Material) or hair.get_name() != KAVITA_HAIR_MATERIAL
            or hair.get_blend_mode() != unreal.BlendMode.BLEND_MASKED
            or not hair.get_editor_property("two_sided")):
        raise RuntimeError("Kavita's ponytail needs a two-sided masked material.")


def load_kavita_ponytail(canonical):
    assets = unreal.get_editor_subsystem(unreal.EditorAssetSubsystem)
    package = _expected_package(KAVITA_HAIR_FOLDER, KAVITA_PONYTAIL)
    if not assets.does_asset_exist(package):
        return None
    mesh = assets.load_asset(package)
    _verify_kavita_variant(mesh, canonical)
    return mesh


def import_kavita_ponytail(directory):
    directory = Path(directory).resolve(strict=True)
    source = directory / KAVITA_PONYTAIL_FILE
    if not source.exists() and not source.is_symlink():
        return None
    source = source.resolve(strict=True)
    if source.parent != directory or _embedded_glb_digest(source) != KAVITA_PONYTAIL_SHA256:
        raise ValueError("Kavita's staged ponytail GLB does not match the verified private intake.")
    source_joints = _joint_names(source)
    if len(source_joints) != 21 or source_joints != _joint_names(directory / "Kavita.glb"):
        raise ValueError("Kavita's staged ponytail GLB does not match her original contact joint list.")

    assets = unreal.get_editor_subsystem(unreal.EditorAssetSubsystem)
    canonical = assets.load_asset(f"{CONTACT_DESTINATION}/Kavita/Kavita")
    if not isinstance(canonical, unreal.SkeletalMesh):
        raise RuntimeError("Import the original Kavita contact mesh before adding her ponytail.")
    cached = load_kavita_ponytail(canonical)
    if cached is not None:
        return cached

    pipeline = unreal.InterchangeGenericAssetsPipeline()
    skeletal = pipeline.get_editor_property("common_skeletal_meshes_and_animations_properties")
    skeletal.set_editor_property("skeleton", canonical.get_editor_property("skeleton"))
    skeletal.set_editor_property("try_auto_select_skeleton", False)
    skeletal.set_editor_property("add_curve_metadata_to_skeleton", False)
    pipeline.get_editor_property("animation_pipeline").set_editor_property("import_animations", False)
    pipeline.get_editor_property("material_pipeline").set_editor_property("import_materials", False)
    pipeline.get_editor_property("mesh_pipeline").set_editor_property("create_physics_asset", False)
    options = unreal.InterchangePipelineStackOverride()
    options.add_pipeline(pipeline)
    imported = _import_glb(source, KAVITA_HAIR_FOLDER, options)
    meshes = [asset for asset in imported if isinstance(asset, unreal.SkeletalMesh)]
    if len(meshes) != 1 or any(isinstance(asset, unreal.AnimSequence) for asset in imported):
        raise RuntimeError("Kavita's ponytail intake must import one mesh and reuse her original animations.")
    mesh = meshes[0]
    if mesh.get_editor_property("skeleton") != canonical.get_editor_property("skeleton"):
        raise RuntimeError("Unreal did not bind Kavita's ponytail variant to her original skeleton.")

    slots = list(mesh.get_editor_property("materials"))
    hair_slots = [index for index, slot in enumerate(slots)
                  if "ponytailhaircardmasked" in _material_names(slot)]
    textures = [asset for asset in imported if isinstance(asset, unreal.Texture2D)
                and "ponytailhaircoverage" in re.sub("[^a-z0-9]", "", asset.get_name().casefold())]
    if len(slots) != 2 or len(hair_slots) != 1 or len(textures) != 1:
        slot_names = [_material_names(slot) for slot in slots]
        asset_names = [asset.get_name() for asset in imported]
        raise RuntimeError(f"Kavita's ponytail import lost its hair slot or coverage map: {slot_names}, {asset_names}.")
    (canonical_body,) = canonical.get_editor_property("materials")
    hair_index = hair_slots[0]
    slots[1 - hair_index].set_editor_property("material_interface", canonical_body.get_editor_property("material_interface"))
    slots[hair_index].set_editor_property("material_interface", _make_kavita_hair_material(textures[0]))
    mesh.set_editor_property("materials", slots)
    _verify_kavita_variant(mesh, canonical)
    _rename(assets, mesh, KAVITA_HAIR_FOLDER, KAVITA_PONYTAIL)
    if not assets.save_directory(KAVITA_HAIR_FOLDER):
        raise RuntimeError("Could not save Kavita's optional ponytail mesh.")
    unreal.log("Imported KavitaFabPonytail with her original contact skeleton and two-sided masked hair.")
    return mesh
