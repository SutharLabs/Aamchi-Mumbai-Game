"""Retarget the approved 100STYLE Neutral clips to Phase 1's T-pose skeleton.

The BVH files are obtained separately from the publisher. This offline tool
expects the publisher's 60 Hz Y-X-Z Euler layout, centimetres, and +Z forward.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import hashlib
import math
from pathlib import Path
import re
import statistics


REPO = Path(__file__).resolve().parents[2]
DEFAULT_OUTPUT = REPO / "prototype/character/motion/phase1_motions.tres"
SAMPLE_RATE = 30
IDENTITY = (0.0, 0.0, 0.0, 1.0)
TURN_TO_GAME = (0.0, 1.0, 0.0, 0.0)
HIP_HEIGHT = 0.90
LEG_OFFSETS = (
    (-0.097, -0.01, 0.0),
    (-0.005, -0.402, -0.016),
    (-0.001, -0.406, 0.025),
    (0.0, -0.044, -0.141),
)

# The capture has four torso joints. Compose them into the rig's two joints.
BONE_MAP = {
    "Hips": ("Hips",),
    "Spine": ("Chest", "Chest2"),
    "Chest": ("Chest3", "Chest4"),
    "Neck": ("Neck",),
    "Head": ("Head",),
}
for side in ("Left", "Right"):
    for destination, source in (
        ("Shoulder", "Collar"), ("UpperArm", "Shoulder"),
        ("LowerArm", "Elbow"), ("Hand", "Wrist"),
        ("UpperLeg", "Hip"), ("LowerLeg", "Knee"),
        ("Foot", "Ankle"), ("Toes", "Toe"),
    ):
        BONE_MAP[side + destination] = (side + source,)


@dataclass(frozen=True)
class Clip:
    name: str
    source: str
    sha256: str
    first: int
    last: int


# Zero-based, inclusive publisher BVH frame indices.
CLIPS = (
    Clip("idle", "Neutral_ID.bvh", "71aead2e3246bdb47a5b839cb3e60e0574e9a1a046c071cc147e2922a35f259f", 796, 970),
    Clip("walk", "Neutral_FW.bvh", "2f28800baa299547c42c257d1c926172542a1e69b46a3d3e6aa0aded0e9b40f6", 524, 604),
    Clip("run", "Neutral_FR.bvh", "f46ca526027a3654c8939a0123413f6008906fb32125d5e885eafcaa830831cb", 501, 547),
)


def read_capture(path: Path, expected_sha: str):
    if not 0 < path.stat().st_size <= 10_000_000:
        raise ValueError(f"{path.name}: unexpected BVH size")
    data = path.read_bytes()
    if hashlib.sha256(data).hexdigest() != expected_sha:
        raise ValueError(f"{path.name}: source hash differs from the reviewed capture")
    header, separator, motion = data.decode("ascii").partition("MOTION\n")
    if not separator:
        header, separator, motion = data.decode("ascii").partition("MOTION\r\n")
    if not separator:
        raise ValueError(f"{path.name}: missing BVH motion section")
    columns, offsets = {}, {}
    frame_width = 0
    bone_re = re.compile(
        r"(?:ROOT|JOINT) (\w+)\s*\{\s*OFFSET ([^\r\n]+)\s+CHANNELS (\d) ([^\r\n]+)"
    )
    for match in bone_re.finditer(header):
        name, offset, count, channels = match.groups()
        expected = "Xposition Yposition Zposition " if name == "Hips" else ""
        expected += "Yrotation Xrotation Zrotation"
        if channels.strip() != expected or len(channels.split()) != int(count):
            raise ValueError(f"{path.name}: unsupported rotation channels for {name}")
        columns[name] = frame_width + int(count) - 3
        offsets[name] = tuple(map(float, offset.split()))
        frame_width += int(count)
    required = {joint for chain in BONE_MAP.values() for joint in chain}
    if not required.issubset(columns) or columns.get("Hips") != 3:
        raise ValueError(f"{path.name}: skeleton does not match 100STYLE Neutral")
    count_line, time_line, *records = motion.splitlines()
    count = int(count_line.removeprefix("Frames:").strip())
    frame_time = float(time_line.removeprefix("Frame Time:").strip())
    if abs(frame_time - 1.0 / 60.0) > 1e-6 or len(records) != count:
        raise ValueError(f"{path.name}: expected complete 60 Hz capture")
    frames = [tuple(map(float, record.split())) for record in records]
    if any(len(frame) != frame_width or not all(map(math.isfinite, frame)) for frame in frames):
        raise ValueError(f"{path.name}: malformed motion sample")
    return frames, columns, offsets


def q_multiply(a, b):
    x, y, z, w = a
    dx, dy, dz, dw = b
    return (
        w * dx + x * dw + y * dz - z * dy,
        w * dy - x * dz + y * dw + z * dx,
        w * dz + x * dy - y * dx + z * dw,
        w * dw - x * dx - y * dy - z * dz,
    )


def q_inverse(q):
    return (-q[0], -q[1], -q[2], q[3])


def q_axis(axis, radians):
    direction = [0.0, 0.0, 0.0, math.cos(radians * 0.5)]
    direction[axis] = math.sin(radians * 0.5)
    return tuple(direction)


def q_bvh(frame, start):
    yaw, pitch, roll = map(math.radians, frame[start:start + 3])
    return q_multiply(q_multiply(q_axis(1, yaw), q_axis(0, pitch)), q_axis(2, roll))


def q_rotate(quaternion, vector):
    return q_multiply(q_multiply(quaternion, (*vector, 0.0)), q_inverse(quaternion))[:3]


def q_mix_identity(rotation, weight):
    if rotation[3] < 0.0:
        rotation = tuple(-value for value in rotation)
    result = (*[value * weight for value in rotation[:3]], 1 + (rotation[3] - 1) * weight)
    magnitude = math.hypot(*result)
    return tuple(value / magnitude for value in result)


def seam_strength(frame_index, count):
    # Spread the residual wrap error over the last 20% of the take.
    blend = max(0.0, (frame_index / (count - 1) - 0.80) / 0.20)
    return blend * blend * (3.0 - 2.0 * blend)


def loop_quaternions(poses):
    wrap = q_multiply(poses[0], q_inverse(poses[-1]))
    for index, pose in enumerate(poses[:-1]):
        result = q_multiply(q_mix_identity(wrap, seam_strength(index, len(poses))), pose)
        yield result
    yield poses[0]


def sole_height(rotations, index, side):
    # Calibrate a single vertical offset using the rig's shoe geometry. Fixed
    # offsets preserve the recorded hip bob and the run's airborne phase.
    joints = ("UpperLeg", "LowerLeg", "Foot", "Toes")
    orientation = rotations["Hips"][index]
    height = 0.0
    for bone, offset in zip(joints, LEG_OFFSETS):
        x, y, z = offset
        height += q_rotate(orientation, (x if side == "Left" else -x, y, z))[1]
        orientation = q_multiply(orientation, rotations[side + bone][index])
    return height + q_rotate(orientation, (0.0, -0.038, 0.0))[1]


def retarget(clip, frames, columns, offsets):
    if not 0 <= clip.first < clip.last < len(frames) or (clip.last - clip.first) % 2:
        raise ValueError(f"{clip.name}: choose a valid inclusive 30 Hz frame span")
    motion = frames[clip.first:clip.last + 1:2]
    duration = (len(motion) - 1) / SAMPLE_RATE
    movement_x = motion[-1][0] - motion[0][0]
    movement_z = motion[-1][2] - motion[0][2]
    source_leg = math.hypot(*offsets["LeftKnee"]) + math.hypot(*offsets["LeftAnkle"])
    rig_leg = math.hypot(*LEG_OFFSETS[1]) + math.hypot(*LEG_OFFSETS[2])
    scale = rig_leg / source_leg
    speed = math.hypot(movement_x, movement_z) * scale / duration
    if clip.name == "idle":
        heading = math.atan2(
            sum(math.sin(math.radians(frame[3])) for frame in motion),
            sum(math.cos(math.radians(frame[3])) for frame in motion),
        )
    else:
        heading = math.atan2(movement_x, movement_z)
    remove_heading = q_axis(1, -heading)

    rotations = {}
    for target, chain in BONE_MAP.items():
        rotations[target] = []
        for frame in motion:
            result = remove_heading if target == "Hips" else IDENTITY
            for name in chain:
                result = q_multiply(result, q_bvh(frame, columns[name]))
            rotations[target].append(q_multiply(q_multiply(TURN_TO_GAME, result), q_inverse(TURN_TO_GAME)))
        rotations[target] = list(loop_quaternions(rotations[target]))

    start_height = statistics.median(frame[1] for frame in motion)
    height_delta = (motion[0][1] - motion[-1][1]) * scale
    hip_y = [
        HIP_HEIGHT + (frame[1] - start_height) * scale + height_delta * seam_strength(index, len(motion))
        for index, frame in enumerate(motion)
    ]
    hip_y[-1] = hip_y[0]
    shoe_heights = sorted(
        height + min(sole_height(rotations, index, "Left"), sole_height(rotations, index, "Right"))
        for index, height in enumerate(hip_y)
    )
    ground_offset = shoe_heights[len(shoe_heights) // 10]
    position = [(0.0, height - ground_offset + 0.004, 0.0) for height in hip_y]
    return duration, speed, {"Hips": position}, rotations


def number(value):
    return format(value, ".8g") if abs(value) > 1e-9 else "0"


def write_track(out, index, prop, bone, keys):
    values = []
    for frame, key in enumerate(keys):
        values.extend((number(frame / SAMPLE_RATE), "1", *(number(value) for value in key)))
    prefix = f"tracks/{index}/"
    out.extend((
        f'{prefix}type = "{prop}_3d"',
        f'{prefix}path = NodePath("Skeleton3D:{bone}")',
        f"{prefix}interp = 1",
        f"{prefix}loop_wrap = true",
        f"{prefix}keys = PackedFloat32Array({', '.join(values)})",
    ))


def build_library(source_dir: Path):
    text = ['[gd_resource type="AnimationLibrary" format=3]']
    for clip in CLIPS:
        frames, columns, offsets = read_capture(source_dir / clip.source, clip.sha256)
        duration, speed, position, rotations = retarget(clip, frames, columns, offsets)
        text.extend((
            "", f'[sub_resource type="Animation" id="Animation_{clip.name}"]',
            f'resource_name = "{clip.name}"', f"length = {number(duration)}",
            "loop_mode = 1", f"step = {number(1 / SAMPLE_RATE)}",
        ))
        tracks = [("position", *item) for item in position.items()]
        tracks.extend(("rotation", *item) for item in rotations.items())
        for index, (prop, bone, keys) in enumerate(tracks):
            write_track(text, index, prop, bone, keys)
        print(f"{clip.name}: frames {clip.first}..{clip.last}, {duration:.3f} s, {speed:.3f} m/s")
    text.extend(("", "[resource]", "_data = {"))
    text.append(",\n".join(f'&"{clip.name}": SubResource("Animation_{clip.name}")' for clip in CLIPS))
    text.extend(("}", ""))
    return "\n".join(text)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_dir", type=Path, help="directory containing the reviewed Neutral BVH files")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="animation library output file")
    args = parser.parse_args()
    library = build_library(args.source_dir)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(library, encoding="ascii", newline="\n")


if __name__ == "__main__":
    main()
