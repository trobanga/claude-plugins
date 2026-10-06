"""Prepare a skill for `claude plugin eval`, and report the results.

    python3 skill_eval.py prepare <skill-dir> <out-dir> [--drop START:END]
    python3 skill_eval.py report <aggregate-result.json> [<ablated.json>]

`prepare` copies the skill into <out-dir> so that the agent can fire it:
a user-invoked skill (`disable-model-invocation: true`) is invisible to the
agent, so its with-arm would equal its baseline. `--drop` deletes lines
START to END of SKILL.md from the copy, for ablation.

`report` prints, per case, the score with the skill, the baseline score and
their delta; given a second result, it compares the two with-arm scores.
"""

import argparse
import json
import os
import re
import shutil
import sys

# a skill reaches another skill of the same plugin through this prefix
SIBLING = re.compile(r"\$\{CLAUDE_SKILL_DIR\}/\.\./([\w.-]+)/")


def prepare(skill_dir, out_dir, drop=None):
    """Copy `skill_dir` into `out_dir`, invocable by the agent; return its path.

    `drop` is a (start, end) pair of 1-based, inclusive line numbers of the
    original SKILL.md to delete from the copy."""
    with open(os.path.join(skill_dir, "SKILL.md")) as f:
        lines = f.read().splitlines(keepends=True)
    if drop is not None:
        start, end = drop
        if not 1 <= start <= end <= len(lines):
            raise ValueError(f"cannot drop lines {start}:{end}; "
                             f"SKILL.md has {len(lines)} lines")
        lines = lines[:start - 1] + lines[end:]
    lines = [l for l in lines
             if not l.startswith("disable-model-invocation:")]
    path = os.path.join(out_dir, os.path.basename(os.path.normpath(skill_dir)))
    shutil.copytree(skill_dir, path)
    with open(os.path.join(path, "SKILL.md"), "w") as f:
        f.write("".join(lines))
    copy_siblings(skill_dir, out_dir)
    return path


def copy_siblings(skill_dir, out_dir):
    """Copy every sibling skill that `skill_dir` reaches through a
    `${CLAUDE_SKILL_DIR}/../<skill>/` path into `out_dir`, and the siblings
    those reach in turn, so the paths resolve in the copy. The eval loads only
    the skill under test; the siblings are files it reads or runs."""
    parent = os.path.dirname(os.path.normpath(skill_dir))
    todo = [skill_dir]
    while todo:
        for name in sorted(siblings(todo.pop())):
            target = os.path.join(out_dir, name)
            if not os.path.exists(target):
                shutil.copytree(os.path.join(parent, name), target)
                todo.append(os.path.join(parent, name))


def siblings(folder):
    """Names of the sibling skills that the text files in `folder` point at."""
    names = set()
    for root, _, files in os.walk(folder):
        for name in files:
            try:
                with open(os.path.join(root, name)) as f:
                    names.update(SIBLING.findall(f.read()))
            except (UnicodeDecodeError, OSError):
                continue
    return {n for n in names
            if os.path.isdir(os.path.join(os.path.dirname(
                os.path.normpath(folder)), n))}


def report(result, ablated=None):
    """One row per case. With one result: the with-arm score, the baseline
    score and the delta. With an ablated result too: both with-arm scores,
    their change, and WORSE where the ablation lowered the score."""
    scores = {c["name"]: c["aggregates"] for c in result["cases"]}
    if ablated is None:
        rows = [("case", "with", "without", "delta")]
        for name, a in scores.items():
            rows.append((name, f"{a['score']:.2f}",
                         f"{a['score'] - a['delta']:.2f}", f"{a['delta']:+.2f}"))
    else:
        rows = [("case", "full", "ablated", "change")]
        for case in ablated["cases"]:
            full = scores[case["name"]]["score"]
            change = case["aggregates"]["score"] - full
            rows.append((case["name"], f"{full:.2f}",
                         f"{case['aggregates']['score']:.2f}", f"{change:+.2f}")
                        + (("WORSE",) if round(change, 2) < 0 else ()))
    lines = [table(rows)]
    for r in (result, ablated):
        if r and r.get("partial"):
            lines.append(f"PARTIAL ({r.get('partialReason')}): "
                         "some runs did not finish; the scores are incomplete")
    return "\n".join(lines)


def table(rows):
    width = max(len(r[0]) for r in rows)
    return "\n".join(r[0].ljust(width) + "  " + "  ".join(c.rjust(7) for c in r[1:])
                     for r in rows)


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("prepare")
    p.add_argument("skill_dir")
    p.add_argument("out_dir")
    p.add_argument("--drop", metavar="START:END")
    r = sub.add_parser("report")
    r.add_argument("result")
    r.add_argument("ablated", nargs="?")
    args = parser.parse_args(argv)
    try:
        if args.command == "prepare":
            drop = None
            if args.drop:
                start, _, end = args.drop.partition(":")
                drop = (int(start), int(end or start))
            print(prepare(args.skill_dir, args.out_dir, drop))
        else:
            print(report(*[load(p) for p in (args.result, args.ablated) if p]))
    except (ValueError, OSError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    return 0


def load(path):
    with open(path) as f:
        return json.load(f)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
