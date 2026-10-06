#!/usr/bin/env bash
# GitHub Issues on acme/store, with a project-specific deviation recorded in
# .agents/issue-tracker.md: every issue needs exactly one `area:` label. Nothing
# is fetched. Runs in the empty run workspace (claude plugin eval --scaffold).
set -euo pipefail
export GIT_AUTHOR_NAME="Eval Dev" GIT_AUTHOR_EMAIL="dev@example.com"
export GIT_COMMITTER_NAME="Eval Dev" GIT_COMMITTER_EMAIL="dev@example.com"

git init -q -b main .
git config user.name "Eval Dev"
git config user.email "dev@example.com"
mkdir -p .agents checkout catalog accounts
cat > .agents/issue-tracker.md <<'EOF'
# Issue tracker

Issues and pull requests live on **GitHub**, `acme/store`.

Branch names are `{id}-{slug}`: the ids are numeric.

## Deviations

- **Required field on creation.** Every new issue carries exactly one area label:
  `area:checkout`, `area:catalog` or `area:accounts`. Triage closes issues without one.
EOF
echo 'def apply_coupon(total, code): return total' > checkout/coupons.py
echo 'def search(q): return []' > catalog/search.py
echo 'def login(u, p): return None' > accounts/login.py
git add -A
git commit -q -m "Initial commit"
git remote add origin https://github.com/acme/store.git
