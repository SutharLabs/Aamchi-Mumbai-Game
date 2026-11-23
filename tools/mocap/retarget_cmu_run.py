"""Retarget the approved CMU running cycle for the player and pedestrians."""

from __future__ import annotations

import argparse
import math
from pathlib import Path
import statistics

from retarget_100style import (
    HIP_HEIGHT, LEG_OFFSETS, REPO, SAMPLE_RATE, TURN_TO_GAME, loop_quaternions,
    number, q_axis, q_inverse, q_multiply, q_rotate, seam_strength, write_track,
)
from retarget_cmu_impacts import approved_text, read_axes, read_samples, retarget, rotation


SKELETON_HASH = "2a8e2eda3c0d7d828566b2a9a8ab36b2b8b3864110574e8b73c8f069fded416c"
CAPTURE_HASH = "b83673d6f66b56eef95beda511ebca7ae9c759c1a1694c852bc602623430aa42"
SOURCE_LEG_LENGTH = 7.41015 + 7.92551  # Left femur and tibia, in the ASF units.
FIRST_FRAME = 60  # One-based, inclusive, 120 Hz.
LAST_FRAME = 152

# Source directions from the hash-verified Subject 35 ASF. The CMU femur and
# tibia rest 20 degrees out from vertical. The game rig has nearly straight
# rest legs, so applying the CMU joint rotations directly crosses both feet.
LEG = ("UpperLeg", "LowerLeg", "Foot", "Toes")
CAPTURE_REST = {
    "Left": ((0.34202, -0.939693, 0.0), (0.34202, -0.939693, 0.0),
             (0.0786834, -0.216181, 0.973178), (0.0, 0.0, 1.0)),
    "Right": ((-0.34202, -0.939693, 0.0), (-0.34202, -0.939693, 0.0),
              (-0.109419, -0.300625, 0.947445), (0.0, 0.0, 1.0)),
}
# Reviewed source contact phases, with easing on either side of the plant.
CONTACTS = {"Right": (72, 80, 104, 112), "Left": (116, 124, 144, 152)}
SOLE_CLEARANCE = 0.004


def align(from_axis, to_axis):
    """Rotate one rest direction onto another without adding bone twist."""
    ax, ay, az = (value / math.hypot(*from_axis) for value in from_axis)
    bx, by, bz = (value / math.hypot(*to_axis) for value in to_axis)
    result = (ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx,
              1.0 + ax * bx + ay * by + az * bz)
    length = math.hypot(*result)
    return tuple(value / length for value in result)


def leg_offsets(side):
    sign = 1 if side == "Left" else -1
    return tuple((x * sign, y, z) for x, y, z in LEG_OFFSETS)


def fit_legs(rotations):
    for side, source_directions in CAPTURE_REST.items():
        game_directions = leg_offsets(side)[1:] + ((0.0, 0.0, -1.0),)
        corrections = [align(game, q_rotate(TURN_TO_GAME, source))
                       for game, source in zip(game_directions, source_directions, strict=True)]
        for frame, hip in enumerate(rotations["Hips"]):
            capture_global = hip
            game_parent = hip
            for joint, offset in zip(LEG, corrections, strict=True):
                key = side + joint
                capture_global = q_multiply(capture_global, rotations[key][frame])
                game_global = q_multiply(capture_global, offset)
                rotations[key][frame] = q_multiply(q_inverse(game_parent), game_global)
                game_parent = game_global


def shoe_contact(rotations, frame, side):
    orientation = rotations["Hips"][frame]
    origin = (0.0, 0.0, 0.0)
    supports = []
    forefoot = None
    for joint, offset in zip(LEG, leg_offsets(side), strict=True):
        origin = tuple(a + b for a, b in zip(origin, q_rotate(orientation, offset), strict=True))
        orientation = q_multiply(orientation, rotations[side + joint][frame])
        if joint == "Foot":
            supports.extend(origin[1] + q_rotate(orientation, (x, -0.079, 0.055))[1]
                            for x in (-0.046, 0.0, 0.046))
        elif joint == "Toes":
            supports.extend(origin[1] + q_rotate(orientation, (x, -0.035, -0.019))[1]
                            for x in (-0.052, 0.0, 0.052))
            forefoot = tuple(a + b for a, b in zip(
                origin, q_rotate(orientation, (0.0, -0.035, -0.019)), strict=True))
    return min(supports), forefoot


