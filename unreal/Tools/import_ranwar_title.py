"""Import the original Godot artwork into Unreal's title screen."""

from pathlib import Path

import unreal


DESTINATION = "/Game/Ranwar/UI"


def import_title_art(project):
    assets = unreal.get_editor_subsystem(unreal.EditorAssetSubsystem)
    tools = unreal.AssetToolsHelpers.get_asset_tools()
    files = {
        "TitleBackdrop": project / "ContentSource" / "UI" / "title-backdrop.jpg",
        "TitleMark": project.parent / "prototype" / "startup" / "art" / "amg-mark.png",
    }
    for name, path in files.items():
        task = unreal.AssetImportTask()
        task.set_editor_property("filename", str(path.resolve(strict=True)))
        task.set_editor_property("destination_path", DESTINATION)
        task.set_editor_property("destination_name", name)
        task.set_editor_property("automated", True)
        task.set_editor_property("replace_existing", True)
        tools.import_asset_tasks([task])
        textures = [item for item in task.get_objects() if isinstance(item, unreal.Texture2D)]
        if len(textures) != 1:
            raise RuntimeError(f"Expected one title texture from {path}.")
        texture = textures[0]
        package = f"{DESTINATION}/{name}"
        if texture.get_path_name().split(".", 1)[0] != package and not assets.rename_loaded_asset(texture, package):
            raise RuntimeError(f"Could not name title texture {package}.")
        texture.set_editor_property("lod_group", unreal.TextureGroup.TEXTUREGROUP_UI)
        if not assets.save_loaded_asset(texture):
            raise RuntimeError(f"Could not save title texture {package}.")
    unreal.log("Saved Ranwar title backdrop and rickshaw mark.")
