import io
import unittest
from textwrap import dedent

import collect_go

PROFILE = dedent("""\
    mode: set
    example.com/m/grade.go:5.35,6.16 1 1
    example.com/m/grade.go:6.16,8.3 1 1
    example.com/m/grade.go:9.16,11.3 1 0
    example.com/m/grade.go:12.2,12.10 1 1
    example.com/m/other/util.go:3.20,5.2 2 1
    github.com/dep/lib/dep.go:1.1,2.2 1 1
    """)

# Two test binaries report on the same file, as `-coverpkg` makes them do.
# The second binary covers the block that the first one misses.
DUPLICATE_PROFILE = dedent("""\
    mode: set
    example.com/m/grade.go:5.35,6.16 1 1
    example.com/m/grade.go:6.16,8.3 1 1
    example.com/m/grade.go:9.16,11.3 1 0
    example.com/m/grade.go:12.2,12.10 1 1
    example.com/m/grade.go:5.35,6.16 1 0
    example.com/m/grade.go:6.16,8.3 1 0
    example.com/m/grade.go:9.16,11.3 1 1
    example.com/m/grade.go:12.2,12.10 1 0
    """)

FUNCTIONS = [
    {"file": "grade.go", "name": "main.Of", "start": 5, "end": 13, "cc": 3},
    {"file": "other/util.go", "name": "other.Trim", "start": 3, "end": 5,
     "cc": 1},
]


class ProfileTest(unittest.TestCase):

    def blocks(self):
        return collect_go.parse_profile(io.StringIO(PROFILE), "example.com/m")

    def test_profile_paths_lose_the_module_prefix(self):
        self.assertIn("grade.go", self.blocks())

    def test_files_of_other_modules_are_dropped(self):
        self.assertNotIn("github.com/dep/lib/dep.go", self.blocks())
        self.assertNotIn("dep.go", self.blocks())

    def test_a_block_carries_its_lines_statements_and_count(self):
        self.assertIn((5, 6, 1, 1), self.blocks()["grade.go"])


class RecordTest(unittest.TestCase):

    def records(self):
        return {r["name"]: r for r in collect_go.records(
            FUNCTIONS, collect_go.parse_profile(
                io.StringIO(PROFILE), "example.com/m"))}

    def test_coverage_is_the_share_of_covered_statements(self):
        # four blocks of one statement each, one of them never run
        self.assertAlmostEqual(0.75, self.records()["main.Of"]["coverage"])

    def test_a_function_without_a_missed_block_is_fully_covered(self):
        self.assertEqual(1.0, self.records()["other.Trim"]["coverage"])

    def test_the_record_keeps_the_complexity_of_the_function(self):
        self.assertEqual(3, self.records()["main.Of"]["cc"])

    def test_go_reports_statement_coverage(self):
        self.assertEqual("statement", self.records()["main.Of"]["kind"])

    def test_a_function_without_any_block_counts_as_uncovered(self):
        gone = [{"file": "grade.go", "name": "main.Dead", "start": 40,
                 "end": 44, "cc": 2}]
        rows = list(collect_go.records(gone, collect_go.parse_profile(
            io.StringIO(PROFILE), "example.com/m")))
        self.assertEqual(0.0, rows[0]["coverage"])


class DuplicateBlockTest(unittest.TestCase):

    def records(self):
        return {r["name"]: r for r in collect_go.records(
            FUNCTIONS, collect_go.parse_profile(
                io.StringIO(DUPLICATE_PROFILE), "example.com/m"))}

    def test_the_counts_of_the_lines_of_one_block_add_up(self):
        blocks = collect_go.parse_profile(
            io.StringIO(DUPLICATE_PROFILE), "example.com/m")
        self.assertEqual([(5, 6, 1, 1), (6, 8, 1, 1), (9, 11, 1, 1),
                          (12, 12, 1, 1)], sorted(blocks["grade.go"]))

    def test_a_block_counts_one_time_however_many_binaries_report_it(self):
        # all four blocks run, each one in one of the two binaries
        self.assertEqual(1.0, self.records()["main.Of"]["coverage"])

    def test_a_block_that_no_binary_runs_stays_uncovered(self):
        profile = DUPLICATE_PROFILE.replace(
            "grade.go:12.2,12.10 1 1", "grade.go:12.2,12.10 1 0")
        rows = {r["name"]: r for r in collect_go.records(
            FUNCTIONS, collect_go.parse_profile(
                io.StringIO(profile), "example.com/m"))}
        self.assertEqual(0.75, rows["main.Of"]["coverage"])

    def test_two_blocks_of_one_source_line_stay_apart(self):
        # equal lines, different columns: `switch x { case 1: a(); }`
        profile = dedent("""\
            mode: set
            example.com/m/grade.go:6.16,6.30 1 1
            example.com/m/grade.go:6.32,6.46 1 0
            """)
        rows = list(collect_go.records(FUNCTIONS, collect_go.parse_profile(
            io.StringIO(profile), "example.com/m")))
        self.assertEqual(0.5, rows[0]["coverage"])


if __name__ == "__main__":
    unittest.main()