def plant_shoes(rotations, pelvis, speed):
    contacts = {side: [shoe_contact(rotations, frame, side) for frame in range(len(pelvis))]
                for side in CAPTURE_REST}
    soles = sorted(height + min(samples[frame][0] for samples in contacts.values())
                   for frame, height in enumerate(pelvis))
    ground = soles[len(soles) // 10]
    position = [(0.0, height - ground + SOLE_CLEARANCE, 0.0) for height in pelvis]
    for side, (approach, begin, end, release) in CONTACTS.items():
        samples = contacts[side]
        stable_frames = range((begin - FIRST_FRAME) // 4, (end - FIRST_FRAME) // 4 + 1)
        anchor_x = statistics.median(samples[frame][1][0] for frame in stable_frames)
        anchor_z = statistics.median(samples[frame][1][2] - frame * speed / SAMPLE_RATE
                                     for frame in stable_frames)
        for frame, (minimum, forefoot) in enumerate(samples):
            sample = FIRST_FRAME + frame * 4
            if not approach < sample < release:
                continue
            blend = min(1.0, (sample - approach) / (begin - approach),
                        (release - sample) / (release - end))
            blend = blend * blend * (3.0 - 2.0 * blend)
            height = position[frame][1]
            position[frame] = (
                (anchor_x - forefoot[0]) * blend,
                height + (SOLE_CLEARANCE - minimum - height) * blend,
                (anchor_z - forefoot[2] + frame * speed / SAMPLE_RATE) * blend,
            )
    # Foot markers follow the rendered soles and the planted pose is baked.
    # The physics capsule provides the forward travel, including on mobile.
    return [
        (x, max(y, SOLE_CLEARANCE - min(samples[frame][0] for samples in contacts.values())), z)
        for frame, (x, y, z) in enumerate(position)
    ]


def retarget_run(folder: Path) -> tuple[str, float]:
    table = read_axes(approved_text(folder / "35.asf", SKELETON_HASH))
    frames = read_samples(approved_text(folder / "35_18.amc", CAPTURE_HASH),
                          FIRST_FRAME, LAST_FRAME, table, include_root=True)
    root = [frame["root"] for frame in frames]
    dx = root[-1][0] - root[0][0]
    dz = root[-1][2] - root[0][2]
    heading = q_axis(1, -math.atan2(dx, dz))
    rotations = {bone: values for track, bone, values in retarget(frames) if track == "rotation"}
    rotations["Hips"] = [
        q_multiply(q_multiply(TURN_TO_GAME,
                              q_multiply(heading, rotation(("rx", "ry", "rz"), row[3:]))),
                   q_inverse(TURN_TO_GAME))
        for row in root
    ]
    fit_legs(rotations)
    rotations = {bone: list(loop_quaternions(poses)) for bone, poses in rotations.items()}
    scale = sum(math.hypot(*offset) for offset in LEG_OFFSETS[1:3]) / SOURCE_LEG_LENGTH
    reference_height = statistics.median(row[1] for row in root)
    seam_height = (root[0][1] - root[-1][1]) * scale
    pelvis = [
        HIP_HEIGHT + (row[1] - reference_height) * scale + seam_height * seam_strength(index, len(root))
        for index, row in enumerate(root)
    ]
    pelvis[-1] = pelvis[0]
    length = (len(root) - 1) / SAMPLE_RATE
    speed = math.hypot(dx, dz) * scale / length
    position = plant_shoes(rotations, pelvis, speed)
    out = ['[gd_resource type="Animation" format=3]', "", "[resource]",
           'resource_name = "run"', f"length = {number(length)}",
           "loop_mode = 1", f"step = {number(1 / SAMPLE_RATE)}"]
    write_track(out, 0, "position", "Hips", position, True)
    for index, (bone, poses) in enumerate(rotations.items(), start=1):
        write_track(out, index, "rotation", bone, poses, True)
    return "\n".join(out) + "\n", speed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_dir", type=Path)
    parser.add_argument("--output", type=Path,
                        default=REPO / "prototype/character/motion/cmu_run.tres")
    args = parser.parse_args()
    animation, reference_speed = retarget_run(args.source_dir)
    args.output.write_text(animation, encoding="ascii", newline="\n")
    print(f"run: 35_18.amc, frames {FIRST_FRAME}..{LAST_FRAME}, {reference_speed:.3f} m/s")


if __name__ == "__main__":
    main()
