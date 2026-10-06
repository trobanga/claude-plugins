#!/usr/bin/env bash
# A small platform repo: a CLI with a --verbose flag, and a billing package that
# bills through Stripe. Tracker: GitHub acme/platform (never reached). Runs in the
# empty run workspace (claude plugin eval --scaffold).
set -euo pipefail
export GIT_AUTHOR_NAME="Eval Dev" GIT_AUTHOR_EMAIL="dev@example.com"
export GIT_COMMITTER_NAME="Eval Dev" GIT_COMMITTER_EMAIL="dev@example.com"

git init -q -b main .
git config user.name "Eval Dev"
git config user.email "dev@example.com"
mkdir -p .agents cli billing
cat > .agents/issue-tracker.md <<'EOF'
# Issue tracker

Issues and pull requests live on **GitHub**, `acme/platform`; pass
`--repo acme/platform` to `gh`. GitHub's native issue dependencies and sub-issues are
enabled. Branch names are `{id}-{slug}`: the ids are numeric.
EOF
cat > cli/main.py <<'EOF'
import argparse


def build_parser():
    parser = argparse.ArgumentParser(prog="plat")
    parser.add_argument("--verbose", action="store_true", help="print debug output")
    return parser
EOF
cat > billing/stripe_billing.py <<'EOF'
"""Subscriptions are billed by Stripe Billing; we mirror invoices locally."""


def create_subscription(customer, plan):
    raise NotImplementedError("calls the Stripe API")
EOF
echo "# platform" > README.md
git add -A
git commit -q -m "Platform: CLI and billing"
git remote add origin https://github.com/acme/platform.git
