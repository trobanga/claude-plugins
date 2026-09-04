"""CRAP score of the functions a diff touches, for one of five languages.

    CRAP(f) = cc(f)^2 * (1 - coverage(f))^3 + cc(f)

This is the entry point. It detects the project type, runs the collector
of that language over a coverage report, and scores the records with
`crap_core`. Run a collector alone to inspect its records.
"""

import importlib
import io
import subprocess
import sys
from collections import namedtuple

import crap_core

Language = namedtuple("Language", "marker module report sources coverage")

LANGUAGES = {
    "java": Language(
        marker="pom.xml", module="collect_java",
        report="target/site/jacoco/jacoco.xml",
        sources=["*.java"], coverage="branch"),
    "go": Language(
        marker="go.mod", module="collect_go",
        report="coverage.out",
        sources=["*.go"], coverage="statement"),
    "rust": Language(
        marker="Cargo.toml", module="collect_rust",
        report="lcov.info",
        sources=["*.rs"], coverage="line"),
    "ts": Language(
        marker="package.json", module="collect_ts",
        report="coverage/coverage-final.json",
        sources=["*.ts", "*.tsx", "*.js", "*.jsx"], coverage="branch"),
}

# a Go or Java repository often ships a package.json for its frontend, so
# the backend markers are tested first
ORDER = ["java", "go", "rust", "ts"]

UNSUPPORTED = {"mix.exs": "Elixir"}


def detect(root="."):
    """Name the language of the project in `root`, from its build file."""
    import os
    for lang in ORDER:
        if os.path.exists(os.path.join(root, LANGUAGES[lang].marker)):
            return lang
    for marker, name in UNSUPPORTED.items():
        if os.path.exists(os.path.join(root, marker)):
            raise SystemExit(f"{name} is not supported by crap-score")
    raise SystemExit(
        "no pom.xml, go.mod, Cargo.toml or package.json found; "
        "give --lang explicitly")


def git(*args):
    return subprocess.run(["git", *args], check=True,
                          capture_output=True, text=True).stdout


def changed_sources(rev_range, patterns):
    return git("diff", "--name-only", rev_range, "--", *patterns).split()


def cli(argv=None):
    import argparse

    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--lang", choices=sorted(LANGUAGES), help="default: detect")
    p.add_argument("--report", help="coverage report of the language")
    p.add_argument("--records", help="skip the collector, read JSON lines")
    src = p.add_mutually_exclusive_group(required=True)
    src.add_argument("--diff", help="unified diff file, or '-' for stdin")
    src.add_argument("--range", help="git revision range, e.g. origin/main...HEAD")
    p.add_argument("--threshold", type=float, default=8)
    p.add_argument("--include-lambdas", action="store_true",
                   help="Java only: score lambdas as their own methods")
    a = p.parse_args(argv)

    lang = a.lang or detect()
    spec = LANGUAGES[lang]
    report = a.report or spec.report

    if a.range:
        changed = changed_sources(a.range, spec.sources)
        if not a.records:
            crap_core.reject_stale_report(report, changed)
        diff = io.StringIO(git("diff", "-U0", a.range, "--", *spec.sources))
    elif a.diff == "-":
        diff = sys.stdin
    else:
        diff = open(a.diff)

    if a.records:
        records = open(a.records)
    else:
        collector = importlib.import_module(spec.module)
        records = collector.collect(report, include_lambdas=a.include_lambdas)
    return crap_core.main(records, diff, a.threshold, sys.stdout)


if __name__ == "__main__":
    raise SystemExit(cli())
