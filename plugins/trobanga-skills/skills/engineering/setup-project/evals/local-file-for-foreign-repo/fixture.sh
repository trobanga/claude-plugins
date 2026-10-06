#!/usr/bin/env bash
# Another team's repo: CLAUDE.md says the team tracks work in GitHub Issues. The
# user tracks their own work on it in beads. Nothing is fetched. Runs in the empty
# run workspace (--scaffold).
set -euo pipefail
export GIT_AUTHOR_NAME="Eval Dev" GIT_AUTHOR_EMAIL="dev@example.com"
export GIT_COMMITTER_NAME="Eval Dev" GIT_COMMITTER_EMAIL="dev@example.com"

git init -q -b main .
git config user.name "Eval Dev"
git config user.email "dev@example.com"
cat > CLAUDE.md <<'EOF'
# shop

## Issue tracking

Work is tracked in GitHub Issues on acme/shop. Branches are named `{id}-{slug}`,
for example `318-fix-cart-rounding`.

## Tests

Run `make test`.
EOF
echo "# shop" > README.md
git add -A
git commit -q -m "Initial commit"
git remote add origin https://github.com/acme/shop.git
