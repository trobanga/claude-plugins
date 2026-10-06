import os
import shutil
import tempfile
import unittest

import check_skill

VALID = """---
name: drafting-issues
description: Drafts one issue. Use when the user asks for an issue.
---

Body.
"""


class CheckSkillTest(unittest.TestCase):

    def setUp(self):
        # the skill sits one level down, so a test can add a sibling skill
        self.root = tempfile.mkdtemp()
        self.dir = os.path.join(self.root, "skill")
        os.mkdir(self.dir)

    def tearDown(self):
        shutil.rmtree(self.root)

    def write(self, name, text):
        path = os.path.join(self.dir, name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            f.write(text)

    def failures(self):
        return [r for r in check_skill.check(self.dir) if not r.ok]

    def test_valid_skill_passes_every_check(self):
        self.write("SKILL.md", VALID)
        self.assertEqual([], self.failures())
        self.assertEqual(0, check_skill.main([self.dir]))

    def test_name_outside_the_rules_fails(self):
        for name in ["Drafting_Issues", "a" * 65, "claude-helper", "my-anthropic"]:
            with self.subTest(name=name):
                self.write("SKILL.md", VALID.replace("drafting-issues", name))
                self.assertEqual(["name"],
                                 [r.check for r in self.failures()])

    def test_description_outside_the_rules_fails(self):
        old = "Drafts one issue. Use when the user asks for an issue."
        for description in ["", "x" * 1025, "Drafts <issue> text."]:
            with self.subTest(description=description[:20]):
                self.write("SKILL.md", VALID.replace(old, description))
                self.assertEqual(["description"],
                                 [r.check for r in self.failures()])

    def test_body_of_500_lines_or_more_fails(self):
        head = VALID.replace("Body.\n", "")
        self.write("SKILL.md", head + "line\n" * 499)
        self.assertEqual([], self.failures())
        self.write("SKILL.md", head + "line\n" * 500)
        self.assertEqual(["length"], [r.check for r in self.failures()])

    def test_link_to_a_missing_file_fails(self):
        self.write("SKILL.md", VALID + "See [the rules](RULES.md).\n")
        self.assertEqual(["links"], [r.check for r in self.failures()])
        self.write("RULES.md", "# Rules\n")
        self.assertEqual([], self.failures())

    def test_backtick_path_to_a_missing_skill_file_fails(self):
        self.write("SKILL.md", VALID + "Read `references/rules.md` first.\n")
        self.write("references/style.md", "# Style\n")
        self.assertEqual(["links"], [r.check for r in self.failures()])
        self.write("references/rules.md", "# Rules\n")
        self.assertEqual([], self.failures())

    def test_backtick_path_to_an_existing_skill_file_discloses_it(self):
        self.write("SKILL.md", VALID + "Read `RULES.md` first.\n")
        self.write("RULES.md", "# Rules\n" + "## Usage\n" + "x\n" * 99)
        self.assertEqual(["contents"], [r.check for r in self.failures()])

    def test_backtick_path_outside_the_skill_folders_is_a_project_file(self):
        self.write("SKILL.md", VALID + "Update `GLOSSARY.md`, "
                   "`.agents/issue-tracker.md`, `docs/adr/` and `src/main.rs`; "
                   "call `run()` or `~/bin/x.md`; themes go in `resources/themes/`.\n"
                   "Run `/code-review` in `<repo>`/.claude/x/`here`; "
                   "open `./lessons/`.\n")
        self.assertEqual([], self.failures())
        # a hidden folder in the skill is tool state, not a bundled file
        self.write(".claude/state", "")
        self.write("SKILL.md", VALID + "Work in `.claude/worktrees/`.\n")
        self.assertEqual([], self.failures())

    def test_skill_dir_path_to_a_missing_file_fails_even_in_code(self):
        self.write("SKILL.md", VALID + "```bash\npython3 "
                   "${CLAUDE_SKILL_DIR}/scripts/run.py <dir>\n```\n")
        self.assertEqual(["links"], [r.check for r in self.failures()])
        self.write("scripts/run.py", "print()\n")
        self.assertEqual([], self.failures())

    def test_web_links_anchors_and_code_blocks_are_not_local_links(self):
        self.write("SKILL.md", VALID
                   + "[docs](https://example.com/a.md) [top](#top)\n"
                   + "```markdown\nSee [advanced](advanced.md)\n```\n")
        self.assertEqual([], self.failures())

    def test_long_disclosed_file_without_contents_fails(self):
        self.write("SKILL.md", VALID + "See [the rules](RULES.md).\n")
        self.write("RULES.md", "# Rules\n" + "## Usage\n" + "x\n" * 98)
        self.assertEqual([], self.failures())
        self.write("RULES.md", "# Rules\n" + "## Usage\n" + "x\n" * 99)
        self.assertEqual(["contents"], [r.check for r in self.failures()])
        self.write("RULES.md", "# Rules\n## Contents\n- Usage\n## Usage\n"
                   + "x\n" * 99)
        self.assertEqual([], self.failures())

    def test_disclosed_file_that_points_one_level_deeper_fails(self):
        self.write("SKILL.md", VALID + "See [the rules](RULES.md).\n")
        self.write("DETAILS.md", "# Details\n")
        self.write("RULES.md", "Back to [the skill](SKILL.md). "
                   "More in [details](DETAILS.md).\n")
        self.assertEqual(["depth"], [r.check for r in self.failures()])
        self.write("SKILL.md", VALID + "See [the rules](RULES.md) and "
                   "[details](DETAILS.md).\n")
        self.assertEqual([], self.failures())

    def test_backslash_in_a_link_path_fails(self):
        self.write("ref/rules.md", "# Rules\n")
        self.write("SKILL.md", VALID + "See [rules](ref\\rules.md).\n")
        self.assertIn("slashes", [r.check for r in self.failures()])
        self.write("SKILL.md", VALID + "See [rules](ref/rules.md).\n")
        self.assertEqual([], self.failures())

    def test_link_to_another_skill_is_not_a_disclosed_file(self):
        self.write("SKILL.md", VALID + "Then run [show-me](../show-me/SKILL.md).\n")
        self.write("../show-me/SKILL.md", "## Steps\n" + "x\n" * 200)
        self.assertEqual([], self.failures())
        self.write("SKILL.md", VALID + "See [the rules](RULES.md).\n")
        self.write("RULES.md", "Then run [show-me](../show-me/SKILL.md).\n")
        self.assertEqual([], self.failures())

    def test_folder_without_skill_md_fails_with_a_reason(self):
        self.assertEqual(["skill"], [r.check for r in self.failures()])
        self.assertEqual(1, check_skill.main([self.dir]))

    def test_no_argument_prints_usage(self):
        self.assertEqual(2, check_skill.main([]))

    def test_folded_description_is_read_across_its_lines(self):
        self.write("SKILL.md", """---
name: drafting-issues
description: >
  Drafts one issue.
  Use when the user asks for an issue.
---
""")
        self.assertEqual([], self.failures())


if __name__ == "__main__":
    unittest.main()
