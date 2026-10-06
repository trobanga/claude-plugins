# Tracker adapter: Linear

Linear has no first-party CLI. Access goes through the **Linear MCP server**, declared in the
project's `.mcp.json`:

```json
{ "mcpServers": { "linear": { "type": "http", "url": "https://mcp.linear.app/mcp" } } }
```

If no `linear` MCP server is connected in this session, stop and tell the user to add it and
authenticate. Nothing below works without it.

`$ID` is the issue identifier, for example `GIAM-123`. Keep its uppercase form when talking to
Linear; lowercase it only for the branch name (T4).

**Tool names are discovered, not assumed.** The server's tool set changes over time. List the
`linear` tools available in this session and match them to the operations below. The names
used here — `linear:get_issue`, `linear:list_comments`, `linear:create_issue`,
`linear:update_issue`, `linear:list_issue_statuses`, `linear:list_issue_labels`,
`linear:list_teams`, `linear:list_users` — are the expected ones, not a guarantee. If a name
does not exist, find the tool that performs the operation.

## T1 — Fetch the issue

1. `linear:get_issue` with the identifier `$ID`. Take title, description, state, assignee,
   team and URL.
2. `linear:list_comments` for the same issue. Linear discussion is a separate call, unlike
   GitHub — do not skip it. Requirements are frequently refined there.

## T2 — Detect existing work

Linear does not hold pull requests of its own. Its GitHub integration attaches a PR to an
issue when the branch name or the PR text contains the issue identifier — which is exactly
what T4 produces. Two checks, both against the **forge**:

```bash
gh pr list --state all --search "$ID in:title" --json number,state,isDraft,url,title,headRefName
git branch -a --list "*$(printf '%s' "$ID" | tr '[:upper:]' '[:lower:]')*"
```

Also treat a Linear issue whose state is already "In Progress" or "Done", or whose assignee is
set, as evidence that work exists. Surface it and confirm.

## T3 — Claim the issue

`linear:update_issue`: set the assignee to the current user, and set the state to the team's
in-progress state.

- The current user comes from `linear:list_users` or from the server's own "me" concept.
  Resolve it once.
- State names are per team. Read them with `linear:list_issue_statuses` for the issue's team
  rather than assuming "In Progress" exists.

If the issue is already assigned to somebody else, do not reassign. Surface it and ask.

## T4 — Branch id

The identifier, lowercased: `GIAM-123` becomes `giam-123`. The id contains a hyphen, so it
needs the default branch format `{id}--{slug}`; run `scripts/branch_name.py` to build and
parse the name.

## T5 — Close reference

Linear has no equivalent of GitHub's `Closes #N` unless the GitHub integration is configured
to close on merge.

- Put the identifier in the **PR title**, for example `GIAM-123: <title>`. That is what the
  Linear GitHub integration matches on, and it is what T2 searches for on the next run.
- Put `Linear: <issue URL>` in the PR body.
- After the PR merges, run `linear:update_issue` to set the state to the team's done state.

Tell the user that closing is a separate step here, not automatic on merge.

## T6 — Create an issue

Inputs: a title, a body, labels, and optionally a parent issue.

`linear:create_issue` with the title, the body as the description, the team, the label names,
and the parent's id as the parent. It returns the new identifier and URL.

- The team is the team key from `.agents/issue-tracker.md`, else the parent's team, else ask
  the user, offering the teams `linear:list_teams` returns.
- Labels must exist in the team; check with `linear:list_issue_labels`. Create a missing one
  with the server's label-creating tool; if it has none, file without that label and name it
  in your report.

## T7 — Link blocking

`$BLOCKER` blocks `$ID`, both already filed: `linear:update_issue` on `$ID`, adding `$BLOCKER`
to its blocked-by relations. If no tool sets issue relations, append the line
`Blocked by $BLOCKER` to the description of `$ID` instead, and say that the link is text only.
