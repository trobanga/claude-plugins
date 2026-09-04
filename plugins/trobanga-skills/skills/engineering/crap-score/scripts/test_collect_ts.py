import io
import json
import unittest

import collect_ts


def loc(first, last):
    return {"start": {"line": first, "column": 0},
            "end": {"line": last, "column": 1}}


COVERAGE = {
    "/repo/src/grade.ts": {
        "path": "/repo/src/grade.ts",
        "statementMap": {
            "0": loc(4, 4), "1": loc(6, 6), "2": loc(18, 18)},
        "fnMap": {
            "0": {"name": "of", "decl": loc(3, 3), "loc": loc(3, 15)},
            "1": {"name": "doubled", "decl": loc(17, 17), "loc": loc(17, 19)},
            "2": {"name": "(anonymous_0)", "decl": loc(5, 5), "loc": loc(5, 7)},
        },
        "branchMap": {
            "0": {"type": "if", "loc": loc(4, 8),
                  "locations": [loc(4, 8), loc(8, 8)]},
            "1": {"type": "binary-expr", "loc": loc(6, 6),
                  "locations": [loc(6, 6), loc(6, 6)]},
        },
        "s": {"0": 1, "1": 1, "2": 3},
        "f": {"0": 2, "1": 3, "2": 1},
        "b": {"0": [1, 0], "1": [1, 1]},
    }
}


def records(**kwargs):
    return {r["name"]: r for r in collect_ts.records(COVERAGE, **kwargs)}


class CollectTsTest(unittest.TestCase):

    def test_complexity_counts_one_decision_per_branch_path(self):
        # one if and one binary expression, each with two paths
        self.assertEqual(3, records()["grade.of"]["cc"])

    def test_branch_coverage_counts_the_covered_paths(self):
        self.assertEqual(0.75, records()["grade.of"]["coverage"])
        self.assertEqual("branch", records()["grade.of"]["kind"])

    def test_a_function_without_branches_uses_its_statements(self):
        doubled = records()["grade.doubled"]
        self.assertEqual(1, doubled["cc"])
        self.assertEqual(1.0, doubled["coverage"])
        self.assertEqual("statement", doubled["kind"])

    def test_the_record_spans_the_whole_function(self):
        self.assertEqual(3, records()["grade.of"]["start"])
        self.assertEqual(15, records()["grade.of"]["end"])

    def test_the_file_of_the_record_is_the_path_of_the_report(self):
        self.assertEqual("/repo/src/grade.ts", records()["grade.of"]["file"])

    def test_anonymous_functions_are_excluded_by_default(self):
        self.assertNotIn("grade.(anonymous_0)", records())

    def test_anonymous_functions_can_be_included(self):
        self.assertIn("grade.(anonymous_0)",
                      records(include_anonymous=True))

    def test_an_uncovered_function_without_branches_scores_zero_coverage(self):
        report = json.loads(json.dumps(COVERAGE))
        report["/repo/src/grade.ts"]["s"]["2"] = 0
        rows = {r["name"]: r for r in collect_ts.records(report)}
        self.assertEqual(0.0, rows["grade.doubled"]["coverage"])


class CliTest(unittest.TestCase):

    def test_the_collector_writes_json_lines(self):
        out = io.StringIO()
        collect_ts.crap_core.emit(collect_ts.records(COVERAGE), out)
        first = json.loads(out.getvalue().splitlines()[0])
        self.assertEqual("grade.of", first["name"])


if __name__ == "__main__":
    unittest.main()
