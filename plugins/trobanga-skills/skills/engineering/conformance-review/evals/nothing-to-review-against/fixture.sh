#!/usr/bin/env bash
# A repo with no documented standards and no spec; branch `retry` (checked out)
# adds a retry helper with an obvious off-by-one. Commit messages carry no issue
# references; tracker none. Runs in the empty run workspace (--scaffold).
set -euo pipefail
export GIT_AUTHOR_NAME="Eval Dev" GIT_AUTHOR_EMAIL="dev@example.com"
export GIT_COMMITTER_NAME="Eval Dev" GIT_COMMITTER_EMAIL="dev@example.com"

git init -q -b main .
git config user.name "Eval Dev"
git config user.email "dev@example.com"
mkdir -p .agents net
cat > .agents/issue-tracker.md <<'EOF'
# Issue tracker

**Tracker: none.** **Forge: none** (plain git). Branch names are `{id}--{slug}`.
EOF
echo "# fetcher" > README.md
echo 'def get(url): raise NotImplementedError' > net/http.py
git add -A
git commit -q -m "Initial commit"
git switch -q -c retry
cat > net/retry.py <<'EOF'
import time


def with_retry(fn, attempts=3, delay=0.5):
    for i in range(attempts - 1):
        try:
            return fn()
        except Exception:
            time.sleep(delay)
    return None
EOF
git add -A
git commit -q -m "Add retry helper"
