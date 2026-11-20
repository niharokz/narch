#!/usr/bin/env python3
"""
dwd - universal downloader

Downloads torrents, magnet links, or plain URLs into the CURRENT directory
(wherever you run it from), regardless of what config defaults are set.

Usage:
    dwd <file.torrent>
    dwd "magnet:?xt=urn:btih:..."
    dwd https://example.com/file.iso
"""
import os
import re
import signal
import subprocess
import sys
from pathlib import Path

URL_RE = re.compile(r"^(https?|ftp)://", re.IGNORECASE)


def download_torrent(source: str, dest_dir: Path) -> int:
    """Download via transmission-cli into dest_dir.
    Auto-stops (and stops seeding) as soon as the torrent hits 'Complete'.
    If the source was a local .torrent file, delete it once done."""
    cmd = ["transmission-cli", "-w", str(dest_dir), source]
    proc = subprocess.Popen(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, bufsize=1,
    )
    stopped = False
    completed = False
    try:
        for line in proc.stdout:
            print(line, end="")
            if not stopped and 'to "Complete"' in line:
                print("\n✅ Download complete — stopping (no seeding).\n")
                proc.send_signal(signal.SIGINT)
                stopped = True
                completed = True
    except KeyboardInterrupt:
        proc.send_signal(signal.SIGINT)
    proc.wait()

    if completed and source.endswith(".torrent") and os.path.isfile(source):
        try:
            os.remove(source)
            print(f"🗑️  Removed {source}")
        except OSError as e:
            print(f"⚠️  Could not remove {source}: {e}")

    return proc.returncode


def download_url(source: str, dest_dir: Path) -> int:
    """Download a plain file via wget, resuming partial downloads if any."""
    cmd = ["wget", "-c", "-P", str(dest_dir), source]
    return subprocess.call(cmd)


def main() -> None:
    if len(sys.argv) != 2:
        print("Usage: dwd <file.torrent | magnet:... | http(s)/ftp url>")
        sys.exit(1)

    source = sys.argv[1]
    dest_dir = Path.cwd()

    if source.startswith("magnet:") or source.endswith(".torrent"):
        rc = download_torrent(source, dest_dir)
    elif URL_RE.match(source):
        rc = download_url(source, dest_dir)
    else:
        print(f"Don't know how to handle: {source}")
        print("Expected a .torrent file, a magnet: link, or an http(s)/ftp URL.")
        sys.exit(1)

    sys.exit(rc)


if __name__ == "__main__":
    main()
