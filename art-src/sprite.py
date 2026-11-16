#!/usr/bin/env python3
"""Zeron Pets' cat sprites, placed by hand: a 28x24 grid, one character a
pixel, frames as small changes to the idle frame. Writes art/cat-<frame>.png
(1x, palette colours, alpha 0 or 255: no smoothing anywhere).

    python3 sprite.py [preview.png]
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw

PALETTE = {
    ".": None,
    "o": (27, 26, 31),     # outline
    "b": (220, 201, 168),  # cream body
    "h": (244, 228, 199),  # light on the left
    "d": (185, 160, 126),  # shade on the right
    "w": (239, 220, 187),  # muzzle and chest
    "m": (78, 55, 45),     # seal points: face, ears, paws and tail
    "i": (158, 113, 105),  # inside the ears
    "e": (104, 192, 245),  # blue eyes
    "n": (224, 154, 166),  # nose
}

IDLE = [
    "............................",
    "....o........o..............",
    "...obo......obo.............",
    "...oibo....obio.............",
    "..obiiboooobiibo............",
    "..obbbbbbbbbbbbo............",
    ".ohbbbbbbbbbbbbdo...........",
    ".ohbbeobbbboebbdo...........",
    ".ohbbeobbbboebbdo...........",
    ".ohbbbwwnnwwbbbdo...........",
    "..obbbwwwwwwbbdo............",
    "...oobbbbbbbboo.............",
    "...ohbbbbbbbbdo.............",
    "..ohbbbwwwwbbbdo............",
    "..ohbbwwwwwwbbdo............",
    ".ohbbbbwwwwwwbbdo...........",
    ".ohbbbbbwwwwbbbdo...........",
    "ohbbbbbbbwwbbbbbdo..........",
    "ohbbbbbbbbbbbbbbdo..........",
    "ohbbbbbbbbbbbbbbdo..........",
    "ohbbwwwwbbwwwwbbdo..........",
    "oobbwwwwoowwwwbboo..........",
    ".oooooooooooooooo...........",
    "............................",
]

# The tail, from behind the right haunch, curling up: each frame's cells
# (x, y, colour) drawn over the body's right (behind the haunch's outline).
def tail(path):
    """A tiny seal-brown tail, two pixels thick and outlined."""
    body = []
    for (x, y) in path:
        body += [(x, y), (x + 1, y)]
    cells = {}
    for (x, y) in body:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                cells.setdefault((x + dx, y + dy), "o")
    for (x, y) in body:
        cells[(x, y)] = "m"
    return cells

TAILS = {
    "rest": [(18, 20), (19, 19), (19, 18)],
    "out": [(18, 20), (19, 20), (20, 19)],
    "over": [(18, 20), (18, 19), (18, 18)],
}

def frame(eyes="open", tail_at="rest", ear="up"):
    g = [list(r) for r in IDLE]
    assert all(len(r) == 28 for r in g) and len(g) == 24
    # The tail behind the body: only where nothing of the body is.
    for (x, y), c in tail(TAILS[tail_at]).items():
        if 0 <= x < 28 and 0 <= y < 24 and g[y][x] == ".":
            g[y][x] = c
    if eyes == "shut":
        for y in (7, 8):
            for x in (5, 6, 11, 12):
                g[y][x] = "b"
        for x in (5, 6, 11, 12):
            g[8][x] = "o"
    if ear == "twitch":
        # the right ear flicks flat, out to the side
        for x in (12, 13, 14):
            g[1][x] = "."
        for x, c in zip(range(11, 16), ".oooo"):
            g[2][x] = c
        for x, c in zip(range(11, 17), "obibbo"):
            g[3][x] = c
    for y, row in enumerate(g):
        for x, c in enumerate(row):
            if (y <= 11 and c in "bhd") or (y in (20, 21) and c == "w"):
                g[y][x] = "m"
    return g

FRAMES = {
    "idle": frame(),
    "blink": frame(eyes="shut"),
    "tail-out": frame(tail_at="out"),
    "tail-over": frame(tail_at="over"),
    "ear": frame(ear="twitch"),
}

assert all(len(path) == 3 for path in TAILS.values())
assert all(g[7][5] == "e" for name, g in FRAMES.items() if name != "blink")
assert FRAMES["blink"][8][5] == "o"
assert all(g[17][5] == "b" and g[20][4] == "m" for g in FRAMES.values())

COATS = {
    "cat": {},
    "ginger": {"b": (218, 142, 57), "h": (248, 184, 88), "d": (174, 101, 41), "m": (218, 142, 57), "e": (99, 161, 94)},
    "black": {"b": (49, 49, 60), "h": (76, 76, 88), "d": (37, 37, 46), "m": (49, 49, 60), "w": (102, 102, 116), "e": (239, 199, 85)},
    "silver": {"b": (165, 175, 188), "h": (205, 215, 225), "d": (120, 132, 150), "m": (165, 175, 188), "w": (225, 231, 238), "e": (107, 184, 124)},
}

def image(g, coat="cat"):
    im = Image.new("RGBA", (28, 24), (0, 0, 0, 0))
    for y, row in enumerate(g):
        for x, c in enumerate(row):
            col = COATS[coat].get(c, PALETTE[c])
            if col:
                im.putpixel((x, y), col + (255,))
    return im

def character(pet, pose):
    """Hand-drawn characters on the same grid and baseline as the cats."""
    im = Image.new("RGBA", (28, 24))
    d = ImageDraw.Draw(im)
    ink, skin, white = "#252530", "#dfb091", "#e9e8dd"
    blink = pose == "blink"
    # Shared frame names keep the runtime animation and reduced motion unchanged.
    hand_y = {"tail-out": 12, "tail-over": 9, "ear": 14}.get(pose, 16)
    if pet == "squidward":
        teal, shade, edge = "#a5c9be", "#729f96", "#345b58"
        # His oversized dome and drooping nose carry the silhouette at 2x.
        d.ellipse((6, 0, 21, 10), fill=edge)
        d.ellipse((7, 1, 20, 10), fill=teal)
        for xy in ((10, 3), (13, 2), (17, 3)):
            d.point(xy, fill=shade)
        d.rectangle((11, 12, 16, 16), fill=edge)
        d.rectangle((12, 12, 15, 16), fill=teal)
        d.polygon([(9, 15), (18, 15), (20, 18), (17, 18),
                   (17, 19), (10, 19), (10, 18), (7, 18)],
                  fill="#a5743f", outline=edge)
        d.line((11, 15, 13, 17, 16, 15), fill="#e0b375")
        for x, tip in ((10, 6), (15, 20)):
            d.line((x, 20, x, 21, tip, 21), fill=edge, width=3)
            d.line((x, 20, x, 21, tip, 21), fill=teal)
        d.line((8, 17, 5, hand_y, 3, hand_y), fill=edge, width=3)
        d.line((8, 17, 5, hand_y, 3, hand_y), fill=teal)
        d.line((19, 17, 21, 19, 19, 20), fill=edge, width=3)
        d.line((19, 17, 21, 19, 19, 20), fill=teal)
        d.ellipse((7, 10, 20, 14), fill=edge)
        d.rectangle((8, 10, 19, 12), fill=teal)
        d.line((9, 12, 18, 12), fill=edge)
        for x in (8, 14):
            d.ellipse((x, 5, x+5, 10), fill=edge)
            d.ellipse((x+1, 5, x+4, 9), fill="#f1e7b0")
            d.rectangle((x+1, 5, x+4, 7), fill=shade)
            d.line((x+1, 7, x+4, 7), fill=edge)
            if blink:
                d.rectangle((x+1, 8, x+4, 9), fill=teal)
            else:
                d.line((x+3, 8, x+3, 9), fill="#993e30")
        d.ellipse((12, 8, 16, 14), fill=edge)
        d.ellipse((12, 8, 15, 13), fill=teal)
        d.line((15, 10, 15, 12), fill=shade)
    else:
        # Boots, seated legs, torso, and one gesturing arm.
        suit = {"darth-revan": "#453743", "the-witcher": "#555962",
                "omniman": "#ededdf", "whiplash": "#202027"}[pet]
        d.rectangle((8, 12, 19, 20), fill=suit, outline=ink)
        for x in (8, 15):
            d.rectangle((x, 20, x+4, 22), fill=ink)
        d.line((8, 14, 5, hand_y), fill=suit, width=3)
        d.rectangle((4, hand_y-1, 6, hand_y+1), fill=skin)
        d.rectangle((19, 14, 21, 19), fill=suit)
        d.rectangle((9, 3, 18, 11), fill=skin, outline=ink)
        eye_y = 7
        if pet == "darth-revan":
            d.polygon([(7, 12), (7, 4), (10, 1), (17, 1), (20, 4), (20, 13)], fill=ink)
            d.rectangle((10, 4, 17, 10), fill="#9f9b92")
            d.rectangle((10, 6, 17, 7), fill="#882a40")
            d.rectangle((13, 7, 14, 11), fill="#882a40")
            d.line((10, 5, 17, 5), fill=white)
            d.polygon([(8, 12), (11, 13), (10, 21), (6, 21)], fill="#773240")
            d.rectangle((12, 14, 16, 15), fill="#aca093")
            # Red lightsaber held outside the silhouette.
            d.line((23, 6 if pose == "tail-over" else 9, 23, 18), fill="#ff536b", width=2)
            d.line((23, 19, 23, 21), fill="#9999aa", width=2)
            if blink:
                d.line((10, 6, 17, 6), fill=ink)
        elif pet == "the-witcher":
            d.rectangle((8, 2, 19, 5), fill=white)
            d.rectangle((8, 5, 9, 11), fill="#b5b7b5")
            d.rectangle((18, 5, 19, 13), fill="#b5b7b5")
            d.line((11, 10, 16, 10), fill="#9b8678")
            d.line((16, 5, 15, 9), fill="#ad655d")
            d.line((9, 13, 18, 19), fill="#9d7b56", width=2)
            d.point((14, 15), fill=white)
            d.line((21, 5, 21, 20), fill="#b8c6d3")
            d.line((19, 13, 23, 13), fill=ink)
        elif pet == "omniman":
            d.polygon([(7, 12), (20, 12), (24, 21), (5, 21)], fill="#b82b3c")
            d.rectangle((9, 12, 18, 19), fill=white)
            d.ellipse((12, 13, 16, 17), outline="#bc3041", width=2)
            d.rectangle((9, 2, 18, 4), fill="#45434a")
            d.rectangle((8, 4, 9, 7), fill="#adaeb2")
            d.rectangle((18, 4, 19, 7), fill="#adaeb2")
            d.line((11, 9, 16, 9), fill="#45434a", width=2)
            d.rectangle((9, 19, 18, 20), fill="#bc3041")
        else:  # Fletcher, displayed as Whiplash.
            d.line((10, 4, 17, 4), fill="#edc7a4")
            d.line((10, 8, 12, 8), fill="#a77765")
            d.line((15, 8, 17, 8), fill="#a77765")
            d.line((12, 10, 15, 10), fill=ink)
            d.polygon([(12, 12), (15, 12), (14, 15)], fill=skin)
            d.line((5, hand_y, 2, hand_y-5), fill="#d8b67f")
            d.line((21, 17, 24, 11), fill="#d8b67f")
            d.ellipse((9, 18, 20, 22), fill="#717783", outline=ink)
            d.line((10, 19, 19, 19), fill=white)
        if pet != "darth-revan":
            for x in (11, 15):
                d.line((x, eye_y, x+1 if blink else x, eye_y),
                       fill="#e2ba4d" if pet == "the-witcher" and not blink else ink)
    return im


art = Path(__file__).resolve().parent.parent / "art"
art.mkdir(exist_ok=True)
for coat in COATS:
    for name, g in FRAMES.items():
        im = image(g, coat)
        assert im.size == (28, 24) and im.getpixel((0, 0))[3] == 0
        im.save(art / f"{coat}-{name}.png")
for pet in ("squidward", "darth-revan", "the-witcher", "omniman", "whiplash"):
    frames = {name: character(pet, name) for name in FRAMES}
    assert frames["idle"].tobytes() != frames["blink"].tobytes(), pet
    assert frames["idle"].tobytes() != frames["tail-out"].tobytes(), pet
    for name, im in frames.items():
        assert im.size == (28, 24) and im.getbbox()[3] <= 23
        im.save(art / f"{pet}-{name}.png")
images = {name: image(g) for name, g in FRAMES.items()}
if len(sys.argv) > 1:
    k = 10
    sheet = Image.new("RGBA", ((28 * k + 20) * len(images) + 20, 24 * k + 40), (40, 40, 46, 255))
    for i, (name, im) in enumerate(images.items()):
        sheet.paste(im.resize((28 * k, 24 * k), Image.NEAREST), (20 + i * (28 * k + 20), 20), im.resize((28 * k, 24 * k), Image.NEAREST))
    sheet.save(sys.argv[1])
