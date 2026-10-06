#!/usr/bin/env bash
# Builds a small Python package with unittest tests in the empty workspace.
set -euo pipefail

mkdir -p textkit tests

cat > textkit/__init__.py <<'EOF'
"""Small text helpers for the blog."""
EOF

cat > textkit/strings.py <<'EOF'
def truncate(text: str, limit: int) -> str:
    """Cut text to at most `limit` characters, ending in an ellipsis if cut."""
    if len(text) <= limit:
        return text
    return text[: max(limit - 1, 0)] + "…"


def word_count(text: str) -> int:
    return len(text.split())
EOF

cat > tests/__init__.py <<'EOF'
EOF

cat > tests/test_strings.py <<'EOF'
import unittest

from textkit.strings import truncate, word_count


class TruncateTest(unittest.TestCase):
    def test_short_text_is_unchanged(self):
        self.assertEqual(truncate("hello", 10), "hello")

    def test_long_text_ends_in_ellipsis(self):
        self.assertEqual(truncate("hello world", 6), "hello…")


class WordCountTest(unittest.TestCase):
    def test_counts_words(self):
        self.assertEqual(word_count("a b  c"), 3)


if __name__ == "__main__":
    unittest.main()
EOF

cat > README.md <<'EOF'
# textkit

Run the tests with `python3 -m unittest discover -s tests -v`.
EOF
