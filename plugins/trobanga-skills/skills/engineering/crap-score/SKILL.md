---
name: crap-score
description: Compute the CRAP score (Change Risk Anti-Patterns) of every function changed on the current branch, from a coverage report and a git diff, and fail above a threshold. Supports Java, Go, Rust and TypeScript. Measures only and writes no tests. Use when the user asks for a CRAP score, a complexity-times-coverage check, or which changed functions are risky. To fix the violations, use the crap-agent.
allowed-tools: Bash, Read, Glob
---

# CRAP score of changed functions

    CRAP(f) = cc(f)^2 * (1 - coverage(f))^3 + cc(f)

`cc` is the cyclomatic complexity of the function, `coverage` its test
coverage in [0, 1]. With full coverage the score equals `cc`. Only
functions that contain a line added by the diff are scored. Default
threshold: 8.

## Structure

The skill has one entry point and one collector per language, in
`~/.agents/skills/engineering/crap-score/scripts/`:

- `crap_score.py` detects the project type, runs the collector, scores.
- `crap_core.py` maps the diff to functions and computes the score.
- `collect_java.py` and its siblings read a coverage report and write
  "function records", one JSON object per line:

      {"file": "src/foo.go", "name": "Foo.bar", "start": 10, "end": 14,
       "cc": 3, "coverage": 0.5, "kind": "branch"}

`end` may be `null`, which means "to the end of the file". `kind` names
the coverage kind and appears in the footer of the table.

## Prerequisites

- Python 3, no third-party packages.
- The coverage tool of the language, see the language section below.

## Instructions

1. Build fresh coverage with the command of the language section. Do not
   reuse an old report, it may describe old code.
2. Score the branch:

       python3 ~/.agents/skills/engineering/crap-score/scripts/crap_score.py \
         --report <report> --range origin/main...HEAD --threshold 8

   `--lang java|go|rust|ts` overrides the detected project type.
   `--diff FILE` or `--diff -` takes a unified diff instead of a range.
   With `--range`, the script fails when the report is older than a
   changed source file. Rebuild the report then.

Show the table verbatim. Exit code 1 means at least one function is at or
above the threshold.

## Java

- Detected by `pom.xml`. Coverage: **branch**, line for methods without
  branches.
- Needs the JaCoCo Maven plugin.
- Build the report per changed module. The first path segment of
  `git diff --name-only origin/main...HEAD -- '*.java'` names the module.

      mvn verify -pl <m1>,<m2> --also-make -Dmaven.test.failure.ignore=true -q
      mvn jacoco:report -pl <m> -Djacoco.dataFile=target/jacoco.exec -q

- Report: `<m>/target/site/jacoco/jacoco.xml`. Give it with `--report`.
- Lambdas are excluded. `--include-lambdas` scores them as own methods.
- JaCoCo gives only the first code line of a method. A method ends where
  the next method of the same source file starts, across inner classes.
  An edit above the first code line (annotation, signature, Javadoc)
  therefore maps to the preceding method.
- Verified on a Maven project with JaCoCo 0.8.15: a method with four
  `if` statements and 5 of 8 branches covered scores 6.3 at cc 5.

## Go

- Detected by `go.mod`. Coverage: **statement**.
- Needs the Go toolchain, nothing else. The helper `crap_funcs.go` reads
  the complexity and the line range of every function from the Go AST.
- Build the report from the repository root:

      go test -count=1 -coverprofile=coverage.out ./...

  Add `-coverpkg=./...` when the tests live in a package of their own.
- Report: `coverage.out`, the default of `--report`.
- Coverage is the share of covered statements of the function. The cover
  tool cuts a block at every branch, so an uncovered branch always lowers
  the number, but a branch without statements stays invisible.
- A function literal keeps no record of its own. Its branches raise the
  complexity of the function around it.
- Verified on a Go module: a function with four `if` statements and 6 of
  9 statements covered scores 5.9 at cc 5.

## Rust

- Detected by `Cargo.toml`. Coverage: **line**.
- Needs two tools:

      cargo install cargo-llvm-cov
      cargo install cargo-crap

  `cargo llvm-cov` also needs the `llvm-tools` component of the
  toolchain. It installs it on the first run and asks before it does.
- Build the report from the crate root:

      cargo llvm-cov --lcov --output-path lcov.info

- Report: `lcov.info`, the default of `--report`. The collector runs
  `cargo crap --lcov lcov.info --format json` over it, which reads the
  complexity of every function from the source with `syn`.
- Coverage is the share of covered lines, from the `DA` records of the
  LCOV file. `cargo llvm-cov --lcov` on a stable toolchain writes no
  branch records (`BRF:0`), so branch coverage is not available. A `match`
  arm that no test reaches lowers the number, but only through the lines
  it holds.
- cargo-crap gives the first line of a function and no last line, so a
  function ends where the next function of the same file starts. An edit
  above the first line of a function (attribute, doc comment) therefore
  maps to the preceding function.
- cargo-crap has a threshold of its own. crap-score ignores it and
  applies `--threshold`.
- Verified on a crate with cargo-crap 0.4.3: a function with four
  decisions and 9 of 11 lines covered scores 5.2 at cc 5, the same value
  cargo-crap reports itself.

## TypeScript and JavaScript

- Detected by `package.json`. Coverage: **branch**, statement for
  functions without branches.
- Needs an Istanbul `coverage-final.json`. Vitest, Jest, nyc and c8 all
  write it. With Vitest, ask for the Istanbul provider, because the V8
  provider writes no `fnMap`:

      // vitest.config.ts
      test: { coverage: { provider: "istanbul", reporter: ["json"] } }

  Then:

      npx vitest run --coverage

  With Jest: `npx jest --coverage --coverageReporters=json`.
- Report: `coverage/coverage-final.json`, the default of `--report`.
- The complexity is one plus the decisions of the branches inside the
  function: a branch with n paths counts n - 1. A default argument
  counts as no decision, Istanbul gives it one path only.
- Anonymous functions keep no record of their own; their branches raise
  the complexity of the function around them.
  `--include-anonymous` on the collector scores them separately.
- A named function inside another function is counted twice: once alone,
  once in the range of the function around it.
- Verified with Vitest 2.1 and the Istanbul provider: a function with
  four `if` statements and 5 of 8 branch paths covered scores 6.3 at
  cc 5, the same numbers as the equal Java method.

## Elixir

Not supported. The Elixir tools report line coverage per file and no
complexity per function, so the two numbers CRAP needs are not available
from one report.

## Tests

    python3 -m unittest discover -s ~/.agents/skills/engineering/crap-score/scripts
