#!/usr/bin/env bash
# Builds a Python backend with a Loan state model persisted in SQLite and a
# Makefile as the task runner.
set -euo pipefail

mkdir -p lending tests

cat > Makefile <<'EOF'
.PHONY: test
test:
	python3 -m unittest discover -s tests -v
EOF

cat > lending/__init__.py <<'EOF'
EOF

cat > lending/loans.py <<'EOF'
"""Loan lifecycle. States: reserved -> out -> returned; out -> overdue -> returned."""
from dataclasses import dataclass, field
from datetime import date, timedelta


@dataclass
class Loan:
    tool_id: str
    member_id: str
    state: str = "reserved"
    due: date | None = None
    renewals: int = 0
    waiting_reservations: list[str] = field(default_factory=list)


def pick_up(loan: Loan, today: date) -> None:
    loan.state = "out"
    loan.due = today + timedelta(days=7)


def renew(loan: Loan) -> None:
    loan.due = loan.due + timedelta(days=7)
    loan.renewals += 1


def mark_overdue(loan: Loan, today: date) -> None:
    if loan.state == "out" and today > loan.due:
        loan.state = "overdue"


def give_back(loan: Loan) -> None:
    loan.state = "returned"
EOF

cat > lending/db.py <<'EOF'
import sqlite3


def connect(path: str = "lending.db") -> sqlite3.Connection:
    db = sqlite3.connect(path)
    db.execute("CREATE TABLE IF NOT EXISTS loans (tool_id, member_id, state, due, renewals)")
    return db
EOF

cat > tests/__init__.py <<'EOF'
EOF
