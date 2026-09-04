"""Per-method CRAP score for methods touched by a diff.

CRAP(m) = cc(m)^2 * (1 - coverage(m))^3 + cc(m)

cc and coverage come from a JaCoCo XML report. A method is "touched"
when at least one added line of the diff lies inside it.
"""

import io
import re
import xml.etree.ElementTree as ET
from collections import defaultdict

HUNK = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")


def added_lines(diff):
    """Map 'package/path/File.java' -> set of added line numbers."""
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
            result[source_key(path)].add(line)
            line += 1
        elif not raw.startswith("-"):
            line += 1
    return result


def source_key(path):
    """Strip the maven module and source-root prefix: keep package path + file."""
    marker = "/src/main/java/"
    idx = path.find(marker)
    return path[idx + len(marker):] if idx >= 0 else path


def is_lambda(name):
    return name.startswith("lambda$")


def method_entry(m):
    counters = {
        c.get("type"): (int(c.get("missed")), int(c.get("covered")))
        for c in m.findall("counter")
    }
    cc = sum(counters["COMPLEXITY"])
    # branch coverage measures the paths cc counts; methods without branches
    # have no BRANCH counter, and for them (cc = 1) line coverage is equivalent
    missed, covered = counters.get("BRANCH", counters["LINE"])
    return int(m.get("line")), m.get("name"), cc, covered / (missed + covered)


def with_ranges(entries):
    """Attach last_line = start of next entry - 1; the last entry is open-ended."""
    entries = sorted(entries)
    for i, (first, cls, name, cc, coverage) in enumerate(entries):
        last = entries[i + 1][0] - 1 if i + 1 < len(entries) else float("inf")
        yield cls, name, first, last, cc, coverage


def methods(report, include_lambdas=False):
    """Yield (source_key, class, name, first_line, last_line, cc, coverage).

    Ranges are computed per source file, so a method of an inner class ends
    the range of the outer class's preceding method.
    """
    per_file = defaultdict(list)
    for package in ET.parse(report).iter("package"):
        for cls in package.findall("class"):
            key = package.get("name") + "/" + cls.get("sourcefilename")
            for m in cls.findall("method"):
                first, name, cc, coverage = method_entry(m)
                per_file[key].append((first, cls.get("name"), name, cc, coverage))
    for key, entries in per_file.items():
        named = [e for e in entries if not is_lambda(e[2])]
        lambdas = [e for e in entries if is_lambda(e[2])] if include_lambdas else []
        # lambdas live inside a named method and must not cut its range
        for group in (named, lambdas):
            for row in with_ranges(group):
                yield (key,) + row


def crap(cc, coverage):
    return cc * cc * (1 - coverage) ** 3 + cc


def score(report, diff, include_lambdas=False):
    added = added_lines(diff)
    rows = []
    for key, cls, name, first, last, cc, coverage in methods(report, include_lambdas):
        if any(first <= n <= last for n in added.get(key, ())):
            rows.append((cls, name, cc, coverage, crap(cc, coverage)))
    return rows


def main(report, diff, threshold, include_lambdas, out):
    rows = sorted(score(report, diff, include_lambdas), key=lambda r: -r[4])
    failed = [r for r in rows if r[4] >= threshold]
    out.write(f"{'CRAP':>7} {'cc':>3} {'cov':>5}  method\n")
    for cls, name, cc, coverage, value in rows:
        flag = " !" if value >= threshold else ""
        out.write(f"{value:7.1f} {cc:3d} {coverage:5.0%}  {cls}.{name}{flag}\n")
    out.write(f"\n{len(rows)} changed methods, {len(failed)} at or above {threshold}\n")
    return 1 if failed else 0


def reject_stale_report(report, changed_files):
    """A report older than a changed source describes other code: refuse it."""
    import os
    report_time = os.path.getmtime(report)
    stale = [f for f in changed_files
             if os.path.exists(f) and os.path.getmtime(f) > report_time]
    if stale:
        raise SystemExit(
            f"{report} is older than changed source {stale[0]}; "
            "rebuild the report (mvn verify jacoco:report)")


def cli(argv=None):
    import argparse
    import subprocess
    import sys

    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--report", required=True, help="JaCoCo XML report")
    src = p.add_mutually_exclusive_group(required=True)
    src.add_argument("--diff", help="unified diff file, or '-' for stdin")
    src.add_argument("--range", help="git revision range, e.g. origin/main...HEAD")
    p.add_argument("--threshold", type=float, default=8)
    p.add_argument("--include-lambdas", action="store_true")
    a = p.parse_args(argv)

    if a.range:
        git = lambda *args: subprocess.run(
            ["git", *args], check=True, capture_output=True, text=True).stdout
        reject_stale_report(
            a.report, git("diff", "--name-only", a.range, "--", "*.java").split())
        diff = io.StringIO(git("diff", "-U0", a.range, "--", "*.java"))
    elif a.diff == "-":
        diff = sys.stdin
    else:
        diff = open(a.diff)
    with open(a.report) as report:
        return main(report, diff, a.threshold, a.include_lambdas, sys.stdout)


if __name__ == "__main__":
    raise SystemExit(cli())
