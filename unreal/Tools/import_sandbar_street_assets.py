"""Dress Hill Road with staged CC0 SandbarCity assets on the Windows DX11 renderer."""

import math

import unreal


SANDBAR_SURFACES = {
    "TowerConcrete": ("concrete_tile_facade", "SandbarConcreteFacade"),
    "WeatheredPlaster": ("plastered_wall_02", "SandbarWeatheredPlaster"),
    "MineralStucco": ("white_stucco", "SandbarMineralStucco"),
    "PavementConcrete": ("concrete_pavement_03", "SandbarPavementConcrete"),
}
PROPS = (
    ("/Game/City/Props/Bench/SM_Bench", "Hill Road modular bench", 2.8, 4.2, 185.0),
    ("/Game/City/Props/UtilityBox/SM_UtilityBox", "Hill Road service cabinet", 5.6, 4.2, 78.0),
)


def sandbar_surface_textures(assets, destination, variant):
    key, base_name = SANDBAR_SURFACES[variant]
    source = f"/Game/City/Textures4k/{key}/T_{key}_4k_"
    channels = ("Diffuse", "Normal", "Rough")
    if not any(assets.does_asset_exist(source + channel) for channel in channels):
        return {}
    textures = {}
    for channel in channels:
        path = source + channel
        name = f"{destination}/{base_name}_{channel}"
        texture = assets.duplicate_asset(path, name)
        if not isinstance(texture, unreal.Texture2D):
            raise RuntimeError(f"Sandbar surface source texture unavailable: {path}.")
        texture.set_editor_property("max_texture_size", 1024)
        texture.set_editor_property("virtual_texture_streaming", False)
        if channel == "Normal":
            texture.set_editor_property("compression_settings", unreal.TextureCompressionSettings.TC_NORMALMAP)
        elif channel == "Rough":
            texture.set_editor_property("compression_settings", unreal.TextureCompressionSettings.TC_DEFAULT)
        texture.set_editor_property("srgb", channel == "Diffuse")
        if not assets.save_loaded_asset(texture):
            raise RuntimeError(f"Could not save {name}.")
        textures[channel] = texture
    unreal.log(f"Sandbar surface: {variant} diffuse, normal and roughness prepared.")
    return textures


def add_sandbar_street_props(actors, spawn, axes, manifest, ground_position):
    assets = unreal.get_editor_subsystem(unreal.EditorAssetSubsystem)
    if not any(assets.does_asset_exist(path) for path, *_ in PROPS):
        return
    fx, fy, _ = manifest["player_start"]["forward"]
    x, y, z = manifest["player_start"]["feet"]
    dx, dy, _ = axes.position((fx, fy, 0.0))
    heading = math.degrees(math.atan2(dy, dx))

    for path, label, forward, church_side, max_width in PROPS:
        mesh = assets.load_asset(path)
        if not isinstance(mesh, unreal.StaticMesh):
            raise RuntimeError(f"Sandbar street mesh unavailable: {path}.")
        point = unreal.Vector(*axes.position((x + fx * forward - fy * church_side,
                                              y + fy * forward + fx * church_side, z)))
        bounds = mesh.get_bounds().box_extent
        yaw = heading + (90.0 if bounds.y > bounds.x else 0.0)
        actor = spawn(actors, unreal.StaticMeshActor, label, (point.x, point.y, point.z),
                      unreal.Rotator(yaw=yaw))
        component = actor.static_mesh_component
        component.set_static_mesh(mesh)
        component.set_collision_profile_name("NoCollision")
        scale = min(1.0, max_width / (2.0 * max(bounds.x, bounds.y)))
        actor.set_actor_scale3d(unreal.Vector(scale, scale, scale))
        center, extent = actor.get_actor_bounds(False)
        foot = ground_position(actor, label, point)
        actor.set_actor_location(point + foot - center + unreal.Vector(0.0, 0.0, extent.z + 0.5), False, False)
        component.set_collision_profile_name("BlockAll")
        unreal.log(f"Sandbar street prop: {label}, LOD0 {mesh.get_num_triangles(0)} triangles, scale {scale:.2f}.")
