# Tracker adapter: none

For work that is tracked nowhere but in the repo. An issue filed here (T6) is a Markdown file
under `.agents/issues/`; any other issue is whatever the user asked for: the skill arguments,
or the conversation that led here.

Pair it with any forge adapter.

## T1 — Fetch the issue

If the id the user gave names a file `.agents/issues/<id>--*.md`, that file is the issue.
Otherwise take the title and the description of the work from the skill arguments; if they
hold none, from the conversation. If neither describes the work well enough to write a title
and a goal, ask the user for them. There is no discussion or assignee to read.

## T2 — Detect existing work

No tracker records work. Say "No tracker: the existing-work check covers only the forge and
local worktrees" and continue. The worktree check in Phase 2 still catches a rerun.

## T3 — Claim the issue

Nothing to claim. Say "No tracker: nothing to claim" and continue.

## T4 — Branch id

The id the user gave, if any — an `.agents/issues/` id, or a ticket number from a system
these adapters do not reach.
Otherwise today's date as `YYYYMMDD`, which keeps branches apart and tells `worktree-cleanup`
how old the branch is.

## T5 — Close reference

Describe the work in the PR body. If the issue is a file under `.agents/issues/`, set its
`**Status:**` to `closed` after the merge; otherwise say "No tracker: nothing to close".

## T6 — Create an issue

Inputs: a title, a body, labels, and optionally a parent issue.

The id is the next number after the highest one under `.agents/issues/`, three digits wide:
`001`, `002`. Build the file name with
[`../../scripts/branch_name.py`](../../scripts/branch_name.py) (run it):
`branch_name.py build --id "$ID" --title "$TITLE"` prints `<id>--<slug>`. Write
`.agents/issues/<id>--<slug>.md`:

```markdown
# <id> — <title>

**Status:** open
**Labels:** <labels, comma-separated, or none>
**Parent:** <parent id, or none>
**Blocked by:** None — can start immediately

<body>
```

The new id and the file path are the result.

## T7 — Link blocking

`$BLOCKER` blocks `$ID`, both already filed: in the file of `$ID`, replace the `None — can
start immediately` of its `**Blocked by:**` line with `$BLOCKER`, or append `, $BLOCKER` to
the ids already there.
