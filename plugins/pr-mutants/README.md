# pr-mutants

A mutation-testing gate for Rust pull requests. Before `gh pr create` runs, the
plugin runs [`cargo-mutants`](https://mutants.rs/) on the lines your branch
changes. If a mutant survives, the plugin blocks the command and tells Claude
which mutants to catch.

A surviving mutant is a change to your code that no test detects. It marks a
line that the test suite executes but does not check.

## Requirements

- A Rust repository with a `Cargo.toml` at the root.
- `cargo-mutants`: `cargo install cargo-mutants`.
- `jq` and `git`.
- `origin` must have a default branch, or `origin/main` must exist.

## Install

```
/plugin marketplace add trobanga/claude-plugins
/plugin install pr-mutants@trobanga
```

## How it works

The plugin registers one `PreToolUse` hook on the `Bash` tool, with a timeout of
1800 seconds. The hook exits immediately (exit code 0, no effect) when any of
these is true:

- the command does not contain `gh pr create`;
- `PR_MUTANTS_SKIP` is `1`;
- the repository root has no `Cargo.toml`;
- `cargo-mutants` is not installed.

Otherwise it diffs the branch against the base ref and runs
`cargo mutants --in-diff <diff> --jobs 2`. On a survivor, a timeout, or a broken
baseline, it exits with code 2. Exit code 2 blocks the `Bash` call and sends the
reason back to Claude.

## Configuration

| Variable | Default | Effect |
| --- | --- | --- |
| `PR_MUTANTS_SKIP` | `0` | Set to `1` to disable the gate. |
| `PR_MUTANTS_BASE` | `origin/HEAD`, else `origin/main` | The ref to diff against. |

Set these per project in `.claude/settings.json`:

```json
{
  "env": {
    "PR_MUTANTS_SKIP": "1"
  }
}
```

## Cost

Mutation testing runs the test suite once per mutant. On a large diff this takes
minutes. Keep the diff small, or raise `--jobs` by editing
`scripts/pre-pr-mutants.sh`.

## License

Apache-2.0. See the [LICENSE](../../LICENSE) at the repository root.
