"""Original non-celebrity static outfit studies, not accepted production NPCs.

Nauvari construction terminology: Maharashtra Gazetteer, Poona, Dress:
https://gazetteers.maharashtra.gov.in/cultural.maharashtra.gov.in/english/gazetteer/Poona/PART%20III/Chap%20%283%29/Dress.htm
Historic dress references inform silhouette only, not contemporary population mix.
"""

import math


def gandhi_cap(ctx, center=(0, 0, 1.68)):
    x, y, z = center
    outline = [(-.095, -.07), (-.065, -.12), (.065, -.12), (.095, -.07),
               (.095, .07), (.065, .12), (-.065, .12), (-.095, .07)]
    vertices = [(x+a, y+b, z) for a, b in outline]
    vertices += [(x+a*.72, y+b*.94, z+.065) for a, b in outline]
    faces = [(i, (i+1)%8, (i+1)%8+8, i+8) for i in range(8)]
    faces += [tuple(range(7, -1, -1)), tuple(range(8, 16))]
    ctx.mesh("gandhi_cap_fold_study", vertices, faces, "cloth_white")
    ctx.beam("cap_top_fold", (x, y-.10, z+.067), (x, y+.10, z+.067), .009, "dhoti")


def pheta(ctx, center=(0, 0, 1.69)):
    x, y, z = center
    # Modular folded-cloth massing only; a specific regional tie needs visual review.
    for i in range(4):
        ring = ctx.lathe("pheta_fold_%02d" % i,
                        [(z+i*.022, .125, .115, x, y),
                         (z+i*.022+.027, .12, .113, x, y)], "pheta")
        ring.rotation_euler[1] = (-1 if i % 2 else 1) * .055
    for i in range(5):
        ctx.beam("pheta_fan_%02d" % i, (x-.025+i*.012, y+.055, z+.075),
                 (x-.055+i*.024, y+.065, z+.19-abs(i-2)*.012), .024, "pheta")
    ctx.box("pheta_tail_study", (x+.09, y+.12, z-.14), (.055, .025, .31), "pheta")


def body(ctx, feminine=False):
    ctx.lathe("body_torso", [(.87,.15,.09,0,0), (1.03,.16,.095,0,0),
                              (1.29,.20 if feminine else .22,.105,0,0),
                              (1.34,.13,.08,0,0)], "skin")
    ctx.cylinder("neck", (0,0,1.38), .054, .11, "skin", vertices=10)
    ctx.ellipsoid("head_original", (0,-.004,1.54), (.112,.092,.145), "skin")
    ctx.ellipsoid("nose", (0,-.091,1.535), (.023,.031,.028), "skin")
    for side in (-1, 1):
        ctx.ellipsoid("eye_%s" % side, (side*.041,-.088,1.563), (.018,.008,.01), "eye")
        ctx.ellipsoid("pupil_%s" % side, (side*.041,-.095,1.563), (.007,.004,.007), "dark")
        ctx.ellipsoid("ear_%s" % side, (side*.111,0,1.54), (.018,.021,.035), "skin")
        ctx.limb("upper_arm_%s" % side, (side*.205,0,1.28),
                 (side*.32,0,1.07), .047, "skin")
        ctx.limb("forearm_%s" % side, (side*.32,0,1.07),
                 (side*.40,-.005,.88), .035, "skin")
        ctx.ellipsoid("hand_%s" % side, (side*.411,-.006,.85), (.037,.026,.061), "skin")
        ctx.limb("leg_%s" % side, (side*.10,0,.91), (side*.10,0,.12), .061, "skin")
        ctx.ellipsoid("foot_%s" % side, (side*.10,-.055,.055), (.069,.13,.052), "shoe")
    ctx.ellipsoid("hair_cap", (0,.012,1.63), (.114,.092,.064), "hair")
    if feminine:
        ctx.ellipsoid("hair_bun", (0,.105,1.57), (.067,.06,.063), "hair")


