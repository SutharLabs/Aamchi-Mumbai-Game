"""Run inside headless Blender. Produce original review-stage geometry and evidence.

Usage: blender -b --python tools/build_queued_model.py -- --spec jobs/specs/id.json
No downloaded .blend files, cloud calls, unsafe deserialization or shell commands.
"""

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import re
import sys
import tempfile

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from modeling.core import Context
from modeling import characters


def confined(relative):
    if not isinstance(relative, str) or len(relative) > 240:
        raise ValueError("Invalid relative path")
    path = (ROOT / relative).resolve()
    if path == ROOT or not path.is_relative_to(ROOT):
        raise ValueError("Path escapes project")
    return path


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def metrics(objects):
    tris = 0
    low, high = Vector((math.inf,)*3), Vector((-math.inf,)*3)
    for obj in objects:
        obj.data.calc_loop_triangles()
        tris += len(obj.data.loop_triangles)
        for corner in obj.bound_box:
            point = obj.matrix_world @ Vector(corner)
            if not all(math.isfinite(v) for v in point):
                raise ValueError("Non-finite geometry")
            for axis in range(3):
                low[axis] = min(low[axis], point[axis])
                high[axis] = max(high[axis], point[axis])
    return tris, low, high


def aim(obj, target):
    obj.rotation_euler = (Vector(target)-obj.location).to_track_quat("-Z", "Y").to_euler()


def studio(low, high):
    center = (low+high)*.5
    span = max(high-low)
    bpy.ops.object.camera_add(location=center+Vector((span*1.3,-span*1.8,span*.95)))
    camera = bpy.context.object
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = max(span*1.45, .35)
    bpy.context.scene.camera = camera
    aim(camera, center)
    bpy.ops.mesh.primitive_plane_add(size=max(span*6,4), location=(center.x,center.y,low.z-.015))
    plane = bpy.context.object
    plane.name = "PRESENTATION_GROUND_NOT_EXPORTED"
    mat = bpy.data.materials.new("presentation_ground")
    mat.diffuse_color = (.16,.18,.20,1)
    plane.data.materials.append(mat)
    for name, offset, energy, scale in [
        ("key",(-1.5,-2,3),1000,2), ("fill",(2,0,2),650,2),
        ("rim",(0,2,2.5),850,1.5)]:
        bpy.ops.object.light_add(type="AREA", location=center+Vector(offset)*max(span,.5))
        light = bpy.context.object
        light.name = "PRESENTATION_"+name
        light.data.energy = energy*max(span*span,.15)
        light.data.shape = "DISK"
        light.data.size = scale*max(span,.5)
        aim(light, center)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 16
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 640
    scene.render.resolution_y = 640
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.exposure = -2.0
    scene.world = bpy.data.worlds.new("Review studio")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (.15,.18,.22,1)
    scene.world.node_tree.nodes["Background"].inputs[1].default_value = .35
    return camera, center, max(span,.25)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--spec", required=True)
    args = parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    spec_path = confined(args.spec)
    if spec_path.suffix != ".json" or spec_path.stat().st_size > 100000:
        raise ValueError("Invalid model spec")
    spec = json.loads(spec_path.read_text(encoding="utf-8-sig"))
    asset_id = spec.get("id", "")
    if not re.fullmatch(r"[a-z0-9][a-z0-9_-]{1,63}", asset_id):
        raise ValueError("Invalid asset ID")
    output = confined("assets/generated/"+asset_id)
    output.mkdir(parents=True, exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix=".attempt-", dir=output))
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0
    ctx = Context()
    build_info = {"dimensions_basis":"estimated_design_parameters_not_surveyed"}
    if spec.get("kind", "").startswith("chawl_"):
        from modeling import chawl
        build_info = chawl.build(ctx, spec)
    else:
        characters.build(ctx, spec)
    bpy.context.view_layer.update()
    triangles, low, high = metrics(ctx.created)
    limit = spec.get("triangle_budget", 60000)
    if not isinstance(limit, int) or not 100 <= limit <= 200000:
        raise ValueError("Invalid triangle budget")
    if not ctx.created or not 0 < triangles <= limit:
        raise ValueError("Triangle budget failed: %s / %s" % (triangles,limit))
    asset_objects = list(ctx.created)
    for obj in asset_objects:
        obj["project_asset_id"] = asset_id
        obj["reference_review"] = "pending"
    bpy.ops.object.select_all(action="DESELECT")
    for obj in asset_objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = asset_objects[0]
    bpy.ops.export_scene.gltf(filepath=str(work/"model.glb"), export_format="GLB",
                              use_selection=True, export_extras=True, export_animations=False)
    camera, center, span = studio(low, high)
    views = {"preview":(1.3,-1.8,.95), "front":(0,-2,.25),
             "rear":(0,2,.25), "side":(2,0,.25)}
    for name, direction in views.items():
        camera.location = center+Vector(direction)*span
        aim(camera, center)
        bpy.context.scene.render.filepath = str(work/(name+".png"))
        bpy.ops.render.render(write_still=True)
    camera.location = center+Vector(views["preview"])*span
    aim(camera, center)
    bpy.ops.wm.save_as_mainfile(filepath=str(work/"model.blend"))
    names = ["model.glb","model.blend","preview.png","front.png","rear.png","side.png"]
    checksums = {}
    for name in names:
        source = work/name
        if not source.is_file() or source.stat().st_size < 20:
            raise ValueError("Missing or empty output: "+name)
        checksums[name] = sha256(source)
        os.replace(source, output/name)
    report = {
        "status":"ok", "technical_export_passed":True, "asset_id":asset_id,
        "geometry_stage":"original_procedural_blockout", "human_review_required":True,
        "cultural_architectural_review":"pending", "rigged":False, "animations":0,
        "triangle_count":triangles, "triangle_budget":limit,
        "mesh_objects":len(asset_objects),
        "materials_used":sorted({m.name for o in asset_objects for m in o.data.materials if m}),
        "bounds_metres":{"min":list(low),"max":list(high),"size":list(high-low)},
        "generator_details":build_info,
        "source_references":spec.get("references",[]),
        "assumptions":spec.get("assumptions",[]), "sha256":checksums,
        "ownership_note":"Original procedural geometry; no external meshes/textures imported.",
        "next_review":spec.get("review_checks",[]),
    }
    (work/"report.json").write_text(json.dumps(report,indent=2)+"\n", encoding="utf-8")
    os.replace(work/"report.json", output/"report.json")
    print("MODEL_STUDY_COMPLETE "+asset_id+" triangles="+str(triangles), flush=True)


if __name__ == "__main__":
    main()
