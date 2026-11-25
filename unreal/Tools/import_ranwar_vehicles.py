"""Import the four original Ranwar vehicle bodies and their materials."""

import hashlib
import json
import math
from pathlib import Path
import struct

import unreal

DESTINATION = "/Game/Ranwar/Vehicles"
VEHICLES = ("Hatchback", "Rickshaw", "Motorcycle", "Scooter")
VINISH_SOURCES = {
    "Scooter": "a52d8983c3ac2ad1a54ff88b762ff32e6b8a14cc95f78fc47b195090aab2675a",
    "Motorcycle": "7b36e3aab8a8cc908fad10ae58e3f6e23c5eaeed522a665953c1acfef3245631",
}
VINISH_PARTS = ("Body", "Fork", "FrontWheel", "RearWheel")


def _read_glb(source):
    with source.open("rb") as stream:
        header = stream.read(20)
        if len(header) != 20:
            raise ValueError(f"Incomplete vehicle GLB: {source}")
        magic, version, total, json_length, kind = struct.unpack("<4sIII4s", header)
        if magic != b"glTF" or version != 2 or total != source.stat().st_size or kind != b"JSON":
            raise ValueError(f"Invalid vehicle GLB header: {source}")
        if json_length > total - len(header):
            raise ValueError(f"Invalid vehicle GLB metadata size: {source}")
        return json.loads(stream.read(json_length))


def _verify_glb(source):
    scene = _read_glb(source)
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


