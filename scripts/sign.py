"""Sign or verify this plugin offline using Python 3 and OpenSSL."""

import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile


DEFAULT_KEY = Path.home() / ".config/zeron-pets/signing-key.pem"
PUBLIC_PREFIX = bytes.fromhex("302a300506032b6570032100")


def openssl(*args):
    return subprocess.run(["openssl", *map(str, args)], check=True, capture_output=True).stdout


def hashes(root):
    files = {}
    total = 0
    for path in root.rglob("*"):
        relative = path.relative_to(root)
        if any(part.startswith(".") for part in relative.parts):
            continue
        if path.is_symlink():
            raise ValueError(f"Plugins can't contain links: {relative}")
        if not path.is_file() or relative.as_posix() == "zeron-plugin.json":
            continue
        data = path.read_bytes()
        total += len(data)
        files[relative.as_posix()] = hashlib.sha256(data).hexdigest()
        if len(files) > 2000 or total > 50 * 1024 * 1024:
            raise ValueError("Plugin exceeds Zeron's 2,000-file / 50 MiB limit")
    return files


def payload(manifest):
    # shortcut: float canonicalization isn't implemented; reject floats if added to the manifest.
    def no_float(value):
        raise ValueError("Floating-point manifest values aren't supported")

    unsigned = json.loads(json.dumps(manifest), parse_float=no_float, parse_constant=no_float)
    unsigned["signature"] = {k: manifest["signature"][k] for k in ("key", "files")}
    return b"zeron-plugin:v1\n" + json.dumps(
        unsigned, sort_keys=True, separators=(",", ":"), ensure_ascii=False, allow_nan=False,
    ).encode()


def b64(data):
    return base64.urlsafe_b64encode(data).decode().rstrip("=")


def unb64(value):
    return base64.b64decode(value + "=" * (-len(value) % 4), altchars=b"-_", validate=True)


def verify(root):
    manifest = json.loads((root / "zeron-plugin.json").read_text())
    signature = manifest["signature"]
    if signature["files"] != hashes(root):
        raise ValueError("Plugin files don't match the signature; sign again")
    public, sig = unb64(signature["key"]), unb64(signature["sig"])
    if len(public) != 32 or len(sig) != 64:
        raise ValueError("Invalid Ed25519 key or signature length")
    with tempfile.TemporaryDirectory() as folder:
        folder = Path(folder)
        (folder / "public.der").write_bytes(PUBLIC_PREFIX + public)
        (folder / "payload").write_bytes(payload(manifest))
        (folder / "signature").write_bytes(sig)
        openssl("pkeyutl", "-verify", "-rawin", "-pubin", "-keyform", "DER",
                "-inkey", folder / "public.der", "-in", folder / "payload",
                "-sigfile", folder / "signature")


def sign(root, key):
    key = key.expanduser().resolve()
    if key.is_relative_to(root.resolve()):
        raise ValueError("Keep the private signing key outside the repository")
    public = openssl("pkey", "-in", key, "-pubout", "-outform", "DER")
    if len(public) != 44 or not public.startswith(PUBLIC_PREFIX):
        raise ValueError("An Ed25519 private key is required")
    path = root / "zeron-plugin.json"
    manifest = json.loads(path.read_text())
    manifest["signature"] = {"key": b64(public[len(PUBLIC_PREFIX):]), "files": hashes(root)}
    with tempfile.TemporaryDirectory() as folder:
        message = Path(folder) / "payload"
        message.write_bytes(payload(manifest))
        manifest["signature"]["sig"] = b64(openssl(
            "pkeyutl", "-sign", "-rawin", "-inkey", key, "-in", message,
        ))
    # Replace atomically, leaving the previous manifest intact if writing fails.
    fd, temporary = tempfile.mkstemp(prefix=".signed-", dir=root)
    try:
        with os.fdopen(fd, "w") as output:
            output.write(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)
    verify(root)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--key", type=Path, default=DEFAULT_KEY)
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    try:
        verify(root) if args.verify else sign(root, args.key)
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Signing check failed: {error}\n")
    print("Signature and plugin files verified." if args.verify else "Plugin signed and verified.")
