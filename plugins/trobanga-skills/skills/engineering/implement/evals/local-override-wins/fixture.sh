#!/usr/bin/env bash
# The shared .agents/issue-tracker.md says GitHub with `{id}-{slug}`; the untracked
# personal override .agents/issue-tracker.local.md says tracker `none`, forge `none`,
# `{id}--{slug}`. `origin` is a bare mirror inside the workspace, so the shared
# GitHub config can never be reached. Runs in the empty run workspace (--scaffold).
set -euo pipefail
export GIT_AUTHOR_NAME="Eval Dev" GIT_AUTHOR_EMAIL="dev@example.com"
export GIT_COMMITTER_NAME="Eval Dev" GIT_COMMITTER_EMAIL="dev@example.com"

git init -q -b main .
git config user.name "Eval Dev"
git config user.email "dev@example.com"

mkdir -p .agents
cat > .agents/issue-tracker.md <<'EOF'
# Issue tracker

Issues live in **GitHub Issues** on `acme/uploader`. Code and pull requests live on
**GitHub** (`acme/uploader`); pass `--repo acme/uploader` to `gh`.

Branch names are `{id}-{slug}`, for example `214-retry-failed-uploads`: the ids are
numeric, and the existing branches already use this format.
EOF

cat > uploader.py <<'EOF'
"""Upload files to the archive."""


def upload(client, path):
    with open(path, "rb") as handle:
        return client.put(path, handle.read())
EOF
git add -A
git commit -q -m "Add uploader"

cat > .agents/issue-tracker.local.md <<'EOF'
# Issue tracker (personal override)

I work on this repo from an offline mirror; GitHub is not reachable from here, and
I copy issue numbers and titles over by hand.

**Tracker: none.** Take the issue number and title from the conversation.

**Forge: none.** `origin` is a bare local mirror; I push the branch and open the
pull request myself later.

Branch format: `{id}--{slug}`.
EOF
printf '.origin.git/\n.agents/issue-tracker.local.md\n' >> .git/info/exclude

git clone -q --bare . .origin.git
git remote add origin "$PWD/.origin.git"
git fetch -q origin
git remote set-head origin main
git branch -q -u origin/main main
