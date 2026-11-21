"""Original low-poly chawl typology studies, generated only from primitives.

These are review drafts, not surveyed replicas. Every dimension below is a
bounded design parameter; historical facts do not establish an as-built plan.
Reference leads (photos/diagrams are not imported or used as textures):
https://www.mhada.gov.in/sites/default/files/PMC-Agreement-for-BDD-Redevelopment-Project-26_2_2019-Worli.pdf
https://www.mmrhcs.org.in/images/documents/projects/03-Gs3-Proformas.pdf
https://mmrhcs.org.in/images/documents/projects/chembur/03-final-stage-5-revised-report-15-12-11.pdf

The caller owns scene creation, export, collision policy, rendering, and QA.
Only the supplied context's primitive API creates Blender objects here. No
network, external files, shell commands, third-party meshes, or credentials.
"""

from collections.abc import Mapping
import math


_KINDS = frozenset({
    "chawl_bay", "chawl_stair", "chawl_gallery_study",
    "chawl_baithi_study", "chawl_props",
})


def _number(parameters, key, default, lower, upper):
    """Bound geometry inputs before allocating meshes; reject NaN and booleans."""
    value = parameters.get(key, default)
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError(f"{key} must be a finite number")
    try:
        result = float(value)
    except (ValueError, OverflowError) as exc:
        raise ValueError(f"{key} must be a finite number") from exc
    if not math.isfinite(result):
        raise ValueError(f"{key} must be a finite number")
    return max(lower, min(upper, result))


def _parameters(spec):
    raw = spec.get("parameters", {})
    if not isinstance(raw, Mapping):
        raise ValueError("parameters must be an object")
    return {
        "bay_width": _number(raw, "bay_width", 3.0, 2.4, 3.8),
        "room_depth": _number(raw, "room_depth", 5.0, 4.0, 6.5),
        "gallery_width": _number(raw, "gallery_width", 1.4, 1.2, 2.0),
        "floor_height": _number(raw, "floor_height", 2.8, 2.5, 3.2),
        "bays": int(_number(raw, "bays", 4, 1, 6)),
        "floors": int(_number(raw, "floors", 4, 1, 4)),
        "courtyard_width": _number(raw, "courtyard_width", 7.0, 4.0, 12.0),
    }


class _Place:
    """Translate or reflect a row while retaining primitive registration."""

    def __init__(self, ctx, prefix, offset=(0.0, 0.0, 0.0), facing=1):
        self.ctx = ctx
        self.prefix = prefix
        self.offset = offset
        self.facing = facing

    def point(self, value):
        return (value[0] + self.offset[0],
                self.facing * value[1] + self.offset[1],
                value[2] + self.offset[2])

    def box(self, name, center, size, material):
        return self.ctx.box(self.prefix + name, self.point(center), size, material)

    def beam(self, name, start, end, width, material):
        return self.ctx.beam(self.prefix + name, self.point(start),
                             self.point(end), width, material)

    def cylinder(self, name, center, radius, depth, material, vertices=8):
        return self.ctx.cylinder(self.prefix + name, self.point(center),
                                 radius, depth, material, vertices=vertices)

    def mesh(self, name, vertices, faces, material):
        transformed = [self.point(vertex) for vertex in vertices]
        if self.facing == -1:
            faces = [tuple(reversed(face)) for face in faces]
        return self.ctx.mesh(self.prefix + name, transformed, faces, material)