def shirt(ctx, long=False, mat="cloth_blue"):
    lower = .79 if long else .95
    ctx.lathe("kurta_sadara" if long else "shirt", [(lower,.185,.118,0,0),
               (1.05,.17,.109,0,0), (1.27,.225,.115,0,0), (1.34,.105,.074,0,0)], mat)
    for side in (-1,1):
        ctx.limb("sleeve_%s" % side, (side*.20,0,1.27),
                 (side*.295,0,1.10), .058, mat)
    ctx.box("shirt_placket", (0,-.116,1.19), (.014,.006,.25), "trim")


def divided_drape(ctx, mat="dhoti", prefix="dhoti"):
    for side in (-1,1):
        ctx.lathe(prefix+"_lower_%s" % side,
                  [(.16,.080,.10,side*.11,0), (.42,.12,.135,side*.11,0),
                   (.73,.115,.14,side*.11,0), (.94,.075,.11,side*.085,0)], mat)
    ctx.lathe(prefix+"_waist", [(.83,.185,.135,0,0),(.97,.17,.12,0,0)], mat)
    # Central narrow pleat, and a separate rear tuck marker, preserve divided legs.
    ctx.box(prefix+"_front_pleat", (0,-.144,.72), (.055,.018,.40), mat)
    ctx.box(prefix+"_back_tuck_study", (0,.137,.87), (.085,.025,.16), mat)


def sari(ctx, nauvari=False):
    ctx.lathe("blouse", [(1.06,.168,.107,0,0), (1.28,.208,.111,0,0),
                          (1.34,.10,.075,0,0)], "blouse")
    for side in (-1,1):
        ctx.limb("blouse_sleeve_%s" % side, (side*.20,0,1.28),
                 (side*.26,0,1.18), .056, "blouse")
    if nauvari:
        divided_drape(ctx, "sari", "nauvari_kashtha_study")
    else:
        ctx.lathe("ordinary_sari_lower", [(.12,.245,.15,0,0),(.50,.22,.145,0,0),
                                         (.92,.18,.13,0,0), (1.04,.17,.12,0,0)], "sari")
        for i in range(5):
            ctx.box("sari_front_pleat_%02d" % i, ((i-2)*.019,-.155,.55),
                    (.012,.009,.68), "sari")
        ctx.lathe("sari_lower_border", [(.12,.248,.154,0,0),(.17,.244,.153,0,0)], "trim")
    # Broad pleated pallu route up to left shoulder and down the back.
    front = [(-.19,-.13,1.30),(-.06,-.14,1.32),(.17,-.138,1.02),(.08,-.147,.95)]
    ctx.mesh("pallu_front_route_study", front, [(0,1,2,3)], "sari")
    back = [(-.19,.125,1.31),(-.06,.13,1.32),(-.05,.16,.76),(-.18,.16,.76)]
    ctx.mesh("pallu_back_drop_study", back, [(0,1,2,3)], "sari")
    ctx.beam("pallu_border", front[0], front[3], .012, "trim")


def build(ctx, spec):
    kind = spec["kind"]
    if kind == "gandhi_cap":
        gandhi_cap(ctx, (0,0,.015))
        return
    if kind == "pheta_study":
        pheta(ctx, (0,0,.18))
        return
    feminine = kind in {"nauvari_study", "sari_study"}
    body(ctx, feminine)
    if kind == "kurta_dhoti_cap":
        divided_drape(ctx)
        shirt(ctx, long=True, mat="kurta")
        gandhi_cap(ctx)
    elif kind in {"nauvari_study", "sari_study"}:
        sari(ctx, nauvari=kind == "nauvari_study")
    elif kind == "contemporary_character":
        for side in (-1,1):
            ctx.limb("trouser_%s" % side, (side*.1,0,.97),
                     (side*.1,0,.15), .077, "dark")
        shirt(ctx)
    else:
        raise ValueError("Unknown character study: " + kind)
