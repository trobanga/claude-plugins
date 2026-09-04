import io
import unittest
from textwrap import dedent

import crap_score

REPORT = dedent("""\
    <?xml version="1.0" encoding="UTF-8"?>
    <report name="fts">
      <package name="care/smith/fts/cda">
        <class name="care/smith/fts/cda/Foo" sourcefilename="Foo.java">
          <method name="bar" desc="()V" line="10">
            <counter type="LINE" missed="0" covered="4"/>
            <counter type="COMPLEXITY" missed="0" covered="3"/>
          </method>
          <method name="lambda$bar$0" desc="()V" line="12">
            <counter type="LINE" missed="0" covered="1"/>
            <counter type="COMPLEXITY" missed="0" covered="1"/>
          </method>
          <method name="branchy" desc="()V" line="15">
            <counter type="LINE" missed="0" covered="3"/>
            <counter type="BRANCH" missed="2" covered="2"/>
            <counter type="COMPLEXITY" missed="1" covered="2"/>
          </method>
          <method name="untouched" desc="()V" line="20">
            <counter type="LINE" missed="2" covered="2"/>
            <counter type="COMPLEXITY" missed="1" covered="1"/>
          </method>
          <method name="halfCovered" desc="()V" line="30">
            <counter type="LINE" missed="2" covered="2"/>
            <counter type="COMPLEXITY" missed="2" covered="2"/>
          </method>
        </class>
        <class name="care/smith/fts/cda/Foo$Inner" sourcefilename="Foo.java">
          <method name="innerMethod" desc="()V" line="50">
            <counter type="LINE" missed="0" covered="1"/>
            <counter type="COMPLEXITY" missed="0" covered="1"/>
          </method>
        </class>
        <sourcefile name="Foo.java">
          <line nr="10" mi="0" ci="1"/>
          <line nr="13" mi="0" ci="1"/>
        </sourcefile>
      </package>
    </report>
    """)

DIFF = dedent("""\
    diff --git a/clinical-domain-agent/src/main/java/care/smith/fts/cda/Foo.java b/clinical-domain-agent/src/main/java/care/smith/fts/cda/Foo.java
    --- a/clinical-domain-agent/src/main/java/care/smith/fts/cda/Foo.java
    +++ b/clinical-domain-agent/src/main/java/care/smith/fts/cda/Foo.java
    @@ -11,0 +12,1 @@
    +    x = 1;
    @@ -15,0 +16,1 @@
    +    y = 2;
    @@ -31,2 +32,3 @@
         a();
    -    b();
    +    b(1);
    +    c();
    """)


class CrapScoreTest(unittest.TestCase):

    def test_fully_covered_changed_method_scores_its_complexity(self):
        rows = crap_score.score(io.StringIO(REPORT), io.StringIO(DIFF))
        self.assertIn(("care/smith/fts/cda/Foo", "bar", 3, 1.0, 3.0), rows)

    def test_untouched_method_is_not_reported(self):
        rows = crap_score.score(io.StringIO(REPORT), io.StringIO(DIFF))
        self.assertNotIn("untouched", [r[1] for r in rows])

    def test_lambdas_are_excluded_by_default(self):
        rows = crap_score.score(io.StringIO(REPORT), io.StringIO(DIFF))
        self.assertNotIn("lambda$bar$0", [r[1] for r in rows])
        # the lambda must not shorten the enclosing method's range
        self.assertIn("bar", [r[1] for r in rows])

    def test_lambdas_can_be_included(self):
        rows = crap_score.score(
            io.StringIO(REPORT), io.StringIO(DIFF), include_lambdas=True)
        self.assertIn("lambda$bar$0", [r[1] for r in rows])

    def test_inner_class_edit_does_not_flag_outer_class_last_method(self):
        diff = DIFF.split("@@ -11,0")[0] + "@@ -50,0 +51,1 @@\n+    y = 2;\n"
        rows = crap_score.score(io.StringIO(REPORT), io.StringIO(diff))
        # line 51 is inside Foo$Inner, not inside Foo.halfCovered, which is
        # the outer class's last method and has no successor in its own class
        self.assertEqual(["innerMethod"], [r[1] for r in rows])

    def test_branch_coverage_is_used_when_present(self):
        rows = crap_score.score(io.StringIO(REPORT), io.StringIO(DIFF))
        # lines 100% covered, branches 50%: 9 * 0.125 + 3 = 4.125
        self.assertIn(("care/smith/fts/cda/Foo", "branchy", 3, 0.5, 4.125), rows)

    def test_partial_coverage_raises_score(self):
        rows = crap_score.score(io.StringIO(REPORT), io.StringIO(DIFF))
        # cc=4, coverage=0.5: 16 * 0.125 + 4 = 6
        self.assertIn(("care/smith/fts/cda/Foo", "halfCovered", 4, 0.5, 6.0), rows)


class CliTest(unittest.TestCase):

    def run_cli(self, threshold):
        out = io.StringIO()
        code = crap_score.main(
            io.StringIO(REPORT), io.StringIO(DIFF), threshold, False, out)
        return code, out.getvalue()

    def test_exit_1_when_a_method_reaches_threshold(self):
        code, out = self.run_cli(threshold=6)
        self.assertEqual(1, code)
        self.assertIn("halfCovered", out)

    def test_exit_0_when_all_methods_below_threshold(self):
        code, out = self.run_cli(threshold=8)
        self.assertEqual(0, code)
        self.assertIn("halfCovered", out)


class StaleReportTest(unittest.TestCase):

    def setUp(self):
        import os
        import subprocess
        import tempfile
        self.dir = tempfile.mkdtemp()
        self.old_cwd = os.getcwd()
        os.chdir(self.dir)
        git = lambda *a: subprocess.run(
            ["git", *a], check=True, capture_output=True,
            env={**os.environ, "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t",
                 "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@t"})
        git("init", "-q", "-b", "main")
        src = "src/main/java/care/smith/fts/cda/Foo.java"
        os.makedirs(os.path.dirname(src))
        open(src, "w").write("class Foo {}\n")
        git("add", "."); git("commit", "-q", "-m", "base")
        open("jacoco.xml", "w").write(REPORT)
        os.utime("jacoco.xml", (1_000_000_000, 1_000_000_000))
        open(src, "a").write("// changed\n")
        git("commit", "-q", "-am", "change")
        self.git = git

    def tearDown(self):
        import os
        import shutil
        os.chdir(self.old_cwd)
        shutil.rmtree(self.dir)

    def test_report_older_than_changed_source_is_rejected(self):
        with self.assertRaises(SystemExit) as ctx:
            crap_score.cli(["--report", "jacoco.xml", "--range", "HEAD~1...HEAD"])
        self.assertIn("older than", str(ctx.exception))


if __name__ == "__main__":
    unittest.main()
