"""Prepare the two attributed Vinish models as textured, independently moving Unreal parts."""

import argparse
from collections import defaultdict
import hashlib
from io import BytesIO
import json
import math
from pathlib import Path
import struct

from PIL import Image


APPROVED = {
    "Scooter": ("scooter.glb", "a52d8983c3ac2ad1a54ff88b762ff32e6b8a14cc95f78fc47b195090aab2675a"),
    "Motorcycle": ("street-motorcycle.glb", "7b36e3aab8a8cc908fad10ae58e3f6e23c5eaeed522a665953c1acfef3245631"),
}
PARTS = {
    "Body": ("Body", "Swingarm"),
    "Fork": ("Fork",),
    "FrontWheel": ("Wheel_Front",),
    "RearWheel": ("Wheel_Rear",),
}
ATTRIBUTES = {"POSITION": "VEC3", "NORMAL": "VEC3", "TANGENT": "VEC4", "TEXCOORD_0": "VEC2"}
ACCESSOR_FORMATS = {(5126, "VEC2"): "2f", (5126, "VEC3"): "3f", (5126, "VEC4"): "4f",
                    (5123, "SCALAR"): "H", (5125, "SCALAR"): "I"}
IDENTITY = (0.0, 0.0, 0.0, 1.0)


def vector_add(a, b):
    return tuple(x + y for x, y in zip(a, b, strict=True))


def vector_subtract(a, b):
    return tuple(x - y for x, y in zip(a, b, strict=True))


def rotate(point, rotation):
    x, y, z, w = rotation
    px, py, pz = point
    tx, ty, tz = 2 * (y * pz - z * py), 2 * (z * px - x * pz), 2 * (x * py - y * px)
    return px + w * tx + y * tz - z * ty, py + w * ty + z * tx - x * tz, pz + w * tz + x * ty - y * tx


def exchange(point):
    # Vinish uses glTF +Z forward. Unreal's translator swaps the exchange file's Y and Z.
    x, y, z = point
    return z, y, -x


def unreal_axes(point, unit=100.0):
    x, y, z = point
    return [round(x * unit, 6), round(z * unit, 6), round(y * unit, 6)]


def png(image):
    output = BytesIO()
    image.save(output, "PNG", optimize=True)
    return output.getvalue()


def encoded_srgb(value):
    encoded = 12.92 * value if value <= 0.0031308 else 1.055 * value ** (1 / 2.4) - 0.055
    return round(255 * encoded)


class SourceModel:
    def __init__(self, path, approved_hash):
        with path.open("rb") as stream:
            self.digest = hashlib.file_digest(stream, "sha256").hexdigest()
            if self.digest != approved_hash:
                raise ValueError(f"Unrecognized source geometry for {path.name}.")
            stream.seek(0)
            magic, version, total, metadata_size, metadata_kind = struct.unpack("<4sIII4s", stream.read(20))
            if (magic, version, total, metadata_kind) != (b"glTF", 2, path.stat().st_size, b"JSON"):
                raise ValueError(f"Unexpected glTF header in {path.name}.")
            self.content = json.loads(stream.read(metadata_size))
            size, kind = struct.unpack("<I4s", stream.read(8))
            self.binary = stream.read(size)
            if kind != bytes((66, 73, 78, 0)) or len(self.binary) != size:
                raise ValueError(f"Unexpected glTF buffer in {path.name}.")
        self.nodes = {node["name"]: node for node in self.content["nodes"]}
        self.parents = {self.content["nodes"][child]["name"]: node["name"]
                        for node in self.nodes.values() for child in node.get("children", ())}

    def bytes_for_view(self, view):
        offset = view.get("byteOffset", 0)
        return self.binary[offset:offset + view["byteLength"]]

    def values(self, index):
        item = self.content["accessors"][index]
        view = self.content["bufferViews"][item["bufferView"]]
        layout = struct.Struct("<" + ACCESSOR_FORMATS[item["componentType"], item["type"]])
        data = self.bytes_for_view(view)
        stride = view.get("byteStride", layout.size)
        offset = item.get("byteOffset", 0)
        if offset + (item["count"] - 1) * stride + layout.size > len(data):
            raise ValueError("Vehicle accessor points past its data.")
        return [layout.unpack_from(data, offset + i * stride) for i in range(item["count"])]

    def world(self, name, point, *, direction=False):
        while name is not None:
            node = self.nodes[name]
            point = rotate(point, node.get("rotation", IDENTITY))
            if not direction:
                point = vector_add(point, node.get("translation", (0.0, 0.0, 0.0)))
            name = self.parents.get(name)
        return exchange(point)

    def surface(self, name):
        mesh = self.content["meshes"][self.nodes[name]["mesh"]]
        for primitive in mesh["primitives"]:
            if primitive.get("mode", 4) != 4:
                raise ValueError("Expected triangle vehicle geometry.")
            yield primitive, self.content["materials"][primitive["material"]]

    def material_points(self, name, material_name=None):
        for primitive, material in self.surface(name):
            if material_name is None or material["name"] == material_name:
                yield from (self.world(name, point) for point in self.values(primitive["attributes"]["POSITION"]))

    def texture(self, index):
        texture = self.content["textures"][index]
        record = self.content["images"][texture["source"]]
        view = self.content["bufferViews"][record["bufferView"]]
        image = Image.open(BytesIO(self.bytes_for_view(view)))
        image.thumbnail((512, 512), Image.Resampling.LANCZOS)
        return png(image.convert("RGB"))


