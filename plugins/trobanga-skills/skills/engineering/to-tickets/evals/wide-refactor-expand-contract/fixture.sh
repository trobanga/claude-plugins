#!/usr/bin/env bash
# A Python monorepo with 14 packages; every package reads `customer_ref` (about 300
# call sites in total) through the shared `CustomerRef` type. Tracker none: tickets
# are local Markdown files under .agents/issues/. Runs in the empty run workspace (--scaffold).
set -euo pipefail
export GIT_AUTHOR_NAME="Eval Dev" GIT_AUTHOR_EMAIL="dev@example.com"
export GIT_COMMITTER_NAME="Eval Dev" GIT_COMMITTER_EMAIL="dev@example.com"

git init -q -b main .
git config user.name "Eval Dev"
git config user.email "dev@example.com"
mkdir -p .agents core db
cat > .agents/issue-tracker.md <<'EOF'
# Issue tracker

**Tracker: none.** This project keeps tickets as local Markdown files under
`.agents/issues/`, one file per ticket. **Forge: none** (plain git).

Branch names are `{id}--{slug}`.
EOF
cat > core/types.py <<'EOF'
from typing import NewType

CustomerRef = NewType("CustomerRef", str)
EOF
echo 'ALTER TABLE orders ADD COLUMN customer_ref TEXT NOT NULL;' > db/0007_customer_ref.sql
for pkg in billing shipping returns loyalty search reports notifications \
           invoicing refunds subscriptions analytics support crm exports; do
  mkdir -p "$pkg"
  for i in $(seq 1 3); do
    {
      echo "from core.types import CustomerRef"
      echo
      for j in $(seq 1 7); do
        echo "def handler_${i}_${j}(order) -> CustomerRef:"
        echo "    return CustomerRef(order['customer_ref'])"
      done
    } > "$pkg/module_$i.py"
  done
done
git add -A
git commit -q -m "Monorepo with customer_ref everywhere"
