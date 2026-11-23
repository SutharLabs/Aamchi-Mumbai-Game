"""Import the reviewed Sea Link FBX and author the isolated Unreal walking level."""

from pathlib import Path

import unreal

LEVEL = "/Game/Pilot/SeaLinkWalk"
ASSETS = "/Game/Pilot/SeaLinkAssets"
MESH_FILENAME = "sea-link-main-span.fbx"
MESH_NAME = "BandraSeaLink"
DECK_HALF_LENGTH = 30000.0  # Unreal uses centimetres.
DECK_CENTRES = (-1125.0, 1125.0)
CARRIAGEWAY_HALF_WIDTH = 700.0
WATER_HEIGHT = -2480.0


def import_bridge(source):
    options = unreal.FbxImportUI()
    options.set_editor_property("automated_import_should_detect_type", False)
    options.set_editor_property("mesh_type_to_import", unreal.FBXImportType.FBXIT_STATIC_MESH)
    options.set_editor_property("import_as_skeletal", False)
    options.set_editor_property("import_materials", True)
    options.set_editor_property("import_textures", True)
    mesh_options = options.get_editor_property("static_mesh_import_data")
    mesh_options.set_editor_property("combine_meshes", True)
    mesh_options.set_editor_property("auto_generate_collision", False)
    mesh_options.set_editor_property("convert_scene_unit", True)
    mesh_options.set_editor_property("generate_lightmap_u_vs", False)
    mesh_options.set_editor_property("normal_import_method", unreal.FBXNormalImportMethod.FBXNIM_IMPORT_NORMALS)

    task = unreal.AssetImportTask()
    task.set_editor_property("filename", str(source))
    task.set_editor_property("destination_path", ASSETS)
    task.set_editor_property("destination_name", MESH_NAME)
    task.set_editor_property("factory", unreal.FbxFactory())
    task.set_editor_property("options", options)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", True)
    task.set_editor_property("save", True)
    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    meshes = [asset for asset in task.get_objects() if isinstance(asset, unreal.StaticMesh)]
    if len(meshes) != 1:
        raise RuntimeError(f"The bridge FBX must import as one static mesh, got {len(meshes)}.")
    return meshes[0]


def spawn(actors, actor_class, name, x=0.0, y=0.0, z=0.0, rotation=None):
    actor = actors.spawn_actor_from_class(actor_class, unreal.Vector(x, y, z), rotation or unreal.Rotator())
    if actor is None:
        raise RuntimeError(f"Could not spawn {name}.")
    actor.set_actor_label(name)
    return actor


def add_bridge(actors, mesh):
    actor = spawn(actors, unreal.StaticMeshActor, "Bandra-Worli Sea Link")
    component = actor.static_mesh_component
    component.set_static_mesh(mesh)
    component.set_collision_profile_name("NoCollision")
    centre, extent = actor.get_actor_bounds(False)
    # FBX tools can choose either horizontal axis as forward. The full twin deck
    # has a 600 m long axis and is centred on the origin in both horizontal axes.
    if extent.y > extent.x:
        actor.set_actor_rotation(unreal.Rotator(yaw=90.0), False)
        centre, extent = actor.get_actor_bounds(False)
    if abs(centre.x) > 150.0 or abs(centre.y) > 150.0 or not (
        29500.0 < extent.x < 31100.0 and 1900.0 < extent.y < 2400.0
    ):
        raise RuntimeError(f"Unexpected Sea Link import bounds: centre {centre}, extent {extent}.")


def add_walk_collision(actors):
    cube = unreal.load_asset("/Engine/BasicShapes/Cube.Cube")
    if cube is None:
        raise RuntimeError("Unreal's standard 100 cm cube is unavailable.")

    def block(label, centre, dimensions):
        actor = spawn(actors, unreal.StaticMeshActor, label, *centre)
        actor.static_mesh_component.set_static_mesh(cube)
        actor.static_mesh_component.set_collision_profile_name("BlockAll")
        actor.set_actor_scale3d(unreal.Vector(*(value / 100.0 for value in dimensions)))
        actor.set_actor_hidden_in_game(True)
        actor.static_mesh_component.set_cast_shadow(False)

    for deck in DECK_CENTRES:
        block("Walkable carriageway", (0.0, deck, -50.0),
              (2.0 * DECK_HALF_LENGTH, 2.0 * CARRIAGEWAY_HALF_WIDTH, 100.0))
        for edge in (-1.0, 1.0):
            block("Pilot side boundary", (0.0, deck + edge * CARRIAGEWAY_HALF_WIDTH, 100.0),
                  (2.0 * DECK_HALF_LENGTH, 20.0, 220.0))
            block("Pilot end boundary", (edge * DECK_HALF_LENGTH, deck, 100.0),
                  (20.0, 2.0 * CARRIAGEWAY_HALF_WIDTH, 220.0))


