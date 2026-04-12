#!/usr/bin/env python
"""Generate a markdown reference table from cursor/keybindings.json.

    ./gen-keybindings-doc.py           # print table to stdout
    ./gen-keybindings-doc.py --write   # replace the block in README.md

The block in README.md is delimited by HTML comment markers; re-running with
--write is idempotent. If the markers don't exist yet, a new "Keybindings
reference" section is appended.
"""
from __future__ import print_function

import json
import os
import re
import sys

dotfiles = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
keybindings_path = os.path.join(dotfiles, "cursor", "keybindings.json")
readme_path = os.path.join(dotfiles, "README.md")

mode = "print"
if len(sys.argv) > 1:
    if sys.argv[1] == "--write":
        mode = "write"
    else:
        print("usage: %s [--write]" % os.path.basename(sys.argv[0]), file=sys.stderr)
        sys.exit(2)

BEGIN = "<!-- BEGIN: generated keybindings table -->"
END = "<!-- END: generated keybindings table -->"

with open(keybindings_path) as f:
    raw = f.read()

# keybindings.json is JSONC — strip // line comments before parsing.
stripped = re.sub(r"^\s*//.*$", "", raw, flags=re.M)
bindings = json.loads(stripped)

MOD_MAP = {
    "ctrl": "Ctrl", "cmd": "Cmd", "shift": "Shift",
    "alt": "Alt", "opt": "Opt", "meta": "Meta",
}


def pretty_key(key):
    """Turn 'ctrl+x ctrl+shift+p' into 'Ctrl+X Ctrl+Shift+P'."""
    chords = []
    for chord in key.split():
        segs = []
        for seg in chord.split("+"):
            low = seg.lower()
            if low in MOD_MAP:
                segs.append(MOD_MAP[low])
            elif len(seg) == 1:
                segs.append(seg.upper())
            else:
                segs.append(seg)
        chords.append("+".join(segs))
    return " ".join(chords)


lines = [
    BEGIN,
    "<!-- source: cursor/keybindings.json -->",
    "<!-- generator: gen-keybindings-doc.py — do not edit by hand; re-run the script to regenerate -->",
    "",
    "| Chord | Command | When |",
    "|-------|---------|------|",
]
for b in bindings:
    chord = pretty_key(b.get("key", ""))
    cmd = b.get("command", "")
    when = b.get("when", "")
    when_cell = "`%s`" % when if when else "—"
    lines.append("| `%s` | `%s` | %s |" % (chord, cmd, when_cell))
lines.append(END)
block = "\n".join(lines)

if mode == "print":
    print(block)
    sys.exit(0)

with open(readme_path) as f:
    readme = f.read()

if BEGIN in readme and END in readme:
    pattern = re.compile(re.escape(BEGIN) + r".*?" + re.escape(END), re.DOTALL)
    new_readme = pattern.sub(block, readme)
    action = "replaced block"
else:
    if not readme.endswith("\n"):
        readme += "\n"
    new_readme = readme + "\n## Keybindings reference\n\n" + block + "\n"
    action = "appended new section"

with open(readme_path, "w") as f:
    f.write(new_readme)

print("README.md: %s" % action, file=sys.stderr)
