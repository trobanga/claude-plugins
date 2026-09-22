"""Function records for Go, from a `go test -coverprofile` profile.

The profile gives blocks of statements with a line range and a hit count.
The helper `crap_funcs.go` gives the line range and the cyclomatic
complexity of every function, from the Go AST.

Coverage is the share of covered statements of the function. Go counts
statements, not branches, but the cover tool cuts a block at every
branch, so an uncovered branch always lowers the number.
"""

import json
import os
import re
import subprocess

import crap_core

HELPER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "crap_funcs.go")

BLOCK = re.compile(r"^(.+):(\d+)\.(\d+),(\d+)\.(\d+) (\d+) (\d+)$")


def module_path(root="."):
    """The module path of go.mod, the prefix of every profile file name."""
    with open(os.path.join(root, "go.mod")) as fh:
        for line in fh:
            if line.startswith("module "):
                return line.split()[1]
    raise SystemExit("go.mod names no module")


def parse_profile(profile, module):
    """Map a repository-relative path -> [(start, end, statements, count)].

    A profile holds one line per block per test binary, so `-coverpkg` gives
    more than one line for the same block. Such lines become one block, and
    their counts add up, as `go tool cover` folds them together.

    Two different blocks can share a line range, because a source line can
    hold more than one block. The columns keep them apart.
    """
    merged = {}
    prefix = module + "/"
    for line in profile:
        m = BLOCK.match(line.strip())
        if not m:
            continue
        name, start, scol, end, ecol, stmts, count = m.groups()
        if not name.startswith(prefix):
            continue  # a file of a dependency, not of this module
        counts = merged.setdefault(name[len(prefix):], {})
        key = (int(start), int(scol), int(end), int(ecol), int(stmts))
        counts[key] = counts.get(key, 0) + int(count)
    return {path: [(start, end, stmts, count)
                   for (start, _sc, end, _ec, stmts), count in counts.items()]
            for path, counts in merged.items()}


def coverage_of(function, blocks):
    total = covered = 0
    for start, _end, stmts, count in blocks.get(function["file"], ()):
        if function["start"] <= start <= function["end"]:
            total += stmts
            covered += stmts if count else 0
    return covered / total if total else 0.0


def records(functions, blocks):
    for f in functions:
        yield {"file": f["file"], "name": f["name"], "start": f["start"],
               "end": f["end"], "cc": f["cc"],
               "coverage": coverage_of(f, blocks), "kind": "statement"}


def functions_of(paths):
    """Run the Go helper over the source files named in the profile."""
    if not paths:
        return []
    out = subprocess.run(["go", "run", HELPER], input="\n".join(paths),
                         check=True, capture_output=True, text=True).stdout
    return [json.loads(line) for line in out.splitlines() if line.strip()]


def collect(report, root=".", **_):
    with open(report) as fh:
        blocks = parse_profile(fh, module_path(root))
    paths = [p for p in blocks if os.path.exists(os.path.join(root, p))]
    return list(records(functions_of(sorted(paths)), blocks))


def cli(argv=None):
    import argparse
    import sys

    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--report", default="coverage.out", help="go cover profile")
    a = p.parse_args(argv)
    crap_core.emit(collect(a.report), sys.stdout)
    return 0


if __name__ == "__main__":
    raise SystemExit(cli())
