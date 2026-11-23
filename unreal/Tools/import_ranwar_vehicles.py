"""Import the four original Ranwar vehicle bodies and their materials."""

import json
from pathlib import Path
import struct

import unreal

DESTINATION = "/Game/Ranwar/Vehicles"
VEHICLES = ("Hatchback", "Rickshaw", "Motorcycle", "Scooter")


def _verify_glb(source):
    with source.open("rb") as stream:
        header = stream.read(20)
        if len(header) != 20:
            raise ValueError(f"Incomplete vehicle GLB: {source}")
        magic, version, total, json_length, kind = struct.unpack("<4sIII4s", header)
        if magic != b"glTF" or version != 2 or total != source.stat().st_size or kind != b"JSON":
            raise ValueError(f"Invalid vehicle GLB header: {source}")
        if json_length > total - len(header):
            raise ValueError(f"Invalid vehicle GLB metadata size: {source}")
        scene = json.loads(stream.read(json_length))
    meshes = scene.get("meshes", [])
    buffers = scene.get("buffers", [])
    if (len(meshes) != 1 or len(meshes[0].get("primitives", [])) < 2 or len(buffers) != 1
            or "uri" in buffers[0] or scene.get("images") or scene.get("skins") or scene.get("animations")):
        raise ValueError(f"Expected one self-contained static vehicle body with original finish slots: {source}")


def _verify_mesh(mesh, name):
    if not isinstance(mesh, unreal.StaticMesh):
        raise RuntimeError(f"Expected a static vehicle mesh for {name}.")
    bounds = mesh.get_bounding_box()
    minimum, maximum = bounds.min, bounds.max
    length, width, height = maximum.x - minimum.x, maximum.y - minimum.y, maximum.z - minimum.z
    if abs(minimum.z) > 1.0 or not 140.0 < length < 500.0 or not 50.0 < width < length or not 70.0 < height < 250.0:
        raise RuntimeError(f"Unexpected orientation, scale, or ground pivot for {name}: {bounds}")
    materials = mesh.get_editor_property("static_materials")
    if len(materials) < 2 or any(slot.get_editor_property("material_interface") is None for slot in materials):
        raise RuntimeError(f"Missing original finish slots on {name}.")
    unreal.log(f"Ranwar vehicle {name}: {length:.1f} x {width:.1f} x {height:.1f} cm, {len(materials)} finishes.")


def import_ranwar_vehicles(source):
    source = Path(source).resolve(strict=True)
    assets = unreal.get_editor_subsystem(unreal.EditorAssetSubsystem)
    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    inputs = {name: source / f"{name}.glb" for name in VEHICLES}
    for path in inputs.values():
        _verify_glb(path)

    for name, path in inputs.items():
        package = f"{DESTINATION}/{name}"
        if assets.does_asset_exist(package):
            _verify_mesh(assets.load_asset(package), name)
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
        _verify_mesh(mesh, name)
        if mesh.get_path_name().split(".", 1)[0] != package and not assets.rename_loaded_asset(mesh, package):
            raise RuntimeError(f"Could not put imported vehicle at {package}.")

    if not assets.save_directory(DESTINATION):
        raise RuntimeError("Could not save the Ranwar vehicle meshes and finishes.")
    unreal.log("Saved the four Ranwar vehicle meshes and their original finishes.")


if __name__ == "__main__":
    project = Path(unreal.Paths.convert_relative_path_to_full(unreal.Paths.project_dir())).resolve()
    import_ranwar_vehicles(project.parent / "builds" / "local" / "unreal-ranwar" / "vehicles")
