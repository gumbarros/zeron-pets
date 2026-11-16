# Zeron Pets

Pixel pets for [Zeron](https://github.com/zeronsh/zeron).

## Pets

Choose a Siamese, Ginger, Black, Silver, Squidward, Darth Revan, The Witcher (Geralt), Omniman, or Whiplash (Fletcher) in **Settings → Plugins → Zeron Pets → Pet**. Siamese remains the default. The selection is saved across restarts. Pets sit on the message box, blink, and make small gestures. Cats also flick their tiny tails. Respects system Reduce Motion and does not intercept mouse input.

### Install

Ask your Zeron agent:

> Install the plugin at https://github.com/gumbarros/zeron-pets

Then allow **Zeron Pets** in Zeron's plugin review. It only requests `ui.add`; no network, commands, or message access.

### Develop

The plugin source lives at the repository root. Edit `art-src/sprite.py` to change its pixel art. Regenerate the 45 PNG frames with Python and Pillow:

```sh
python art-src/sprite.py
```

An optional argument writes an enlarged animation-frame preview:

```sh
python art-src/sprite.py /tmp/siamese-preview.png
```

Editing files invalidates the plugin signature. Sign offline using Python 3.10+
and OpenSSL; no running Zeron or Python packages are required:

```sh
PYTHONDONTWRITEBYTECODE=1 python scripts/test_sign.py
python scripts/sign.py
python scripts/sign.py --verify
```

The private Ed25519 PEM key defaults to
`~/.config/zeron-pets/signing-key.pem`; pass `--key /path/to/key.pem` to override.
Keep and back up this key outside the repository. For a brand-new signing identity
only, create it once (never overwrite an existing key):

```sh
mkdir -p ~/.config/zeron-pets
(umask 077; set -C; openssl genpkey -algorithm ED25519 > ~/.config/zeron-pets/signing-key.pem)
```

Commit the updated `zeron-plugin.json` with every change, and sign again if any
file changes afterward. Zeron hashes non-hidden files regardless of `.gitignore`;
remove generated `__pycache__` folders and `.pyc` files before signing. A new key
changes the signer and may require reinstalling an existing plugin. An unregistered
key appears as an unknown author; users still allow the plugin in Zeron's review.

Adapted from Zeron's [Composer Cat development plugin](https://github.com/zeronsh/zeron/tree/main/apps/zgx/plugins-dev/composer-cat). Original MIT license retained in [LICENSE](LICENSE).

### Custom pets

The current Zeron settings API has no file-upload control and does not allow plugins to draw their own settings UI. An upload button directly in plugin settings requires a Zeron host change. A separate plugin page with a file dialog would need additional permissions and image handling; this plugin does not implement it.

Renaming the plugin changes its ID: existing installations of the original plugin must be disabled and Zeron Pets installed separately. Select your pet again after installing.

### Translations

English and Portuguese catalogs live in `locales/en.json` and
`locales/pt.json`. Zeron resolves Portuguese variants such as `pt-BR`
through `pt`, with English as the fallback. Use `zeron.t` or `zeron.s`
for plugin-rendered text.

Zeron currently displays manifest names, descriptions, and setting options
as literal strings. The catalogs include their translations, but showing
those translations in the host settings requires localization support in Zeron.
