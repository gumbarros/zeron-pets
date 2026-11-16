# Zeron Pets

Pixel pets for [Zeron](https://github.com/zeronsh/zeron).

## Composer Cat

A blue-eyed Siamese cat with a cream coat, seal-brown points, and a tiny tail. It sits on the message box, blinks, flicks its tail, and twitches an ear. Respects system Reduce Motion and does not intercept mouse input.

### Install

Ask your Zeron agent:

> Install the plugin at https://github.com/gumbarros/zeron-pets/tree/main/composer-cat

Then allow **Composer Cat** in Zeron's plugin review. It only requests `ui.add`.

### Develop

The complete signed plugin lives in `composer-cat/`. Edit `art-src/sprite.py` to change its pixel art. Regenerate the five PNG frames with Python and Pillow:

```sh
python composer-cat/art-src/sprite.py
```

An optional argument writes an enlarged animation-frame preview:

```sh
python composer-cat/art-src/sprite.py /tmp/siamese-preview.png
```

Editing files invalidates the plugin signature. To publish changes, copy the plugin into your local Zeron plugins directory, then sign it with `zeron plugin sign composer-cat` and copy the signed folder back before committing. Do not edit the signature manually.

Adapted from Zeron's [Composer Cat development plugin](https://github.com/zeronsh/zeron/tree/main/apps/zgx/plugins-dev/composer-cat). Original MIT license retained in [composer-cat/LICENSE](composer-cat/LICENSE).
