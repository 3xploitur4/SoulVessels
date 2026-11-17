"""Story 051: write the M4 rig clips into data/art/rigs/*.json (Darius's hammer kit, Ilyr's
Dislocation, Absolute Rupture and Null Space blink, the Guardian Below's and the Abyssal
Leviathan's per-attack telegraph and strike poses). Rerun after editing; it replaces only the clips
named here and keeps each file's formatting (indent 1, CRLF, no final newline).

    bash tools/python.sh tools/art/author_m4_clips.py

Joint angles in degrees, as in caelan.json: positive turns a part counter-clockwise as seen when
the character faces right (a hanging arm swings forward; 160 is overhead). root_y in metres.
Vessel action clips are one-shots keyed over the action (0..1); enemy attack clips are poses the
rig blends into ("telegraph_<attack id>", "attack_<attack id>").
"""
import json
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def one_shot(*keys, blend=40):
    return {"blend": blend, "keys": [list(k) for k in keys]}


def pose(d, blend=40):
    return {"blend": blend, "keys": [[0, d]]}


# ---- Darius: the hammer ("sword" is the hammer's part) ----------------------------------------
DARIUS = {
    # 1: a flat sweep from the back shoulder across.
    "primary_0": one_shot(
        [0, {}],
        [0.3, {"torso": 14, "arm_upper": -35, "arm_fore": 30, "sword": 40, "shield_arm": 20, "leg_r_thigh": 10}, "out"],
        [0.55, {"torso": -16, "head": -5, "arm_upper": 85, "arm_fore": -10, "sword": -30, "shield_arm": -10,
                "leg_l_thigh": 22, "leg_l_shin": -14, "leg_r_thigh": -14}, "in"],
        [0.8, {"torso": -10, "arm_upper": 70, "arm_fore": -6, "sword": -24, "leg_l_thigh": 14, "leg_r_thigh": -8}],
        [1, {}]),
    # 2: the return swing, low to high.
    "primary_1": one_shot(
        [0, {}],
        [0.3, {"torso": -10, "arm_upper": 15, "arm_fore": -20, "sword": -50, "leg_l_thigh": 12}, "out"],
        [0.55, {"torso": 12, "head": 6, "arm_upper": 150, "arm_fore": 30, "sword": 20, "shield_arm": 30,
                "leg_r_thigh": 16, "leg_l_thigh": -10, "root_y": 0.04}, "in"],
        [0.8, {"torso": 6, "arm_upper": 130, "arm_fore": 20, "sword": 12, "shield_arm": 18}],
        [1, {}]),
    # 3: the heavy two-handed overhead slam into the floor.
    "primary_2": one_shot(
        [0, {}],
        [0.35, {"torso": 18, "head": 8, "arm_upper": 175, "arm_fore": 40, "sword": 40, "shield_arm": 165,
                "leg_l_thigh": -12, "leg_r_thigh": 8, "root_y": 0.06, "squash": 0.04}, "out"],
        [0.55, {"torso": -32, "head": -10, "arm_upper": 40, "arm_fore": -12, "sword": -30, "shield_arm": 45,
                "leg_l_thigh": 36, "leg_l_shin": -30, "leg_r_thigh": -24, "leg_r_shin": -20, "root_y": -0.14,
                "squash": -0.06}, "in"],
        [0.85, {"torso": -24, "head": -8, "arm_upper": 35, "arm_fore": -10, "sword": -26, "shield_arm": 40,
                "leg_l_thigh": 28, "leg_l_shin": -24, "leg_r_thigh": -18, "root_y": -0.1}],
        [1, {}], blend=35),
    # Crushing Blow: a long wind-up behind the head, then everything into one strike.
    "crushing_blow": one_shot(
        [0, {}],
        [0.4, {"torso": 22, "head": 10, "arm_upper": 190, "arm_fore": 60, "sword": 55, "shield_arm": 175,
               "leg_r_thigh": 14, "leg_l_thigh": -14, "root_y": 0.05, "squash": 0.05}, "out"],
        [0.55, {"torso": -36, "head": -12, "arm_upper": 55, "arm_fore": -14, "sword": -40, "shield_arm": 55,
                "leg_l_thigh": 40, "leg_l_shin": -34, "leg_r_thigh": -26, "leg_r_shin": -22, "root_y": -0.16,
                "squash": -0.08}, "in"],
        [0.85, {"torso": -30, "head": -10, "arm_upper": 50, "arm_fore": -12, "sword": -36, "shield_arm": 50,
                "leg_l_thigh": 34, "leg_l_shin": -28, "leg_r_thigh": -22, "root_y": -0.12}],
        [1, {}], blend=30),
    # Groundbreaker: crouch, hammer high, then a seismic two-handed drive into the ground.
    "groundbreaker": one_shot(
        [0, {}],
        [0.35, {"torso": 8, "head": 6, "arm_upper": 165, "arm_fore": 20, "sword": 30, "shield_arm": 160,
                "leg_l_thigh": 30, "leg_l_shin": -40, "leg_r_thigh": -20, "leg_r_shin": -30, "root_y": -0.08}, "out"],
        [0.5, {"torso": -40, "head": -14, "arm_upper": 20, "arm_fore": -20, "sword": -60, "shield_arm": 20,
               "leg_l_thigh": 44, "leg_l_shin": -46, "leg_r_thigh": -30, "leg_r_shin": -30, "root_y": -0.22,
               "squash": -0.1}, "in"],
        [0.9, {"torso": -34, "arm_upper": 20, "arm_fore": -18, "sword": -55, "shield_arm": 20,
               "leg_l_thigh": 38, "leg_l_shin": -40, "leg_r_thigh": -26, "root_y": -0.18}],
        [1, {}], blend=30),
    # The shoulder charge: low, shoulder first, hammer trailing.
    "shoulder_charge": pose({"torso": -34, "head": -10, "shield_arm": 70, "arm_upper": -50, "arm_fore": 20,
                             "sword": 30, "leg_l_thigh": 36, "leg_l_shin": -30, "leg_r_thigh": -40, "leg_r_shin": -24,
                             "root_y": -0.04}, blend=30),
    # Meteor Drop: a leap with the hammer up, then down onto the ground.
    "meteor_drop": one_shot(
        [0, {}],
        [0.35, {"torso": 14, "head": 8, "arm_upper": 180, "arm_fore": 30, "sword": 40, "shield_arm": 170,
                "leg_l_thigh": 50, "leg_l_shin": -70, "leg_r_thigh": 30, "leg_r_shin": -60, "root_y": 0.25}, "out"],
        [0.6, {"torso": -38, "head": -12, "arm_upper": 30, "arm_fore": -16, "sword": -50, "shield_arm": 30,
               "leg_l_thigh": 44, "leg_l_shin": -46, "leg_r_thigh": -30, "leg_r_shin": -30, "root_y": -0.2,
               "squash": -0.1}, "in"],
        [1, {}], blend=30),
    # Worldbreaker Override: the charge (hammer raised, braced), then the strike.
    "worldbreaker_override": one_shot(
        [0, {}],
        [0.15, {"torso": 10, "head": 10, "arm_upper": 170, "arm_fore": 20, "sword": 25, "shield_arm": 165,
                "leg_l_thigh": 26, "leg_l_shin": -30, "leg_r_thigh": -22, "leg_r_shin": -16, "root_y": -0.05}],
        [0.7, {"torso": 16, "head": 12, "arm_upper": 185, "arm_fore": 35, "sword": 40, "shield_arm": 178,
               "leg_l_thigh": 30, "leg_l_shin": -34, "leg_r_thigh": -24, "leg_r_shin": -18, "root_y": -0.07,
               "squash": 0.04}, "out"],
        [0.8, {"torso": -42, "head": -14, "arm_upper": 25, "arm_fore": -20, "sword": -55, "shield_arm": 25,
               "leg_l_thigh": 46, "leg_l_shin": -46, "leg_r_thigh": -30, "leg_r_shin": -30, "root_y": -0.22,
               "squash": -0.1}, "in"],
        [1, {"torso": -30, "arm_upper": 25, "sword": -45, "shield_arm": 25, "leg_l_thigh": 36, "root_y": -0.14}],
        blend=25),
}

