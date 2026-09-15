---
name: setup-project
description: Record which issue tracker, forge and branch format a project uses, in .agents/issue-tracker.md, so implement, worktree-cleanup and conformance-review stop guessing. Use when a project has no tracker configuration, when a skill asks which tracker to use, or when the user asks to set up or configure a project for these skills.
---

# Set Up a Project's Tracker Configuration

Write down two axes and one format, so the workflow skills stop guessing.

One file holds all of it:

- **`.agents/issue-tracker.md`** — shared and tracked. Its name says nothing about any
  agent tool, it reads as project documentation, and `conformance-review` already expects this
  exact path.
- **`.agents/issue-tracker.local.md`** — the untracked alternative, for a repo you do not
  control or a team that does not want the shared file. Same content, gitignored, and it wins
  over the shared file when both exist.

**Never write `CLAUDE.md`.** The skills read it — a project frequently states its tracker
there as prose, and that counts — but the enum-shaped configuration of a tool that only some
of the team uses does not belong in a shared context file.

## 1. Detect before you ask

Gather evidence first, then confirm it. Do not interrogate the user about facts the repo
already states.

| Signal | Tells you |
|---|---|
| An existing "Issue tracking" section in `CLAUDE.md` | Both axes, frequently as prose |
| `.beads/` directory | TRACKER is beads |
| A `linear` entry in `.mcp.json` | TRACKER is linear |
| `.github/` directory, issue templates | TRACKER may be github |
| `git remote get-url origin` host | FORGE, with high confidence |
| Existing branch names (`git branch -a`) | The branch format in use |
| `gh auth status`, `bd where` | Which tools work on this machine |

The remote host settles the FORGE. It does **not** settle the TRACKER: a repo hosted on GitHub
may track its work in Linear or beads. Always confirm the tracker with the user.

## 2. Ask what is left

Use `AskUserQuestion`, one question per unresolved item, with the detected value first and
marked as recommended.

- **Issue tracker** — `github`, `linear`, `beads`, `none`
- **Forge** — `github`, `git` (a remote with no PR host), `none`
- **Branch format** — `{id}--{slug}` (default) or `{id}-{slug}`

For Linear, also ask for the team and the issue key prefix (for example `GIAM`). For beads,
ask for the id prefix if it is not obvious from `.beads/`.

## 3. Refuse the one broken combination

`{id}-{slug}` together with a non-numeric id — Linear `GIAM-123`, beads `bd-42` — produces a
branch name that no parser can split back apart: `giam-123-fix-login` gives no way to tell
where the id ends. `worktree-cleanup` then cannot match the worktree to its issue.

If the user picks that pair, say so and offer `{id}--{slug}`. Accept the pair only if they
insist, and warn that cleanup will report `Issue: unknown` for those worktrees.

`{id}-{slug}` is safe with numeric GitHub ids, and is the right choice for a repo whose
existing branches already use it.

## 4. Ask where the file goes

Two choices, and the answer depends on the team, not on the repo:

- **`.agents/issue-tracker.md`**, tracked. Right when the facts are project truth the
  whole team benefits from, which is the usual case.
- **`.agents/issue-tracker.local.md`**, untracked. Right for a repo you do not control, or a
  team that does not want the file. Add it to `.git/info/exclude` rather than `.gitignore`, so
  the shared repo stays untouched.

Recommend the tracked file. Ask, do not assume.

## 5. Write the file

Write prose a human can read, not a config dump. Both axes, the branch format, and the reason
behind the branch format when it is not the default.

```markdown
# Issue tracker

Issues live in **Linear**, team *general iam*, issue keys `GIAM-123`. Code and pull requests
live on **GitHub** (`dd-photos/giam`).

Branch names are `{id}--{slug}`, for example `giam-123--refuse-deleted-subject`. The double
separator is what lets the id be told apart from the slug, since the id itself contains a
hyphen.
```

Then add the deviations, and **only** the deviations from the adapters in
`trobanga-skills/skills/engineering/implement/references/`. Do not copy the adapter's commands
into the file — the copy goes stale and the adapter is the source of truth.

Write a deviation when the project has one of these:

- A `--repo owner/name` that `gh` cannot infer, because the repo has several remotes
- A Linear team key or an in-progress state name that differs from the adapter's assumption
- A beads id prefix, or a non-default `BEADS_DIR`
- A required field on issue creation
- A tracker-specific step the adapter does not know about

When nothing deviates, say so in one line. The file is still worth writing: it carries the two
axes and the branch format, and `conformance-review` resolves the path.

## 6. Leave CLAUDE.md alone

If `CLAUDE.md` already states the tracker as prose, that is fine and the skills read it. Do
not duplicate it into the new file's wording and do not edit it. If it states something that
contradicts what the user just told you, point out the contradiction and let them fix it.

## 7. Report

State which file you wrote, the three resolved values, and which skills now stop guessing:
`implement`, `worktree-cleanup`, `conformance-review`.
