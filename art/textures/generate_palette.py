"""Generates assets/textures/palette.png: one 32x32 swatch per color (8 columns, rows as needed).

Every low-poly model maps its faces onto these swatches, so the whole game can share one
material (docs/06-arte-e-audio.md). Add colors at the end; never reorder (UVs point at cells).
Run from the repo root: python art/textures/generate_palette.py
"""

from pathlib import Path

from PIL import Image

CELL = 32
GRID = 8
OUT = Path(__file__).resolve().parents[2] / "assets" / "textures" / "palette.png"

COLORS = [
    "7CC456", "5FA83F", "4C8A33", "93D16A",  # grass
    "E3A65C", "C98545", "A86A35", "F2C98A",  # dirt / sand
    "B5713A", "8A5129", "6B4226", "D9A066",  # wood
    "5E6670", "3F444B", "9AA3AD", "DCE1E6",  # asphalt / metal
    "3FD3F2", "2A9FBF", "BDF2FB", "1E6F86",  # cyan UI / water
    "3DBA4E", "2A8A38", "A8E6B0", "1D5E27",  # money green
    "E5483B", "B8352A", "F28B82", "7A2018",  # red
    "F7C531", "D9A41C", "FBE38A", "A67A12",  # yellow
    "F6F1E4", "E8DFC8", "FFFFFF", "C9C2B2",  # white / egg / milk
    "FFCBA4", "E8A57E", "B9785A", "7A4A35",  # skin tones
    "3F7FD9", "2B5BA6", "8DB8F2", "1C3C70",  # blue overalls
    "F28C38", "C76A1E", "F9C08C", "8A4512",  # orange
    "222326", "45474D", "6E7078", "9A9CA3",  # black / gray
    "B06BE0", "8344B0", "D9B3F2", "5A2A80",  # purple
    "F2A7C3", "D97A9E", "FAD3E1", "A04A6A",  # pink (pigs, noses)
    "87CEEB", "5FA9C9", "C4E8F5", "3A7A99",  # sky
    "E8D08A", "C9AE62", "F5E6B3", "9C8440",  # straw
    "B8A27A", "8F7B58", "D6C6A3", "655539",  # khaki
    "5B7DB1", "3F5C8C", "8FAAD1", "2B4066",  # denim
    "6B4A2F", "4A3220", "8C6542", "2E1F14",  # hair
    "E6C16A", "C29B45", "F2DB94", "8E6D26",  # hair
    "C8602B", "9B4520", "E58D55", "6B2D12",  # hair
    "3FB3A6", "2A8479", "8EDDD3", "1B5850",  # teal
    "A3C46B", "7A9A47", "C9E08F", "56702F",  # lime
]


def main():
    rows = -(-len(COLORS) // GRID)
    image = Image.new("RGB", (CELL * GRID, CELL * rows), "#ff00ff")
    for index, color in enumerate(COLORS):
        x, y = index % GRID, index // GRID
        image.paste("#" + color, (x * CELL, y * CELL, (x + 1) * CELL, (y + 1) * CELL))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUT)
    print("written", OUT, len(COLORS), "colors")


if __name__ == "__main__":
    main()
