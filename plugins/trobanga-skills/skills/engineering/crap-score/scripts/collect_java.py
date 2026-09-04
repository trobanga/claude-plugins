"""Function records for Java, from a JaCoCo XML report.

JaCoCo gives the first code line of a method and no end line. A method
ends where the next method of the same source file starts, across inner
classes. The last method of a file is open-ended.

Coverage is the branch coverage of the method. A method without branches
has no BRANCH counter; for it (cc = 1) line coverage is equivalent.
"""

import xml.etree.ElementTree as ET
from collections import defaultdict

import crap_core


def is_lambda(name):
    return name.startswith("lambda$")


def method_entry(m):
    counters = {
        c.get("type"): (int(c.get("missed")), int(c.get("covered")))
        for c in m.findall("counter")
    }
    cc = sum(counters["COMPLEXITY"])
    kind = "branch" if "BRANCH" in counters else "line"
    missed, covered = counters.get("BRANCH", counters["LINE"])
    return int(m.get("line")), m.get("name"), cc, covered / (missed + covered), kind


def with_ranges(entries):
    """Attach end = start of the next entry - 1; the last entry is open."""
    entries = sorted(entries)
    for i, entry in enumerate(entries):
        end = entries[i + 1][0] - 1 if i + 1 < len(entries) else None
        yield entry, end


def records(report, include_lambdas=False):
    """Yield one record per method of the report."""
    per_file = defaultdict(list)
    for package in ET.parse(report).iter("package"):
        for cls in package.findall("class"):
            key = package.get("name") + "/" + cls.get("sourcefilename")
            for m in cls.findall("method"):
                start, name, cc, coverage, kind = method_entry(m)
                per_file[key].append(
                    (start, cls.get("name"), name, cc, coverage, kind))
    for key, entries in per_file.items():
        named = [e for e in entries if not is_lambda(e[2])]
        lambdas = [e for e in entries if is_lambda(e[2])] if include_lambdas else []
        # a lambda lives inside a named method and must not cut its range
        for group in (named, lambdas):
            for (start, cls, name, cc, coverage, kind), end in with_ranges(group):
                yield {"file": key, "name": f"{cls}.{name}", "start": start,
                       "end": end, "cc": cc, "coverage": coverage, "kind": kind}


def collect(report, include_lambdas=False, **_):
    """The uniform collector interface: a report path -> records."""
    with open(report) as fh:
        return list(records(fh, include_lambdas))


def cli(argv=None):
    import argparse
    import sys

    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--report", required=True, help="JaCoCo XML report")
    p.add_argument("--include-lambdas", action="store_true")
    a = p.parse_args(argv)
    with open(a.report) as report:
        crap_core.emit(records(report, a.include_lambdas), sys.stdout)
    return 0


if __name__ == "__main__":
    raise SystemExit(cli())
