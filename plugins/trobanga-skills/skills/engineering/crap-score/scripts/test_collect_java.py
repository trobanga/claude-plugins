import io
import unittest
from textwrap import dedent

import collect_java
import crap_core

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


def collect(include_lambdas=False):
    return list(collect_java.records(io.StringIO(REPORT), include_lambdas))


def by_name(records):
    return {r["name"].rsplit(".", 1)[1]: r for r in records}


class CollectJavaTest(unittest.TestCase):

    def test_method_carries_complexity_and_line_coverage(self):
        bar = by_name(collect())["bar"]
        self.assertEqual(3, bar["cc"])
        self.assertEqual(1.0, bar["coverage"])
        self.assertEqual(10, bar["start"])

    def test_branch_coverage_is_used_when_present(self):
        branchy = by_name(collect())["branchy"]
        # lines 100% covered, branches 50%
        self.assertEqual(0.5, branchy["coverage"])
        self.assertEqual("branch", branchy["kind"])

    def test_method_name_carries_its_class(self):
        self.assertIn("care/smith/fts/cda/Foo.bar",
                      [r["name"] for r in collect()])

    def test_source_file_path_holds_the_package(self):
        self.assertEqual("care/smith/fts/cda/Foo.java",
                         by_name(collect())["bar"]["file"])

    def test_a_method_ends_where_the_next_one_starts(self):
        self.assertEqual(14, by_name(collect())["bar"]["end"])

    def test_the_last_method_of_a_file_is_open_ended(self):
        self.assertIsNone(by_name(collect())["innerMethod"]["end"])

    def test_lambdas_are_excluded_by_default(self):
        names = [r["name"] for r in collect()]
        self.assertNotIn("care/smith/fts/cda/Foo.lambda$bar$0", names)

    def test_lambdas_can_be_included(self):
        names = [r["name"] for r in collect(include_lambdas=True)]
        self.assertIn("care/smith/fts/cda/Foo.lambda$bar$0", names)

    def test_a_lambda_does_not_shorten_the_method_around_it(self):
        # the lambda starts at line 12, inside bar, which still ends at 14
        self.assertEqual(14, by_name(collect(include_lambdas=True))["bar"]["end"])

    def test_an_inner_class_ends_the_range_of_the_preceding_method(self):
        # halfCovered is the last method of its own class but not of the file
        self.assertEqual(49, by_name(collect())["halfCovered"]["end"])


class ScoredWithCoreTest(unittest.TestCase):
    """The records of a real report, scored by the language-neutral core."""

    def rows(self):
        return dict((r[0].rsplit(".", 1)[1], r)
                    for r in crap_core.score(collect(), io.StringIO(DIFF)))

    def test_fully_covered_changed_method_scores_its_complexity(self):
        self.assertEqual(3.0, self.rows()["bar"][3])

    def test_untouched_method_is_not_reported(self):
        self.assertNotIn("untouched", self.rows())

    def test_partial_coverage_raises_the_score(self):
        # cc=4, coverage=0.5: 16 * 0.125 + 4 = 6
        self.assertEqual(6.0, self.rows()["halfCovered"][3])

    def test_inner_class_edit_does_not_flag_the_outer_class(self):
        diff = DIFF.split("@@ -11,0")[0] + "@@ -50,0 +51,1 @@\n+    y = 2;\n"
        rows = crap_core.score(collect(), io.StringIO(diff))
        self.assertEqual(["care/smith/fts/cda/Foo$Inner.innerMethod"],
                         [r[0] for r in rows])


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
        git("add", ".")
        git("commit", "-q", "-m", "base")
        open("jacoco.xml", "w").write(REPORT)
        os.utime("jacoco.xml", (1_000_000_000, 1_000_000_000))
        open(src, "a").write("// changed\n")
        git("commit", "-q", "-am", "change")

    def tearDown(self):
        import os
        import shutil
        os.chdir(self.old_cwd)
        shutil.rmtree(self.dir)

    def test_report_older_than_a_changed_source_is_rejected(self):
        with self.assertRaises(SystemExit) as ctx:
            crap_core.reject_stale_report("jacoco.xml", ["src/main/java/care/smith/fts/cda/Foo.java"])
        self.assertIn("older than", str(ctx.exception))


if __name__ == "__main__":
    unittest.main()
