"""Function records for Rust, from cargo-crap.

cargo-crap (https://github.com/minikin/cargo-crap) reads an LCOV file and
the source, and reports file, line, cyclomatic complexity and coverage
per function. This collector runs it and maps its entries.

    cargo llvm-cov --lcov --output-path lcov.info
    cargo crap --lcov lcov.info --format json

cargo-crap gives the first line of a function and no last line, so a
function ends where the next function of the same file starts, as in
Java. Its coverage comes from the DA records of the LCOV file, which are
line counts.
"""

import json
import subprocess

import crap_core


def clean(path):
    return path[2:] if path.startswith("./") else path


def with_ranges(entries):
    """Attach end = start of the next function - 1; the last one is open."""
    per_file = {}
    for e in entries:
        per_file.setdefault(clean(e["file"]), []).append(e)
    for file, group in per_file.items():
        group.sort(key=lambda e: e["line"])
        for i, e in enumerate(group):
            end = group[i + 1]["line"] - 1 if i + 1 < len(group) else None
            yield file, e, end


def records(report):
    """Yield one record per entry of a cargo-crap JSON report."""
    if "entries" not in report:
        raise SystemExit(
            "the cargo-crap report has no entries; expected the JSON of "
            "cargo crap --format json")
    for file, e, end in with_ranges(report["entries"]):
        yield {"file": file, "name": e["function"], "start": e["line"],
               "end": end, "cc": int(e["cyclomatic"]),
               "coverage": e["coverage"] / 100, "kind": "line"}


def run_cargo_crap(lcov, root="."):
    out = subprocess.run(
        ["cargo", "crap", "--lcov", lcov, "--format", "json"],
        cwd=root, capture_output=True, text=True)
    if out.returncode not in (0, 1):  # 1 means "above its own threshold"
        raise SystemExit(f"cargo crap failed: {out.stderr.strip()}")
    return json.loads(out.stdout)


def collect(report, root=".", **_):
    return list(records(run_cargo_crap(report, root)))


def cli(argv=None):
    import argparse
    import sys

    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--report", default="lcov.info",
                   help="LCOV file of cargo llvm-cov")
    a = p.parse_args(argv)
    crap_core.emit(collect(a.report), sys.stdout)
    return 0


if __name__ == "__main__":
    raise SystemExit(cli())
