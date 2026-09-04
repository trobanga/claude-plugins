import io
import unittest
from textwrap import dedent

import crap_core

DIFF = dedent("""\
    diff --git a/src/foo.go b/src/foo.go
    --- a/src/foo.go
    +++ b/src/foo.go
    @@ -11,0 +12,1 @@
    +    x := 1
    """)


def records(*rows):
    return io.StringIO("\n".join(rows))


class ScoreTest(unittest.TestCase):

    def test_touched_function_is_scored(self):
        given = records(
            '{"file": "src/foo.go", "name": "Foo", "start": 10, "end": 14,'
            ' "cc": 3, "coverage": 1.0}')
        rows = crap_core.score(given, io.StringIO(DIFF))
        self.assertEqual([("Foo", 3, 1.0, 3.0)], rows)

    def test_record_path_matches_a_longer_diff_path(self):
        # a collector may report a package path or an absolute path
        given = records(
            '{"file": "foo.go", "name": "Short", "start": 1, "end": null,'
            ' "cc": 1, "coverage": 1.0}',
            '{"file": "/repo/src/foo.go", "name": "Absolute", "start": 1,'
            ' "end": null, "cc": 1, "coverage": 1.0}',
            '{"file": "other/foo.go", "name": "Other", "start": 1,'
            ' "end": null, "cc": 1, "coverage": 1.0}')
        rows = crap_core.score(given, io.StringIO(DIFF))
        self.assertEqual(["Short", "Absolute"], [r[0] for r in rows])


class ReportTest(unittest.TestCase):

    GIVEN = (
        '{"file": "src/foo.go", "name": "Risky", "start": 10, "end": 14,'
        ' "cc": 4, "coverage": 0.5, "kind": "branch"}',
        '{"file": "src/foo.go", "name": "Safe", "start": 12, "end": 13,'
        ' "cc": 3, "coverage": 1.0, "kind": "branch"}')

    def run_main(self, threshold):
        out = io.StringIO()
        code = crap_core.main(
            records(*self.GIVEN), io.StringIO(DIFF), threshold, out)
        return code, out.getvalue()

    def test_worst_function_comes_first(self):
        _, out = self.run_main(threshold=8)
        self.assertIn("Risky", out.splitlines()[1])
        self.assertIn("Safe", out.splitlines()[2])

    def test_exit_1_when_a_function_reaches_the_threshold(self):
        code, out = self.run_main(threshold=6)
        self.assertEqual(1, code)
        self.assertIn("Risky", out)
        self.assertIn("1 at or above 6", out)

    def test_exit_0_when_all_functions_are_below_the_threshold(self):
        code, out = self.run_main(threshold=8)
        self.assertEqual(0, code)
        self.assertIn("2 changed functions", out)

    def test_footer_names_the_coverage_kind(self):
        _, out = self.run_main(threshold=8)
        self.assertIn("branch coverage", out)


if __name__ == "__main__":
    unittest.main()