class PartFile:
    def __init__(self, name):
        self.binary = bytearray()
        self.name = name
        self.document = {
            "asset": {"version": "2.0", "generator": "Aamchi Mumbai vehicle exchange"},
            "scene": 0, "scenes": [{"nodes": [0]}], "nodes": [{"name": name, "mesh": 0}],
            "meshes": [{"name": name, "primitives": []}], "buffers": [],
            "bufferViews": [], "accessors": [], "images": [], "textures": [], "materials": [],
            "samplers": [{"wrapS": 10497, "wrapT": 10497}, {"wrapS": 33071, "wrapT": 33071}],
        }
        self.textures = {}

    def view(self, data, target=None):
        self.binary.extend(bytes((-len(self.binary)) % 4))
        descriptor = {"buffer": 0, "byteOffset": len(self.binary), "byteLength": len(data)}
        if target is not None:
            descriptor["target"] = target
        self.binary.extend(data)
        self.document["bufferViews"].append(descriptor)
        return len(self.document["bufferViews"]) - 1

    def texture(self, data, name, sampler):
        key = hashlib.sha256(data).digest(), sampler
        if key not in self.textures:
            image = {"name": name, "bufferView": self.view(data), "mimeType": "image/png"}
            self.document["images"].append(image)
            self.document["textures"].append({"source": len(self.document["images"]) - 1, "sampler": sampler})
            self.textures[key] = len(self.document["textures"]) - 1
        return self.textures[key]

    def material(self, descriptor):
        self.document["materials"].append(descriptor)
        return len(self.document["materials"]) - 1

    def accessor(self, rows, shape, target, *, bounds=False):
        fmt = "I" if shape == "SCALAR" else shape[-1] + "f"
        layout = struct.Struct("<" + fmt)
        content = bytearray(len(rows) * layout.size)
        for i, row in enumerate(rows):
            layout.pack_into(content, i * layout.size, *row)
        item = {"bufferView": self.view(content, target), "componentType": 5125 if shape == "SCALAR" else 5126,
                "count": len(rows), "type": shape}
        if bounds:
            columns = list(zip(*rows, strict=True))
            item["min"] = [min(column) for column in columns]
            item["max"] = [max(column) for column in columns]
        self.document["accessors"].append(item)
        return len(self.document["accessors"]) - 1

    def add_geometry(self, material, attributes, triangles):
        primitive = {"attributes": {attribute: self.accessor(attributes[attribute], shape, 34962,
                                                              bounds=attribute == "POSITION")
                                    for attribute, shape in ATTRIBUTES.items()},
                     "indices": self.accessor(triangles, "SCALAR", 34963), "material": material, "mode": 4}
        self.document["meshes"][0]["primitives"].append(primitive)

    def save(self, path):
        self.binary.extend(bytes((-len(self.binary)) % 4))
        self.document["buffers"] = [{"byteLength": len(self.binary)}]
        metadata = json.dumps(self.document, ensure_ascii=True, separators=(",", ":")).encode("utf-8")
        metadata += b" " * ((-len(metadata)) % 4)
        header = struct.pack("<4sIII4s", b"glTF", 2, 28 + len(metadata) + len(self.binary), len(metadata), b"JSON")
        result = header + metadata + struct.pack("<I4s", len(self.binary), bytes((66, 73, 78, 0))) + self.binary
        temporary = path.with_suffix(".glb.tmp")
        temporary.write_bytes(result)
        temporary.replace(path)
        return hashlib.sha256(result).hexdigest()


