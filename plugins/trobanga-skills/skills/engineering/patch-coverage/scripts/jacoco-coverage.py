#!/usr/bin/env python3
"""Analyze JaCoCo XML reports for per-class coverage and missed branches.

Usage:
  jacoco-coverage.py <jacoco.xml> [--filter PATTERN] [--branches-only]

Examples:
  jacoco-coverage.py research-domain-agent/target/site/jacoco/jacoco.xml
  jacoco-coverage.py research-domain-agent/target/site/jacoco/jacoco.xml --filter IdMapper
  jacoco-coverage.py research-domain-agent/target/site/jacoco/jacoco.xml --filter IdMapper --branches-only
"""

import argparse
import sys
import xml.etree.ElementTree as ET

COUNTER_TYPES = ["INSTRUCTION", "BRANCH", "LINE", "COMPLEXITY", "METHOD"]


def parse_args():
    parser = argparse.ArgumentParser(description="Analyze JaCoCo XML coverage reports")
    parser.add_argument("xml_path", help="Path to jacoco.xml report")
    parser.add_argument(
        "--filter", "-f", default=None, help="Filter classes by name substring"
    )
    parser.add_argument(
        "--branches-only",
        "-b",
        action="store_true",
        help="Only show missed branch details",
    )
    return parser.parse_args()


def pct(covered, total):
    return (covered / total * 100) if total > 0 else 0.0


def print_class_coverage(root, class_filter):
    print("=== Coverage Summary ===")
    for cls in root.iter("class"):
        name = cls.get("name")
        short = name.split("/")[-1]
        if class_filter and class_filter not in name:
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


def print_missed_branches(root, class_filter):
    print("=== Missed Branches by Source Line ===")
    found_any = False
    for sf in root.iter("sourcefile"):
        src_name = sf.get("name")
        if class_filter and class_filter not in src_name.replace(".java", ""):
            continue

        missed_lines = []
        for line in sf.findall("line"):
            mb = int(line.get("mb", "0"))
            if mb > 0:
                cb = int(line.get("cb", "0"))
                missed_lines.append((line.get("nr"), mb, cb))

        if missed_lines:
            found_any = True
            print(f"\n  {src_name}:")
            for nr, mb, cb in missed_lines:
                total = mb + cb
                print(f"    Line {nr:>4s}: {cb}/{total} branches covered (missing {mb})")

    if not found_any:
        print("  None! All branches covered.")


def print_method_gaps(root, class_filter):
    print("\n=== Methods with Missed Branches ===")
    found_any = False
    for cls in root.iter("class"):
        name = cls.get("name")
        if class_filter and class_filter not in name:
            continue

        short = name.split("/")[-1]
        for method in cls.findall("method"):
            mname = method.get("name")
            for counter in method.findall("counter"):
                if counter.get("type") == "BRANCH":
                    missed = int(counter.get("missed"))
                    covered = int(counter.get("covered"))
                    if missed > 0:
                        found_any = True
                        total = missed + covered
                        print(
                            f"  {short}.{mname}(): {covered}/{total} branches"
                            f" (missing {missed})"
                        )

    if not found_any:
        print("  None! All method branches covered.")


def main():
    args = parse_args()

    try:
        tree = ET.parse(args.xml_path)
    except FileNotFoundError:
        print(f"Error: File not found: {args.xml_path}", file=sys.stderr)
        sys.exit(1)

    root = tree.getroot()

    if args.branches_only:
        print_missed_branches(root, args.filter)
        print_method_gaps(root, args.filter)
    else:
        print_class_coverage(root, args.filter)
        print_missed_branches(root, args.filter)
        print_method_gaps(root, args.filter)


if __name__ == "__main__":
    main()
