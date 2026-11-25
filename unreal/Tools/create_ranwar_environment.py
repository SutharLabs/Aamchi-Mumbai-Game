"""Author the low-cost Ranwar sky, distant dressing and practical lights."""

import math
import random
import struct
import zlib

import unreal


DESTINATION = "/Game/Ranwar/Environment"
SUN_TAG = "RanwarSun"
MOON_TAG = "RanwarMoon"
STREET_TAG = "RanwarStreetLight"
SHOP_TAG = "RanwarShopLight"


def smooth(lower, upper, value):
    t = min(1.0, max(0.0, (value - lower) / (upper - lower)))
    return t * t * (3.0 - 2.0 * t)


def make_cloud_mask(path):
    """Write one original RGB alpha-source texture with soft horizon edges."""
    size = 512
    generator = random.Random(190619)
    grids = [(frequency, weight, [[generator.random() for _ in range(frequency + 1)]
                                  for _ in range(frequency + 1)])
             for frequency, weight in ((4, 0.43), (8, 0.25), (15, 0.17), (30, 0.10), (66, 0.05))]

    def noise(grid, frequency, u, v):
        x, y = u * frequency, v * frequency
        ix, iy = int(x), int(y)
        a, b = smooth(0.0, 1.0, x - ix), smooth(0.0, 1.0, y - iy)
        top = grid[iy][ix] * (1.0 - a) + grid[iy][ix + 1] * a
        bottom = grid[iy + 1][ix] * (1.0 - a) + grid[iy + 1][ix + 1] * a
        return top * (1.0 - b) + bottom * b

    pixels = bytearray()
    for row in range(size):
        pixels.append(0)
        v = (row + 0.5) / size
        for column in range(size):
            u = (column + 0.5) / size
            edge = smooth(0.0, 0.13, min(u, v, 1.0 - u, 1.0 - v))
            value = sum(weight * noise(data, frequency, u, v) for frequency, weight, data in grids)
            alpha = int(255.0 * edge * smooth(0.45, 0.65, value))
            pixels.extend((alpha,) * 3)

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))

    header = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header)
                     + chunk(b"IDAT", zlib.compress(pixels, 6)) + chunk(b"IEND", b""))


def new_material(name):
    material = unreal.AssetToolsHelpers.get_asset_tools().create_asset(
        name, DESTINATION, unreal.Material, unreal.MaterialFactoryNew())
    if not material:
        raise RuntimeError(f"Could not create Ranwar environment material {name}.")
    return material


def bake_material(material):
    unreal.MaterialEditingLibrary.recompile_material(material)
    if not unreal.get_editor_subsystem(unreal.EditorAssetSubsystem).save_loaded_asset(material):
        raise RuntimeError(f"Could not save Ranwar finish {material.get_name()}.")
    return material


