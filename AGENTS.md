# Character art consistency

Always generate and edit every character in the same established Super Mario
World / SNES-inspired pixel-art style. Use the existing character atlases in
`art-src/<character>/atlas.png` as visual references for every new or revised
sprite; include them in image-generation requests. Preserve crisp square pixel
clusters, dark outlines, compact coordinated palettes, upper-left highlights,
warm lights and cool shadows, and readable character silhouettes. Do not mix in
smooth illustration, antialiasing, painterly texture, or a different art style.

Keep each character's proportions, outfit, palette, pixel scale, and foot baseline
consistent across all its animation frames. Allow extra canvas space for props
and motion without shrinking the character between poses. Keep source artwork
in `art-src/<character>/` and runtime frames in `art/<character>/`.

Regenerate the frames and the full `art-src/preview.png` sheet after artwork
changes. Inspect every character and pose together for style consistency, then
run `PYTHONDONTWRITEBYTECODE=1 python art-src/test_sprite.py` before signing.

# Plugin signing

After every change to this repository, re-sign the plugin as the final file-changing
step, including changes to docs, tests, art, scripts, or this file:

```sh
PYTHONDONTWRITEBYTECODE=1 python scripts/test_sign.py
python scripts/sign.py
python scripts/sign.py --verify
```

Include the updated `zeron-plugin.json` with the changes. If you edit anything
after signing, sign and verify again before finishing or committing.

Requires Python 3.10+ and OpenSSL with Ed25519 support; Zeron does not need to run.
The dedicated private key lives at `~/.config/zeron-pets/signing-key.pem`.
Use `--key /outside/the/repository/key.pem` if it is stored elsewhere.
Never commit, print, or copy private keys into the repository. Reuse the same key
for future releases; do not silently generate a replacement if it is missing.
Report a missing key as a blocker to signing.

Zeron hashes every non-hidden file, ignoring the root manifest itself. Git ignore
rules do not affect signing: remove generated `__pycache__` folders and `.pyc`
files before signing. Hidden files and directories such as `.git` are excluded.


# Development

Generation is deterministic: regular pets use a 40×48 pixel grid;
Squidward, Fletcher and Anti Sergio use 64×64 to leave room for their gags.
Each pet has a compact shared palette. Frames use hard alpha, nearest-neighbor
sampling, and a fixed foot baseline. The generator checks pet settings, source
layout, transparency, palette size, baseline, and distinct poses before writing.
The runtime displays each pixel at 2× (80×96 points; Squidward, Fletcher and Anti Sergio 128×128), without smoothing.
The source atlas was created with the built-in image generator using the supplied
Super Mario World references: crisp SNES pixel clusters, dark outlines, upper-left
highlights, warm lights/cool shadows, consistent character identities, and five
poses (idle, blink, two gestures, head tilt) for pets with the standard five-frame sheet.
Gordon Freeman uses five poses: idle, blink, two crowbar-lifting gestures and
a glasses adjustment. His source prompt uses the supplied HEV-suit reference
and the existing Omniman atlas style: orange-and-charcoal armor, silver shoulder
plates, lambda chest emblem, brown hair/goatee, rectangular glasses and a red crowbar.
Hollow Knight uses five poses: idle, a mask dip, two nail-lifting gestures,
and a head tilt with cloak movement. The source prompt uses the existing Darth
Revan atlas for the SNES pixel style, with a horned white mask, black eye holes,
a dark blue-gray cloak and a silver nail.
Fletcher has a separate 4×2 sheet: idle, blink, windup, lift, release, flight,
follow-through, and recover. He never plays drums; every 20–40 seconds he throws
a metal rehearsal chair, then returns to idle. Reduce Motion disables the throw.
His source prompt preserves the reference character and pixel style, removes all
drums and drumsticks, and specifies a planted full-body chair-throw sequence.
Anti Sergio uses a 4×2 sheet: idle, blink, two thumbs-up poses, head tilt,
dog arriving, petting the dog, and dog leaving. The dog visits every 18–32
seconds for about three seconds; Reduce Motion keeps Anti Sergio alone and still.
His artwork uses the supplied photos for short straight side-swept black hair
with trimmed sides, an oval face, smaller almond-shaped eyes, a thin mustache
and separate chin goatee, a relaxed smile, and a burgundy shirt. The dog keeps
its cream fur, red web-pattern costume and blue bandana;
the existing character atlas supplies the shared SNES pixel-art style.
Squidward keeps his five normal poses in `art-src/squidward/atlas.png`. His
separate `machine-atlas.png` has 20 chronological scenes in a 4×5 grid, following
the [reference GIF](https://c.tenor.com/DYI1DqcIOgAAAAAd/tenor.gif): curled-up panic
in a brown pinstriped suit, turning spiked rollers with their right-side linkage,
drive shaft and orange motor, sideways feeding and tumbling tentacles, then a
diagonal close-up as his head and hands disappear between the drums. The gag
uses 96×80 frames (192×160 points) for the machinery details; normal poses keep
their existing size. Source keyframes 0, 15, 45, 60, 65, 80, 95, 110, 125, 140,
155, 175, 195, 205, 220, 235, 250, 265, 280 and 297 supply the pose timing for the
full 9.93-second sequence; the three empty-machine phases cycle every 100 ms. This is a pixel-art restaging, not the original video.
It runs every 28–50 seconds and returns to idle after the final empty rollers;
Reduce Motion disables it. The generation prompt uses the existing character
atlas for style and sampled GIF frames for the action, with no dust-cloud,
pancake or reinflation ending.
The Siamese source edit preserves the existing cat and SNES style while replacing
every long tail with a very small dark seal-brown rabbit bobtail. All seal-point
fur (face mask, outer ears, paws and tail) uses deep espresso brown, with the
cream body and blue eyes preserved. Its gesture frames retain the shared
`tail-out` and `tail-over` filenames for runtime compatibility.
Importing the module does not write files. Run generator checks with
`PYTHONDONTWRITEBYTECODE=1 python art-src/test_sprite.py`.
Run the chat-selection checks with `lua scripts/test_pet_selection.lua` (Lua 5.1+).
