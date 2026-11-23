"""Run with PYTHONDONTWRITEBYTECODE=1 python art-src/test_sprite.py."""
import importlib.util
import re
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image


class SpriteTests(unittest.TestCase):
    def load_generator(self):
        spec = importlib.util.spec_from_file_location("sprite", Path(__file__).with_name("sprite.py"))
        module = importlib.util.module_from_spec(spec)
        with patch.object(Image.Image, "save", side_effect=AssertionError("Import wrote an image")), \
             patch.object(Path, "mkdir", side_effect=AssertionError("Import created a directory")):
            spec.loader.exec_module(module)
        return module

    def test_frames_match_committed_art_and_are_deterministic(self):
        sprite = self.load_generator()
        frames = sprite.generate()
        again = sprite.generate()
        self.assertEqual(len(frames), 193)
        for name, im in frames.items():
            with self.subTest(frame=name), Image.open(sprite.ROOT / "art" / f"{name}.png") as saved:
                self.assertEqual(im.tobytes(), saved.convert("RGBA").tobytes())
                self.assertEqual(im.tobytes(), again[name].tobytes())

    def test_runtime_grid_and_all_frame_bounds(self):
        sprite = self.load_generator()
        runtime = (sprite.ROOT / "init.luau").read_text()
        grid = re.search(r"local GRID_W, GRID_H, PIXEL = (\d+), (\d+), (\d+)", runtime)
        self.assertIsNotNone(grid)
        self.assertEqual(tuple(map(int, grid.groups())), (sprite.WIDTH, sprite.HEIGHT, 2))
        self.assertIn(f"local FOOT = {sprite.BASELINE} * PIXEL", runtime)
        for name, im in sprite.generate().items():
            with self.subTest(frame=name):
                width, height, baseline = sprite.dimensions(*name.split("/"))
                self.assertEqual(im.size, (width, height))
                self.assertEqual(im.getbbox()[3], baseline + 1)
                self.assertLessEqual(set(im.getchannel("A").tobytes()), {0, 255})

    def test_idle_characters_fill_their_runtime_frames(self):
        sprite = self.load_generator()
        frames = sprite.generate()
        for pet in sprite.PETS:
            with self.subTest(pet=pet):
                bounds = frames[f"{pet}/idle"].getbbox()
                self.assertGreaterEqual(bounds[3] - bounds[1], 53)

    def test_runtime_motion_frames_exist_in_character_folders(self):
        sprite = self.load_generator()
        runtime = (sprite.ROOT / "init.luau").read_text()
        self.assertIn("local WIDE_W = 96", runtime)
        self.assertIn("art/{pet}/{name}.png", runtime)
        self.assertEqual(list((sprite.ROOT / "art").glob("*.png")), [])
        for motion in ("BLINK", "FLICK", "TWITCH", "THROW", "DOG", "DESTROY", "EXPLODE", "CART", "ASSASSINATE", "RELIC", "CAR_THEFT", "HEIST", "MILK"):
            body = re.search(rf"local {motion} = (.*?)(?=\n--|\nlocal)", runtime, re.S).group(1)
            names = re.findall(r'\{ "([^" ]+)", \d+ \}', body)
            self.assertTrue(names)
            pets = {"MILK": ("otis",), "CART": ("bergamini-cow",), "THROW": ("whiplash",), "DOG": ("anti-sergio",), "DESTROY": ("squidward",), "EXPLODE": ("creeper",), "ASSASSINATE": ("ezio",), "RELIC": ("lara-croft",), "CAR_THEFT": ("jason-duval",), "HEIST": ("lucia-caminos",)}.get(motion, sprite.PETS)
            for pet in pets:
                if pet == "whiplash" and motion in ("FLICK", "TWITCH"):
                    continue
                for name in names:
                    self.assertIn(name, sprite.PET_FRAMES[pet])
                    self.assertTrue((sprite.ROOT / "art" / pet / f"{name}.png").is_file())
        self.assertNotIn("tail-out", sprite.PET_FRAMES["whiplash"])

    def test_squidward_gag_matches_reference_duration_and_scene_sizes(self):
        sprite = self.load_generator()
        frames = sprite.generate()
        runtime = (sprite.ROOT / "init.luau").read_text()
        body = re.search(r"local DESTROY = (.*?)(?=\n--)", runtime, re.S).group(1)
        steps = re.findall(r'\{ "([^" ]+)", (\d+) \}', body)
        self.assertEqual(tuple(dict.fromkeys(name for name, _ in steps)), sprite.SQUIDWARD_GAG)
        self.assertEqual(sum(int(ms) for _, ms in steps), 9930)
        self.assertEqual(len(steps), 32)
        for name, _ in steps:
            self.assertEqual(frames[f"squidward/{name}"].size, sprite.GAG_DIMENSIONS[:2])
        self.assertIn("local GAG_W, GAG_H, GAG_FOOT = 96, 80, 78", runtime)
        self.assertNotIn("flattened", sprite.PET_FRAMES["squidward"])

    def test_creeper_explosion_keeps_character_scale(self):
        sprite = self.load_generator()
        frames = sprite.generate()
        idle_height = frames["creeper/idle"].getbbox()[3] - frames["creeper/idle"].getbbox()[1]
        for name in ("charge", "charged"):
            bounds = frames[f"creeper/{name}"].getbbox()
            self.assertEqual(bounds[3] - bounds[1], idle_height)
        runtime = (sprite.ROOT / "init.luau").read_text()
        self.assertIn('motion = EXPLODE, range = { 15, 25 }, pet = "creeper"', runtime)
        self.assertIn('gone or busy or reduced()', runtime)

    def test_ezio_assassination_keeps_character_scale(self):
        sprite = self.load_generator()
        frames = sprite.generate()
        idle = frames["ezio/idle"].getbbox()
        final = frames["ezio/assassinate-08"].getbbox()
        self.assertLessEqual(abs((idle[3] - idle[1]) - (final[3] - final[1])), 2)
        self.assertEqual(tuple(frames[f"ezio/{name}"].size for name in sprite.EZIO_GAG),
                         (sprite.EZIO_GAG_DIMENSIONS[:2],) * len(sprite.EZIO_GAG))
        runtime = (sprite.ROOT / "init.luau").read_text()
        self.assertIn('motion = ASSASSINATE, range = { 14, 24 }, pet = "ezio"', runtime)
        self.assertIn('local EZIO_GAG_W, EZIO_GAG_H, EZIO_GAG_FOOT = 100, 80, 78', runtime)

    def test_lara_relic_sequence_uses_large_scene(self):
        sprite = self.load_generator()
        frames = sprite.generate()
        self.assertEqual(tuple(frames[f"lara-croft/{name}"].size for name in sprite.LARA_GAG),
                         (sprite.LARA_GAG_DIMENSIONS[:2],) * len(sprite.LARA_GAG))
        runtime = (sprite.ROOT / "init.luau").read_text()
        self.assertIn('motion = RELIC, range = { 14, 24 }, pet = "lara-croft"', runtime)
        self.assertEqual(sprite.DIMENSIONS["lara-croft"], (64, 64, 62))

    def test_detached_source_specks_do_not_shift_the_scene(self):
        sprite = self.load_generator()
        cell = Image.new("RGBA", (32, 32))
        for y in range(20):
            for x in range(20):
                cell.putpixel((x, y), (100, 100, 100, 255))
        cell.putpixel((31, 31), (100, 100, 100, 255))
        sprite.remove_specks(cell)
        self.assertEqual(cell.getbbox(), (0, 0, 20, 20))

    def test_unknown_setting_is_rejected(self):
        sprite = self.load_generator()
        with patch.object(sprite, "PETS", (*sprite.PETS, "unknown")):
            with self.assertRaisesRegex(AssertionError, "settings and artwork differ"):
                sprite.generate()

    def test_preview_includes_every_row_and_column(self):
        sprite = self.load_generator()
        frames = sprite.generate()
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "preview.png"
            sprite.preview(frames, path)
            with Image.open(path) as sheet:
                for row, pet in enumerate(sprite.PETS):
                    for col, name in enumerate(sprite.PET_FRAMES[pet]):
                        x, y = sprite.LABEL + col * (max(im.width for im in frames.values()) * sprite.SCALE + sprite.GAP), sprite.GAP + row * (max(im.height for im in frames.values()) * sprite.SCALE + sprite.GAP)
                        pixel = next((i % frames[f"{pet}/{name}"].width, i // frames[f"{pet}/{name}"].width) for i, alpha in
                                     enumerate(frames[f"{pet}/{name}"].getchannel("A").tobytes()) if alpha)
                        px, py = pixel
                        self.assertEqual(sheet.getpixel((x + px * sprite.SCALE, y + py * sprite.SCALE)),
                                         frames[f"{pet}/{name}"].getpixel(pixel))


if __name__ == "__main__":
    unittest.main()
