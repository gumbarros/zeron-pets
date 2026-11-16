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

Editing files invalidates the plugin signature. Before distributing changes, copy the repository contents (excluding `.git/`) into Zeron’s plugins folder as `zeron-pets/`, run `zeron plugin sign zeron-pets`, and copy the signed `zeron-plugin.json` back to the repository root. Check it with `zeron plugin verify .`. The current Zeron CLI only signs plugins in its plugins folder. Do not edit the signature manually.

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
