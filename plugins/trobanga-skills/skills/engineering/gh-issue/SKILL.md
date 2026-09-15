---
name: gh-issue
description: Work on a GitHub issue in a fresh git worktree based on the default branch. Claims the issue, creates the worktree, explores, designs, implements test-first, reviews, and opens a PR that closes the issue. Use when the user asks to start, pick up, or work on a GitHub issue by number ("work on #123", "take issue 45", "start on that issue").
---

# Work on a GitHub Issue

This is an entry point, not a workflow. The workflow lives in
`Skill(trobanga-skills:implement)`, which is tracker-agnostic.

Invoke it with the axes already resolved, so it skips its own detection:

- TRACKER `github` — adapter `references/trackers/github.md`
- FORGE `github` — adapter `references/forges/github.md`

Pass the issue number through as the argument. Strip a leading `#` first.

Honour the project's branch format if the config sets one — `implement` Phase 0 says where it
reads the config from, and `gh-issue` changes none of that. GitHub issue ids are
numeric, so both `{id}--{slug}` and the legacy `{id}-{slug}` parse unambiguously here.

If the repo turns out to track its work somewhere other than GitHub Issues — Linear, beads —
say so and hand over to `Skill(trobanga-skills:implement)` without a preset tracker.
