"""Language-neutral CRAP score of the functions touched by a diff.

CRAP(f) = cc(f)^2 * (1 - coverage(f))^3 + cc(f)

The input is one JSON object per line, a "function record", produced by a
per-language collector:

    {"file": "src/foo.go", "name": "Foo.bar", "start": 10, "end": 14,
     "cc": 3, "coverage": 0.5}

`end` may be null, which means "to the end of the file". A function is
"touched" when at least one added line of the diff lies inside it.
"""

import json
import re
from collections import defaultdict

HUNK = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")


def added_lines(diff):
    """Map 'path/to/File' -> set of added line numbers."""
    result = defaultdict(set)
    path = None
    line = None
    for raw in diff:
        raw = raw.rstrip("\n")
        if raw.startswith("+++ "):
            path = raw[4:]
            path = path[2:] if path.startswith("b/") else path
            continue
        hunk = HUNK.match(raw)
        if hunk:
            line = int(hunk.group(1))
            continue
        if line is None:
            continue
        if raw.startswith("+"):
            result[path].add(line)
            line += 1
        elif not raw.startswith("-"):
            line += 1
    return result


def load(records):
    """Parse JSON lines; already parsed records pass through."""
    return [r if isinstance(r, dict) else json.loads(r)
            for r in records if isinstance(r, dict) or r.strip()]


def emit(records, out):
    """Write records as JSON lines, the interface of every collector."""
    for r in records:
        out.write(json.dumps(r) + "\n")


def reject_stale_report(report, changed_files):
    """A report older than a changed source describes other code: refuse it."""
    import os
    report_time = os.path.getmtime(report)
    stale = [f for f in changed_files
             if os.path.exists(f) and os.path.getmtime(f) > report_time]
    if stale:
        raise SystemExit(
            f"{report} is older than changed source {stale[0]}; "
            "rebuild the coverage report")


def crap(cc, coverage):
    return cc * cc * (1 - coverage) ** 3 + cc


def same_path(a, b):
    """True when the shorter path is a tail of the longer one.

    A collector may report a package path (Java) or an absolute path
    (Rust), the diff always reports a repository-relative path.
    """
    a, b = a.split("/"), b.split("/")
    n = min(len(a), len(b))
    return a[-n:] == b[-n:]


def lines_of(added, file):
    for path, lines in added.items():
        if same_path(file, path):
            yield from lines


def score(records, diff):
    """Return (name, cc, coverage, crap) for every touched function."""
    added = added_lines(diff)
    rows = []
    for r in load(records):
        end = r["end"] if r["end"] is not None else float("inf")
        if any(r["start"] <= n <= end for n in lines_of(added, r["file"])):
            rows.append((r["name"], r["cc"], r["coverage"],
                         crap(r["cc"], r["coverage"])))
    return rows


def coverage_kind(records):
    """The coverage kind the collector reports, for the footer."""
    kinds = {r.get("kind", "line") for r in records}
    return "/".join(sorted(kinds)) if kinds else "line"


def main(records, diff, threshold, out):
    records = load(records)
    rows = sorted(score(records, diff), key=lambda r: -r[3])
    failed = [r for r in rows if r[3] >= threshold]
    out.write(f"{'CRAP':>7} {'cc':>3} {'cov':>5}  function\n")
    for name, cc, coverage, value in rows:
        flag = " !" if value >= threshold else ""
        out.write(f"{value:7.1f} {cc:3d} {coverage:5.0%}  {name}{flag}\n")
    out.write(f"\n{len(rows)} changed functions, {len(failed)} at or above "
              f"{threshold:g} ({coverage_kind(records)} coverage)\n")
    return 1 if failed else 0