def solid_finish(name, color, instanced=False, emission_name=None):
    material = new_material(name)
    if instanced:
        material.set_editor_property("used_with_instanced_static_meshes", True)
    editor = unreal.MaterialEditingLibrary
    rgb = editor.create_material_expression(material, unreal.MaterialExpressionConstant3Vector, -340, 0)
    rgb.set_editor_property("constant", unreal.LinearColor(*color))
    editor.connect_material_property(rgb, "", unreal.MaterialProperty.MP_BASE_COLOR)
    roughness = editor.create_material_expression(material, unreal.MaterialExpressionConstant, -340, 150)
    roughness.set_editor_property("r", 0.89)
    editor.connect_material_property(roughness, "", unreal.MaterialProperty.MP_ROUGHNESS)
    if emission_name:
        emission = editor.create_material_expression(material, unreal.MaterialExpressionVectorParameter, -340, 310)
        emission.set_editor_property("parameter_name", emission_name)
        emission.set_editor_property("default_value", unreal.LinearColor(0.0, 0.0, 0.0, 1.0))
        editor.connect_material_property(emission, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
    return bake_material(material)


def cloud_finish(source, import_task, imported):
    path = source / "BandraCloudMask.png"
    make_cloud_mask(path)
    task = import_task(path, DESTINATION, "BandraCloudMask")
    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    mask = imported(task, unreal.Texture2D)
    material = new_material("BandraCloudSheet")
    material.set_editor_property("blend_mode", unreal.BlendMode.BLEND_TRANSLUCENT)
    material.set_editor_property("shading_model", unreal.MaterialShadingModel.MSM_UNLIT)
    material.set_editor_property("two_sided", True)
    editor = unreal.MaterialEditingLibrary
    sample = editor.create_material_expression(material, unreal.MaterialExpressionTextureSample, -740, 170)
    sample.set_editor_property("texture", mask)
    alpha = editor.create_material_expression(material, unreal.MaterialExpressionScalarParameter, -740, 350)
    alpha.set_editor_property("parameter_name", "CloudOpacity")
    alpha.set_editor_property("default_value", 0.52)
    product = editor.create_material_expression(material, unreal.MaterialExpressionMultiply, -490, 160)
    editor.connect_material_expressions(sample, "R", product, "A")
    editor.connect_material_expressions(alpha, "", product, "B")
    editor.connect_material_property(product, "", unreal.MaterialProperty.MP_OPACITY)
    color = editor.create_material_expression(material, unreal.MaterialExpressionVectorParameter, -480, -80)
    color.set_editor_property("parameter_name", "CloudTint")
    color.set_editor_property("default_value", unreal.LinearColor(6900.0, 6850.0, 6750.0, 1.0))
    editor.connect_material_property(color, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
    return bake_material(material)


def mesh_at(actors, spawn, label, mesh, finish, position, scale, rotation=None):
    actor = spawn(actors, unreal.StaticMeshActor, label, position, rotation)
    mesh_component = actor.static_mesh_component
    mesh_component.set_static_mesh(mesh)
    mesh_component.set_material(0, finish)
    mesh_component.set_relative_scale3d(unreal.Vector(*scale))
    mesh_component.set_collision_profile_name("NoCollision")
    mesh_component.set_cast_shadow(False)
    return actor


def add_distant_dressing(actors, spawn, environment, axes, manifest, cube):
    bounds = next(section["bounds_m"] for section in manifest["parts"] if section["asset"] == "Ground")
    middle = [(low + high) * 0.5 for low, high in zip(bounds["min"], bounds["max"], strict=True)]
    x, y, _ = axes.position(middle)
    ground = solid_finish("FarBandraGround", (0.20, 0.22, 0.21, 1.0))
    mesh_at(actors, spawn, "Far horizon base", cube, ground, (x, y, -320.0), (2800.0, 2800.0, 2.0))
    skyline = environment.get_editor_property("distant_buildings")
    skyline.set_static_mesh(cube)
    skyline.set_material(0, solid_finish("FarBandraBuildings", (0.30, 0.32, 0.33, 1.0), instanced=True))
    generator = random.Random(531)
    for ring, count in ((54000.0, 37), (78000.0, 43)):
        for index in range(count):
            angle = math.tau * (index + generator.uniform(-0.28, 0.28)) / count
            if 3.68 < angle < 4.39:  # Keep a lower gap toward the coastal skyline.
                continue
            radius = ring + generator.uniform(-4400.0, 4400.0)
            height = generator.uniform(7.0, 35.0)
            if index % 7 == 3:
                height += generator.uniform(7.0, 18.0)
            transform = unreal.Transform()
            transform.translation = unreal.Vector(x + math.cos(angle) * radius, y + math.sin(angle) * radius,
                                                   -220.0 + height * 50.0)
            transform.scale3d = unreal.Vector(generator.uniform(12.0, 35.0), generator.uniform(13.0, 32.0), height)
            skyline.add_instance(transform, world_space=True)
            if height > 23.0:
                roof = unreal.Transform()
                roof_height = 2.7 if index % 3 else 4.8
                roof.translation = transform.translation + unreal.Vector(
                    transform.scale3d.x * 16.0, transform.scale3d.y * -13.0,
                    (height + roof_height) * 50.0 - 10.0
                )
                roof.scale3d = unreal.Vector(transform.scale3d.x * 0.55, transform.scale3d.y * 0.62, roof_height)
                skyline.add_instance(roof, world_space=True)
    return x, y


def sample_road(road, axes, fraction):
    points = [unreal.Vector(*axes.position(point)) for point in road["points"]]
    spans = [(math.hypot(end.x - start.x, end.y - start.y, end.z - start.z), start, end)
             for start, end in zip(points[:-1], points[1:], strict=True)]
    target = sum(length for length, _, _ in spans) * fraction
    for length, start, end in spans:
        if length > 0.0 and target <= length:
            direction = (end - start) / length
            return start + direction * target, direction
        target -= length
    raise RuntimeError("Street light could not find a usable Ranwar road segment.")


def practical_light(actors, spawn, cls, label, tag, position, intensity, radius, color, cast_shadows=False):
    light = spawn(actors, cls, label, position, unreal.Rotator(pitch=-90.0))
    light.set_editor_property("tags", [tag])
    component = light.light_component
    component.set_mobility(unreal.ComponentMobility.MOVABLE)
    component.set_editor_property("intensity_units", unreal.LightUnits.CANDELAS)
    component.set_editor_property("intensity", intensity)
    component.set_editor_property("light_color", unreal.Color(*color, 255))
    component.set_editor_property("attenuation_radius", radius)
    component.set_editor_property("max_draw_distance", 8000.0)
    component.set_editor_property("max_distance_fade_range", 1400.0)
    component.set_editor_property("cast_shadows", cast_shadows)
    if cast_shadows:
        component.set_editor_property("source_radius", 5.0)
        component.set_editor_property("shadow_bias", 0.32)
    if cls == unreal.SpotLight:
        component.set_editor_property("inner_cone_angle", 33.0)
        component.set_editor_property("outer_cone_angle", 69.0)
    return light


def add_practicals(actors, spawn, axes, manifest, cube):
    pole_mesh = unreal.load_asset("/Engine/BasicShapes/Cylinder.Cylinder")
    pole_finish = solid_finish("WeatheredStreetPole", (0.14, 0.17, 0.17, 1.0))
    lens_finish = solid_finish("StreetLampLens", (0.36, 0.37, 0.35, 1.0), emission_name="LensGlow")
    streets = []
    lenses = []
    placements = (
        (0, 0.14, 1), (0, 0.38, -1), (0, 0.63, 1), (0, 0.87, -1),
        (1, 0.28, -1), (1, 0.70, 1),
        (2, 0.26, 1), (2, 0.74, -1),
        (3, 0.24, -1), (3, 0.72, 1),
    )
    for index, (road_index, fraction, side) in enumerate(placements, start=1):
        road = manifest["roads"][road_index]
        point, direction = sample_road(road, axes, fraction)
        lateral = unreal.Vector(-direction.y * side, direction.x * side, 0.0)
        base = point + lateral * (road["width_m"] * 50.0 + 115.0)
        mesh_at(actors, spawn, f"Bandra lamp {index} pole", pole_mesh, pole_finish,
                (base.x, base.y, base.z + 265.0), (0.095, 0.095, 5.30))
        lamp = base - lateral * 58.0
        orientation = unreal.Rotator(yaw=math.degrees(math.atan2(lateral.y, lateral.x)))
        mesh_at(actors, spawn, f"Bandra lamp {index} head", cube, pole_finish,
                (lamp.x, lamp.y, base.z + 530.0), (1.33, 0.28, 0.10), orientation)
        lenses.append(mesh_at(actors, spawn, f"Bandra lamp {index} lens", cube, lens_finish,
                              (lamp.x, lamp.y, base.z + 523.0), (0.92, 0.21, 0.035), orientation))
        streets.append(practical_light(actors, spawn, unreal.SpotLight, f"Bandra lamp {index}", STREET_TAG,
                                       (lamp.x, lamp.y, base.z + 519.0), 1250.0, 1230.0, (255, 221, 176)))

    # The shelter is 2.8 m farther west and 2.2 m farther from the road than
    # player_start. This is the same curb-relative relationship as the Godot kit.
    feet = manifest["player_start"]["feet"]
    forward_x, forward_y, _ = manifest["player_start"]["forward"]
    x, y, _ = axes.position((feet[0] + forward_x * 2.8 - forward_y * 2.2,
                             feet[1] + forward_y * 2.8 + forward_x * 2.2, 0.0))
    fx, fy, _ = axes.position((forward_x, forward_y, 0.0))
    shelter_orientation = unreal.Rotator(yaw=math.degrees(math.atan2(fy, fx)))
    mesh_at(actors, spawn, "BEST shelter light housing", cube, pole_finish, (x, y, 252.0),
            (0.98, 0.22, 0.075), shelter_orientation)
    lenses.append(mesh_at(actors, spawn, "BEST shelter light lens", cube, lens_finish, (x, y, 247.0),
                          (0.91, 0.18, 0.025), shelter_orientation))
    streets.append(practical_light(actors, spawn, unreal.SpotLight, "BEST shelter light", STREET_TAG,
                                   (x, y, 244.0), 600.0, 710.0, (255, 208, 149)))

    interiors = []
    for door in manifest["doors"]:
        x, y, z = axes.position(door["inside"])
        interiors.append(practical_light(actors, spawn, unreal.SpotLight, f"{door['name']} ceiling", SHOP_TAG,
                                         (x, y, z + 261.0), 7600.0, 545.0, (255, 232, 200), cast_shadows=True))
        threshold_x, threshold_y, _ = axes.position(door["threshold"])
        near_x, near_y = (x + threshold_x) * 0.5, (y + threshold_y) * 0.5
        interiors.append(practical_light(actors, spawn, unreal.PointLight, f"{door['name']} entrance fill", SHOP_TAG,
                                         (near_x, near_y, z + 222.0), 1950.0, 390.0, (236, 232, 215)))
    return streets, interiors, lenses


def add_environment(actors, spawn, axes, manifest, source, import_task, imported):
    environment = spawn(actors, unreal.RanwarEnvironment, "Ranwar environment clock")
    sun = spawn(actors, unreal.DirectionalLight, "Bandra sunlight", rotation=unreal.Rotator(pitch=-46, yaw=-41))
    sun.set_editor_property("tags", [SUN_TAG])
    directional = sun.light_component
    directional.set_mobility(unreal.ComponentMobility.MOVABLE)
    directional.set_editor_property("atmosphere_sun_light", True)
    directional.set_editor_property("intensity", 28000.0)
    directional.set_editor_property("use_temperature", True)
    directional.set_editor_property("temperature", 5950.0)
    directional.set_editor_property("dynamic_shadow_distance_movable_light", 9200.0)
    directional.set_editor_property("dynamic_shadow_cascades", 2)
    directional.set_editor_property("cascade_distribution_exponent", 2.2)
    directional.set_editor_property("shadow_bias", 0.40)
    directional.set_editor_property("contact_shadow_length", 24.0)
    directional.set_editor_property("contact_shadow_length_in_ws", True)
    moon = spawn(actors, unreal.DirectionalLight, "Bandra cool night fill", rotation=unreal.Rotator(pitch=-35, yaw=128))
    moon.set_editor_property("tags", [MOON_TAG])
    moon.light_component.set_mobility(unreal.ComponentMobility.MOVABLE)
    moon.light_component.set_editor_property("atmosphere_sun_light", True)
    moon.light_component.set_editor_property("atmosphere_sun_light_index", 1)
    moon.light_component.set_editor_property("light_color", unreal.Color(165, 191, 246, 255))
    moon.light_component.set_editor_property("cast_shadows", False)
    moon.light_component.set_editor_property("intensity", 0.0)
    sky = spawn(actors, unreal.SkyLight, "Bandra skylight")
    sky.light_component.set_mobility(unreal.ComponentMobility.MOVABLE)
    sky.light_component.set_editor_property("real_time_capture", True)
    sky.light_component.set_editor_property("cubemap_resolution", 64)
    sky.light_component.set_editor_property("intensity", 1.16)
    atmosphere = spawn(actors, unreal.SkyAtmosphere, "Bandra coastal air")
    scattering = atmosphere.get_editor_property("sky_atmosphere_component")
    scattering.set_editor_property("mie_scattering_scale", 0.68)
    scattering.set_editor_property("mie_anisotropy", 0.80)
    scattering.set_editor_property("sky_and_aerial_perspective_luminance_factor", unreal.LinearColor(0.78, 0.94, 1.09, 1.0))
    fog = spawn(actors, unreal.ExponentialHeightFog, "Bandra distance haze")
    haze = fog.component
    haze.set_editor_property("enable_volumetric_fog", False)
    haze.set_editor_property("start_distance", 4400.0)
    haze.set_editor_property("fog_density", 0.019)
    haze.set_editor_property("fog_height_falloff", 0.088)
    haze.set_editor_property("fog_max_opacity", 0.49)
    haze.set_editor_property("fog_inscattering_luminance", unreal.LinearColor(0.36, 0.49, 0.56, 1.0))

    cube = unreal.load_asset("/Engine/BasicShapes/Cube.Cube")
    x, y = add_distant_dressing(actors, spawn, environment, axes, manifest, cube)
    layer = environment.get_editor_property("cloud_layer")
    layer.set_static_mesh(unreal.load_asset("/Engine/BasicShapes/Plane.Plane"))
    layer.set_material(0, cloud_finish(source, import_task, imported))
    layer.set_relative_location(unreal.Vector(x, y, 80000.0), sweep=False, teleport=True)
    layer.set_relative_scale3d(unreal.Vector(9900.0, 9900.0, 1.0))
    streets, interiors, lenses = add_practicals(actors, spawn, axes, manifest, cube)
    for name, value in (("sun", sun), ("moon_fill", moon), ("sky", sky), ("haze", fog),
                        ("streets", streets), ("interiors", interiors), ("lamp_lenses", lenses)):
        environment.set_editor_property(name, value)
    unreal.log(f"Ranwar environment: sky sheet, {len(streets) - 1} road fixtures, BEST shelter and {len(interiors)} shop lights.")