def is_palette_material(material):
    pbr = material["pbrMetallicRoughness"]
    return (material.get("alphaMode", "OPAQUE") == "OPAQUE" and "baseColorTexture" not in pbr
            and "normalTexture" not in material and "emissiveFactor" not in material
            and "extensions" not in material)


def make_palette(destination, entries):
    grid = math.ceil(math.sqrt(len(entries)))
    size = 32 if grid <= 4 else 64
    paint = Image.new("RGB", (size, size))
    orm = Image.new("RGB", (size, size), (255, 255, 0))
    uv_cell = {}
    for index, material in enumerate(entries.values()):
        x, y = (index % grid) * 8, (index // grid) * 8
        pbr = material["pbrMetallicRoughness"]
        srgb = tuple(encoded_srgb(value) for value in pbr.get("baseColorFactor", (1, 1, 1, 1))[:3])
        paint.paste(srgb, (x, y, x + 8, y + 8))
        orm.paste((255, round(255 * pbr.get("roughnessFactor", 1)), round(255 * pbr.get("metallicFactor", 1))),
                  (x, y, x + 8, y + 8))
        uv_cell[material["name"]] = ((x + 4) / size, (y + 4) / size)
    color = destination.texture(png(paint), destination.name + "_ColorSwatches", 1)
    roughness = destination.texture(png(orm), destination.name + "_FinishSwatches", 1)
    index = destination.material({"name": destination.name + "_Palette",
                                  "pbrMetallicRoughness": {"baseColorTexture": {"index": color},
                                                           "metallicRoughnessTexture": {"index": roughness}}})
    return index, uv_cell


def retain_textured_material(source, destination, material):
    result = json.loads(json.dumps(material))
    result["name"] = destination.name + "_" + material["name"]
    for group, keys in ((result, ("normalTexture", "occlusionTexture", "emissiveTexture")),
                        (result["pbrMetallicRoughness"], ("baseColorTexture", "metallicRoughnessTexture"))):
        for key in keys:
            if key in group:
                slot = group[key]
                slot["index"] = destination.texture(source.texture(slot["index"]), result["name"] + "_" + key, 0)
    return destination.material(result)


def tangent_from_normal(normal):
    x, y, z = normal
    basis = (z, 0.0, -x) if abs(y) > 0.75 else (-z, 0.0, x)
    if math.hypot(basis[0], basis[2]) < 0.01:
        return (1.0, 0.0, 0.0, 1.0)
    length = math.hypot(*basis)
    return (*[axis / length for axis in basis], 1.0)


def add_surface(source, name, primitive, pivot, cell, attributes, indices):
    offset = len(attributes["POSITION"])
    for attribute in ATTRIBUTES:
        source_attributes = primitive["attributes"]
        if attribute == "TANGENT" and attribute not in source_attributes:
            rows = [tangent_from_normal(normal) for normal in source.values(source_attributes["NORMAL"])]
        elif attribute == "TEXCOORD_0" and attribute not in source_attributes:
            points = source.values(source_attributes["POSITION"])
            rows = [(x + z, y) for x, y, z in points]
        else:
            rows = source.values(source_attributes[attribute])
        if attribute == "POSITION":
            rows = [vector_subtract(source.world(name, row), pivot) for row in rows]
        elif attribute == "NORMAL":
            rows = [source.world(name, row, direction=True) for row in rows]
        elif attribute == "TANGENT":
            rows = [(*source.world(name, row[:3], direction=True), row[3]) for row in rows]
        elif cell is not None:
            # Preserve small UV derivatives inside each padded swatch without sampling its neighbour.
            rows = [(cell[0] + 0.014 * math.tanh(u), cell[1] + 0.014 * math.tanh(v)) for u, v in rows]
        attributes[attribute].extend(rows)
    indices.extend((index + offset,) for index, in source.values(primitive["indices"]))


def write_part(source, names, pivot, output):
    destination = PartFile(output.stem)
    palette = {material["name"]: material for name in names for _, material in source.surface(name)
               if is_palette_material(material)}
    palette_index, cells = make_palette(destination, palette)
    material_indices = {}
    sections = defaultdict(lambda: (defaultdict(list), []))
    for name in names:
        for primitive, material in source.surface(name):
            material_name = material["name"]
            if material_name in cells:
                index = palette_index
            else:
                if material_name not in material_indices:
                    material_indices[material_name] = retain_textured_material(source, destination, material)
                index = material_indices[material_name]
            attributes, indices = sections[index]
            add_surface(source, name, primitive, pivot, cells.get(material_name), attributes, indices)
    for index, (attributes, indices) in sections.items():
        destination.add_geometry(index, attributes, indices)
    return {"sha256": destination.save(output), "triangles": sum(len(indices) // 3 for _, indices in sections.values()),
            "materials": len(sections)}


def prepare(source, name, output):
    wheel_names = PARTS["FrontWheel"] + PARTS["RearWheel"]
    local_center = (0.0, 0.0, 0.0)
    axles = {wheel: source.world(wheel, local_center) for wheel in wheel_names}
    wheel_bottom = {wheel: min(point[1] for point in source.material_points(wheel)) for wheel in wheel_names}
    floor = min(wheel_bottom.values())
    body_origin = (sum(axle[0] for axle in axles.values()) / 2, floor, 0.0)
    pivots = {"Body": body_origin, "Fork": source.world("Fork", local_center),
              "FrontWheel": axles["Wheel_Front"], "RearWheel": axles["Wheel_Rear"]}
    seat = list(source.material_points("Body", "Seat_Brown" if name == "Scooter" else "Seat_Black"))
    seat_x = [point[0] for point in seat]
    driver_hip = (min(seat_x) + 0.63 * (max(seat_x) - min(seat_x)), max(point[1] for point in seat) + 0.075, 0.0)
    receipt = {
        "source_sha256": source.digest,
        "attribution": "Vinish, CC BY 4.0, https://vinish.dev/free-3d-models/motorcycles",
        "fork_pivot_cm": unreal_axes(vector_subtract(pivots["Fork"], body_origin)),
        "front_wheel_pivot_cm": unreal_axes(vector_subtract(pivots["FrontWheel"], body_origin)),
        "rear_wheel_pivot_cm": unreal_axes(vector_subtract(pivots["RearWheel"], body_origin)),
        "steering_axis": unreal_axes(source.world("Fork", (0.0, 1.0, 0.0), direction=True), 1.0),
        "front_wheel_radius_cm": round(100.0 * (axles["Wheel_Front"][1] - wheel_bottom["Wheel_Front"]), 6),
        "rear_wheel_radius_cm": round(100.0 * (axles["Wheel_Rear"][1] - wheel_bottom["Wheel_Rear"]), 6),
        "driver_hip_cm": unreal_axes(vector_subtract(driver_hip, body_origin)),
        "parts": {},
    }
    # Leave only the deployed side stand out of the driveable mesh.
    for part, nodes in PARTS.items():
        receipt["parts"][part] = write_part(source, nodes, pivots[part], output / f"{name}Vinish{part}.glb")
    return receipt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="Directory containing both verified original Vinish GLBs")
    parser.add_argument("output", type=Path, help="Directory for the Unreal vehicle visual exchange")
    args = parser.parse_args()
    options = {name: SourceModel(args.source / file, digest) for name, (file, digest) in APPROVED.items()}
    args.output.mkdir(parents=True, exist_ok=True)
    result = {"schema": 1, "vehicles": {name: prepare(source, name, args.output) for name, source in options.items()}}
    manifest = args.output / "manifest.json"
    temporary = manifest.with_suffix(".json.tmp")
    temporary.write_text(json.dumps(result, indent=2) + chr(10), encoding="utf-8")
    temporary.replace(manifest)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
