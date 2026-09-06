#!/usr/bin/env bash
# PreToolUse hook on Bash. Before `gh pr create`, run cargo-mutants on the lines
# the current branch changes against the default branch of `origin`.
# Exit 2 blocks the command and sends stderr back to Claude.
#
# The hook passes through (exit 0) when:
#   - the Bash command does not contain `gh pr create`,
#   - PR_MUTANTS_SKIP is set to 1 (per-project opt-out via settings "env"),
#   - the repository root has no Cargo.toml,
#   - cargo-mutants is not installed.
# PR_MUTANTS_BASE overrides the base ref (default: origin/HEAD, else origin/main).
set -u

command=$(jq -r '.tool_input.command // ""')
grep -q 'gh pr create' <<<"$command" || exit 0
[ "${PR_MUTANTS_SKIP:-0}" = "1" ] && exit 0

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 1
[ -f Cargo.toml ] || exit 0
cargo mutants --version >/dev/null 2>&1 || exit 0

base=${PR_MUTANTS_BASE:-$(git symbolic-ref -q --short refs/remotes/origin/HEAD || echo origin/main)}

diff=$(mktemp)
log=$(mktemp)
trap 'rm -f "$diff" "$log"' EXIT
git diff "$base"...HEAD >"$diff" || {
    echo "pr-mutants: cannot diff against $base" >&2
    exit 2
}

cargo mutants --in-diff "$diff" --jobs 2 >"$log" 2>&1
code=$?
case $code in
0)
    exit 0
    ;;
2)
    {
        echo "pr-mutants: mutants survived on the changed lines. Add tests that catch them, then create the PR again."
        cat mutants.out/missed.txt
    } >&2
    ;;
3)
    {
        echo "pr-mutants: mutants timed out. Check mutants.out/timeout.txt."
        cat mutants.out/timeout.txt
    } >&2
    ;;
4)
    echo "pr-mutants: the baseline build or tests failed. Fix them first." >&2
    tail -n 30 "$log" >&2
    ;;
*)
    echo "pr-mutants: cargo mutants failed with exit code $code." >&2
    tail -n 30 "$log" >&2
    ;;
esac
exit 2
