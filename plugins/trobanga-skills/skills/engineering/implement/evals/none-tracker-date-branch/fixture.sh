#!/usr/bin/env bash
# A small Python CLI in plain git, configured for tracker `none` and forge `none`.
# `origin` is a bare repository inside the run workspace, so fetching never
# touches the network. Runs in the empty run workspace (claude plugin eval --scaffold).
set -euo pipefail
export GIT_AUTHOR_NAME="Eval Dev" GIT_AUTHOR_EMAIL="dev@example.com"
export GIT_COMMITTER_NAME="Eval Dev" GIT_COMMITTER_EMAIL="dev@example.com"

git init -q -b main .
git config user.name "Eval Dev"
git config user.email "dev@example.com"

mkdir -p .agents tests
cat > .agents/issue-tracker.md <<'EOF'
# Issue tracker

**Tracker: none.** This project tracks its work nowhere: the work is whatever the
conversation describes.

**Forge: none.** Plain git. `origin` is a bare repository with no pull-request host;
review happens over the shoulder.

Branch names are `{id}--{slug}`. No deviations from the adapters.
EOF

cat > greet.py <<'EOF'
"""Greet a person by name."""
import argparse
import os


def resolve_name(cli_name):
    return cli_name or os.environ.get("GREET_NAME") or "world"


def main(argv=None):
    parser = argparse.ArgumentParser(prog="greet")
    parser.add_argument("name", nargs="?")
    args = parser.parse_args(argv)
    print(f"Hello, {resolve_name(args.name)}!")


if __name__ == "__main__":
    main()
EOF

cat > tests/test_greet.py <<'EOF'
from greet import resolve_name


def test_cli_name_wins():
    assert resolve_name("Ada") == "Ada"
EOF

git add -A
git commit -q -m "Add greet CLI"

git clone -q --bare . .origin.git
echo ".origin.git/" >> .git/info/exclude
git remote add origin "$PWD/.origin.git"
git fetch -q origin
git remote set-head origin main
git branch -q -u origin/main main
