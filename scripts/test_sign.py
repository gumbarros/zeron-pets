import json
import subprocess
from pathlib import Path
import tempfile
import unittest

from sign import hashes, openssl, sign, verify


class SigningTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        base = Path(self.temp.name)
        self.root = base / "plugin"
        self.root.mkdir()
        self.key = base / "key.pem"
        openssl("genpkey", "-algorithm", "ED25519", "-out", self.key)
        (self.root / "zeron-plugin.json").write_text(json.dumps({"id": "test", "name": "Café"}))
        (self.root / "init.luau").write_text("-- test\n")

    def test_sign_verify_and_tampering(self):
        sign(self.root, self.key)
        verify(self.root)
        (self.root / "init.luau").write_text("-- changed\n")
        with self.assertRaises(ValueError):
            verify(self.root)
        sign(self.root, self.key)
        path = self.root / "zeron-plugin.json"
        manifest = json.loads(path.read_text())
        manifest["name"] = "tampered"
        path.write_text(json.dumps(manifest))
        with self.assertRaises(subprocess.CalledProcessError):
            verify(self.root)

    def test_hidden_files_ignored_and_visible_links_rejected(self):
        (self.root / ".git").mkdir()
        (self.root / ".git/config").write_text("ignored")
        self.assertEqual(set(hashes(self.root)), {"init.luau"})
        (self.root / "link").symlink_to(self.key)
        with self.assertRaises(ValueError):
            hashes(self.root)

    def test_private_key_in_repo_rejected(self):
        with self.assertRaises(ValueError):
            sign(self.root, self.root / "private.pem")


if __name__ == "__main__":
    unittest.main()
