#!/usr/bin/env python3
"""Build crisp runtime frames from the illustrated atlas. python sprite.py [preview.png]."""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
PETS = ("cat", "squidward", "darth-revan", "the-witcher", "omniman", "whiplash", "anti-sergio", "hollow-knight", "gordon-freeman", "silksong", "zombie", "ornstein-smough", "creeper", "grand-admiral-thrawn", "jak-and-daxter")
FRAMES = ("idle", "blink", "tail-out", "tail-over", "ear")
PET_FRAMES = {pet: FRAMES for pet in PETS}
PET_FRAMES["whiplash"] = ("idle", "blink", "windup", "lift", "release", "flight", "follow-through", "recover")
SQUIDWARD_GAG = tuple(f"machine-{i:02}" for i in range(1, 21))
PET_FRAMES["squidward"] = (*FRAMES, *SQUIDWARD_GAG)
PET_FRAMES["anti-sergio"] = (*FRAMES, "dog-arrive", "dog-pet", "dog-leave")
CREEPER_GAG = ("charge", "charged", "explode", "smoke")
PET_FRAMES["creeper"] = (*FRAMES, *CREEPER_GAG)
WIDTH, HEIGHT, BASELINE = 40, 48, 46
DIMENSIONS = {pet: (WIDTH, HEIGHT, BASELINE) for pet in PETS}
DIMENSIONS["whiplash"] = DIMENSIONS["anti-sergio"] = DIMENSIONS["squidward"] = DIMENSIONS["ornstein-smough"] = (64, 64, 62)
GAG_DIMENSIONS = (96, 80, 78)
SCALE, GAP, LABEL = 6, 20, 100


def remove_specks(cell):
    """Drop tiny detached generation artifacts before they can move the baseline."""
    mask = cell.getchannel("A")
    pixels = mask.load()
    remaining = {(x, y) for y in range(cell.height) for x in range(cell.width) if pixels[x, y]}
    while remaining:
        component = [remaining.pop()]
        for x, y in component:
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                neighbor = (x + dx, y + dy)
                if neighbor in remaining:
                    remaining.remove(neighbor)
                    component.append(neighbor)
        if len(component) < 256:
            for point in component:
                pixels[point] = 0
    cell.putalpha(mask)


def dimensions(pet, name):
    return GAG_DIMENSIONS if pet == "squidward" and name in SQUIDWARD_GAG else DIMENSIONS[pet]


