import io
import unittest
from textwrap import dedent

import collect_elixir

LCOV = dedent("""\
    TN:
    SF:lib/grade.ex
    FN:2,of/2
    DA:2,1
    DA:3,1
    DA:4,1
    DA:5,0
    DA:6,1
    DA:9,0
    LF:6
    LH:4
    end_of_record
    TN:
    SF:lib/other/util.ex
    DA:3,2
    DA:4,2
    LF:2
    LH:2
    end_of_record
    """)


class LcovTest(unittest.TestCase):

    def test_an_absolute_path_becomes_relative_to_the_project_root(self):
        # ExCoveralls writes SF: with the absolute path of the source
        report = io.StringIO("SF:/work/app/lib/grade.ex\nDA:1,1\nend_of_record\n")
        self.assertEqual({"lib/grade.ex": {1: 1}},
                         collect_elixir.parse_lcov(report, root="/work/app"))

    def test_a_path_outside_the_root_stays_as_it_is(self):
        report = io.StringIO("SF:/elsewhere/x.ex\nDA:1,1\nend_of_record\n")
        self.assertIn("/elsewhere/x.ex",
                      collect_elixir.parse_lcov(report, root="/work/app"))

    def lines(self):
        return collect_elixir.parse_lcov(io.StringIO(LCOV))

    def test_every_source_file_of_the_report_is_listed(self):
        self.assertEqual({"lib/grade.ex", "lib/other/util.ex"},
                         set(self.lines()))

    def test_a_line_carries_its_hit_count(self):
        self.assertEqual({2: 1, 3: 1, 4: 1, 5: 0, 6: 1, 9: 0},
                         self.lines()["lib/grade.ex"])



FUNCTIONS = [
    {"file": "lib/grade.ex", "name": "Grade.of/2", "start": 2, "end": 7,
     "cc": 3},
    {"file": "lib/other/util.ex", "name": "Util.trim/1", "start": 3,
     "end": 4, "cc": 1},
]


class RecordTest(unittest.TestCase):

    def records(self):
        return {r["name"]: r for r in collect_elixir.records(
            FUNCTIONS, collect_elixir.parse_lcov(io.StringIO(LCOV)))}

    def test_coverage_is_the_share_of_covered_lines_in_the_range(self):
        # lines 2..6 are relevant, line 5 never ran, line 9 lies outside
        self.assertAlmostEqual(0.8, self.records()["Grade.of/2"]["coverage"])

    def test_a_function_without_a_missed_line_is_fully_covered(self):
        self.assertEqual(1.0, self.records()["Util.trim/1"]["coverage"])

    def test_the_record_keeps_the_complexity_of_the_function(self):
        self.assertEqual(3, self.records()["Grade.of/2"]["cc"])

    def test_elixir_reports_line_coverage(self):
        self.assertEqual("line", self.records()["Grade.of/2"]["kind"])

    def test_a_function_without_any_line_counts_as_uncovered(self):
        gone = [{"file": "lib/grade.ex", "name": "Grade.dead/0", "start": 40,
                 "end": 44, "cc": 2}]
        rows = list(collect_elixir.records(
            gone, collect_elixir.parse_lcov(io.StringIO(LCOV))))
        self.assertEqual(0.0, rows[0]["coverage"])


if __name__ == "__main__":
    unittest.main()
