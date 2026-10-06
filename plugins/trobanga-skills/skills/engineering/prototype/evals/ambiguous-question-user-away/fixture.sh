#!/usr/bin/env bash
# Builds a Python backend module for reservations, persisted in SQLite,
# with no UI code in the repo.
set -euo pipefail

mkdir -p reservations

cat > pyproject.toml <<'EOF'
[project]
name = "toolshed"
version = "0.1.0"
requires-python = ">=3.11"

[project.scripts]
toolshed = "reservations.cli:main"
EOF

cat > reservations/__init__.py <<'EOF'
EOF

cat > reservations/store.py <<'EOF'
import sqlite3


def connect(path: str = "toolshed.db") -> sqlite3.Connection:
    db = sqlite3.connect(path)
    db.execute("CREATE TABLE IF NOT EXISTS reservations (tool_id, member_id, created_at)")
    return db


def add(db: sqlite3.Connection, tool_id: str, member_id: str, created_at: str) -> None:
    db.execute("INSERT INTO reservations VALUES (?, ?, ?)", (tool_id, member_id, created_at))
EOF

cat > reservations/cli.py <<'EOF'
import sys

from reservations import store


def main():
    db = store.connect()
    store.add(db, sys.argv[1], sys.argv[2], sys.argv[3])
EOF
