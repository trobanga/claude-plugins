"""Function records for TypeScript and JavaScript, from Istanbul.

`coverage-final.json`, written by Istanbul, nyc, c8, Jest or Vitest, has
everything CRAP needs:

- `fnMap` gives the name and the line range of every function,
- `branchMap` gives every branch with one location per path, and `b`
  gives the hit count of each path,
- `statementMap` and `s` give the statements.

The complexity of a function is one plus the decisions of the branches
inside its range: a branch with n paths is n - 1 decisions. Coverage is
the share of covered branch paths, or the share of covered statements
when the function has no branch.
"""

import json
import os

import crap_core


def line_range(entry):
    loc = entry["loc"]
    return loc["start"]["line"], loc["end"]["line"]


def inside(first, last, entry):
    return first <= entry["loc"]["start"]["line"] <= last


def is_anonymous(name):
    return name.startswith("(anonymous")


def stem(path):
    return os.path.splitext(os.path.basename(path))[0]


def branch_coverage(data, first, last):
    """Covered paths / all paths of the branches inside the range."""
    total = covered = 0
    for bid, branch in data["branchMap"].items():
        if not inside(first, last, branch):
            continue
        counts = data["b"][bid]
        total += len(counts)
        covered += sum(1 for c in counts if c)
    return total, covered


def statement_coverage(data, first, last):
    total = covered = 0
    for sid, statement in data["statementMap"].items():
        line = statement["start"]["line"]
        if first <= line <= last:
            total += 1
            covered += 1 if data["s"][sid] else 0
    return total, covered


def complexity(data, first, last):
    decisions = sum(len(b["locations"]) - 1
                    for b in data["branchMap"].values()
                    if inside(first, last, b))
    return 1 + decisions


def records(coverage, include_anonymous=False):
    """Yield one record per function of an Istanbul coverage report."""
    for path, data in coverage.items():
        for fn in data["fnMap"].values():
            if is_anonymous(fn["name"]) and not include_anonymous:
                continue
            first, last = line_range(fn)
            total, covered = branch_coverage(data, first, last)
            kind = "branch"
            if not total:
                total, covered = statement_coverage(data, first, last)
                kind = "statement"
            yield {"file": path, "name": f"{stem(path)}.{fn['name']}",
                   "start": first, "end": last,
                   "cc": complexity(data, first, last),
                   "coverage": covered / total if total else 0.0,
                   "kind": kind}


def collect(report, include_anonymous=False, **_):
    with open(report) as fh:
        return list(records(json.load(fh), include_anonymous))


def cli(argv=None):
    import argparse
    import sys

    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--report", default="coverage/coverage-final.json",
                   help="Istanbul JSON coverage report")
    p.add_argument("--include-anonymous", action="store_true")
    a = p.parse_args(argv)
    crap_core.emit(collect(a.report, a.include_anonymous), sys.stdout)
    return 0


if __name__ == "__main__":
    raise SystemExit(cli())
