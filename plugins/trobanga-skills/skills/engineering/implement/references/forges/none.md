# Forge adapter: none (plain git)

For a repo with no pull-request host: a bare remote, a local-only repo, or a mirror where
review happens elsewhere.

## F1 — Default branch

```bash
DEFAULT_BRANCH="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD | sed 's|^origin/||')"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
```

If the repo has no `origin`, ask the user for the base branch. Do not guess.

## F2 — Commit and push

Commit with `Skill(commit-commands:commit)`, passing `--signoff`.

Then push, if a remote exists:

```bash
git push -u origin "$BRANCH"
```

With no remote, the branch stays local. Say so — the work is not backed up anywhere.

## F3 — Pull request

There is none. Instead:

1. Report the branch name and the commit range to the user.
2. State how to merge it, and do not merge it yourself.
3. Run the tracker's T5 close operation only after the user confirms the merge.

## F4 — Review

There is no PR to review. The in-workflow review (Phase 4, step 17) is the only review pass.
Say so explicitly, so the user knows no second pair of eyes is coming.
