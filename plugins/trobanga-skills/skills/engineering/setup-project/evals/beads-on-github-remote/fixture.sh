#!/usr/bin/env bash
# Code on GitHub (origin URL, .github/ issue templates), work tracked in beads
# (.beads/ with prefix `wid`, branches `wid-12--...`). Nothing is fetched: the
# origin URL is only recorded. Runs in the empty run workspace (--scaffold).
set -euo pipefail
export GIT_AUTHOR_NAME="Eval Dev" GIT_AUTHOR_EMAIL="dev@example.com"
export GIT_COMMITTER_NAME="Eval Dev" GIT_COMMITTER_EMAIL="dev@example.com"

git init -q -b main .
git config user.name "Eval Dev"
git config user.email "dev@example.com"

mkdir -p .beads .github/ISSUE_TEMPLATE src
cat > .beads/config.yaml <<'EOF'
# beads configuration
issue-prefix: "wid"
EOF
cat > .github/ISSUE_TEMPLATE/bug.md <<'EOF'
---
name: Bug report
about: Report a bug in widget
---
EOF
cat > README.md <<'EOF'
# widget

Renders widgets. See `src/`.
EOF
echo 'def render(): return "widget"' > src/widget.py
git add -A
git commit -q -m "Initial commit"
git branch wid-12--fix-upload-timeout
git branch wid-15--cache-auth-tokens
git remote add origin https://github.com/acme/widget.git
