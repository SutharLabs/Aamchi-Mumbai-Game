"""Build the game's limb and spine animation tracks from approved CMU falls."""

from __future__ import annotations

import argparse
import hashlib
import math
from pathlib import Path
import re

from retarget_100style import (
    HIP_HEIGHT, IDENTITY, REPO, SAMPLE_RATE, TURN_TO_GAME, number,
    q_axis, q_inverse, q_multiply, write_track,
)


SKELETON_SHA256 = "2b8d402ef539db75263ab7c7697bc387777fa037ac55ee85a7b734960c965384"
# Original one-based frames, inclusive. Front crop covers the descent and
# hand contact. Rear crop covers the loss of balance and contact.
CLIPS = (
    ("fall_forward", "90_16.amc", "6cf3344e887d483ab0ff917fea3b8a92f383277263a344ae6141f377bfa7b3c1", 415, 487),
    ("fall_backward", "90_17.amc", "657b34029af668d44f6af962c150bfd2234096397fec4601d64abf6e58889bbd", 333, 449),
)
JOINTS = {
    "Spine": ("lowerback",),
    "Chest": ("upperback", "thorax"),
    "Neck": ("lowerneck", "upperneck"),
    "Head": ("head",),
}
for side, prefix in (("Left", "l"), ("Right", "r")):
    for destination, source in (
        ("Shoulder", ("clavicle",)), ("UpperArm", ("humerus",)),
        ("LowerArm", ("radius",)), ("Hand", ("wrist", "hand")),
        ("UpperLeg", ("femur",)), ("LowerLeg", ("tibia",)),
        ("Foot", ("foot",)), ("Toes", ("toes",)),
    ):
        JOINTS[side + destination] = tuple(prefix + joint for joint in source)

REQUIRED = {name for source in JOINTS.values() for name in source}
AXIS = {"rx": 0, "ry": 1, "rz": 2}


def approved_text(path: Path, expected_hash: str) -> str:
    if not 0 < path.stat().st_size <= 4_000_000:
        raise ValueError(f"{path.name}: invalid capture size")
    data = path.read_bytes()
    if hashlib.sha256(data).hexdigest() != expected_hash:
        raise ValueError(f"{path.name}: capture hash changed")
    return data.decode("ascii")


def rotation(channels, angles):
    result = IDENTITY
    for channel, angle in zip(channels, angles, strict=True):
        result = q_multiply(q_axis(AXIS[channel], math.radians(angle)), result)
    return result


def read_axes(asf: str):
    _, content = asf.split(":bonedata", 1)
    blocks, _ = content.split(":hierarchy", 1)
    table = {}
    for section in re.findall(r"^\s*begin\s*$(.*?)^\s*end\s*$", blocks, re.M | re.S):
        fields = {line.split()[0]: line.split()[1:] for line in section.splitlines() if line.strip()}
        name = fields["name"][0]
        if name not in REQUIRED:
            continue
        x, y, z, order = fields["axis"]
        channels = fields["dof"]
        if order != "XYZ" or not all(channel in AXIS for channel in channels):
            raise ValueError(f"{name}: unsupported Acclaim axes")
        basis = rotation(("rx", "ry", "rz"), map(float, (x, y, z)))
        table[name] = channels, basis
    if set(table) != REQUIRED:
        raise ValueError("ASF omitted required source bones")
    return table


def read_samples(amc: str, first: int, last: int, table):
    frames = []
    current = None
    frame = 0
    for raw in amc.split(":DEGREES", 1)[1].splitlines():
        columns = raw.split()
        if not columns:
            continue
        name = columns[0]
        if name.isdigit():
            frame = int(name)
            current = {} if first <= frame <= last and (frame - first) % 4 == 0 else None
            if current is not None:
                frames.append(current)
        elif current is not None and name in table:
            channels, basis = table[name]
            angles = tuple(map(float, columns[1:]))
            if not all(map(math.isfinite, angles)):
                raise ValueError(f"AMC frame {frame} contains non-finite angles")
            local = rotation(channels, angles)
            current[name] = q_multiply(q_multiply(basis, local), q_inverse(basis))
    if len(frames) != (last - first) // 4 + 1 or any(sample.keys() != REQUIRED for sample in frames):
        raise ValueError("AMC selection is incomplete")
    return frames


def retarget(frames):
    yield "position", "Hips", [(0.0, HIP_HEIGHT, 0.0)] * len(frames)
    # The runtime capsule turns and settles the entire body. Use the recorded
    # spine and limbs with a neutral pelvis so both transforms are not applied.
    yield "rotation", "Hips", [IDENTITY] * len(frames)
    for destination, source in JOINTS.items():
        keys = []
        for frame in frames:
            local = IDENTITY
            for bone in source:
                local = q_multiply(local, frame[bone])
            keys.append(q_multiply(q_multiply(TURN_TO_GAME, local), q_inverse(TURN_TO_GAME)))
        yield "rotation", destination, keys


def build_library(folder: Path) -> str:
    table = read_axes(approved_text(folder / "90.asf", SKELETON_SHA256))
    out = ['[gd_resource type="AnimationLibrary" format=3]']
    for name, filename, digest, first, last in CLIPS:
        frames = read_samples(approved_text(folder / filename, digest), first, last, table)
        length = (len(frames) - 1) / SAMPLE_RATE
        out.extend((
            "", f'[sub_resource type="Animation" id="Animation_{name}"]',
            f'resource_name = "{name}"', f"length = {number(length)}",
            f"step = {number(1 / SAMPLE_RATE)}",
        ))
        for index, (prop, bone, keys) in enumerate(retarget(frames)):
            write_track(out, index, prop, bone, keys, False)
        print(f"{name}: {filename}, frames {first}..{last}, {length:.3f} s")
    out.extend(("", "[resource]", "_data = {"))
    out.append(",\n".join(f'&"{name}": SubResource("Animation_{name}")' for name, *_ in CLIPS))
    out.extend(("}", ""))
    return "\n".join(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_dir", type=Path)
    parser.add_argument("--output", type=Path,
                        default=REPO / "prototype/character/motion/cmu_falls.tres")
    args = parser.parse_args()
    args.output.write_text(build_library(args.source_dir), encoding="ascii", newline="\n")


if __name__ == "__main__":
    main()
