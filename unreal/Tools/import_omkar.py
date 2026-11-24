"""Import the original Ranwar character rigs and matched animation clips."""

import re
from pathlib import Path

import unreal

DESTINATION = "/Game/Ranwar/Characters/Omkar"
MESH_NAME = "Omkar"
CLIP_NAMES = {"idle": "OmkarIdle", "walk": "OmkarWalk", "run": "OmkarRun"}
CONTACT_DESTINATION = "/Game/Ranwar/Characters/Contacts"
CONTACTS = ("Ravi", "Kavita")


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

    # GLB uses the engine's Interchange asset pipeline. AssetImportTask waits for
    # that import before get_objects() reports the skeletal mesh and animation sequences.
    task = unreal.AssetImportTask()
    task.set_editor_property("filename", str(source))
    task.set_editor_property("destination_path", destination)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", False)
    task.set_editor_property("save", False)
    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    imported = task.get_objects() or []
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
