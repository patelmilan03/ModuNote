#!/usr/bin/env python3
"""
Repair mojibake in the ModuNote GitHub issues.

WHY: github_issues.sh was run from a Windows shell using a cp1252 code page, so
UTF-8 punctuation in the issue text ( ->  em-dash, middle dot, ellipsis ) was
double-encoded. 5 titles and 14 bodies are affected.

HOW: the damage is losslessly reversible -- text that was UTF-8, misread as
cp1252, then re-encoded as UTF-8 can be restored with:
      broken.encode('cp1252').decode('utf-8')
The script only rewrites an issue when that round-trip succeeds AND actually
changes the text, so clean issues are left untouched (safe to re-run).

USAGE:
    python modunote/bugs/fix_issue_encoding.py --dry-run   # preview (default)
    python modunote/bugs/fix_issue_encoding.py --apply     # write changes

PREREQ: gh CLI authenticated (`gh auth login`).
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
import os

REPO = "patelmilan03/ModuNote"

# Windows consoles default to cp1252, which cannot print the very characters we
# are repairing. Force UTF-8 output so the preview is readable (and so printing
# a fixed title never crashes the run).
for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, ValueError):
        pass


def run(args: list[str], **kw) -> subprocess.CompletedProcess:
    """Run a command, always decoding output as UTF-8 (never the OS code page)."""
    return subprocess.run(
        args, capture_output=True, encoding="utf-8", errors="replace", **kw
    )


def repair(text: str) -> str:
    """Reverse one round of UTF-8 -> cp1252 -> UTF-8 double-encoding.

    Returns the original text unchanged if it is not repairable (already clean,
    or damaged in some other way we should not guess at).
    """
    if not text:
        return text
    # Some bodies also carry a stray BOM from the generating script. It is junk,
    # and because U+FEFF has no cp1252 mapping it would abort the round-trip.
    cleaned = text.replace("﻿", "")
    try:
        fixed = cleaned.encode("cp1252").decode("utf-8")
    except (UnicodeEncodeError, UnicodeDecodeError):
        return cleaned  # not double-encoded (or damaged otherwise) — at least drop the BOM
    # Only accept the round-trip if it removed the tell-tale mojibake marker.
    if "â" in cleaned and "â" not in fixed:
        return fixed
    return cleaned


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="write changes (default: dry run)")
    args = ap.parse_args()

    print(f"Repo: {REPO}   mode: {'APPLY' if args.apply else 'DRY RUN'}\n")

    listing = run([
        "gh", "issue", "list", "-R", REPO, "--limit", "100",
        "--state", "open", "--json", "number,title,body",
    ])
    if listing.returncode != 0:
        print("Failed to list issues:\n" + (listing.stderr or ""), file=sys.stderr)
        return 1

    issues = json.loads(listing.stdout)
    changed = 0

    for issue in issues:
        num = issue["number"]
        title, body = issue["title"], issue.get("body") or ""
        new_title, new_body = repair(title), repair(body)

        if new_title == title and new_body == body:
            continue

        changed += 1
        print(f"#{num}")
        if new_title != title:
            print(f"   title: {title}")
            print(f"       -> {new_title}")
        if new_body != body:
            print(f"   body:  {len(body)} chars -> repaired")

        if not args.apply:
            print()
            continue

        # Pass the body through a UTF-8 file so no shell/locale can mangle it.
        tmp = tempfile.NamedTemporaryFile(
            "w", suffix=".md", delete=False, encoding="utf-8", newline="\n"
        )
        try:
            tmp.write(new_body)
            tmp.close()
            cmd = ["gh", "issue", "edit", str(num), "-R", REPO, "--body-file", tmp.name]
            if new_title != title:
                cmd += ["--title", new_title]
            res = run(cmd)
            print("   OK" if res.returncode == 0 else f"   FAILED: {res.stderr.strip()}")
        finally:
            os.unlink(tmp.name)
        print()

    print(f"\n{changed} issue(s) need repair.")
    if changed and not args.apply:
        print("Re-run with --apply to write the fixes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
