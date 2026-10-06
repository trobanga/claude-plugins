#!/usr/bin/env bash
# Code on GitHub (origin URL, .github/ issue templates); .agents/issue-tracker.md
# says issues live in beads with prefix `wid`. Nothing is fetched. Runs in the
# empty run workspace (claude plugin eval --scaffold).
set -euo pipefail
export GIT_AUTHOR_NAME="Eval Dev" GIT_AUTHOR_EMAIL="dev@example.com"
export GIT_COMMITTER_NAME="Eval Dev" GIT_COMMITTER_EMAIL="dev@example.com"

git init -q -b main .
git config user.name "Eval Dev"
git config user.email "dev@example.com"
mkdir -p .agents .github/ISSUE_TEMPLATE src
cat > .agents/issue-tracker.md <<'EOF'
# Issue tracker

Issues live in **beads**, id prefix `wid`. Code and pull requests live on **GitHub**
(`acme/widget`); GitHub Issues are switched off for this repo.

Branch names are `{id}--{slug}`. No deviations from the adapters.
EOF
cat > .github/ISSUE_TEMPLATE/bug.md <<'EOF'
---
name: Bug report
about: Report a bug in widget
---
EOF
cat > src/export.py <<'EOF'
import csv


def export_rows(rows, handle):
    writer = csv.writer(handle)
    for row in rows:
        if any("," in str(cell) for cell in row):
            continue
        writer.writerow(row)
EOF
git add -A
git commit -q -m "Initial commit"
git remote add origin https://github.com/acme/widget.git
