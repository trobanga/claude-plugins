#!/usr/bin/env python3
"""Check that the marketplace manifest agrees with every plugin manifest.

For each entry in .claude-plugin/marketplace.json:
  - the `source` directory exists and holds .claude-plugin/plugin.json
  - `name`, `version` and `description` are the same in both files

Exits 1 and prints one line per problem.
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MARKETPLACE = ROOT / ".claude-plugin" / "marketplace.json"
FIELDS = ("name", "version", "description")


def load(path: Path):
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        print(f"{path.relative_to(ROOT)}: invalid JSON: {exc}")
        raise SystemExit(1)


def main() -> int:
    market = load(MARKETPLACE)
    problems = []
    seen = set()

    for entry in market.get("plugins", []):
        name = entry.get("name", "<unnamed>")
        if name in seen:
            problems.append(f"{name}: listed twice in marketplace.json")
        seen.add(name)

        source = entry.get("source")
        if not isinstance(source, str) or not source.startswith("./"):
            problems.append(f"{name}: source must be a relative path, got {source!r}")
            continue

        manifest = ROOT / source / ".claude-plugin" / "plugin.json"
        if not manifest.is_file():
            problems.append(f"{name}: missing {manifest.relative_to(ROOT)}")
            continue

        plugin = load(manifest)
        for field in FIELDS:
            if entry.get(field) != plugin.get(field):
                problems.append(
                    f"{name}: {field} differs — "
                    f"marketplace.json {entry.get(field)!r} vs plugin.json {plugin.get(field)!r}"
                )

        if not (ROOT / source / "README.md").is_file():
            problems.append(f"{name}: missing {source}/README.md")

    for directory in sorted((ROOT / "plugins").iterdir()):
        if directory.is_dir() and f"./plugins/{directory.name}" not in {
            e.get("source") for e in market.get("plugins", [])
        }:
            problems.append(f"plugins/{directory.name}: not listed in marketplace.json")

    for problem in problems:
        print(problem)

    if problems:
        print(f"\n{len(problems)} problem(s) found.")
        return 1

    print(f"{len(seen)} plugin(s) checked, all consistent.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