def add_sea_and_daylight(actors, assets):
    water = spawn(actors, unreal.StaticMeshActor, "Arabian Sea study", z=WATER_HEIGHT)
    plane = unreal.load_asset("/Engine/BasicShapes/Plane.Plane")
    if plane is None:
        raise RuntimeError("Unreal's standard water plane mesh is unavailable.")
    water.static_mesh_component.set_static_mesh(plane)
    water.static_mesh_component.set_collision_profile_name("NoCollision")
    water.set_actor_scale3d(unreal.Vector(4000.0, 4000.0, 1.0))
    material = assets.load_asset(ASSETS + "/SeaSurface")
    if material is None:
        material = unreal.AssetToolsHelpers.get_asset_tools().create_asset(
            "SeaSurface", ASSETS, unreal.Material, unreal.MaterialFactoryNew()
        )
        if material is None:
            raise RuntimeError("Could not create the sea material.")
        api = unreal.MaterialEditingLibrary
        colour = api.create_material_expression(material, unreal.MaterialExpressionConstant3Vector, -350, 0)
        colour.set_editor_property("constant", unreal.LinearColor(0.018, 0.079, 0.096, 1.0))
        roughness = api.create_material_expression(material, unreal.MaterialExpressionConstant, -350, 140)
        roughness.set_editor_property("r", 0.24)
        api.connect_material_property(colour, "", unreal.MaterialProperty.MP_BASE_COLOR)
        api.connect_material_property(roughness, "", unreal.MaterialProperty.MP_ROUGHNESS)
        api.recompile_material(material)
        if not assets.save_loaded_asset(material):
            raise RuntimeError("Could not save the sea material.")
    water.static_mesh_component.set_material(0, material)

    sun = spawn(actors, unreal.DirectionalLight, "Afternoon sun",
                rotation=unreal.Rotator(pitch=-33.0, yaw=-35.0))
    sun.light_component.set_mobility(unreal.ComponentMobility.MOVABLE)
    sun.light_component.set_editor_property("atmosphere_sun_light", True)
    sun.light_component.set_editor_property("intensity", 38000.0)
    sky = spawn(actors, unreal.SkyLight, "Sky bounce")
    sky.light_component.set_mobility(unreal.ComponentMobility.MOVABLE)
    sky.light_component.set_editor_property("real_time_capture", True)
    spawn(actors, unreal.SkyAtmosphere, "Marine daylight")


def main():
    project = Path(unreal.Paths.convert_relative_path_to_full(unreal.Paths.project_dir()))
    source = project.parent / "builds" / "local" / "unreal-pilot" / MESH_FILENAME
    if not source.is_file():
        raise FileNotFoundError(f"Generate the bridge exchange asset first: {source}")
    assets = unreal.get_editor_subsystem(unreal.EditorAssetSubsystem)
    if assets.does_asset_exist(LEVEL):
        raise RuntimeError(f"{LEVEL} already exists. Open it in the Content Browser to play or edit it.")

    editor = unreal.EditorLoadingAndSavingUtils
    world = editor.new_blank_map(False)
    if world is None:
        raise RuntimeError("Could not create a blank Unreal map.")
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    add_bridge(actors, import_bridge(source))
    add_walk_collision(actors)
    add_sea_and_daylight(actors, assets)
    spawn(actors, unreal.PlayerStart, "Bandra inspection start", -19000.0, DECK_CENTRES[1], 105.0)
    unreal.get_editor_subsystem(unreal.UnrealEditorSubsystem).set_level_viewport_camera_info(
        unreal.Vector(-19000.0, DECK_CENTRES[1], 180.0), unreal.Rotator()
    )
    if not editor.save_map(world, LEVEL):
        raise RuntimeError(f"Could not save {LEVEL}.")
    unreal.log(f"Saved {LEVEL}. Press Play in the Unreal Editor to walk the deck.")


if __name__ == "__main__":
    main()
