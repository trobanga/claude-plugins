#!/usr/bin/env bash
# Plain git repo, tracker `none`, forge `none`, bare `origin` inside the workspace.
# A worktree for OPS-881 already exists from an earlier session, with one WIP commit.
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

**Tracker: none.** Ops tickets live in an internal system these skills cannot
reach; when a ticket number exists, it is given in the conversation.

**Forge: none.** Plain git; `origin` is a bare repository with no pull-request host.

Branch names are `{id}--{slug}`. No deviations from the adapters.
EOF

cat > signing.py <<'EOF'
"""Sign payloads for the webhook relay."""
import hashlib
import hmac

SIGNING_KEY = b"dev-key-do-not-ship"


def sign(payload: bytes) -> str:
    return hmac.new(SIGNING_KEY, payload, hashlib.sha256).hexdigest()
EOF
git add -A
git commit -q -m "Add webhook signing"

git clone -q --bare . .origin.git
printf '.origin.git/\n.claude/worktrees/\n' >> .git/info/exclude
git remote add origin "$PWD/.origin.git"
git fetch -q origin
git remote set-head origin main
git branch -q -u origin/main main

mkdir -p .claude/worktrees
git worktree add -q -b ops-881--rotate-the-signing-keys \
  .claude/worktrees/ops-881--rotate-the-signing-keys origin/main
(
  cd .claude/worktrees/ops-881--rotate-the-signing-keys
  sed -i 's/^SIGNING_KEY = .*/SIGNING_KEY = os.environ["SIGNING_KEY"].encode()/' signing.py
  sed -i 's/^import hmac$/import hmac\nimport os/' signing.py
  git commit -q -am "WIP: read signing key from the environment"
)