def _hinged_door(place, name, left, level, width, height, opened=False):
    """Place a door leaf with its actual object origin at the lower hinge."""
    t = 0.045
    vertices = [(0, -t, 0), (width, -t, 0), (width, t, 0), (0, t, 0),
                (0, -t, height), (width, -t, height),
                (width, t, height), (0, t, height)]
    faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4),
             (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    obj = place.ctx.mesh(place.prefix + name, vertices, faces, "wood")
    obj.location = place.point((left, -0.07, level))
    if opened:
        obj.rotation_euler[2] = math.radians(-65 * place.facing)
    return obj


def _frontage(place, x, level, width, height, material, door_open=False):
    """Wall piers/header surround real door/window openings, not a solid cube."""
    door_w, opening_h = 0.80, 2.05
    door_left = 0.22
    door_right = door_left + door_w
    win_left = width * 0.57
    win_right = width - 0.18
    sill = 0.95
    wall_t = 0.15
    for label, a, b in (("left_pier", 0, door_left),
                        ("middle_pier", door_right, win_left),
                        ("right_pier", win_right, width)):
        place.box(label, (x + (a+b)/2, 0, level+height/2),
                  (b-a, wall_t, height), material)
    place.box("window_sill_wall", (x+(win_left+win_right)/2, 0, level+sill/2),
              (win_right-win_left, wall_t, sill), material)
    place.box("opening_header", (x+width/2, 0, level+(opening_h+height)/2),
              (width, wall_t, height-opening_h), material)
    _hinged_door(place, "door_leaf", x+door_left+0.025, level+0.025,
                 door_w-0.05, opening_h-0.05, door_open)
    for label, side in (("door_jamb_l", door_left), ("door_jamb_r", door_right)):
        place.box(label, (x+side, -0.09, level+opening_h/2),
                  (0.05, 0.05, opening_h), "wood")
    place.box("door_lintel", (x+(door_left+door_right)/2, -0.09, level+opening_h),
              (door_w+0.08, 0.07, 0.065), "wood")
    window_w = win_right-win_left
    place.box("window_recess", (x+(win_left+win_right)/2, 0.045,
                                 level+(sill+opening_h)/2),
              (window_w-0.05, 0.035, opening_h-sill-0.06), "dark")
    for label, side in (("window_jamb_l", win_left), ("window_jamb_r", win_right)):
        place.box(label, (x+side, -0.09, level+(sill+opening_h)/2),
                  (0.045, 0.05, opening_h-sill), "wood")
    for index in range(1, 4):
        bar_x = x+win_left+index*window_w/4
        place.beam(f"window_bar_{index}", (bar_x, -0.11, level+sill),
                   (bar_x, -0.11, level+opening_h), 0.022, "metal")


def _gallery_railing(place, x, width, gallery, level, height=0.98):
    y = -gallery+0.045
    count = max(3, math.ceil(width/0.75))
    for index in range(count):
        px = x+index*width/count+0.035
        place.box(f"rail_post_{index}", (px, y, level+height/2),
                  (0.045, 0.045, height), "metal")
    for index, rail_z in enumerate((0.38, height)):
        place.beam(f"rail_horizontal_{index}", (x, y, level+rail_z),
                   (x+width, y, level+rail_z), 0.045, "metal")


def _bay(place, p, x=0.0, level=0.16, left_wall=True,
         right_wall=True, railing=True, door_open=False):
    width, depth = p["bay_width"], p["room_depth"]
    gallery, floor_h = p["gallery_width"], p["floor_height"]
    wall_h = floor_h-0.16
    place.box("floor", (x+width/2, (depth-gallery)/2, level-0.08),
              (width, depth+gallery, 0.16), "concrete")
    mat = "plaster" if int(round(x/width)) % 2 == 0 else "worn_plaster"
    place.box("back_wall", (x+width/2, depth-0.075, level+wall_h/2),
              (width, 0.15, wall_h), mat)
    if left_wall:
        place.box("left_wall", (x+0.075, depth/2, level+wall_h/2),
                  (0.15, depth, wall_h), mat)
    if right_wall:
        place.box("right_wall", (x+width-0.075, depth/2, level+wall_h/2),
                  (0.15, depth, wall_h), mat)
    _frontage(place, x, level, width, wall_h, mat, door_open)
    if railing:
        _gallery_railing(place, x, width, gallery, level)


def _step_flight(place, label, center_x, start_y, direction,
                 start_z, rise, run, width, steps):
    """Real visible treads; caller defines runtime collision/step-up handling."""
    for index in range(steps):
        dy, dz = run/steps, rise/steps
        place.box(f"{label}_tread_{index}",
                  (center_x, start_y+direction*dy*(index+0.5),
                   start_z+dz*(index+0.5)),
                  (width, dy+0.008, dz), "concrete")
    # An original closed wedge supports the treads visually. Collision ramps
    # should be generated/filtered by the import/export policy, not inferred.
    x0, x1 = center_x-width/2, center_x+width/2
    y0, y1 = start_y, start_y+direction*run
    verts = [(x0, y0, start_z), (x1, y0, start_z),
             (x0, y1, start_z), (x1, y1, start_z),
             (x0, y1, start_z+rise), (x1, y1, start_z+rise)]
    faces = [(0, 2, 3, 1), (0, 1, 5, 4), (2, 4, 5, 3),
             (0, 4, 2), (1, 3, 5)]
    if direction < 0:
        faces = [tuple(reversed(face)) for face in faces]
    place.mesh(f"{label}_support", verts, faces, "concrete")
    for side_index, side in enumerate((-1, 1)):
        rail_x = center_x+side*(width/2-0.04)
        place.beam(f"{label}_handrail_{side_index}",
                   (rail_x, y0, start_z+0.95),
                   (rail_x, y1, start_z+rise+0.95), 0.04, "metal")
        for post in range(3):
            fraction = post/2
            py, pz = y0+(y1-y0)*fraction, start_z+rise*fraction
            place.beam(f"{label}_post_{side_index}_{post}",
                       (rail_x, py, pz), (rail_x, py, pz+0.95), 0.035, "metal")


def _stairs(place, p, levels):
    """Switchback tower connects the row's open gallery ends at each level."""
    gallery, floor_h = p["gallery_width"], p["floor_height"]
    flight_w, middle_gap, landing = 1.05, 0.14, 1.2
    tower_w = flight_w*2+middle_gap
    run = max(2.0, floor_h*0.9)
    near_y = -gallery
    for level_index in range(levels):
        level = 0.16+level_index*floor_h
        place.box(f"near_landing_{level_index}",
                  (-tower_w/2, -gallery/2, level-0.08),
                  (tower_w, gallery, 0.16), "concrete")
        place.beam(f"near_outer_guard_{level_index}",
                   (-tower_w+0.04, -gallery, level+0.98),
                   (-tower_w+0.04, 0, level+0.98), 0.045, "metal")
        place.beam(f"near_back_guard_{level_index}",
                   (-tower_w+0.04, -0.04, level+0.98),
                   (-0.04, -0.04, level+0.98), 0.045, "metal")
        for post, py in enumerate((-gallery, 0)):
            place.beam(f"near_outer_post_{level_index}_{post}",
                       (-tower_w+0.04, py, level),
                       (-tower_w+0.04, py, level+0.98), 0.04, "metal")
    for floor in range(max(1, levels-1)):
        start_z = 0.16+floor*floor_h
        half = floor_h/2
        steps = math.ceil(half/0.18)
        _step_flight(place, f"floor_{floor}_out", -tower_w+flight_w/2,
                     near_y, -1, start_z, half, run, flight_w, steps)
        place.box(f"far_landing_{floor}",
                  (-tower_w/2, near_y-run-landing/2, start_z+half-0.08),
                  (tower_w, landing, 0.16), "concrete")
        _step_flight(place, f"floor_{floor}_return", -flight_w/2,
                     near_y-run, 1, start_z+half, half, run, flight_w, steps)
        place.beam(f"far_guard_{floor}",
                   (-tower_w, near_y-run-landing+0.04, start_z+half+0.98),
                   (0, near_y-run-landing+0.04, start_z+half+0.98),
                   0.045, "metal")
        for post, px in enumerate((-tower_w+0.04, -0.04)):
            place.beam(f"far_side_guard_{floor}_{post}",
                       (px, near_y-run, start_z+half+0.98),
                       (px, near_y-run-landing+0.04, start_z+half+0.98),
                       0.045, "metal")
            place.beam(f"far_guard_post_{floor}_{post}",
                       (px, near_y-run-landing+0.04, start_z+half),
                       (px, near_y-run-landing+0.04, start_z+half+0.98),
                       0.04, "metal")


def _pitched_roof(place, length, depth, gallery, level):
    front, back = -gallery-0.20, depth+0.20
    ridge_y = (front+back)/2
    vertices = [(-0.15, front, level), (length+0.15, front, level),
                (-0.15, back, level), (length+0.15, back, level),
                (-0.15, ridge_y, level+0.85),
                (length+0.15, ridge_y, level+0.85)]
    faces = [(0, 1, 5, 4), (2, 4, 5, 3), (0, 2, 3, 1),
             (0, 4, 2), (1, 3, 5)]
    place.mesh("pitched_roof", vertices, faces, "roof")


def _row(ctx, prefix, p, offset=(0, 0, 0), facing=1,
         floors=None, pitched=False):
    count = p["floors"] if floors is None else floors
    width, depth, gallery = p["bay_width"], p["room_depth"], p["gallery_width"]
    length = p["bays"]*width
    for floor in range(count):
        for bay in range(p["bays"]):
            place = _Place(ctx, f"{prefix}f{floor:02d}_b{bay:02d}_", offset, facing)
            _bay(place, p, x=bay*width, level=0.16+floor*p["floor_height"],
                 left_wall=(bay == 0), railing=(floor > 0),
                 door_open=(floor == 0 and bay == 1))
    roof_place = _Place(ctx, prefix, offset, facing)
    roof_z = 0.16+count*p["floor_height"]
    if pitched:
        _pitched_roof(roof_place, length, depth, gallery, roof_z-0.16)
    else:
        roof_place.box("roof_slab", (length/2, (depth-gallery)/2, roof_z-0.08),
                       (length, depth+gallery, 0.16), "concrete")
        roof_place.box("roof_parapet", (length/2, -gallery+0.07, roof_z+0.20),
                       (length, 0.14, 0.40), "plaster")
    return length


def _props(place):
    for index, (x, y) in enumerate(((0.0, 0.0), (0.55, 0.05))):
        place.cylinder(f"bucket_{index}", (x, y, 0.19), 0.17, 0.38,
                       "cloth_blue" if index == 0 else "metal", vertices=8)
    place.box("wash_platform", (1.30, 0.25, 0.16), (1.0, 0.9, 0.32), "concrete")
    place.box("wash_back", (1.30, 0.70, 0.55), (1.0, 0.10, 0.78), "plaster")
    place.beam("wash_tap_pipe", (1.30, 0.60, 0.62), (1.30, 0.37, 0.62),
               0.04, "metal")
    place.box("bench_seat", (0.85, -1.0, 0.48), (1.5, 0.38, 0.10), "wood")
    for index, x in enumerate((0.25, 1.45)):
        place.box(f"bench_leg_{index}", (x, -1.0, 0.23), (0.10, 0.32, 0.46),
                  "metal")
    for index, x in enumerate((-0.4, 2.1)):
        place.beam(f"laundry_post_{index}", (x, 1.30, 0), (x, 1.30, 2.2),
                   0.045, "metal")
    place.beam("laundry_line", (-0.4, 1.30, 2.1), (2.1, 1.30, 2.1),
               0.012, "metal")
    for index, mat in enumerate(("cloth_blue", "cloth_white", "cloth_red")):
        x = index*0.65
        place.mesh(f"laundry_{index}",
                   [(x, 1.30, 2.10), (x+0.45, 1.30, 2.10),
                    (x+0.42, 1.34, 1.40), (x+0.02, 1.28, 1.35)],
                   [(0, 1, 2, 3), (3, 2, 1, 0)], mat)


def build(ctx, spec):
    """Generate one bounded, original reference-inspired chawl draft.

    All numeric values are estimated design choices, clamped to small meshes.
    Metadata returned here is advisory; the caller must mark drafts pending
    architectural/authenticity review and validate exported scene statistics.
    """
    if not isinstance(spec, Mapping):
        raise ValueError("spec must be an object")
    kind = spec.get("kind")
    if not isinstance(kind, str) or kind not in _KINDS:
        raise ValueError("unsupported chawl model kind")
    p = _parameters(spec)
    if kind == "chawl_bay":
        _bay(_Place(ctx, "chawl_bay_"), p)
    elif kind == "chawl_stair":
        _stairs(_Place(ctx, "chawl_stair_"), p, max(2, p["floors"]))
    elif kind == "chawl_gallery_study":
        length = p["bays"]*p["bay_width"]
        offset = (-length/2, 0, 0)
        _row(ctx, "gallery_", p, offset)
        if p["floors"] > 1:
            _stairs(_Place(ctx, "gallery_stair_", offset), p, p["floors"])
        _Place(ctx, "gallery_").box(
            "forecourt", (0, -p["gallery_width"]-3.5, 0.025),
            (length+4.5, 7.0, 0.05), "concrete")
    elif kind == "chawl_baithi_study":
        length = p["bays"]*p["bay_width"]
        courtyard = p["courtyard_width"]
        p = dict(p, floors=1)
        # Both galleries face the common space. Two distinct rows remain
        # separate from the multistorey gallery study above.
        _row(ctx, "baithi_north_", p,
             (-length/2, courtyard/2+p["gallery_width"], 0), pitched=True)
        _row(ctx, "baithi_south_", p,
             (-length/2, -courtyard/2-p["gallery_width"], 0),
             facing=-1, pitched=True)
        place = _Place(ctx, "baithi_")
        place.box("courtyard", (0, 0, 0.025),
                  (length+0.5, courtyard+2*p["gallery_width"], 0.05), "concrete")
        _props(_Place(ctx, "baithi_service_", (length/2+1.0, 0, 0)))
        place.box("service_back", (length/2+2.0, 2.5, 1.1),
                  (2.0, 0.12, 2.2), "plaster")
    elif kind == "chawl_props":
        _props(_Place(ctx, "chawl_props_"))
    return {
        "kind": kind,
        "parameters": p,
        "status": "draft_pending_architectural_and_gameplay_review",
        "dimensions_basis": "estimated_design_parameters_not_surveyed",
        "geometry_origin": "original_procedural_primitives_no_external_meshes",
    }
