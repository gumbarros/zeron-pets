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

Use Zeron's native signing and export commands; do not implement signing or
create a separate private key. Keep Zeron running. Sign in to Zeron and claim
a username for a publicly verified author identity.

After every repository change (including docs, tests and artwork):

1. Run the relevant checks and remove generated `__pycache__` folders and `.pyc` files.
2. Sync the complete repository contents, excluding hidden files and directories,
   to the installed `zeron-pixel-pets` folder reported by `zeron plugin list`. Remove
   obsolete files there too. Never copy `.git` or private keys.
3. Run `zeron plugin sign zeron-pixel-pets`. If Zeron requires consent, the user must
   decide in Zeron's own window; never bypass consent or fall back to manual signing.
4. Run `zeron plugin verify <installed-plugin-folder>`.
5. Copy the signed `zeron-plugin.json` back to this repository as the final
   repository file change, then run `zeron plugin verify .`.

Include the updated manifest with every change. If anything changes afterward,
repeat the sync, sign and verification steps before finishing or committing.
Zeron hashes all non-hidden files regardless of `.gitignore`.
Sign from a checkout with the LF line endings set in `.gitattributes`. Finish
all edits, including README changes, before signing.

For distribution, run `zeron plugin export zeron-pixel-pets` and verify the repository
again (export can re-sign the installed plugin). Keep the exported `.zeron-plugin`
outside this repository. Before publishing, verify a fresh clone of the exact
commit being released with `zeron plugin verify <clone-folder>`. Attach the
export to a GitHub release tagged `v<version>` for that commit. Publishing is
a separate action. Increment the manifest version for updates.
Reuse the current signing device or a verified key registered to the same Zeron
account. A different author can require users to remove and reinstall the plugin.
Never read, print, copy into the repository, or replace private signing keys.

# Development

Generation is deterministic: pets use a 64×64 pixel grid;
Ornstein & Smough uses 96×64, and Fletcher uses 96×96 for his chair throw.
Each pet has a compact shared palette. Frames use hard alpha, nearest-neighbor
sampling, and a fixed foot baseline. The generator checks pet settings, source
layout, transparency, palette size, baseline, and distinct poses before writing.
The runtime displays each pixel at 2× (128×128 points; Ornstein & Smough 192×128 and Fletcher 192×192), without smoothing.
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
follow-through, and recover. He never plays drums; every 10–20 seconds he throws
a metal rehearsal chair, then returns to idle. Reduce Motion disables the throw.
His source prompt preserves the reference character and pixel style, removes all
drums and drumsticks, and specifies a planted full-body chair-throw sequence.
Anti Sergio uses a 4×2 sheet: idle, blink, two thumbs-up poses, head tilt,
dog arriving, petting the dog, and dog leaving. The dog visits every 9–16
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
It runs every 14–25 seconds and returns to idle after the final empty rollers;
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


# Developer workflow and implementation notes

The plugin source lives at the repository root. Python with Pillow generates
artwork; Lua 5.1+ runs the selection and click checks. These tools are not needed
by users installing the signed plugin. Zeron runs the bundled Luau code and PNG
frames inside its plugin sandbox.

Edit `art-src/<pet>/atlas.png` to change artwork. Regenerate runtime frames and
the complete labeled preview with:

```sh
PYTHONDONTWRITEBYTECODE=1 python art-src/sprite.py art-src/preview.png
```

Without the preview argument, the generator writes runtime frames only. Run:

```sh
PYTHONDONTWRITEBYTECODE=1 python art-src/test_sprite.py
lua scripts/test_pet_selection.lua
lua scripts/test_pet_click.lua
```

Random selection uses chat IDs and persists across reopening and restarting.
Different chats can share a pet; roster changes can remap Random choices.
A configured character appears in every chat, including new drafts. With
Random, a draft keeps its companion when that chat is created. An explicit
selection overrides pets saved by earlier versions.
The `sessions.read` permission reads IDs, not messages; `ui.add` draws the pet.

Click animations reuse the bounded scheduler in `init.luau`: one motion at a
time, return to idle after its final frame, ignore clicks while busy, and honor
Reduce Motion. Only pets with a special motion capture pointer input within
their sprite bounds or receive keyboard focus. Do not use the button's disabled
state for decorative pets: it reduces opacity. Position adjusts to the bar width.

Bergamini Cow uses an eight-pose 4×2 atlas and a 64×64 runtime grid (128×128
points). The source atlas and built-in image-generation prompt are in
`art-src/bergamini-cow/`. The sequence is cart arrival, cartoon explosion, smoke,
then idle; it also plays on click. Bergamini Cow and Creeper special motions
use the scheduler's 15–25 range, currently about 18–30 seconds because `within`
multiplies by 1200 ms. Creeper's source gag is `explosion-atlas.png`.
Ornstein & Smough uses the 96×64 grid.

# Localization

English and Portuguese catalogs live in `locales/en.json` and `locales/pt.json`.
Zeron resolves Portuguese variants such as `pt-BR` through `pt`, with English
as fallback. Use `zeron.t` or `zeron.s` for plugin-rendered text.

Manifest names, descriptions and setting options currently display as literal
strings. Their catalog translations require host localization support before
Zeron can show them in settings.

# Distribution notes and attribution

The current plugin ID is `zeron-pixel-pets`. The legacy `zeron-pets` plugin used
a standalone signing key that Zeron cannot transfer. Install the current package
as a new plugin and disable the old one; settings and per-chat pet choices do
not migrate. A locally valid signature alone does not establish a publicly
verified author: the author must sign in and claim a username in Zeron.

Follow the Plugin signing section above for every change, including docs.
Export with `zeron plugin export zeron-pixel-pets` for distribution. After export,
verify the repository again; if export re-signed the installed plugin, copy its
manifest back and verify again. Commit the signed manifest with the changes.

See Zeron's [sharing and installation guide](https://github.com/zeronsh/zeron/blob/main/apps/zgx/docs/plugins.md#sharing-and-installing).
Adapted from Zeron's [Composer Cat development plugin](https://github.com/zeronsh/zeron/tree/main/apps/zgx/plugins-dev/composer-cat).
Original MIT license retained in [LICENSE](LICENSE).
