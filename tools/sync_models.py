"""Brings third-party (Kenney and KayKit, CC0) and own models into the shared-material setup.

Run from the repo root, around a Godot import (the .import files only exist after one):

    python tools/sync_models.py                      # copy models, write materials, patch imports
    godot --headless --import                        # import (creates .import files for new models)
    python tools/sync_models.py                      # patch the new .import files; clears stale caches
    godot --headless --import                        # re-import with the shared materials

What it does:
  1. Copies the models listed in KENNEY_SELECTION / KAYKIT_SELECTION from art/downloads/ (raw packs,
     not in git) into assets/models/kenney|kaykit/<pack>/, with the pack's texture and License.txt.
  2. Writes assets/materials/kenney_<pack>.tres / kaykit_<pack>.tres (nearest filter, flat roughness).
  3. Points every .glb/.gltf import at its shared material (palette.tres for our own models).
  4. Imports palette/colormap textures lossless (no VRAM compression: flat color swatches).
"""

import glob
import json
import os
import re
import shutil
import struct

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOWNLOADS = os.path.join(ROOT, "art", "downloads")
MODELS = os.path.join(ROOT, "assets", "models")
MATERIALS = os.path.join(ROOT, "assets", "materials")

KENNEY_SELECTION = {
    "mini-characters": [f"character-{g}-{l}" for g in ("female", "male") for l in "abcdef"],
    "cube-pets": ["animal-cow", "animal-chick"],
    "food-kit": ["egg", "carton-small", "corn"],
    "mini-forest": [
        "tent", "building-structure", "building-roof", "tree", "tree-high", "rocks-low", "rocks-high",
        "stones", "plant", "flag", "patch-grass", "fence",
    ],
    "mini-dungeon": ["table", "banner", "chest", "barrel", "coin", "pot", "chair", "column"],
    "mini-arena": ["tree", "trophy", "banner"],
}

# KayKit packs ship .gltf + .bin next to one texture: pack -> (extracted folder, texture file, names)
KAYKIT_SELECTION = {
    "hexagon": (
        "kaykit_hexagon/KayKit_Medieval_Hexagon_Pack_1.0_FREE",
        "hexagons_medieval.png",
        [
            "building_market_red", "building_market_yellow", "building_market_blue",
            "building_windmill_red", "building_well_red", "building_home_A_blue", "building_home_B_green",
            "building_scaffolding", "building_grain", "wheelbarrow", "sack", "crate_A_big", "crate_A_small",
            "barrel", "bucket_water", "bucket_empty", "flag_red", "pallet", "tree_single_A", "tree_single_B",
            "trees_A_small", "trees_B_small", "rock_single_A", "rock_single_B", "rock_single_C",
            "resource_lumber", "resource_stone",
        ],
    ),
    "forest": (
        "kaykit_forest/KayKit_Forest_Nature_Pack_1.0_FREE",
        "forest_texture.png",
        [
            "Tree_1_A_Color1", "Tree_2_A_Color1", "Tree_3_A_Color1", "Tree_4_A_Color1", "Bush_1_A_Color1",
            "Bush_2_A_Color1", "Bush_3_A_Color1", "Bush_4_A_Color1", "Rock_1_A_Color1", "Rock_2_A_Color1",
            "Rock_3_A_Color1", "Grass_1_A_Color1", "Grass_2_A_Color1",
        ],
    ),
}
OWN_MATERIALS = {"Palette": "res://assets/materials/palette.tres"}


def copy_kenney():
    copied = 0
    for pack, names in KENNEY_SELECTION.items():
        source_root = os.path.join(DOWNLOADS, f"kenney_{pack}")
        if not os.path.isdir(source_root):
            print(f"skip kenney {pack}: {source_root} not found (download it from kenney.nl)")
            continue
        target_root = os.path.join(MODELS, "kenney", pack)
        os.makedirs(os.path.join(target_root, "Textures"), exist_ok=True)
        glb_dir = os.path.join(source_root, "Models", "GLB format")
        shutil.copyfile(os.path.join(glb_dir, "Textures", "colormap.png"),
                        os.path.join(target_root, "Textures", "colormap.png"))
        shutil.copyfile(os.path.join(source_root, "License.txt"), os.path.join(target_root, "License.txt"))
        for name in names:
            shutil.copyfile(os.path.join(glb_dir, name + ".glb"), os.path.join(target_root, name + ".glb"))
            copied += 1
        write_pack_material("kenney", pack, f"res://assets/models/kenney/{pack}/Textures/colormap.png")
    print(f"copied {copied} kenney models")


