# Forge adapter: GitHub

Requires `gh`, authenticated. Check with `gh auth status`.

When the repo has several remotes, or `gh` picks the wrong one, add `--repo owner/name` to
every command. Put that value in `.agents/issue-tracker.md`.

## F1 — Default branch

Do not assume `main`:

```bash
DEFAULT_BRANCH="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null \
  || git symbolic-ref --quiet --short refs/remotes/origin/HEAD | sed 's|^origin/||')"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
```

## F2 and F3 — Commit, push, open the pull request

Both run through one command:

```
/commit-commands:commit-push-pr --signoff
```

`--signoff` is required for all commits in this environment.

The PR body carries the tracker's T5 close reference. When T5 closes through the tracker's own
API instead (Linear, beads), the PR still names the issue id, and the T5 command runs after
the merge.

Capture the PR number from the output.

Assign the PR to yourself:

```bash
gh pr edit "$PR_NUMBER" --add-assignee @me
```

If this fails — a PR opened from a fork may not allow it — report it and continue.

## F4 — Review the pull request

```
/code-review:code-review <PR_NUMBER>
```

Run it only for large or risky changes. The workflow already ran a full review before
shipping.
