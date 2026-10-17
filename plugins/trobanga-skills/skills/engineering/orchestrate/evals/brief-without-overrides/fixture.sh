#!/usr/bin/env bash
# A small Python HTTP backend with migrations, handlers, tests and API docs.
# Tracker none, forge none: specs are files under docs/specs/. Three spec files:
#   api-keys.md          locked spec, four requirements, one debatable locked decision
#   api-keys-slices.md   a pre-sliced epic for api-keys.md with one stale child and one gap
#   key-expiry.md        locked spec whose slices differ sharply in risk
# Runs in the empty run workspace (claude plugin eval --scaffold).
set -euo pipefail
export GIT_AUTHOR_NAME="Eval Dev" GIT_AUTHOR_EMAIL="dev@example.com"
export GIT_COMMITTER_NAME="Eval Dev" GIT_COMMITTER_EMAIL="dev@example.com"

git init -q -b main .
git config user.name "Eval Dev"
git config user.email "dev@example.com"
mkdir -p .agents app/handlers app/auth migrations tests docs/specs docs/adr
cat > .agents/issue-tracker.md <<'EOF'
# Issue tracker

**Tracker: none.** Specs and slices are Markdown files under `docs/specs/`; the spec
file is the issue. **Forge: none** (plain git).

Branch names are `{id}--{slug}`.
EOF
cat > GLOSSARY.md <<'EOF'
# Glossary

**API key** — a secret a client sends in the `X-Api-Key` header. Shown once, at creation.
**Key prefix** — the first 8 characters of an API key, stored in clear to identify it.
**Revoked** — an API key that is refused from now on; never deleted.
EOF
cat > docs/adr/0001-handlers-go-through-repositories.md <<'EOF'
# 0001 — Handlers go through repositories

Handlers never run SQL. Each table has a repository in `app/`; handlers call it.
EOF
cat > docs/specs/api-keys.md <<'EOF'
# Spec: API keys (LOCKED)

Decision map and research: docs/specs/api-keys-research.md (not reproduced here).

## Requirements

- **R1 Create.** `POST /keys` creates an API key for the calling user and returns it once.
- **R2 List.** `GET /keys` lists the caller's keys by key prefix and creation date; never the key.
- **R3 Revoke.** `DELETE /keys/{prefix}` marks a key revoked; revoked keys are refused.
- **R4 Storage.** Keys are stored as an unsalted SHA-256 hash. (Decided: keys are 256-bit
  random, so a salt adds nothing; see the decision map.)

Each requirement ships with its migration (if any), handler, tests, and a section in
`docs/api.md`.

## Out of scope

Rate limiting key creation. Key scopes.
EOF
cat > docs/specs/api-keys-slices.md <<'EOF'
# Epic: API keys — child slices (filed last month)

Parent spec: docs/specs/api-keys.md

1. **Create API keys** — `POST /keys`, migration for the `api_key` table, tests, docs.
2. **List API keys** — `GET /keys` by prefix and creation date, tests, docs.
3. **Rate-limit key creation** — at most 5 keys per user per hour, tests, docs.
EOF
cat > docs/specs/key-expiry.md <<'EOF'
# Spec: API key expiry (LOCKED)

- **E1 Rename the setting.** The setting `API_KEYS_TTL` becomes `API_KEY_TTL_DAYS`. It is read
  in `app/config.py`, `app/handlers/keys.py` and `tests/test_config.py`; the existing tests
  already cover reading it. Pure rename, no behaviour change.
- **E2 Refuse expired keys.** The auth middleware in `app/auth/middleware.py` refuses a key
  older than `API_KEY_TTL_DAYS` with 401, in constant time like the existing hash check, and
  logs the key prefix, never the key.
- **E3 Document expiry.** `docs/api.md` gets a section on expiry and the 401 response.
EOF
cat > app/config.py <<'EOF'
import os

API_KEYS_TTL = int(os.environ.get("API_KEYS_TTL", "90"))
EOF
cat > app/handlers/keys.py <<'EOF'
from app.config import API_KEYS_TTL


def ttl_days():
    return API_KEYS_TTL
EOF
cat > app/auth/middleware.py <<'EOF'
import hashlib
import hmac


def authenticate(header_key, stored_hash):
    candidate = hashlib.sha256(header_key.encode()).hexdigest()
    return hmac.compare_digest(candidate, stored_hash)
EOF
cat > tests/test_config.py <<'EOF'
from app import config


def test_default_ttl_is_90_days():
    assert config.API_KEYS_TTL == 90
EOF
echo "-- 0001: users" > migrations/0001_users.sql
echo "# API" > docs/api.md
touch app/__init__.py app/handlers/__init__.py app/auth/__init__.py
cat > AGENTS.md <<'EOF2'
# Agents

- Tests need Postgres on localhost:5432. The Claude Code sandbox blocks localhost, so
  `pytest` runs outside the sandbox.
- Never ask about a migration number: take the next free one.
EOF2
git add -A
git commit -q -m "Backend skeleton and specs"