def copy_kaykit():
    copied = 0
    for pack, (folder, texture_name, names) in KAYKIT_SELECTION.items():
        source_root = os.path.join(DOWNLOADS, *folder.split("/"))
        if not os.path.isdir(source_root):
            print(f"skip kaykit {pack}: {source_root} not found (extract the KayKit zip there)")
            continue
        target_root = os.path.join(MODELS, "kaykit", pack)
        os.makedirs(target_root, exist_ok=True)
        gltf_root = os.path.join(source_root, "Assets", "gltf")
        texture_source = glob.glob(os.path.join(source_root, "**", texture_name), recursive=True)[0]
        shutil.copyfile(texture_source, os.path.join(target_root, texture_name))
        shutil.copyfile(os.path.join(source_root, "License.txt"), os.path.join(target_root, "License.txt"))
        for name in names:
            found = glob.glob(os.path.join(gltf_root, "**", name + ".gltf"), recursive=True)
            if not found:
                raise SystemExit(f"kaykit {pack}: {name}.gltf not found under {gltf_root}")
            for extension in (".gltf", ".bin"):
                shutil.copyfile(found[0][:-5] + extension, os.path.join(target_root, name + extension))
            copied += 1
        write_pack_material("kaykit", pack, f"res://assets/models/kaykit/{pack}/{texture_name}")
    print(f"copied {copied} kaykit models")


def write_pack_material(brand, pack, texture):
    os.makedirs(MATERIALS, exist_ok=True)
    text = (
        '[gd_resource type="StandardMaterial3D" load_steps=2 format=3]\n\n'
        f'[ext_resource type="Texture2D" path="{texture}" id="1_texture"]\n\n'
        "[resource]\n"
        'albedo_texture = ExtResource("1_texture")\n'
        "roughness = 1.0\n"
        "metallic_specular = 0.0\n"
        "texture_filter = 0\n"
    )
    with open(os.path.join(MATERIALS, f"{brand}_{pack}.tres"), "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def model_json(path):
    """The glTF JSON of a .gltf (the file itself) or a .glb (its first chunk)."""
    if path.endswith(".gltf"):
        return json.load(open(path, encoding="utf-8"))
    data = open(path, "rb").read()
    length = struct.unpack("<I", data[8:12])[0]
    offset = 12
    while offset < length:
        chunk_len, chunk_type = struct.unpack("<II", data[offset:offset + 8])
        if chunk_type == 0x4E4F534A:
            return json.loads(data[offset + 8: offset + 8 + chunk_len])
        offset += 8 + chunk_len
    return {}


def model_material_name(path):
    materials = model_json(path).get("materials", [])
    return materials[0].get("name") if materials else None


def shared_material_for(model_path, material_name):
    rel = os.path.relpath(model_path, MODELS).replace("\\", "/")
    for brand in ("kenney", "kaykit"):
        if rel.startswith(brand + "/"):
            return f"res://assets/materials/{brand}_{rel.split('/')[1]}.tres"
    return OWN_MATERIALS.get(material_name)


def replace_subresources(text, block):
    lines = text.split("\n")
    for index, line in enumerate(lines):
        if line.startswith("_subresources="):
            depth = line.count("{") - line.count("}")
            end = index
            while depth > 0:
                end += 1
                depth += lines[end].count("{") - lines[end].count("}")
            return "\n".join(lines[:index] + block.split("\n") + lines[end + 1:])
    raise ValueError("no _subresources line")


def patch_model_imports():
    patched = 0
    patterns = ("*.glb.import", "*.gltf.import")
    import_paths = [p for pattern in patterns for p in glob.glob(os.path.join(MODELS, "**", pattern), recursive=True)]
    for import_path in import_paths:
        model_path = import_path[: -len(".import")]
        material_name = model_material_name(model_path)
        target = shared_material_for(model_path, material_name)
        if material_name is None or target is None:
            continue
        block = (
            "_subresources={\n\"materials\": {\n"
            f'"{material_name}": {{\n"use_external/enabled": true,\n"use_external/path": "{target}"\n}}\n'
            "}\n}"
        )
        text = open(import_path, encoding="utf-8").read()
        if f'"use_external/path": "{target}"' in text and f'"{material_name}"' in text:
            continue
        with open(import_path, "w", encoding="utf-8", newline="\n") as f:
            f.write(replace_subresources(text, block))
        for cached in glob.glob(os.path.join(ROOT, ".godot", "imported", os.path.basename(model_path) + "-*")):
            os.remove(cached)
        patched += 1
    print(f"patched {patched} model imports")


def patch_texture_imports():
    patched = 0
    paths = glob.glob(os.path.join(MODELS, "kenney", "*", "Textures", "colormap.png.import"))
    for pack, (_, texture_name, _) in KAYKIT_SELECTION.items():
        paths.append(os.path.join(MODELS, "kaykit", pack, texture_name + ".import"))
    paths.append(os.path.join(ROOT, "assets", "textures", "palette.png.import"))
    for import_path in paths:
        if not os.path.exists(import_path):
            continue
        text = open(import_path, encoding="utf-8").read()
        new = re.sub(r"^compress/mode=\d+", "compress/mode=0", text, flags=re.M)
        new = re.sub(r"^detect_3d/compress_to=\d+", "detect_3d/compress_to=0", new, flags=re.M)
        if new != text:
            with open(import_path, "w", encoding="utf-8", newline="\n") as f:
                f.write(new)
            cached_name = os.path.basename(import_path)[: -len(".import")]
            for cached in glob.glob(os.path.join(ROOT, ".godot", "imported", cached_name + "-*")):
                os.remove(cached)
            patched += 1
    print(f"patched {patched} texture imports")


if __name__ == "__main__":
    copy_kenney()
    copy_kaykit()
    patch_model_imports()
    patch_texture_imports()
