import unittest

import collect_rust

REPORT = {
    "$schema": "https://example/report-v1.json",
    "version": "0.4.3",
    "entries": [
        {"file": "./src/lib.rs", "function": "of", "line": 1,
         "cyclomatic": 5.0, "coverage": 81.81818181818183,
         "crap": 5.150262960180315},
        {"file": "./src/lib.rs", "function": "doubled", "line": 15,
         "cyclomatic": 1.0, "coverage": 100.0, "crap": 1.0},
        {"file": "./src/other.rs", "function": "trim", "line": 3,
         "cyclomatic": 2.0, "coverage": 0.0, "crap": 6.0},
    ],
}


def records():
    return {r["name"]: r for r in collect_rust.records(REPORT)}


class CollectRustTest(unittest.TestCase):

    def test_percent_coverage_becomes_a_share(self):
        self.assertAlmostEqual(0.8181818, records()["of"]["coverage"])

    def test_complexity_becomes_a_whole_number(self):
        self.assertEqual(5, records()["of"]["cc"])
        self.assertIsInstance(records()["of"]["cc"], int)

    def test_the_path_of_the_record_keeps_the_source_file(self):
        self.assertEqual("src/lib.rs", records()["of"]["file"])

    def test_a_function_ends_where_the_next_one_of_the_file_starts(self):
        self.assertEqual(14, records()["of"]["end"])

    def test_the_last_function_of_a_file_is_open_ended(self):
        self.assertIsNone(records()["doubled"]["end"])
        self.assertIsNone(records()["trim"]["end"])

    def test_rust_reports_line_coverage(self):
        self.assertEqual("line", records()["of"]["kind"])

    def test_a_report_of_an_unknown_schema_version_is_refused(self):
        with self.assertRaises(SystemExit) as ctx:
            list(collect_rust.records({"version": "0.4.3", "no": "entries"}))
        self.assertIn("entries", str(ctx.exception))


class ScoreTest(unittest.TestCase):

    def test_the_core_repeats_the_score_of_cargo_crap(self):
        import crap_core
        row = records()["of"]
        self.assertAlmostEqual(
            REPORT["entries"][0]["crap"],
            crap_core.crap(row["cc"], row["coverage"]))


if __name__ == "__main__":
    unittest.main()
