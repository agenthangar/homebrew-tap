"""Offline checks for the maintainer release bump command."""

import hashlib
import importlib.util
import io
from pathlib import Path
import tarfile
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parent.parent / "scripts/bump.py"
spec = importlib.util.spec_from_file_location("bump", SCRIPT)
bump = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bump)
FORMULA = Path(__file__).resolve().parent.parent / "Formula/t.rb"


def release(version="v0.3.0", capability="1"):
    output = io.BytesIO()
    with tarfile.open(fileobj=output, mode="w:gz") as tar:
        for name, content in ((".t-release-version", version), (".t-install-version", capability)):
            data = (content + "\n").encode()
            member = tarfile.TarInfo("t/" + name)
            member.size = len(data)
            tar.addfile(member, io.BytesIO(data))
    archive = output.getvalue()
    digest = hashlib.sha256(archive).hexdigest()
    return archive, (digest + "  t.tar.gz\n").encode(), digest


class BumpTests(unittest.TestCase):
    def test_verifies_archive_checksum_version_and_capability(self):
        archive, sums, digest = release()
        self.assertEqual(bump.verify(archive, sums, "v0.3.0"), ("v0.3.0", digest))
        with self.assertRaisesRegex(ValueError, "mismatch"):
            bump.verify(archive + b"tampered", sums)
        with self.assertRaisesRegex(ValueError, "unexpected release version"):
            bump.verify(archive, sums, "v0.4.0")
        bad, sums, _ = release(capability="2")
        with self.assertRaisesRegex(ValueError, "capability"):
            bump.verify(bad, sums)

    def test_rewrites_only_formula_release_fields(self):
        original = FORMULA.read_text()
        updated = bump.rewrite_formula(original, "v0.3.0", "a" * 64)
        self.assertIn('releases/download/v0.3.0/t.tar.gz', updated)
        self.assertIn('  sha256 "' + "a" * 64 + '"', updated)
        self.assertEqual(bump.rewrite_formula(updated, "v0.3.0", "a" * 64), updated)
        self.assertEqual(original.replace(bump.URL_LINE.search(original).group(), "")
                         .replace(bump.SHA_LINE.search(original).group(), ""),
                         updated.replace(bump.URL_LINE.search(updated).group(), "")
                         .replace(bump.SHA_LINE.search(updated).group(), ""))
        with self.assertRaisesRegex(ValueError, "exactly one"):
            bump.rewrite_formula(original + '\n  sha256 "' + "b" * 64 + '"\n', "v0.3.0", "a" * 64)

    def test_dry_run_uses_published_assets_without_writing(self):
        archive, sums, _ = release()
        with tempfile.TemporaryDirectory() as directory:
            formula = Path(directory) / "t.rb"
            formula.write_text(FORMULA.read_text())
            before = formula.read_bytes()
            urls = []

            def fetched(url):
                urls.append(url)
                return archive if url.endswith("t.tar.gz") else sums

            with patch.object(bump, "FORMULA", formula), patch.object(bump, "download", fetched):
                self.assertEqual(bump.main(["--version", "v0.3.0", "--dry-run"]), 0)
            self.assertEqual(formula.read_bytes(), before)
            self.assertEqual(urls, [
                "https://github.com/agenthangar/t/releases/download/v0.3.0/t.tar.gz",
                "https://github.com/agenthangar/t/releases/download/v0.3.0/SHA256SUMS",
            ])


if __name__ == "__main__":
    unittest.main()
