"""Retarget the approved CMU running cycle for the player and pedestrians."""

from __future__ import annotations

import argparse
import math
from pathlib import Path
import statistics

from retarget_100style import (
    HIP_HEIGHT, LEG_OFFSETS, REPO, SAMPLE_RATE, TURN_TO_GAME, loop_quaternions,
    number, q_axis, q_inverse, q_multiply, seam_strength, sole_height, write_track,
)
from retarget_cmu_impacts import approved_text, read_axes, read_samples, retarget, rotation


SKELETON_HASH = "2a8e2eda3c0d7d828566b2a9a8ab36b2b8b3864110574e8b73c8f069fded416c"
CAPTURE_HASH = "b83673d6f66b56eef95beda511ebca7ae9c759c1a1694c852bc602623430aa42"
SOURCE_LEG_LENGTH = 7.41015 + 7.92551  # Left femur and tibia, in the ASF units.
FIRST_FRAME = 60  # One-based, inclusive, 120 Hz.
LAST_FRAME = 152


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
    rotations = {bone: list(loop_quaternions(poses)) for bone, poses in rotations.items()}
    scale = sum(math.hypot(*offset) for offset in LEG_OFFSETS[1:3]) / SOURCE_LEG_LENGTH
    reference_height = statistics.median(row[1] for row in root)
    seam_height = (root[0][1] - root[-1][1]) * scale
    pelvis = [
        HIP_HEIGHT + (row[1] - reference_height) * scale + seam_height * seam_strength(index, len(root))
        for index, row in enumerate(root)
    ]
    pelvis[-1] = pelvis[0]
    soles = sorted(height + min(sole_height(rotations, index, side) for side in ("Left", "Right"))
                   for index, height in enumerate(pelvis))
    ground = soles[len(soles) // 10]
    position = [(0.0, height - ground + 0.004, 0.0) for height in pelvis]
    length = (len(root) - 1) / SAMPLE_RATE
    out = ['[gd_resource type="Animation" format=3]', "", "[resource]",
           'resource_name = "run"', f"length = {number(length)}",
           "loop_mode = 1", f"step = {number(1 / SAMPLE_RATE)}"]
    write_track(out, 0, "position", "Hips", position, True)
    for index, (bone, poses) in enumerate(rotations.items(), start=1):
        write_track(out, index, "rotation", bone, poses, True)
    return "\n".join(out) + "\n", math.hypot(dx, dz) * scale / length


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
