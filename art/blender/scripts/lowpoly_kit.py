"""Low-poly modeling kit for Farm Collect (run inside Blender).

Every part is a simple primitive whose faces all point at one swatch of
assets/textures/palette.png, so each finished model has ONE mesh and ONE material.
Blender axes: Z up, model front faces -Y (glTF export turns that into Godot's +Z).
Units: meters, feet at z = 0, centered on the origin.
"""

import math
import os

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

PROJECT = r"D:\DEV\Farm-collect"
PALETTE_PATH = os.path.join(PROJECT, "assets", "textures", "palette.png")
GRID = 8

# Must follow the order in art/textures/generate_palette.py.
COLOR_NAMES = [
    "grass", "grass_dark", "grass_deep", "grass_light",
    "dirt", "dirt_dark", "dirt_deep", "sand",
    "wood", "wood_dark", "wood_deep", "wood_light",
    "asphalt", "asphalt_dark", "metal", "metal_light",
    "cyan", "cyan_dark", "glass", "cyan_deep",
    "money", "money_dark", "money_light", "money_deep",
    "red", "red_dark", "red_light", "red_deep",
    "yellow", "yellow_dark", "yellow_light", "yellow_deep",
    "cream", "cream_dark", "white", "gray_warm",
    "skin", "skin_tan", "skin_brown", "skin_dark",
    "blue", "blue_dark", "blue_light", "blue_deep",
    "orange", "orange_dark", "orange_light", "orange_deep",
    "black", "charcoal", "gray", "gray_light",
    "purple", "purple_dark", "purple_light", "purple_deep",
    "pink", "pink_dark", "pink_light", "pink_deep",
    "sky", "sky_dark", "sky_light", "sky_deep",
    "straw", "straw_dark", "straw_light", "straw_deep",
    "khaki", "khaki_dark", "khaki_light", "khaki_deep",
    "denim", "denim_dark", "denim_light", "denim_deep",
    "hair_brown", "hair_brown_dark", "hair_brown_light", "hair_black",
    "hair_blond", "hair_blond_dark", "hair_blond_light", "hair_blond_deep",
    "hair_ginger", "hair_ginger_dark", "hair_ginger_light", "hair_ginger_deep",
    "teal", "teal_dark", "teal_light", "teal_deep",
    "lime", "lime_dark", "lime_light", "lime_deep",
]
COLORS = {name: index for index, name in enumerate(COLOR_NAMES)}
ROWS = -(-len(COLOR_NAMES) // GRID)

_parts = []


def reset():
    """Empties the scene and the part list."""
    global _parts
    _parts = []
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for mesh in list(bpy.data.meshes):
        if mesh.users == 0:
            bpy.data.meshes.remove(mesh)
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)
    for armature in list(bpy.data.armatures):
        if armature.users == 0:
            bpy.data.armatures.remove(armature)


def palette_material():
    material = bpy.data.materials.get("Palette")
    if material is not None:
        return material
    material = bpy.data.materials.new("Palette")
    material.use_nodes = True
    nodes = material.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 1.0
    bsdf.inputs["Metallic"].default_value = 0.0
    image_node = nodes.new("ShaderNodeTexImage")
    image_node.image = bpy.data.images.load(PALETTE_PATH, check_existing=True)
    image_node.interpolation = "Closest"
    material.node_tree.links.new(image_node.outputs["Color"], bsdf.inputs["Base Color"])
    return material


def _uv_for(color):
    index = COLORS[color]
    return ((index % GRID + 0.5) / GRID, 1.0 - (index // GRID + 0.5) / ROWS)


def _register(obj, color, location, rotation, scale):
    matrix = (
        Matrix.Translation(Vector(location))
        @ Euler([math.radians(a) for a in rotation]).to_matrix().to_4x4()
        @ Matrix.Diagonal((*scale, 1.0))
    )
    obj.data.transform(matrix)
    obj.matrix_basis = Matrix.Identity(4)
    uv_layer = obj.data.uv_layers.active or obj.data.uv_layers.new(name="UVMap")
    u, v = _uv_for(color)
    for loop_uv in uv_layer.data:
        loop_uv.uv = (u, v)
    for polygon in obj.data.polygons:
        polygon.use_smooth = False
    obj.data.materials.clear()
    obj.data.materials.append(palette_material())
    _parts.append(obj)
    return obj


def _bevel(obj, amount):
    if amount <= 0.0:
        return
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.bevel(
        bm, geom=list(bm.edges), offset=amount, offset_type="OFFSET",
        segments=1, profile=0.5, affect="EDGES",
    )
    bm.to_mesh(obj.data)
    bm.free()


def box(size, location, color, rotation=(0, 0, 0), bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    obj = bpy.context.active_object
    obj.data.transform(Matrix.Diagonal((*size, 1.0)))
    _bevel(obj, bevel)
    return _register(obj, color, location, rotation, (1, 1, 1))


def cylinder(radius, depth, location, color, vertices=8, radius_top=None, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices, radius1=radius,
        radius2=radius if radius_top is None else radius_top, depth=depth,
    )
    return _register(bpy.context.active_object, color, location, rotation, (1, 1, 1))


def sphere(radius, location, color, scale=(1, 1, 1), segments=8, rings=6, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=radius)
    return _register(bpy.context.active_object, color, location, rotation, scale)


def blob(radius, location, color, scale=(1, 1, 1)):
    """Faceted icosphere: foliage, bushes, puffy shapes."""
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=radius)
    return _register(bpy.context.active_object, color, location, (0, 0, 0), scale)


def wedge(width, depth, height, location, color, rotation=(0, 0, 0)):
    """Triangular prism with the ridge along X (roofs). Base centered at `location`."""
    mesh = bpy.data.meshes.new("wedge")
    w, d = width / 2.0, depth / 2.0
    verts = [(-w, -d, 0), (w, -d, 0), (w, d, 0), (-w, d, 0), (-w, 0, height), (w, 0, height)]
    faces = [(0, 1, 2, 3), (0, 4, 5, 1), (3, 2, 5, 4), (0, 3, 4), (1, 5, 2)]
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new("wedge", mesh)
    bpy.context.collection.objects.link(obj)
    return _register(obj, color, location, rotation, (1, 1, 1))


def finish(name):
    """Joins every part created since reset() into one object called `name`."""
    bpy.ops.object.select_all(action="DESELECT")
    for part in _parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = _parts[0]
    bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = name
    obj.data.name = name
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    return obj


def export(obj, relative_path):
    path = os.path.join(PROJECT, relative_path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=path, export_format="GLB", use_selection=True, export_apply=True,
        export_yup=True, export_materials="EXPORT", export_texcoords=True, export_normals=True,
        # The palette is NOT embedded: Godot applies one shared material (assets/materials/palette.tres).
        export_image_format="NONE",
    )
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    return f"{relative_path}: {tris} tris"


def build_and_export(name, relative_path, builder):
    reset()
    builder()
    obj = finish(name)
    return export(obj, relative_path)
