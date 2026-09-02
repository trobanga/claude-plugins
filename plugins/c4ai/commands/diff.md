---
allowed-tools: Bash(c4ai diff:*)
argument-hint: <base> [head]
description: Show what changed architecturally between two git refs
---

## Your task

Run: `c4ai diff $ARGUMENTS`

Typical use before opening a pull request: `c4ai diff main`. `head` defaults to `HEAD`.

It writes `before.md`, `after.md` and `diff.md` into `.c4ai/diff` (override with `--out`). Read `diff.md` and report what moved — that is the only file carrying the diff colours, the legend and the `[+]`/`[-]`/`[~]` markers.

### Read it honestly

- **If `diff.md` says "No architectural change", say so and stop.** There is no diagram because nothing structural moved. Do not go looking for one, and do not describe the content-touched list as if it were architectural drift — it is prose.
- **Content touched is not change.** A reworded `ai_summary` or a retitled document is listed in its own section precisely so it is not mistaken for a structural edit.
- **Derived (L4) deltas are extracted from source, not declared.** Deterministic, but lossy: a cosmetic refactor can defeat the extractor's heuristics, so a removal there is not proof that code was deleted. Say where the claim came from.
- **Report drift with its denominator.** "9 unmodelled" alone reads as an indictment of the commit; "9 unmodelled, and 2 of 11 documents declare a `source:`" is a statement about coverage. The `## Drift` section prints both — quote both.
- **Read the `## Caveats` section if present.** Those documents were not compared at all. Their absence from the diagram means "not looked at", not "unchanged".

The exit code is zero even when there are changes. Non-zero means the command itself failed — a ref that does not resolve, or a write that could not happen.

### Options worth knowing

- `--focus <id>` — restrict the diagrams to one document id and its boundary. Useful when the default (every boundary that moved, capped at 8) is too broad.
- `--merge-base` — compare against the merge base, matching what a GitHub pull request shows.
- `--format svg` — write sibling `.svg` files instead of mermaid fences. Only do this if asked: GitHub renders inline mermaid and does not reliably render linked SVG in markdown.

c4ai emits mermaid as text and never renders it. Do not try to render it either — paste the fence.