# ---- Ilyr ----------------------------------------------------------------------------------------
ILYR = {
    # Null Space: a blink, body thin and leaning into the tear.
    "dodge": pose({"torso": -24, "head": -8, "arm_upper": -30, "arm_fore": 20, "sword": 20, "shield_arm": 40,
                   "leg_l_thigh": 26, "leg_l_shin": -20, "leg_r_thigh": -30, "leg_r_shin": -12, "cape": -4.0},
                  blend=30),
    # Dislocation: a reaching thrust as he steps through space.
    "dislocation": one_shot(
        [0, {}],
        [0.3, {"torso": -20, "head": -6, "arm_upper": 100, "arm_fore": -6, "sword": -30, "shield_arm": -20,
               "leg_l_thigh": 32, "leg_l_shin": -18, "leg_r_thigh": -28, "cape": -3.0}, "out"],
        [0.8, {"torso": -14, "arm_upper": 92, "arm_fore": -4, "sword": -26, "leg_l_thigh": 24, "leg_r_thigh": -20}],
        [1, {}], blend=30),
    # Absolute Rupture: both arms raised, tearing the air open.
    "absolute_rupture": one_shot(
        [0, {}],
        [0.25, {"torso": 6, "head": 14, "arm_upper": 165, "arm_fore": 15, "sword": 20, "shield_arm": 160,
                "cape": 4.0, "root_y": 0.08}, "out"],
        [0.85, {"torso": 8, "head": 16, "arm_upper": 172, "arm_fore": 20, "sword": 25, "shield_arm": 168,
                "cape": 5.0, "root_y": 0.12}],
        [1, {}], blend=30),
}

