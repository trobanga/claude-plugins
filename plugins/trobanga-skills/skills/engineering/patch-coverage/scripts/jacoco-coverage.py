#!/usr/bin/env python3
"""Analyze JaCoCo XML reports for per-class coverage and missed branches.

Usage:
  jacoco-coverage.py <jacoco.xml>... [--filter PATTERN]... [--branches-only] [--quiet]

Give more than one report to analyze several Maven modules in one run.
--filter matches a class name exactly, so "Order" does not match "OrderService".
A nested class matches the name of its top-level class.
Repeat --filter to keep several classes.
--quiet prints nothing if the matched classes have no missed branch.

Exit codes:
  0  the matched classes have no missed branch
  1  a report file does not exist
  2  at least one matched class has a missed branch

Examples:
  jacoco-coverage.py target/site/jacoco/jacoco.xml
  jacoco-coverage.py target/site/jacoco/jacoco.xml --filter IdMapper
  jacoco-coverage.py a/jacoco.xml b/jacoco.xml -f IdMapper -f Router -b -q
"""

import argparse
import sys
import xml.etree.ElementTree as ET

COUNTER_TYPES = ["INSTRUCTION", "BRANCH", "LINE", "COMPLEXITY", "METHOD"]

# Exit code that reports at least one missed branch in the matched classes.
EXIT_GAPS = 2


def parse_args():
    parser = argparse.ArgumentParser(description="Analyze JaCoCo XML coverage reports")
    parser.add_argument(
        "xml_paths", nargs="+", help="Paths to one or more jacoco.xml reports"
    )
    parser.add_argument(
        "--filter",
        "-f",
        action="append",
        default=None,
        dest="filters",
        help="Keep only this class name. Exact match. Repeat to keep several.",
    )
    parser.add_argument(
        "--branches-only",
        "-b",
        action="store_true",
        help="Only show missed branch details",
    )
    parser.add_argument(
        "--quiet",
        "-q",
        action="store_true",
        help="Print nothing if the matched classes have no missed branch",
    )
    return parser.parse_args()


def pct(covered, total):
    return (covered / total * 100) if total > 0 else 0.0


def top_level_name(name):
    """Return the top-level class name.

    JaCoCo writes a class as a path, and a nested class with a dollar sign:
    "com/example/Outer$Inner" becomes "Outer".
    """
    return name.split("/")[-1].split("$")[0]


def matches(name, filters):
    """Report whether the class name equals any of the filter patterns.

    The match is exact, so the filter "Order" does not match "OrderService".
    A nested class matches the name of its top-level class.
    """
    if not filters:
        return True
    return top_level_name(name) in filters


def print_class_coverage(root, filters):
    print("=== Coverage Summary ===")
    for cls in root.iter("class"):
        name = cls.get("name")
        short = name.split("/")[-1]
        if not matches(name, filters):
            continue

        for counter in cls.findall("counter"):
            ctype = counter.get("type")
            if ctype not in COUNTER_TYPES:
                continue
            missed = int(counter.get("missed"))
            covered = int(counter.get("covered"))
            total = missed + covered
            p = pct(covered, total)
            marker = " <--" if p < 100 and ctype in ("BRANCH", "LINE") else ""
            print(f"  {short:35s} {ctype:15s} {p:6.1f}% ({covered}/{total}){marker}")
        print()


def print_section(heading, lines, empty_message, quiet):
    """Print a section. In quiet mode, print nothing if the section is empty."""
    if not lines and quiet:
        return
    print(heading)
    for line in lines:
        print(line)
    if not lines:
        print(empty_message)


def print_missed_branches(root, filters, quiet=False):
    lines = []
    for sf in root.iter("sourcefile"):
        src_name = sf.get("name")
        if not matches(src_name.replace(".java", ""), filters):
            continue

        missed_lines = []
        for line in sf.findall("line"):
            mb = int(line.get("mb", "0"))
            if mb > 0:
                cb = int(line.get("cb", "0"))
                missed_lines.append((line.get("nr"), mb, cb))

        if missed_lines:
            lines.append(f"\n  {src_name}:")
            for nr, mb, cb in missed_lines:
                total = mb + cb
                lines.append(
                    f"    Line {nr:>4s}: {cb}/{total} branches covered (missing {mb})"
                )

    print_section(
        "=== Missed Branches by Source Line ===",
        lines,
        "  None! All branches covered.",
        quiet,
    )
    return bool(lines)


def print_method_gaps(root, filters, quiet=False):
    lines = []
    for cls in root.iter("class"):
        name = cls.get("name")
        if not matches(name, filters):
            continue

        short = name.split("/")[-1]
        for method in cls.findall("method"):
            mname = method.get("name")
            for counter in method.findall("counter"):
                if counter.get("type") == "BRANCH":
                    missed = int(counter.get("missed"))
                    covered = int(counter.get("covered"))
                    if missed > 0:
                        total = missed + covered
                        lines.append(
                            f"  {short}.{mname}(): {covered}/{total} branches"
                            f" (missing {missed})"
                        )

    print_section(
        "\n=== Methods with Missed Branches ===",
        lines,
        "  None! All method branches covered.",
        quiet,
    )
    return bool(lines)


def main():
    args = parse_args()

    found_gaps = False

    for xml_path in args.xml_paths:
        try:
            tree = ET.parse(xml_path)
        except FileNotFoundError:
            print(f"Error: File not found: {xml_path}", file=sys.stderr)
            sys.exit(1)

        root = tree.getroot()

        if not args.branches_only and not args.quiet:
            print_class_coverage(root, args.filters)
        if print_missed_branches(root, args.filters, args.quiet):
            found_gaps = True
        if print_method_gaps(root, args.filters, args.quiet):
            found_gaps = True

    sys.exit(EXIT_GAPS if found_gaps else 0)


if __name__ == "__main__":
    main()
