#!/usr/bin/env bash
# Builds a git repo: main has a bill-splitting CLI that loses cents; the
# checked-out branch fix-split-rounding fixes it and adds a test.
set -euo pipefail

g() { git -c user.name=Eval -c user.email=eval@example.com -c init.defaultBranch=main "$@"; }

g init -q
mkdir -p tests

cat > split.py <<'EOF'
import sys


def split_bill(total_cents: int, people: int) -> list[int]:
    share = total_cents // people
    return [share] * people


if __name__ == "__main__":
    total, people = int(sys.argv[1]), int(sys.argv[2])
    print(" ".join(f"{c / 100:.2f}" for c in split_bill(total, people)))
EOF

cat > tests/test_split.py <<'EOF'
import unittest

from split import split_bill


class SplitTest(unittest.TestCase):
    def test_even_split(self):
        self.assertEqual(split_bill(900, 3), [300, 300, 300])


if __name__ == "__main__":
    unittest.main()
EOF
touch tests/__init__.py
g add -A
g commit -qm "Add bill splitting CLI"

g checkout -qb fix-split-rounding

cat > split.py <<'EOF'
import sys


def split_bill(total_cents: int, people: int) -> list[int]:
    share, rest = divmod(total_cents, people)
    return [share + 1] * rest + [share] * (people - rest)


if __name__ == "__main__":
    total, people = int(sys.argv[1]), int(sys.argv[2])
    print(" ".join(f"{c / 100:.2f}" for c in split_bill(total, people)))
EOF

cat > tests/test_split.py <<'EOF'
import unittest

from split import split_bill


class SplitTest(unittest.TestCase):
    def test_even_split(self):
        self.assertEqual(split_bill(900, 3), [300, 300, 300])

    def test_shares_add_up_to_total(self):
        self.assertEqual(sum(split_bill(1000, 3)), 1000)


if __name__ == "__main__":
    unittest.main()
EOF
g add -A
g commit -qm "Give the leftover cents to the first people in a split (#42)"
