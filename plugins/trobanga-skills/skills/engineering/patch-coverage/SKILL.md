---
name: patch-coverage
description: Measure patch coverage for the current branch against origin/main with diff-cover, for Java (JaCoCo), Go, Rust (tarpaulin), or Elixir (ExCoveralls). Reports per-file coverage and missing lines; it measures only and writes no tests. Use when the user asks how well the branch's changes are covered, wants a diff-cover run, or asks for a patch coverage number. To raise the number, use improve-coverage instead.
allowed-tools: Bash, Read, Glob
---

# Patch Coverage

Compute patch coverage for the current branch compared to origin/main.

## Prerequisites
- `diff-cover`: `pip install diff-cover`
- Java: JaCoCo configured in pom.xml
- Go: `go install github.com/boumenot/gocover-cobertura@latest`
- Rust: `cargo install cargo-tarpaulin`
- Elixir: `{:excoveralls, "~> 0.18", only: :test}` in mix.exs, with `test_coverage: [tool: ExCoveralls]` in `project/0` (LCOV output needs diff-cover >= 7.5)

## Instructions

Detect project type and run appropriate script:

The scripts ship with this skill, in `~/.agents/skills/engineering/patch-coverage/scripts/`.

1. If `pom.xml` exists (Java):
   ```bash
   ~/.agents/skills/engineering/patch-coverage/scripts/patch-coverage-java.sh
   ```

2. If `go.mod` exists (Go):
   ```bash
   ~/.agents/skills/engineering/patch-coverage/scripts/patch-coverage-go.sh
   ```

3. If `Cargo.toml` exists (Rust):
   ```bash
   ~/.agents/skills/engineering/patch-coverage/scripts/patch-coverage-rust.sh
   ```

4. If `mix.exs` exists (Elixir):
   ```bash
   ~/.agents/skills/engineering/patch-coverage/scripts/patch-coverage-elixir.sh
   ```

If none match, tell the user the project type is not supported and stop.

Display results in a formatted table showing file name, coverage %, and missing lines.
Highlight files below 80% coverage.

## Optional: HTML Report
```bash
diff-cover coverage.xml --compare-branch=origin/main --html-report=patch-coverage.html
```
