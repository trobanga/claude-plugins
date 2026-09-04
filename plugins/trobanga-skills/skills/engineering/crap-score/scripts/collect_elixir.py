"""Function records for Elixir, from an ExCoveralls LCOV report.

The report gives a hit count per line. The helper `crap_funcs.exs` gives
the line range and the cyclomatic complexity of every `def` and `defp`
clause, from the Elixir AST.

Coverage is the share of covered lines of the function. Erlang's `cover`
counts lines and no branches, so a `case` arm that no test reaches
lowers the number only through the lines it holds.
"""

import json
import os
import subprocess

import crap_core

HELPER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "crap_funcs.exs")


def relative(path, root):
    """ExCoveralls writes absolute SF paths; the diff names relative ones."""
    prefix = os.path.abspath(root) + os.sep
    return path[len(prefix):] if path.startswith(prefix) else path


def parse_lcov(report, root="."):
    """Map a project-relative path -> {line: hit count}."""
    lines = {}
    current = None
    for raw in report:
        line = raw.strip()
        if line.startswith("SF:"):
            current = lines.setdefault(relative(line[3:], root), {})
        elif line.startswith("DA:") and current is not None:
            number, count = line[3:].split(",")[:2]
            current[int(number)] = int(count)
        elif line == "end_of_record":
            current = None
    return lines


def coverage_of(function, lines):
    hits = [count for number, count in lines.get(function["file"], {}).items()
            if function["start"] <= number <= function["end"]]
    return sum(1 for h in hits if h) / len(hits) if hits else 0.0


def records(functions, lines):
    for f in functions:
        yield {"file": f["file"], "name": f["name"], "start": f["start"],
               "end": f["end"], "cc": f["cc"],
               "coverage": coverage_of(f, lines), "kind": "line"}


def functions_of(paths):
    """Run the Elixir helper over the source files named in the report."""
    if not paths:
        return []
    out = subprocess.run(["elixir", HELPER], input="\n".join(paths),
                         check=True, capture_output=True, text=True).stdout
    return [json.loads(line) for line in out.splitlines() if line.strip()]


def collect(report, root=".", **_):
    with open(report) as fh:
        lines = parse_lcov(fh, root)
    paths = [p for p in lines if os.path.exists(os.path.join(root, p))]
    return list(records(functions_of(sorted(paths)), lines))


def cli(argv=None):
    import argparse
    import sys

    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--report", default="cover/lcov.info",
                   help="LCOV file of mix coveralls.lcov")
    a = p.parse_args(argv)
    crap_core.emit(collect(a.report), sys.stdout)
    return 0


if __name__ == "__main__":
    raise SystemExit(cli())
