#!/usr/bin/env bash
# Builds a git repo: main has a report module with inline formatting; the
# checked-out branch extracts the formatting into a function. Behaviour and
# tests are unchanged.
set -euo pipefail

g() { git -c user.name=Eval -c user.email=eval@example.com -c init.defaultBranch=main "$@"; }

g init -q
mkdir -p tests
touch tests/__init__.py

cat > report.py <<'EOF'
def overdue_report(loans: list[dict]) -> str:
    lines = []
    for loan in loans:
        if loan["days_late"] > 0:
            lines.append(f"{loan['member']:<12} {loan['tool']:<10} {loan['days_late']:>3} days")
    return "\n".join(lines)


def weekly_report(loans: list[dict]) -> str:
    lines = []
    for loan in loans:
        lines.append(f"{loan['member']:<12} {loan['tool']:<10} {loan['days_late']:>3} days")
    return "\n".join(lines)
EOF

cat > tests/test_report.py <<'EOF'
import unittest

from report import overdue_report, weekly_report

LOANS = [
    {"member": "ada", "tool": "drill", "days_late": 2},
    {"member": "bob", "tool": "saw", "days_late": 0},
]


class ReportTest(unittest.TestCase):
    def test_overdue_lists_only_late_loans(self):
        self.assertEqual(overdue_report(LOANS), "ada          drill        2 days")

    def test_weekly_lists_all_loans(self):
        self.assertEqual(len(weekly_report(LOANS).splitlines()), 2)


if __name__ == "__main__":
    unittest.main()
EOF
g add -A
g commit -qm "Add loan reports"

g checkout -qb extract-loan-line

cat > report.py <<'EOF'
def _loan_line(loan: dict) -> str:
    return f"{loan['member']:<12} {loan['tool']:<10} {loan['days_late']:>3} days"


def overdue_report(loans: list[dict]) -> str:
    return "\n".join(_loan_line(l) for l in loans if l["days_late"] > 0)


def weekly_report(loans: list[dict]) -> str:
    return "\n".join(_loan_line(l) for l in loans)
EOF
g add -A
g commit -qm "Extract the loan line format shared by both reports"