# ---- The Guardian Below (husk channels: arm_l, arm_r, torso, head, leg_l, leg_r) -----------------
G = {
    "telegraph_fist_slam": pose({"torso": 12, "head": 6, "arm_r": 168, "arm_l": 20, "leg_l": -6, "squash": 0.04}),
    "attack_fist_slam": pose({"torso": -24, "head": -8, "arm_r": 18, "arm_l": 10, "leg_l": 14, "leg_r": -10,
                              "root_y": -0.12, "squash": -0.06}, blend=30),
    "telegraph_backhand": pose({"torso": 16, "head": 4, "arm_l": -70, "arm_r": 30, "squash": 0.03}),
    "attack_backhand": pose({"torso": -16, "head": -6, "arm_l": 115, "arm_r": -10, "leg_l": 10}, blend=30),
    "telegraph_ground_pound": pose({"torso": 14, "head": 8, "arm_l": 172, "arm_r": 168, "leg_l": -6, "leg_r": 6,
                                    "squash": 0.05}),
    "attack_ground_pound": pose({"torso": -28, "head": -10, "arm_l": 12, "arm_r": 8, "leg_l": 16, "leg_r": -14,
                                 "root_y": -0.18, "squash": -0.08}, blend=28),
    "telegraph_seismic_wave": pose({"torso": 8, "head": 6, "arm_l": 140, "arm_r": 145, "squash": 0.04}),
    "attack_seismic_wave": pose({"torso": -22, "head": -8, "arm_l": 0, "arm_r": -4, "leg_l": 12, "root_y": -0.1,
                                 "squash": -0.06}, blend=30),
    # The chest laser: it leans back and opens its chest to the player.
    "telegraph_chest_laser": pose({"torso": -12, "head": 12, "arm_l": -35, "arm_r": -30, "squash": 0.02}),
    "attack_chest_laser": pose({"torso": -16, "head": 14, "arm_l": -45, "arm_r": -42, "leg_l": -6}),
    # The core: arms cross to gather, then fling open.
    "telegraph_core_shockwave": pose({"torso": 22, "head": -6, "arm_l": 70, "arm_r": 75, "squash": 0.06}),
    "attack_core_shockwave": pose({"torso": -18, "head": 10, "arm_l": -75, "arm_r": -70, "squash": -0.04}, blend=28),
    "telegraph_core_beam": pose({"torso": 10, "head": -4, "arm_l": 60, "arm_r": 62, "squash": 0.04}),
    "attack_core_beam": pose({"torso": -14, "head": 8, "arm_l": -65, "arm_r": -62}),
}

