#!/usr/bin/env bash
# Plain git repo, tracker `none`, forge `none`, bare `origin` inside the workspace.
# Worktrees:
#   .claude/worktrees/20260901--add-csv-export     merged into origin/main, clean    -> safe to remove
#   .claude/worktrees/20260915--fix-date-parsing   merged, but uncommitted changes    -> review first
#   .claude/worktrees/20260920--new-importer       unmerged commit, clean            -> review first
#   .worktrees/20260801--old-docs                  merged, clean, legacy location     -> safe to remove (legacy)
#   scratch-wt                                     branch `experiment`, not managed   -> not listed
# Runs in the empty run workspace (claude plugin eval --scaffold).
set -euo pipefail
export GIT_AUTHOR_NAME="Eval Dev" GIT_AUTHOR_EMAIL="dev@example.com"
export GIT_COMMITTER_NAME="Eval Dev" GIT_COMMITTER_EMAIL="dev@example.com"

git init -q -b main .
git config user.name "Eval Dev"
git config user.email "dev@example.com"
mkdir -p .agents
cat > .agents/issue-tracker.md <<'EOF'
# Issue tracker

**Tracker: none.** Work is tracked nowhere; branch ids are dates (`YYYYMMDD`).

**Forge: none.** Plain git; `origin` is a bare repository with no pull-request host.

Branch names are `{id}--{slug}`.
EOF
echo "# ledger" > README.md
git add -A
git commit -q -m "Initial commit"
printf '.origin.git/\n.claude/worktrees/\n.worktrees/\nscratch-wt/\n' >> .git/info/exclude

branch_commit() { # branch file message
  git switch -q -c "$1" main
  echo "$3" > "$2"
  git add "$2"
  git commit -q -m "$3"
  git switch -q main
}
branch_commit 20260801--old-docs docs.md "Document the ledger format"
branch_commit 20260901--add-csv-export export.py "Add CSV export"
branch_commit 20260915--fix-date-parsing dates.py "Fix date parsing"
branch_commit 20260920--new-importer importer.py "Add new importer"
branch_commit experiment spike.py "Spike"
git merge -q --no-ff -m "Merge old docs" 20260801--old-docs
git merge -q --no-ff -m "Merge CSV export" 20260901--add-csv-export
git merge -q --no-ff -m "Merge date parsing fix" 20260915--fix-date-parsing

git clone -q --bare . .origin.git
git remote add origin "$PWD/.origin.git"
git fetch -q origin
git remote set-head origin main
git branch -q -u origin/main main

mkdir -p .claude/worktrees .worktrees
git worktree add -q .claude/worktrees/20260901--add-csv-export 20260901--add-csv-export
git worktree add -q .claude/worktrees/20260915--fix-date-parsing 20260915--fix-date-parsing
git worktree add -q .claude/worktrees/20260920--new-importer 20260920--new-importer
git worktree add -q .worktrees/20260801--old-docs 20260801--old-docs
git worktree add -q scratch-wt experiment
echo "# also handle two-digit years" >> .claude/worktrees/20260915--fix-date-parsing/dates.py
