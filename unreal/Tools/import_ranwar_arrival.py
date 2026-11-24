"""Import the original Ranwar arrival coach and the baked civilian meshes."""

import json
from pathlib import Path
import struct

import unreal

DESTINATION = "/Game/Ranwar/Arrival"
ASSETS = ("BestBus", "AnjaliKurta", "Pedestrian", "Farah", "Nitin", "Leena", "Iqbal", "Ravi", "Kavita")


def _source_bounds(path):
    with path.open("rb") as stream:
        header = stream.read(20)
        if len(header) != 20:
            raise ValueError(f"Incomplete arrival GLB: {path}")
        magic, version, size, json_length, kind = struct.unpack("<4sIII4s", header)
        if (magic, version, size, kind) != (b"glTF", 2, path.stat().st_size, b"JSON") or json_length > size - 20:
            raise ValueError(f"Invalid arrival GLB header: {path}")
        data = json.loads(stream.read(json_length))
    meshes = data.get("meshes", [])
    buffers = data.get("buffers", [])
    if (len(meshes) != 1 or len(buffers) != 1 or "uri" in buffers[0]
            or any("bufferView" not in image or "uri" in image for image in data.get("images", []))
            or data.get("skins") or data.get("animations")):
        raise ValueError(f"Expected one self-contained static arrival mesh: {path}")
    positions = [data["accessors"][primitive["attributes"]["POSITION"]]
                 for primitive in meshes[0]["primitives"]]
    # Interchange converts the authored GLB coordinates from metres to centimetres.
    axes = (0, 2, 1)
    lower = tuple(min(position["min"][axis] for position in positions) * 100.0 for axis in axes)
    upper = tuple(max(position["max"][axis] for position in positions) * 100.0 for axis in axes)
    if abs(lower[2]) > 1.0 or any(stop <= start for start, stop in zip(lower, upper)):
        raise ValueError(f"Missing model volume or ground pivot in {path}.")
    return (*lower, *upper)


def _verify_mesh(mesh, name, expected):
    if not isinstance(mesh, unreal.StaticMesh):
        raise RuntimeError(f"Expected a static mesh for {name}.")
    box = mesh.get_bounding_box()
    actual = (box.min.x, box.min.y, box.min.z, box.max.x, box.max.y, box.max.z)
    if any(abs(value - reference) > 1.0 for value, reference in zip(actual, expected)):
        raise RuntimeError(f"Imported {name} scale, heading, or pivot differs from its source GLB.")
    slots = mesh.get_editor_property("static_materials")
    if not slots or any(slot.get_editor_property("material_interface") is None for slot in slots):
        raise RuntimeError(f"Missing original material assignments for {name}.")
    unreal.log(f"Ranwar arrival asset {name}: {len(slots)} material slots, ground pivot verified.")


def import_ranwar_arrival(source):
    source = Path(source).resolve(strict=True)
    assets = unreal.get_editor_subsystem(unreal.EditorAssetSubsystem)
    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    inputs = {name: source / f"{name}.glb" for name in ASSETS}
    bounds = {name: _source_bounds(path) for name, path in inputs.items()}

    for name, path in inputs.items():
        package = f"{DESTINATION}/{name}"
        if assets.does_asset_exist(package):
            _verify_mesh(assets.load_asset(package), name, bounds[name])
            continue
        task = unreal.AssetImportTask()
        task.set_editor_property("filename", str(path))
        task.set_editor_property("destination_path", DESTINATION)
        task.set_editor_property("automated", True)
        task.set_editor_property("replace_existing", False)
        task.set_editor_property("save", False)
        asset_tools.import_asset_tasks([task])
        meshes = [asset for asset in task.get_objects() if isinstance(asset, unreal.StaticMesh)]
        if len(meshes) != 1:
            raise RuntimeError(f"Expected one imported static mesh from {path}, got {len(meshes)}.")
        mesh = meshes[0]
        _verify_mesh(mesh, name, bounds[name])
        if mesh.get_path_name().split(".", 1)[0] != package and not assets.rename_loaded_asset(mesh, package):
            raise RuntimeError(f"Could not put imported arrival asset at {package}.")

    if not assets.save_directory(DESTINATION):
        raise RuntimeError("Could not save the Ranwar arrival meshes and finishes.")
    unreal.log("Saved the Ranwar arrival bus and eight civilian meshes.")


if __name__ == "__main__":
    project = Path(unreal.Paths.convert_relative_path_to_full(unreal.Paths.project_dir())).resolve()
    import_ranwar_arrival(project.parent / "builds" / "local" / "unreal-ranwar" / "arrival")
