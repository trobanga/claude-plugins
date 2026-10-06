#!/usr/bin/env bash
# Python repo with documented standards (CODING_STANDARDS.md) and a spec
# (docs/specs/csv-export.md). Branch `csv-export` (checked out) adds an exporter that:
#   - calls datetime.now() and raises a bare Exception   (Standards violations, cited)
#   - writes no header row and uses ',' not ';'          (Spec: missing / wrong)
#   - adds an unrequested JSON export                    (Spec: scope creep)
#   - duplicates a formatting block                      (generic smell, no source: must NOT be reported)
# Tracker none. Runs in the empty run workspace (claude plugin eval --scaffold).
set -euo pipefail
export GIT_AUTHOR_NAME="Eval Dev" GIT_AUTHOR_EMAIL="dev@example.com"
export GIT_COMMITTER_NAME="Eval Dev" GIT_COMMITTER_EMAIL="dev@example.com"

git init -q -b main .
git config user.name "Eval Dev"
git config user.email "dev@example.com"
mkdir -p .agents docs/specs exporter tests
cat > .agents/issue-tracker.md <<'EOF'
# Issue tracker

**Tracker: none**; specs live in `docs/specs/`. **Forge: none** (plain git).
Branch names are `{id}--{slug}`.
EOF
cat > CODING_STANDARDS.md <<'EOF'
# Coding standards

1. **Time.** Get the current time from `exporter.clock.now_utc()`. Never call
   `datetime.now()` or `datetime.utcnow()` directly: tests freeze the clock through
   `clock`.
2. **Errors.** Raise `ExportError` from `exporter/errors.py`. Never raise a bare
   `Exception`.
3. **Docstrings.** Every public function in `exporter/` has a one-line docstring.
EOF
cat > docs/specs/csv-export.md <<'EOF'
# Spec: CSV export of orders

1. The export starts with a header row naming the columns: `id;customer;total;exported_at`.
2. Fields are separated by a semicolon (`;`), because finance opens the files in a
   German-locale spreadsheet.
3. `exported_at` is the export time in UTC, ISO 8601.
4. Exporting no orders writes the header row only.

Out of scope: any other export format.
EOF
cat > exporter/__init__.py <<'EOF'
EOF
cat > exporter/clock.py <<'EOF'
"""The clock every module reads, so tests can freeze it."""
from datetime import datetime, timezone


def now_utc():
    """Return the current time in UTC."""
    return datetime.now(timezone.utc)
EOF
cat > exporter/errors.py <<'EOF'
class ExportError(Exception):
    """Raised when an export cannot be written."""
EOF
git add -A
git commit -q -m "Add exporter package, standards and CSV export spec"

git switch -q -c csv-export
cat > exporter/csv_export.py <<'EOF'
import csv
import json
from datetime import datetime


def export_csv(orders, handle):
    """Write orders as CSV."""
    if handle is None:
        raise Exception("no output handle")
    stamp = datetime.now().isoformat()
    writer = csv.writer(handle, delimiter=",")
    for order in orders:
        total = f"{order['total']:.2f}"
        customer = order["customer"].strip().title()
        writer.writerow([order["id"], customer, total, stamp])


def export_json(orders, handle):
    """Write orders as JSON."""
    rows = []
    for order in orders:
        total = f"{order['total']:.2f}"
        customer = order["customer"].strip().title()
        rows.append({"id": order["id"], "customer": customer, "total": total})
    json.dump(rows, handle)
EOF
git add -A
git commit -q -m "Add CSV export"
cat > tests/test_csv_export.py <<'EOF'
import io

from exporter.csv_export import export_csv


def test_writes_one_line_per_order():
    out = io.StringIO()
    export_csv([{"id": 1, "customer": "ada", "total": 3}], out)
    assert out.getvalue().count("\n") == 1
EOF
git add -A
git commit -q -m "Test CSV export"
