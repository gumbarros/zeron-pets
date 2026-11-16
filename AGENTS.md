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
