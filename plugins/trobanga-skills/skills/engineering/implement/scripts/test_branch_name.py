"""Tests for branch_name.py, through its command line. Run: python3 -m unittest test_branch_name.py"""

import subprocess
import sys
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("branch_name.py")


def run(*args):
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args], capture_output=True, text=True
    )


class Build(unittest.TestCase):
    def test_default_format_joins_id_and_slug_with_double_hyphen(self):
        result = run("build", "--id", "42", "--title", "Fix the login page")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "42--fix-the-login-page")

    def test_id_is_lowercased_and_a_leading_hash_dropped(self):
        self.assertEqual(
            run("build", "--id", "GIAM-123", "--title", "Login").stdout.strip(),
            "giam-123--login",
        )
        self.assertEqual(
            run("build", "--id", "#42", "--title", "Login").stdout.strip(),
            "42--login",
        )

    def test_single_hyphen_format_with_a_numeric_id(self):
        result = run("build", "--id", "42", "--title", "Login", "--format", "{id}-{slug}")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "42-login")

    def test_title_without_letters_or_digits_is_refused(self):
        result = run("build", "--id", "42", "--title", "!!! ???")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, "")
        self.assertIn("--title", result.stderr)

    def test_id_that_is_not_a_bare_identifier_is_refused(self):
        for bad in ("", "#", "giam 123", "https://github.com/o/r/issues/4", "-42"):
            with self.subTest(id=bad):
                result = run("build", "--id", bad, "--title", "Login")
                self.assertEqual(result.returncode, 1)
                self.assertIn("--id", result.stderr)

    def test_single_hyphen_format_with_a_non_numeric_id_warns(self):
        result = run("build", "--id", "bd-42", "--title", "Login", "--format", "{id}-{slug}")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "bd-42-login")
        self.assertIn("{id}--{slug}", result.stderr)

    def test_slug_is_cut_to_40_characters_without_a_trailing_hyphen(self):
        # The slug's 40th character is a hyphen.
        title = "abcdefghij abcdefghij abcdefghij abcdef ghij"
        result = run("build", "--id", "7", "--title", title)
        self.assertEqual(
            result.stdout.strip(), "7--abcdefghij-abcdefghij-abcdefghij-abcdef"
        )


class Parse(unittest.TestCase):
    def test_default_format_splits_on_the_last_double_hyphen(self):
        for branch, issue_id in (
            ("giam-123--fix-login", "giam-123"),
            ("gt--xyz--fix-login", "gt--xyz"),
        ):
            with self.subTest(branch=branch):
                result = run("parse", branch)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.strip(), issue_id)

    def test_legacy_numeric_branch_gives_its_digits(self):
        for branch in ("42-fix-login", "issue-42-fix-login", "42"):
            with self.subTest(branch=branch):
                result = run("parse", branch)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.strip(), "42")

    def test_configured_single_hyphen_format_is_tried_first(self):
        result = run("parse", "42-fix--thing", "--format", "{id}-{slug}")
        self.assertEqual(result.stdout.strip(), "42")

    def test_full_ref_name_is_accepted(self):
        result = run("parse", "refs/heads/giam-123--fix-login")
        self.assertEqual(result.stdout.strip(), "giam-123")

    def test_branch_without_a_recoverable_id_is_unknown(self):
        for branch in ("bd-42-fix-login", "feature-login"):
            with self.subTest(branch=branch):
                result = run("parse", branch)
                self.assertEqual(result.returncode, 1)
                self.assertEqual(result.stdout, "")
                self.assertIn("Issue: unknown", result.stderr)


class EmptyFormat(unittest.TestCase):
    def test_empty_format_means_the_default(self):
        # An unset $BRANCH_FORMAT in `--format "$BRANCH_FORMAT"` arrives as "".
        built = run("build", "--id", "GIAM-1", "--title", "Login", "--format", "")
        self.assertEqual(built.stdout.strip(), "giam-1--login")
        parsed = run("parse", "giam-1--login", "--format", "")
        self.assertEqual(parsed.stdout.strip(), "giam-1")


class RoundTrip(unittest.TestCase):
    def test_parse_recovers_the_id_that_build_used(self):
        for issue_id, title in (
            ("GIAM-123", "Refuse -- deleted subject"),
            ("gt--xyz", "a--b"),
            ("42", "Fix #7: crash"),
        ):
            with self.subTest(id=issue_id):
                branch = run("build", "--id", issue_id, "--title", title).stdout.strip()
                self.assertEqual(run("parse", branch).stdout.strip(), issue_id.lower())


if __name__ == "__main__":
    unittest.main()
