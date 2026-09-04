import os
import shutil
import tempfile
import unittest

import crap_score


class DetectTest(unittest.TestCase):

    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.old_cwd = os.getcwd()
        os.chdir(self.dir)

    def tearDown(self):
        os.chdir(self.old_cwd)
        shutil.rmtree(self.dir)

    def marker(self, name):
        open(name, "w").close()

    def test_detects_java_from_pom_xml(self):
        self.marker("pom.xml")
        self.assertEqual("java", crap_score.detect())

    def test_detects_go_from_go_mod(self):
        self.marker("go.mod")
        self.assertEqual("go", crap_score.detect())

    def test_detects_rust_from_cargo_toml(self):
        self.marker("Cargo.toml")
        self.assertEqual("rust", crap_score.detect())

    def test_elixir_is_refused_by_name(self):
        self.marker("mix.exs")
        with self.assertRaises(SystemExit) as ctx:
            crap_score.detect()
        self.assertIn("Elixir", str(ctx.exception))

    def test_detects_typescript_from_package_json(self):
        self.marker("package.json")
        self.assertEqual("ts", crap_score.detect())

    def test_an_unknown_project_is_refused(self):
        with self.assertRaises(SystemExit):
            crap_score.detect()

    def test_a_javascript_toolchain_beside_a_backend_does_not_win(self):
        # a Go or Java repository often ships a package.json for its frontend
        self.marker("package.json")
        self.marker("go.mod")
        self.assertEqual("go", crap_score.detect())


class LanguageTableTest(unittest.TestCase):

    def test_every_language_names_a_collector_and_a_source_pattern(self):
        for lang, spec in crap_score.LANGUAGES.items():
            self.assertTrue(spec.module, lang)
            self.assertTrue(spec.sources, lang)
            self.assertTrue(spec.report, lang)


if __name__ == "__main__":
    unittest.main()
