#!/usr/bin/env python3
"""Build a branch name from an issue, or parse the issue id back out of a branch name.

    branch_name.py build --id GIAM-123 --title "Refuse deleted subject" [--format '{id}-{slug}']
    branch_name.py parse giam-123--refuse-deleted-subject [--format '{id}-{slug}']

`build` prints the branch name, `parse` prints the issue id (lowercase; uppercase it
again for Linear). Exit 0 on success, 1 when the input is wrong or the branch carries
no issue id (the message on stderr says what to do), 2 on a usage error.
Standard library only.
"""

import argparse
import re
import sys

DEFAULT_FORMAT = "{id}--{slug}"
SINGLE_FORMAT = "{id}-{slug}"
FORMATS = (DEFAULT_FORMAT, SINGLE_FORMAT)

# Long enough to say what the branch is about, short enough to keep
# `git branch` and worktree paths readable.
SLUG_MAX = 40

# A tracker id as it may stand in a branch name: lowercase letters, digits and
# the separators `.`, `_`, `-` inside (beads ids such as `gt--xyz` included).
BRANCH_ID = re.compile(r"[a-z0-9](?:[a-z0-9._-]*[a-z0-9])?")

# Branches from before the `{id}--{slug}` default, and GitHub repos that keep
# `{id}-{slug}`: a number, optionally behind `issue-`.
LEGACY_NUMERIC = re.compile(r"(?:issue-)?([0-9]+)(?:-|$)")


class InputError(Exception):
    """Bad input; the message tells the caller how to fix it."""


class UnknownId(InputError):
    """The branch carries no recoverable issue id."""


def slugify(title):
    # Collapsing every run of non-alphanumerics to one hyphen guarantees the slug
    # never contains `--`, so the last `--` of a branch name is always the separator.
    slug = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")
    return slug[:SLUG_MAX].rstrip("-")


def build(issue_id, title, fmt=DEFAULT_FORMAT):
    branch_id = issue_id.lower().lstrip("#")
    if not BRANCH_ID.fullmatch(branch_id):
        raise InputError(
            f"--id {issue_id!r} is not a bare issue id. Pass the id alone, as the "
            "tracker adapter's T4 gives it: 123, GIAM-123, bd-42 (not a URL, no spaces)."
        )
    slug = slugify(title)
    if not slug:
        raise InputError(
            f"--title {title!r} has no letters or digits, so it gives no slug. "
            "Pass the issue title as T1 returned it."
        )
    if fmt == SINGLE_FORMAT and not branch_id.isdigit():
        print(
            f"branch_name.py: warning: {fmt} with the non-numeric id {branch_id!r} "
            "cannot be parsed back; worktree-cleanup will report this branch as "
            f"Issue: unknown. Configure {DEFAULT_FORMAT} for this tracker.",
            file=sys.stderr,
        )
    return fmt.format(id=branch_id, slug=slug)


def parse(branch, fmt=DEFAULT_FORMAT):
    branch = branch.removeprefix("refs/heads/")
    legacy = LEGACY_NUMERIC.match(branch)
    if fmt == SINGLE_FORMAT and legacy:
        return legacy.group(1)
    issue_id, _, _ = branch.rpartition("--")
    if issue_id:
        return issue_id
    if legacy:
        return legacy.group(1)
    raise UnknownId(
        f"no issue id in branch {branch!r}. Report it as Issue: unknown and judge "
        "the worktree on the git facts alone; do not guess an id."
    )


def main(argv):
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    # An unset $BRANCH_FORMAT arrives as "", which means the default.
    fmt_help = f"the project's branch format (default {DEFAULT_FORMAT}, also for '')"
    sub = parser.add_subparsers(dest="command", required=True)
    b = sub.add_parser("build", help="print the branch name for an issue")
    b.add_argument("--id", required=True, help="the issue id, as T4 gives it")
    b.add_argument("--title", required=True, help="the issue title, as T1 gives it")
    b.add_argument("--format", default=DEFAULT_FORMAT, choices=FORMATS + ("",), help=fmt_help)
    p = sub.add_parser("parse", help="print the issue id a branch name carries")
    p.add_argument("branch", help="a branch name, with or without refs/heads/")
    p.add_argument("--format", default=DEFAULT_FORMAT, choices=FORMATS + ("",), help=fmt_help)
    args = parser.parse_args(argv)
    args.format = args.format or DEFAULT_FORMAT
    try:
        if args.command == "build":
            print(build(args.id, args.title, args.format))
        else:
            print(parse(args.branch, args.format))
    except InputError as error:
        print(f"branch_name.py: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