# ---- The Abyssal Leviathan (tail, tail_tip, body, neck, head) ------------------------------------
L = {
    "telegraph_tail_whip": pose({"tail": 34, "tail_tip": -34, "neck": -6, "head": -6, "squash": 0.03}),
    "attack_tail_whip": pose({"tail": -42, "tail_tip": 44, "neck": 6, "head": 4, "squash": -0.03}, blend=28),
    "telegraph_lunge_bite": pose({"neck": -24, "head": -28, "tail": 10, "tail_tip": -12, "squash": 0.05}),
    "attack_lunge_bite": pose({"neck": 28, "head": 26, "tail": -12, "tail_tip": 14, "squash": -0.06}, blend=28),
    "telegraph_blindside_bite": pose({"neck": -28, "head": -30, "tail": 12, "squash": 0.06}),
    "attack_blindside_bite": pose({"neck": 30, "head": 28, "tail": -14, "squash": -0.07}, blend=26),
    "telegraph_tidal_slam": pose({"neck": -32, "head": -12, "tail": 6, "root_y": 0.35, "squash": 0.04}),
    "attack_tidal_slam": pose({"neck": 32, "head": 22, "tail": -8, "root_y": -0.2, "squash": -0.07}, blend=28),
    "telegraph_abyss_slam": pose({"neck": -36, "head": -16, "tail": 10, "root_y": 0.45, "squash": 0.05}),
    "attack_abyss_slam": pose({"neck": 36, "head": 26, "tail": -10, "root_y": -0.25, "squash": -0.08}, blend=26),
    "telegraph_breaker_wave": pose({"neck": -8, "head": -6, "tail": 40, "tail_tip": -30}),
    "attack_breaker_wave": pose({"neck": 8, "head": 6, "tail": -40, "tail_tip": 36}, blend=30),
    # The roar and the sonar: the head lifts, the jaw to the dark.
    "telegraph_sonic_roar": pose({"neck": -8, "head": -24, "tail": 6, "squash": 0.04}),
    "attack_sonic_roar": pose({"neck": -16, "head": -40, "tail": 10, "tail_tip": -10, "squash": 0.07}),
    "telegraph_sonar_orbs": pose({"neck": 4, "head": -14, "tail": 4}),
    "attack_sonar_orbs": pose({"neck": 8, "head": 10, "tail": -4}),
    "telegraph_rift_beams": pose({"neck": -20, "head": -34, "tail": 14, "tail_tip": -14, "squash": 0.05}),
    "attack_rift_beams": pose({"neck": -22, "head": -38, "tail": 16, "tail_tip": -16, "squash": 0.06}),
}


def write(rig, clips):
    p = os.path.join(ROOT, "data", "art", "rigs", rig + ".json")
    raw = open(p, encoding="utf-8", newline="").read()
    d = json.loads(raw)
    d.setdefault("clips", {}).update(clips)
    out = json.dumps(d, indent=1, ensure_ascii=False).replace("\n", "\r\n")
    with open(p, "w", encoding="utf-8", newline="") as f:
        f.write(out)
    print("%s: %d clips written" % (rig, len(clips)))


write("darius", DARIUS)
write("ilyr", ILYR)
write("guardian_below", G)
write("abyssal_leviathan", L)
