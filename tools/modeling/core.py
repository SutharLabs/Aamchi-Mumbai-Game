"""Small Blender-only geometry helpers. No external meshes or textures are loaded."""

import math
import bpy
from mathutils import Vector


PALETTE = {
    "plaster": (0.71, 0.62, 0.45), "worn_plaster": (0.54, 0.62, 0.57),
    "concrete": (0.43, 0.45, 0.44), "wood": (0.22, 0.12, 0.07),
    "roof": (0.37, 0.18, 0.12), "metal": (0.15, 0.22, 0.24),
    "dark": (0.035, 0.045, 0.055), "cloth_blue": (0.08, 0.30, 0.49),
    "cloth_red": (0.67, 0.12, 0.14), "cloth_white": (0.86, 0.83, 0.73),
    "skin": (0.47, 0.24, 0.12), "kurta": (0.83, 0.78, 0.62),
    "dhoti": (0.91, 0.87, 0.74), "pheta": (0.88, 0.31, 0.08),
    "hair": (0.035, 0.025, 0.02), "shoe": (0.11, 0.065, 0.035),
    "blouse": (0.55, 0.08, 0.14), "sari": (0.05, 0.39, 0.30),
    "trim": (0.85, 0.58, 0.17), "eye": (0.93, 0.90, 0.81),
}


class Context:
    def __init__(self):
        self.created = []
        self.materials = {}
        for key, rgb in PALETTE.items():
            mat = bpy.data.materials.new(key)
            mat.diffuse_color = (*rgb, 1.0)
            mat.use_nodes = True
            shader = mat.node_tree.nodes.get("Principled BSDF")
            shader.inputs["Base Color"].default_value = (*rgb, 1.0)
            shader.inputs["Roughness"].default_value = 0.85
            self.materials[key] = mat

    def register(self, obj, name, mat):
        obj.name = name
        if mat not in self.materials:
            raise ValueError("Unknown material key: " + mat)
        obj.data.materials.append(self.materials[mat])
        obj["asset_stage"] = "procedural_reference_study"
        self.created.append(obj)
        return obj

    def box(self, name, center, size, mat):
        if any(not math.isfinite(v) or v <= 0 for v in size):
            raise ValueError("Box dimensions must be finite and positive")
        bpy.ops.mesh.primitive_cube_add(size=1, location=center)
        obj = bpy.context.object
        obj.scale = size
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        return self.register(obj, name, mat)

    def cylinder(self, name, center, radius, depth, mat, vertices=8):
        if radius <= 0 or depth <= 0 or not 3 <= vertices <= 64:
            raise ValueError("Invalid cylinder dimensions")
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=vertices, radius=radius, depth=depth, location=center)
        return self.register(bpy.context.object, name, mat)

    def beam(self, name, a, b, width, mat):
        start, end = Vector(a), Vector(b)
        delta = end - start
        if delta.length < 0.0001:
            raise ValueError("Beam endpoints coincide")
        obj = self.box(name, (start + end) * 0.5, (width, width, delta.length), mat)
        obj.rotation_mode = "QUATERNION"
        obj.rotation_quaternion = delta.to_track_quat("Z", "Y")
        return obj

    def mesh(self, name, vertices, faces, mat):
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(vertices, [], faces)
        mesh.update()
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        return self.register(obj, name, mat)

    def ellipsoid(self, name, center, radii, mat):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8,
                                           radius=1, location=center)
        obj = bpy.context.object
        obj.scale = radii
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        return self.register(obj, name, mat)

    def limb(self, name, a, b, radius, mat):
        start, end = Vector(a), Vector(b)
        delta = end - start
        obj = self.cylinder(name, (start + end) * 0.5, radius, delta.length,
                            mat, vertices=10)
        obj.rotation_mode = "QUATERNION"
        obj.rotation_quaternion = delta.to_track_quat("Z", "Y")
        return obj

    def lathe(self, name, rings, mat, segments=16):
        """Rings are (z, x_radius, y_radius, x_offset, y_offset)."""
        verts, faces = [], []
        for z, rx, ry, ox, oy in rings:
            for i in range(segments):
                angle = 2 * math.pi * i / segments
                verts.append((ox + rx * math.cos(angle), oy + ry * math.sin(angle), z))
        for ring in range(len(rings) - 1):
            for i in range(segments):
                a = ring * segments + i
                b = ring * segments + (i + 1) % segments
                faces.append((a, b, b + segments, a + segments))
        faces.append(tuple(reversed(range(segments))))
        faces.append(tuple((len(rings) - 1) * segments + i for i in range(segments)))
        return self.mesh(name, verts, faces, mat)
