#!/usr/bin/env python3

import os
import sys
import datetime
import subprocess
from pathlib import Path


def find_journal_dir():
    home = Path.home()
    candidates = [
        home / "Dropbox" / "Brain" / "journal",
        home / "Brain" / "journal",
        home / ".journal",
    ]
    for d in candidates:
        if d.is_dir():
            return d
    # If none found, fallback to first candidate (or create it)
    return candidates[0]


def format_date(date_str):
    # Input format: YYYY-MM-DD
    dt = datetime.datetime.strptime(date_str, "%Y-%m-%d")
    return dt.strftime("%a, %b %d, %Y")


def tomorrow(date_str):
    dt = datetime.datetime.strptime(date_str, "%Y-%m-%d") + datetime.timedelta(days=1)
    return dt.strftime("%Y-%m-%d")


def yesterday(date_str):
    dt = datetime.datetime.strptime(date_str, "%Y-%m-%d") - datetime.timedelta(days=1)
    return dt.strftime("%Y-%m-%d")


def ensure_journal_file(journal_file):
    if not journal_file.exists():
        date_part = journal_file.stem.split(" ")[-1]  # Extract date from filename
        header = f"""# Journal on {format_date(date_part)}

## Metadata

**Date**:: [[{date_part}]]
**Next**:: [[Journal {tomorrow(date_part)}]]
**Prev**:: [[Journal {yesterday(date_part)}]]
**Kind**:: #journal

## Journal
"""
        journal_file.write_text(header)


def main(args):
    journal_dir = find_journal_dir()
    today_str = datetime.datetime.now().strftime("%Y-%m-%d")
    journal_file = journal_dir / f"Journal {today_str}.md"

    ensure_journal_file(journal_file)

    sep_title = " ".join(args)
    if sep_title == "-p":
        print(journal_file)
        return
    elif sep_title == "-e":
        editor = os.environ.get("EDITOR", "nvim")
        # Replace current process with editor
        os.execvp(editor, [editor, str(journal_file)])
        return

    if sep_title != "":
        sep_title = " " + sep_title

    # Append journal entry from stdin
    # Output format:
    # (blank line)
    # ### HH:MM [title]
    # (blank line)
    # <content from stdin>
    # (blank line)
    now_time = datetime.datetime.now().strftime("%H:%M")

    with journal_file.open("a") as f:
        f.write("\n")
        f.write(f"### {now_time}{sep_title}\n")
        f.write("\n")
        # Read from stdin until EOF and write to file
        content = sys.stdin.read()
        f.write(content)
        if not content.endswith("\n"):
            f.write("\n")
        f.write("\n")

    print(journal_file)


if __name__ == "__main__":
    # Set -e and -u equivalent behavior:
    # -e: exit on error (default in Python)
    # -u: error on unset variables (Python raises NameError)
    # DEBUG mode can be handled by environment variable if needed (not implemented here)
    main(sys.argv[1:])
