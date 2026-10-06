#!/usr/bin/env bash
# Tracker beads (prefix `wid`), forge `none`, bare `origin` inside the workspace.
# There is no beads database, so issue state cannot be read. Worktrees:
#   .claude/worktrees/wid-7--retry-uploads      merged, clean      -> id wid-7, safe to remove
#   .claude/worktrees/wid-12--cache-auth-tokens unmerged, clean    -> id wid-12, review first
#   .claude/worktrees/spike-graphql             unmerged, clean    -> Issue: unknown, review first
#   .worktrees/wid-3--document-config           unmerged, clean    -> id wid-3, legacy, review first
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

Issues live in **beads**, id prefix `wid` (for example `wid-12`). Code lives in plain
git: **forge none**, `origin` is a bare repository with no pull-request host.

Branch names are `{id}--{slug}`, for example `wid-12--cache-auth-tokens`; the double
separator is needed because the bead id itself contains a hyphen.
EOF
echo "# widget" > README.md
git add -A
git commit -q -m "Initial commit"
printf '.origin.git/\n.claude/worktrees/\n.worktrees/\n' >> .git/info/exclude

branch_commit() { # branch file message
  git switch -q -c "$1" main
  echo "$3" > "$2"
  git add "$2"
  git commit -q -m "$3"
  git switch -q main
}
branch_commit wid-7--retry-uploads retry.py "Retry failed uploads"
branch_commit wid-12--cache-auth-tokens cache.py "Cache auth tokens"
branch_commit spike-graphql schema.graphql "GraphQL spike"
branch_commit wid-3--document-config CONFIG.md "Document configuration"
git merge -q --no-ff -m "Merge wid-7" wid-7--retry-uploads

git clone -q --bare . .origin.git
git remote add origin "$PWD/.origin.git"
git fetch -q origin
git remote set-head origin main
git branch -q -u origin/main main

mkdir -p .claude/worktrees .worktrees
for b in wid-7--retry-uploads wid-12--cache-auth-tokens spike-graphql; do
  git worktree add -q ".claude/worktrees/$b" "$b"
done
git worktree add -q .worktrees/wid-3--document-config wid-3--document-config
