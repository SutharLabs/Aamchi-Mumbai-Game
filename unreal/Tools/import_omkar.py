"""Import the first-party Omkar GLB into canonical native gameplay asset paths."""

import re
from pathlib import Path

import unreal

DESTINATION = "/Game/Ranwar/Characters/Omkar"
MESH_NAME = "Omkar"
CLIP_NAMES = {"idle": "OmkarIdle", "walk": "OmkarWalk", "run": "OmkarRun"}


def _clip_key(asset):
    name = asset.get_name().casefold()
    words = re.findall(r"[a-z]+", name)
    matches = [key for key in CLIP_NAMES if key in words or name.endswith(key)]
    return matches[0] if len(matches) == 1 else None


def _expected_package(name):
    return f"{DESTINATION}/{name}"


def _rename(assets, asset, expected_name):
    if asset.get_path_name().split(".", 1)[0] != _expected_package(expected_name):
        if not assets.rename_loaded_asset(asset, _expected_package(expected_name)):
            raise RuntimeError(f"Could not rename {asset.get_name()} to {expected_name}.")


def _verify_skeleton(mesh, clips):
    if not isinstance(mesh, unreal.SkeletalMesh) or any(
        not isinstance(clip, unreal.AnimSequence) for clip in clips.values()
    ):
        raise RuntimeError("Omkar needs a skeletal mesh and three animation sequences.")
    skeleton = mesh.get_editor_property("skeleton")
    if skeleton is None or any(
        clip.get_editor_property("skeleton") != skeleton for clip in clips.values()
    ):
        raise RuntimeError("The imported Omkar mesh and animation sequences need a shared skeleton.")


def import_omkar(source):
    source = Path(source).resolve(strict=True)
    if source.suffix.casefold() != ".glb":
        raise ValueError(f"Expected a GLB source for Omkar, received {source}.")

    assets = unreal.get_editor_subsystem(unreal.EditorAssetSubsystem)
    expected = [MESH_NAME, *CLIP_NAMES.values()]
    existing = [assets.does_asset_exist(_expected_package(name)) for name in expected]
    if all(existing):
        _verify_skeleton(
            assets.load_asset(_expected_package(MESH_NAME)),
            {key: assets.load_asset(_expected_package(name)) for key, name in CLIP_NAMES.items()},
        )
        unreal.log("Using existing Omkar gameplay assets.")
        return
    if any(existing):
        raise RuntimeError("The Omkar gameplay folder contains only part of the expected import.")

    # GLB uses the engine's Interchange asset pipeline. AssetImportTask waits for
    # that import before get_objects() reports the skeletal mesh and animation sequences.
    task = unreal.AssetImportTask()
    task.set_editor_property("filename", str(source))
    task.set_editor_property("destination_path", DESTINATION)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", False)
    task.set_editor_property("save", False)
    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    imported = task.get_objects() or []
    meshes = [asset for asset in imported if isinstance(asset, unreal.SkeletalMesh)]
    clips = {}
    for asset in imported:
        if isinstance(asset, unreal.AnimSequence):
            key = _clip_key(asset)
            if key in clips:
                raise RuntimeError(f"Two imported Omkar animations match {key}.")
            if key is not None:
                clips[key] = asset
    if len(meshes) != 1 or set(clips) != set(CLIP_NAMES):
        names = ", ".join(asset.get_name() for asset in imported)
        raise RuntimeError(f"Omkar import needs one skeletal mesh and idle, walk, and run. Found {names}.")

    _verify_skeleton(meshes[0], clips)
    _rename(assets, meshes[0], MESH_NAME)
    for key, name in CLIP_NAMES.items():
        _rename(assets, clips[key], name)
    if not assets.save_directory(DESTINATION):
        raise RuntimeError("Could not save the imported Omkar gameplay assets.")
    unreal.log("Imported Omkar gameplay mesh and idle, walk, and run clips.")
