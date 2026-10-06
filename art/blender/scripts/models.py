"""Farm Collect models built with lowpoly_kit (run inside Blender after the kit).

Only what the Kenney packs do not provide: the wheat bundle and the delivery truck.
Characters, animals, buildings, trees and the other items come from Kenney (see CREDITS.md).
"""


def build_wheat():
    cylinder(0.1, 0.22, (0, 0, 0.11), "yellow", vertices=8, radius_top=0.13)
    cylinder(0.125, 0.05, (0, 0, 0.13), "wood_dark", vertices=8)
    for i in range(6):
        angle = math.tau * i / 6
        x, y = math.cos(angle) * 0.07, math.sin(angle) * 0.07
        cylinder(0.035, 0.12, (x, y, 0.27), "yellow_light", vertices=5, radius_top=0.0,
                 rotation=(math.degrees(-y) * 2.5, math.degrees(x) * 2.5, 0))


def build_truck():
    box((1.6, 1.4, 1.15), (1.55, 0, 0.95), "yellow", bevel=0.08)
    box((0.06, 1.2, 0.45), (2.36, 0, 1.2), "glass")
    box((1.1, 0.06, 0.4), (1.45, -0.71, 1.25), "glass")
    box((1.1, 0.06, 0.4), (1.45, 0.71, 1.25), "glass")
    box((0.12, 1.45, 0.2), (2.38, 0, 0.55), "charcoal", bevel=0.03)
    box((0.06, 0.18, 0.12), (2.4, -0.5, 0.78), "yellow_light")
    box((0.06, 0.18, 0.12), (2.4, 0.5, 0.78), "yellow_light")
    box((2.5, 1.7, 0.25), (-0.4, 0, 0.5), "charcoal", bevel=0.03)
    box((2.45, 1.65, 0.12), (-0.4, 0, 0.68), "wood")
    for y in (-0.82, 0.82):
        box((2.45, 0.08, 0.4), (-0.4, y, 0.9), "red", bevel=0.02)
    box((0.08, 1.7, 0.4), (-1.62, 0, 0.9), "red", bevel=0.02)
    for x in (1.6, -0.9):
        for y in (-0.85, 0.85):
            cylinder(0.33, 0.24, (x, y, 0.33), "black", vertices=10, rotation=(90, 0, 0))
            cylinder(0.15, 0.26, (x, y, 0.33), "gray_light", vertices=8, rotation=(90, 0, 0))


MODELS = [
    ("Wheat", "assets/models/items/wheat.glb", build_wheat),
    ("Truck", "assets/models/props/truck.glb", build_truck),
]


def build_all(only=None):
    report = []
    for name, path, builder in MODELS:
        if only is None or name in only:
            report.append(build_and_export(name, path, builder))
    return report
