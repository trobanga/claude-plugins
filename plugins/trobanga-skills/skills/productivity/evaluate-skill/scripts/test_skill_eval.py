import json
import os
import shutil
import tempfile
import unittest

import skill_eval

SKILL = """---
name: drafting-issues
description: Drafts one issue.
disable-model-invocation: true
---

Line 7.
Line 8.
Line 9.
"""


class SkillFixture(unittest.TestCase):

    def setUp(self):
        self.root = tempfile.mkdtemp()
        self.skill = os.path.join(self.root, "drafting-issues")
        os.makedirs(os.path.join(self.skill, "evals"))
        with open(os.path.join(self.skill, "SKILL.md"), "w") as f:
            f.write(SKILL)
        self.out = os.path.join(self.root, "out")

    def tearDown(self):
        shutil.rmtree(self.root)

    def copied(self, *path):
        with open(os.path.join(self.out, "drafting-issues", *path)) as f:
            return f.read()


class PrepareTest(SkillFixture):

    def test_copy_lets_the_agent_invoke_the_skill(self):
        path = skill_eval.prepare(self.skill, self.out)
        self.assertEqual(os.path.join(self.out, "drafting-issues"), path)
        self.assertNotIn("disable-model-invocation", self.copied("SKILL.md"))
        self.assertIn("description: Drafts one issue.", self.copied("SKILL.md"))
        self.assertTrue(os.path.isdir(os.path.join(path, "evals")))
        self.assertIn("disable-model-invocation",
                      open(os.path.join(self.skill, "SKILL.md")).read())

    def test_sibling_skills_the_skill_points_into_are_copied_beside_it(self):
        with open(os.path.join(self.skill, "SKILL.md"), "a") as f:
            f.write("Read `${CLAUDE_SKILL_DIR}/../tracker/rules.md` first.\n")
        tracker = os.path.join(self.root, "tracker")
        os.makedirs(os.path.join(tracker, "scripts"))
        with open(os.path.join(tracker, "rules.md"), "w") as f:
            f.write("Run ${CLAUDE_SKILL_DIR}/../naming/name.py.\n")
        os.makedirs(os.path.join(self.root, "naming"))
        open(os.path.join(self.root, "naming", "name.py"), "w").close()
        os.makedirs(os.path.join(self.root, "unrelated"))
        skill_eval.prepare(self.skill, self.out)
        self.assertTrue(os.path.isfile(
            os.path.join(self.out, "tracker", "rules.md")))
        self.assertTrue(os.path.isfile(
            os.path.join(self.out, "naming", "name.py")))
        self.assertFalse(os.path.exists(os.path.join(self.out, "unrelated")))

    def test_drop_deletes_lines_counted_in_the_original_file(self):
        skill_eval.prepare(self.skill, self.out, drop=(8, 9))
        text = self.copied("SKILL.md")
        self.assertIn("Line 7.", text)
        self.assertNotIn("Line 8.", text)
        self.assertNotIn("Line 9.", text)

    def test_drop_outside_the_file_is_refused(self):
        for drop in [(0, 2), (9, 10), (8, 7)]:
            with self.subTest(drop=drop):
                with self.assertRaisesRegex(ValueError, "SKILL.md has 9 lines"):
                    skill_eval.prepare(self.skill, self.out, drop=drop)
                self.assertFalse(os.path.exists(self.out))


def result(scores, partial=False):
    """An aggregate-result.json as `claude plugin eval` writes it."""
    return {
        "schemaVersion": 1,
        "partial": partial,
        "partialReason": "cost_ceiling" if partial else None,
        "costUsd": 1.5,
        "cases": [{"name": name, "aggregates": {"score": s, "delta": d}}
                  for name, (s, d) in scores.items()],
    }


class MainTest(SkillFixture):

    def test_command_line_prepares_and_reports(self):
        self.assertEqual(0, skill_eval.main(
            ["prepare", self.skill, self.out, "--drop", "8:9"]))
        self.assertNotIn("Line 8.", self.copied("SKILL.md"))
        path = os.path.join(self.root, "a.json")
        with open(path, "w") as f:
            json.dump(result({"review": (0.5, 0.0)}), f)
        self.assertEqual(0, skill_eval.main(["report", path]))

    def test_bad_drop_exits_with_a_message(self):
        self.assertEqual(1, skill_eval.main(
            ["prepare", self.skill, self.out, "--drop", "9:20"]))


class ReportTest(unittest.TestCase):

    def row(self, text, case):
        return next(l.split() for l in text.splitlines()
                    if l.startswith(case + " "))

    def test_one_result_shows_with_without_and_delta(self):
        text = skill_eval.report(result({"review": (0.83, 0.5),
                                         "write": (0.5, 0.0)}))
        self.assertEqual(["review", "0.83", "0.33", "+0.50"],
                         self.row(text, "review"))
        self.assertEqual(["write", "0.50", "0.50", "+0.00"],
                         self.row(text, "write"))

    def test_ablated_result_shows_which_cases_got_worse(self):
        full = result({"review": (0.83, 0.5), "write": (0.5, 0.0)})
        ablated = result({"review": (0.5, 0.17), "write": (0.5, 0.0)})
        text = skill_eval.report(full, ablated)
        self.assertEqual(["review", "0.83", "0.50", "-0.33", "WORSE"],
                         self.row(text, "review"))
        self.assertEqual(["write", "0.50", "0.50", "+0.00"],
                         self.row(text, "write"))

    def test_partial_result_is_flagged(self):
        text = skill_eval.report(result({"review": (0.5, 0.0)}, partial=True))
        self.assertIn("PARTIAL (cost_ceiling)", text)


if __name__ == "__main__":
    unittest.main()