def generate():
    """Use one scale and palette per character and anchor every pose at its feet."""
    manifest = json.loads((ROOT / "zeron-plugin.json").read_text())
    options = next(s["options"] for s in manifest["settings"] if s["id"] == "pet")
    assert {option["value"] for option in options} == set(PETS) | {"random"}, "Pet settings and artwork differ"
    sprites = {}
    groups = []
    for pet in PETS:
        names = FRAMES if pet in ("squidward", "creeper", "grand-admiral-thrawn") else PET_FRAMES[pet]
        layout = (4, len(names) // 4) if len(names) > 5 else (5, 1)
        groups.append((pet, names, "atlas.png", layout, DIMENSIONS[pet]))
        if pet == "creeper":
            groups.append((pet, CREEPER_GAG, "explosion-atlas.png", (4, 1), DIMENSIONS[pet]))
        if pet == "squidward":
            groups.append((pet, SQUIDWARD_GAG, "machine-atlas.png", (4, 5), GAG_DIMENSIONS))
    for pet, names, filename, (columns, rows), (width, height, baseline) in groups:
        with Image.open(Path(__file__).parent / pet / filename) as source:
            atlas = source.convert("RGBA")
        cell_w, cell_h = (atlas.width + columns - 1) // columns, (atlas.height + rows - 1) // rows
        cells = []
        for index in range(len(names)):
            col, row = index % columns, index // columns
            cell = atlas.crop((col * atlas.width // columns, row * atlas.height // rows,
                               (col + 1) * atlas.width // columns, (row + 1) * atlas.height // rows))
            # Discard the generated soft fringe; runtime pixels are fully opaque or transparent.
            cell.putalpha(cell.getchannel("A").point(lambda a: 255 if a >= 192 else 0))
            if filename == "machine-atlas.png":
                remove_specks(cell)
            bounds = cell.getbbox()
            assert bounds, (pet, col, "empty source cell")
            cells.append(cell if pet in ("whiplash", "anti-sergio", "squidward", "ornstein-smough") else cell.crop(bounds))
        if pet in ("whiplash", "anti-sergio", "squidward", "ornstein-smough"):
            # Preserve horizontal space for props and companions without shifting the character.
            bounds = [cell.getbbox() for cell in cells]
            left, right = min(b[0] for b in bounds), max(b[2] for b in bounds)
            source_height = max(b[3] - b[1] for b in bounds)
            cells = [cell.crop((left, b[3] - source_height, right, b[3]))
                     for cell, b in zip(cells, bounds)]
        ratio = min((width - 2) / max(c.width for c in cells),
                    (height - 4) / max(c.height for c in cells))
        # A shared compact palette prevents color drift between animation poses.
        strip = Image.new("RGB", (cell_w * len(cells), cell_h), "#211b28")
        for col, cell in enumerate(cells):
            strip.paste(cell, (col * cell_w, 0), cell)
        palette = strip.quantize(colors=48, method=Image.Quantize.MEDIANCUT)
        for name, cell in zip(names, cells):
            frame_ratio = ratio
            if pet == "creeper" and name in ("charge", "charged"):
                idle_bounds = sprites["creeper/idle"].getbbox()
                frame_ratio = (idle_bounds[3] - idle_bounds[1]) / cell.height
            size = (max(1, round(cell.width * frame_ratio)), max(1, round(cell.height * frame_ratio)))
            small = cell.resize(size, Image.Resampling.NEAREST)
            alpha = small.getchannel("A")
            small = small.convert("RGB").quantize(palette=palette, dither=Image.Dither.NONE).convert("RGBA")
            small.putalpha(alpha)
            im = Image.new("RGBA", (width, height))
            im.alpha_composite(small, ((width - small.width) // 2, baseline + 1 - small.height))
            assert im.getbbox()[3] == baseline + 1, (pet, name, "baseline")
            assert set(im.getchannel("A").tobytes()) <= {0, 255}
            assert len(im.convert("RGB").getcolors(256)) <= 49
            sprites[f"{pet}/{name}"] = im
        assert len({sprites[f"{pet}/{name}"].tobytes() for name in names}) == len(names), pet
    return sprites


def preview(sprites, path):
    """Show every runtime pixel enlarged without filtering."""
    cell_w = max(im.width for im in sprites.values()) * SCALE + GAP
    cell_h = max(im.height for im in sprites.values()) * SCALE + GAP
    sheet = Image.new("RGBA", (LABEL + cell_w * max(map(len, PET_FRAMES.values())), GAP + cell_h * len(PETS)),
                      (40, 40, 46, 255))
    draw = ImageDraw.Draw(sheet)
    for row, pet in enumerate(PETS):
        draw.text((4, GAP + row * cell_h), pet, fill="white")
        for col, name in enumerate(PET_FRAMES[pet]):
            x, y = LABEL + col * cell_w, GAP + row * cell_h
            draw.text((x, y - 15), name, fill="white")
            enlarged = sprites[f"{pet}/{name}"].resize((sprites[f"{pet}/{name}"].width * SCALE, sprites[f"{pet}/{name}"].height * SCALE),
                                                       Image.Resampling.NEAREST)
            sheet.alpha_composite(enlarged, (x, y))
    sheet.save(path)


def main():
    sprites = generate()
    art = ROOT / "art"
    art.mkdir(exist_ok=True)
    for name, im in sprites.items():
        path = art / f"{name}.png"
        path.parent.mkdir(exist_ok=True)
        im.save(path)
    if len(sys.argv) > 1:
        preview(sprites, sys.argv[1])


if __name__ == "__main__":
    main()
