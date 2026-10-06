#!/usr/bin/env bash
# A shop repo whose .agents/issue-tracker.md says GitHub Issues on acme/shop.
# Nothing is fetched. Runs in the empty run workspace (claude plugin eval --scaffold).
set -euo pipefail
export GIT_AUTHOR_NAME="Eval Dev" GIT_AUTHOR_EMAIL="dev@example.com"
export GIT_COMMITTER_NAME="Eval Dev" GIT_COMMITTER_EMAIL="dev@example.com"

git init -q -b main .
git config user.name "Eval Dev"
git config user.email "dev@example.com"
mkdir -p .agents shop
cat > .agents/issue-tracker.md <<'EOF'
# Issue tracker

Issues and pull requests live on **GitHub**, `acme/shop`. The repo has a second
remote, so pass `--repo acme/shop` to every `gh` command.

Branch names are `{id}-{slug}`: the ids are numeric.
EOF
cat > shop/cart.py <<'EOF'
from decimal import Decimal


def line_total(unit_price: float, quantity: int) -> Decimal:
    return Decimal(unit_price * quantity).quantize(Decimal("0.01"))
EOF
git add -A
git commit -q -m "Initial commit"
git remote add origin https://github.com/acme/shop.git
git remote add upstream https://github.com/acme-old/shop.git
