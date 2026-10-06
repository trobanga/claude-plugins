#!/usr/bin/env bash
# Builds a git repo: main has an export CLI with --out; the checked-out
# branch renames the flag to --output and removes --out.
set -euo pipefail

g() { git -c user.name=Eval -c user.email=eval@example.com -c init.defaultBranch=main "$@"; }

g init -q

cat > export.py <<'EOF'
import argparse
import csv
import sys

LOANS = [("L-1", "drill", "2026-10-01"), ("L-2", "saw", "2026-10-03")]


def main(argv=None):
    p = argparse.ArgumentParser(description="Export loans as CSV.")
    p.add_argument("--out", help="file to write; stdout if omitted")
    args = p.parse_args(argv)
    f = open(args.out, "w", newline="") if args.out else sys.stdout
    w = csv.writer(f)
    w.writerow(["loan", "tool", "due"])
    w.writerows(LOANS)


if __name__ == "__main__":
    main()
EOF

cat > README.md <<'EOF'
# loan-export

Nightly job on the reporting host runs: `python3 export.py --out /srv/reports/loans.csv`
EOF
g add -A
g commit -qm "Add loan export CLI"

g checkout -qb rename-out-flag
cat > export.py <<'EOF'
import argparse
import csv
import sys

LOANS = [("L-1", "drill", "2026-10-01"), ("L-2", "saw", "2026-10-03")]


def main(argv=None):
    p = argparse.ArgumentParser(description="Export loans as CSV.")
    p.add_argument("--output", "-o", help="file to write; stdout if omitted")
    args = p.parse_args(argv)
    f = open(args.output, "w", newline="") if args.output else sys.stdout
    w = csv.writer(f)
    w.writerow(["loan", "tool", "due"])
    w.writerows(LOANS)


if __name__ == "__main__":
    main()
EOF

cat > README.md <<'EOF'
# loan-export

Nightly job on the reporting host runs: `python3 export.py --output /srv/reports/loans.csv`
EOF
g add -A
g commit -qm "Rename --out to --output and add -o"
