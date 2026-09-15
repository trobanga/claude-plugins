# Tracker adapter: beads

Requires the `bd` CLI and a beads database in the repo (`.beads/`). Check with `bd where`; it
reports the resolved workspace, or says no database was found.

**Run every `bd` command outside the Bash sandbox.** beads writes to a Dolt database and the
sandbox blocks it.

`$ID` is the bead id, for example `bd-42` or `bd-a3f8e9`.

beads is a **tracker only**. It has no pull requests, no forge and no remote review. Pair it
with a forge adapter — usually `github`, sometimes `none`.

## T1 — Fetch the issue

```bash
bd show "$ID" --json --include-comments
```

`--include-comments` is required: the discussion is not in the default output, and
requirements are frequently refined there. Add `--long` when you need the extended metadata.

If the id starts with a character that looks like a flag, use `bd show --id="$ID"`.

## T2 — Detect existing work

beads holds no pull requests, so this check runs against two sources.

Tracker side — the bead's own status and assignee, from the T1 JSON. A status of
`in_progress`, or a set assignee, is evidence that work exists.

Forge side — a branch or a pull request that carries the id:

```bash
gh pr list --state all --search "$ID in:body" --json number,state,isDraft,url,title,headRefName
git branch -a --list "*$ID*"
```

Skip the `gh` half when the forge is `none`.

## T3 — Claim the issue

```bash
bd assign "$ID" "$(git config user.name)"
bd update "$ID" --status in_progress
```

Read the valid statuses with `bd statuses` rather than assuming `in_progress` exists in this
database.

If the bead is already assigned to somebody else, do not reassign. Surface it and ask.

## T4 — Branch id

The bead id, unchanged: `bd-42`.

**The branch format must be `{id}--{slug}` for beads.** The id contains a hyphen, so
`{id}-{slug}` cannot be split back apart.

Some beads ids contain `--` themselves (the CLI's own example is `gt--xyz`). This stays
unambiguous because the slug never contains `--`: split the branch name on its **last** `--`.

## T5 — Close reference

There is no PR-body keyword that beads understands. Close it explicitly after the work merges:

```bash
bd close "$ID"
```

Put `Closes $ID` in the PR body anyway, as a human-readable trail and as the string that T2
searches for on the next run. It does not close anything by itself.

Tell the user that closing is a separate step here, not automatic on merge.