def _verified_visual_glb(directory, name, receipt):
    path = (directory / f"{name}.glb").resolve()
    if not path.is_relative_to(directory) or not path.is_file():
        raise ValueError(f"Missing verified two-wheeler part {name}.")
    with path.open("rb") as stream:
        if hashlib.file_digest(stream, "sha256").hexdigest() != receipt["sha256"]:
            raise ValueError(f"Two-wheeler part hash changed: {name}.")
    data = _read_glb(path)
    meshes = data.get("meshes", [])
    images = data.get("images", [])
    buffers = data.get("buffers", [])
    if (len(meshes) != 1 or len(buffers) != 1 or "uri" in buffers[0] or not images
            or any("uri" in image or "bufferView" not in image for image in images)
            or data.get("animations") or data.get("skins")):
        raise ValueError(f"Unexpected two-wheeler part structure: {name}.")
    primitives = meshes[0]["primitives"]
    count = sum(data["accessors"][primitive["indices"]]["count"] // 3 for primitive in primitives)
    if count != receipt["triangles"] or not 0 < count <= 50000 or not 1 <= len(primitives) <= 10:
        raise ValueError(f"Two-wheeler visual budget exceeded: {name}.")
    return path


def _import_visual_part(asset_tools, assets, directory, name, receipt):
    path = _verified_visual_glb(directory, name, receipt)
    destination = f"{DESTINATION}/{name}"
    task = unreal.AssetImportTask()
    task.set_editor_property("filename", str(path))
    task.set_editor_property("destination_path", destination)
    task.set_editor_property("destination_name", name)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", True)
    task.set_editor_property("save", False)
    asset_tools.import_asset_tasks([task])
    meshes = [asset for asset in task.get_objects() if isinstance(asset, unreal.StaticMesh)]
    if len(meshes) != 1 or meshes[0].get_num_triangles(0) <= 0:
        raise RuntimeError(f"Could not import the visual geometry for {name}.")
    mesh = meshes[0]
    # GLB imports can enable Nanite by default and substitute a heavily reduced DX11 fallback.
    nanite = mesh.get_editor_property("nanite_settings")
    nanite.set_editor_property("enabled", False)
    mesh.set_editor_property("nanite_settings", nanite)
    # The built-in group applies during commandlet imports as well as in the editor.
    mesh.set_editor_property("lod_group", "SmallProp")
    lod_count = mesh.get_num_lods()
    if lod_count < 2:
        raise RuntimeError(f"Could not generate distance detail levels for {name}.")
    triangle_count = mesh.get_num_triangles(0)
    if triangle_count < receipt["triangles"] * 0.95:
        raise RuntimeError(f"DX11 near geometry lost detail on {name}: {triangle_count} triangles.")
    if not assets.save_directory(destination):
        raise RuntimeError(f"Could not save the visual geometry and materials for {name}.")
    unreal.log(f"Ranwar two-wheeler {name}: {triangle_count} triangles, {lod_count} LODs.")
    return mesh


def _import_vinish_visuals(source, asset_tools, assets):
    directory = (source / "visuals").resolve()
    if not directory.is_dir():
        return
    manifest = (directory / "manifest.json").resolve()
    if not directory.is_relative_to(source) or not manifest.is_relative_to(directory):
        raise ValueError("Two-wheeler manifest resolves outside the vehicle exchange.")
    data = json.loads(manifest.read_text(encoding="utf-8"))
    if data["schema"] != 1 or set(data["vehicles"]) != set(VINISH_SOURCES):
        raise ValueError("The two-wheeler visual manifest does not contain the verified models.")
    profile_type = unreal.load_class(None, "/Script/MumbaiPilot.RanwarVehicleVisualProfile")
    if profile_type is None:
        raise RuntimeError("The native Ranwar two-wheeler visual profile class is unavailable.")
    for kind, source_hash in VINISH_SOURCES.items():
        entry = data["vehicles"][kind]
        if entry["source_sha256"] != source_hash or set(entry["parts"]) != set(VINISH_PARTS):
            raise ValueError(f"Unapproved source or components for {kind} visual.")
        profile_name = f"{kind}VinishProfile"
        profile_path = f"{DESTINATION}/{profile_name}"
        profile = assets.load_asset(profile_path) if assets.does_asset_exist(profile_path) else None
        if profile is None:
            factory = unreal.DataAssetFactory()
            factory.set_editor_property("data_asset_class", profile_type)
            profile = asset_tools.create_asset(profile_name, DESTINATION, profile_type, factory)
        if profile is None or profile.get_class() != profile_type:
            raise RuntimeError(f"Could not prepare the visual profile for {kind}.")
        for part in VINISH_PARTS:
            name = f"{kind}Vinish{part}"
            mesh = _import_visual_part(asset_tools, assets, directory, name, entry["parts"][part])
            profile.set_editor_property(part, mesh)
        for prop, key in (
            ("ForkPivot", "fork_pivot_cm"), ("FrontWheelPivot", "front_wheel_pivot_cm"),
            ("RearWheelPivot", "rear_wheel_pivot_cm"), ("DriverHip", "driver_hip_cm"),
            ("SteeringAxis", "steering_axis"),
        ):
            values = entry[key]
            if len(values) != 3 or not all(math.isfinite(value) for value in values):
                raise ValueError(f"Invalid two-wheeler pivot {key} for {kind}.")
            profile.set_editor_property(prop, unreal.Vector(*values))
        for prop, key in (("FrontWheelRadius", "front_wheel_radius_cm"), ("RearWheelRadius", "rear_wheel_radius_cm")):
            radius = entry[key]
            if not 10.0 <= radius <= 60.0:
                raise ValueError(f"Invalid wheel radius {key} for {kind}.")
            profile.set_editor_property(prop, radius)
        if not assets.save_loaded_asset(profile):
            raise RuntimeError(f"Could not save the visual profile for {kind}.")
        unreal.log(f"Ranwar two-wheeler profile saved: {profile_path}.")


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
    _import_vinish_visuals(source, asset_tools, assets)


if __name__ == "__main__":
    project = Path(unreal.Paths.convert_relative_path_to_full(unreal.Paths.project_dir())).resolve()
    import_ranwar_vehicles(project.parent / "builds" / "local" / "unreal-ranwar" / "vehicles")
