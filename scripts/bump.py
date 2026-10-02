#!/usr/bin/env python3
"""Verify a published t release and update the tap formula's URL and SHA-256."""

import argparse
import hashlib
import io
import os
from pathlib import Path
import re
import sys
import tarfile
import tempfile
from urllib.request import urlopen

RELEASES = "https://github.com/agenthangar/t/releases"
VERSION = re.compile(r"v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\Z")
CHECKSUM = re.compile(r"([0-9a-fA-F]{64})[ \t]+\*?t\.tar\.gz\Z")
URL_LINE = re.compile(r'^  url "https://github\.com/agenthangar/t/releases/download/v[0-9]+\.[0-9]+\.[0-9]+/t\.tar\.gz"$', re.M)
SHA_LINE = re.compile(r'^  sha256 "[0-9a-f]{64}"$', re.M)
FORMULA = Path(__file__).resolve().parent.parent / "Formula/t.rb"
MAX_ARCHIVE = 64 * 1024 * 1024


def download(url):
    with urlopen(url, timeout=30) as response:
        data = response.read(MAX_ARCHIVE + 1)
    if len(data) > MAX_ARCHIVE:
        raise ValueError("release asset exceeds 64 MiB")
    return data


def _marker(tar, name, limit):
    members = [member for member in tar.getmembers() if member.name == "t/" + name]
    if len(members) != 1 or not members[0].isfile() or members[0].size > limit:
        raise ValueError("release archive has no unique regular " + name)
    file = tar.extractfile(members[0])
    if file is None:
        raise ValueError("cannot read " + name)
    return file.read().decode("ascii").strip()


def verify(archive, sums, expected_version=None):
    matches = [match.group(1).lower() for line in sums.decode("ascii").splitlines()
               if (match := CHECKSUM.fullmatch(line.strip()))]
    if len(matches) != 1:
        raise ValueError("SHA256SUMS must name t.tar.gz exactly once")
    digest = hashlib.sha256(archive).hexdigest()
    if digest != matches[0]:
        raise ValueError("t.tar.gz SHA-256 mismatch")
    with tarfile.open(fileobj=io.BytesIO(archive), mode="r:gz") as tar:
        version = _marker(tar, ".t-release-version", 32)
        capability = _marker(tar, ".t-install-version", 8)
    if not VERSION.fullmatch(version) or (expected_version and version != expected_version):
        raise ValueError("invalid or unexpected release version")
    if capability != "1":
        raise ValueError("unsupported installer capability")
    return version, digest


def rewrite_formula(text, version, digest):
    url = f'  url "{RELEASES}/download/{version}/t.tar.gz"'
    replacement = f'  sha256 "{digest}"'
    updated, urls = URL_LINE.subn(url, text)
    updated, hashes = SHA_LINE.subn(replacement, updated)
    if urls != 1 or hashes != 1:
        raise ValueError("formula must have exactly one t release URL and sha256 line")
    return updated


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", help="published release tag, e.g. v0.3.0 (default: latest)")
    parser.add_argument("--dry-run", action="store_true", help="verify and print the formula change without writing")
    args = parser.parse_args(argv)
    if args.version and not VERSION.fullmatch(args.version):
        parser.error("--version must be vX.Y.Z")
    base = f"{RELEASES}/download/{args.version}" if args.version else f"{RELEASES}/latest/download"
    try:
        archive = download(base + "/t.tar.gz")
        sums = download(base + "/SHA256SUMS")
        version, digest = verify(archive, sums, args.version)
        old = FORMULA.read_text(encoding="utf-8")
        new = rewrite_formula(old, version, digest)
        if args.dry_run:
            print(f"Verified {version}: sha256 {digest}")
            print(f"Formula URL: {RELEASES}/download/{version}/t.tar.gz")
            print("Formula would change" if new != old else "Formula is already current")
        elif new != old:
            with tempfile.NamedTemporaryFile("w", dir=FORMULA.parent, encoding="utf-8", delete=False) as file:
                temporary = Path(file.name)
                file.write(new)
            os.chmod(temporary, FORMULA.stat().st_mode & 0o777)
            os.replace(temporary, FORMULA)
            print(f"Updated Formula/t.rb to {version} ({digest})")
        else:
            print(f"Formula/t.rb is already at {version}")
    except (OSError, ValueError, UnicodeError, tarfile.TarError) as error:
        print("tap bump: " + str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
