---
name: patch-coverage
description: Measure patch coverage for the current branch against origin/main with diff-cover, for Java (JaCoCo), Go, Rust (tarpaulin), or Elixir (ExCoveralls). Reports per-file coverage and missing lines; it measures only and writes no tests. Use when the user asks how well the branch's changes are covered, wants a diff-cover run, or asks for a patch coverage number. To raise the number, use improve-coverage instead.
allowed-tools: Bash, Read, Glob
---

# Patch Coverage

Compute patch coverage for the current branch compared to origin/main.

## Prerequisites
- `diff-cover`: `pip install diff-cover`
- Java: JaCoCo's `prepare-agent` goal bound in pom.xml. If the pom names the data file other than `jacoco.exec`, set `JACOCO_EXEC` to that name when you run the script.
- Go: `go install github.com/boumenot/gocover-cobertura@latest`
- Rust: `cargo install cargo-tarpaulin`
- Elixir: `{:excoveralls, "~> 0.18", only: :test}` in mix.exs, with `test_coverage: [tool: ExCoveralls]` in `project/0` (LCOV output needs diff-cover >= 7.5)

## Instructions

Detect the project type and run its script from the repository root. Take the first match:

1. If `pom.xml` exists (Java):
   ```bash
   "${CLAUDE_SKILL_DIR}/scripts/patch-coverage-java.sh"
   ```

2. If `go.mod` exists (Go):
   ```bash
   "${CLAUDE_SKILL_DIR}/scripts/patch-coverage-go.sh"
   ```

3. If `Cargo.toml` exists (Rust):
   ```bash
   "${CLAUDE_SKILL_DIR}/scripts/patch-coverage-rust.sh"
   ```

4. If `mix.exs` exists (Elixir):
   ```bash
   "${CLAUDE_SKILL_DIR}/scripts/patch-coverage-elixir.sh"
   ```

If none match, tell the user the project type is not supported and stop.

Display results in a formatted table showing file name, coverage %, and missing lines.
If the user named a target percentage, highlight the files below it.
