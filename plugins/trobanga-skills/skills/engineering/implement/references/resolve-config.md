# Resolve the tracker, the forge and the branch format

Three values. Resolve only the ones your skill uses.

- **TRACKER** — where the issue lives: `github`, `linear`, `beads`, `none`.
- **FORGE** — where the code and the pull request go: `github`, or `none` for plain git with
  or without a remote.
- **Branch format** — `{id}--{slug}` (default) or `{id}-{slug}`.

TRACKER and FORGE are independent. A repo hosted on GitHub may track its work in Linear.

## Lookup order

Resolve each value by the first rule that answers it:

1. **Project config**, in this order. Stop at the first file that answers the value:
   1. `.agents/issue-tracker.local.md` — an untracked, personal override, for a repo you do
      not control or a team that did not want a shared file.
   2. `.agents/issue-tracker.md` — the shared answer. Holds all three values and any
      project-specific deviation from the adapters (a `--repo owner/name`, a team key, an id
      prefix, a required field).
   3. `CLAUDE.md`, which is already in your context. Read it, never write it: a project may
      state the tracker as prose, for example "Issue tracking: Linear, team general iam (issue
      keys `GIAM-123`)". That counts.
2. **The shape of the id**, when you have one. A URL identifies both host and tracker.
   `ABC-123` is Linear or Jira. A bare number or `#123` narrows to a forge-native tracker. A
   beads prefix (`bd-42`, or the prefix in `.beads/`) is beads.
3. **Repo evidence.** A `.beads/` directory means beads. The host of
   `git remote get-url origin` gives the FORGE with high confidence, and the TRACKER with low
   confidence. Existing branch names read like rule 2: `giam-123--…` points to Linear,
   `bd-42--…` to beads.
4. **Machine evidence.** `gh auth status`, `bd version`, a connected `linear` MCP server. It
   describes the machine, not the project, so it never decides a value: when it is the only
   evidence, ask the user, and recommend the value it points to.

If rule 3 decided a value, state the guess in one line and continue. If no rule decided the
TRACKER, ask the user, and offer `Skill(trobanga-skills:setup-project)` to persist the answer.

The branch format is `{id}--{slug}` unless the config sets `{id}-{slug}`. The double separator
is what lets a non-numeric id such as `giam-123` be split from its slug, so `{id}-{slug}` works
only with numeric ids. Build and parse branch names with
[`../scripts/branch_name.py`](../scripts/branch_name.py) (run it), passing the format with
`--format`.

## Adapters

Each resolved value names an adapter file beside this one. Read the one your skill needs:

- `trackers/{TRACKER}.md` — operations **T1** (fetch the issue) to **T5** (close reference),
  which `implement` uses, and **T6** (create an issue) and **T7** (link blocking), which the
  skills that file issues use.
- `forges/{FORGE}.md` — operations **F1** (default branch) to **F4** (review the pull request),
  which `implement` uses, **F5** (wait for the checks), which its delegated mode uses, and
  **F6** (merge), which `orchestrate` uses.
