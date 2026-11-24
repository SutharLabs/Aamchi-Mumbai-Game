"""Import original asset studies and adopted references into an editor library."""

import hashlib
import json
from pathlib import Path
import re
import struct

import unreal


LIBRARY = "/Game/ModelLibrary"


def _study_sources(root):
    queue = json.loads((root / "jobs" / "night-queue.json").read_text(encoding="utf-8"))
    for job in queue["jobs"]:
        name = job["id"]
        if re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name) is None:
            raise ValueError(f"Invalid model-study identifier {name!r}.")
        relative = f"assets/generated/{name}/model.glb"
        if relative in job["outputs"]:
            yield name.replace("-", "_"), root / relative
    yield "IndianStreetShop", root / "prototype" / "world" / "props" / "indian_street_shop.glb"
    bridge = root / "builds" / "local" / "unreal-pilot" / "sea-link-main-span.glb"
    if bridge.is_file():
        yield "BandraWorliSeaLinkStudy", bridge


def _embedded_glb_digest(path):
    content = path.read_bytes()
    if len(content) < 20:
        raise ValueError(f"Truncated GLB {path}.")
    magic, version, total, json_length, kind = struct.unpack_from("<4sIII4s", content)
    if (magic, version, total, kind) != (b"glTF", 2, len(content), b"JSON") or json_length > total - 20:
        raise ValueError(f"Invalid GLB {path}.")
    scene = json.loads(content[20:20 + json_length])
    if not scene.get("meshes") or any("uri" in part for key in ("buffers", "images") for part in scene.get(key, [])):
        raise ValueError(f"Expected self-contained model geometry in {path}.")
    return hashlib.sha256(content).hexdigest()


def import_model_library(root):
    root = root.resolve(strict=True)
    assets = unreal.get_editor_subsystem(unreal.EditorAssetSubsystem)
    tools = unreal.AssetToolsHelpers.get_asset_tools()
    total = 0
    for name, path in _study_sources(root):
        path = path.resolve(strict=True)
        if not path.is_relative_to(root):
            raise ValueError(f"Model is outside the project: {path}.")
        digest = _embedded_glb_digest(path)
        destination = f"{LIBRARY}/{name}"
        existing = []
        if assets.does_directory_exist(destination):
            existing = [assets.load_asset(item) for item in assets.list_assets(destination, recursive=True)]
        meshes = [asset for asset in existing if isinstance(asset, unreal.StaticMesh)]
        if not meshes or any(assets.get_metadata_tag(mesh, "SourceSHA256") != digest for mesh in meshes):
            task = unreal.AssetImportTask()
            task.set_editor_property("filename", str(path))
            task.set_editor_property("destination_path", destination)
            task.set_editor_property("automated", True)
            task.set_editor_property("replace_existing", True)
            tools.import_asset_tasks([task])
            meshes = [item for item in task.get_objects() if isinstance(item, unreal.StaticMesh)]
            if not meshes:
                raise RuntimeError(f"Expected static mesh assets from {path}.")
            for mesh in meshes:
                assets.set_metadata_tag(mesh, "SourceSHA256", digest)
            if not assets.save_directory(destination):
                raise RuntimeError(f"Could not save model library group {destination}.")
        unreal.log(f"Model library {name}: {len(meshes)} static meshes.")
        total += 1
    unreal.log(f"Ranwar model library ready with {total} source groups.")


if __name__ == "__main__":
    project = Path(unreal.Paths.convert_relative_path_to_full(unreal.Paths.project_dir())).resolve()
    import_model_library(project.parent)
