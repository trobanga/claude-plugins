# Tracker adapter: GitHub Issues

Requires `gh`, authenticated. Check with `gh auth status`; it distinguishes "not installed"
from "not logged in".

`$ID` is the issue number. Strip a leading `#` before use.

When the repo has several remotes, or `gh` picks the wrong one, add `--repo owner/name` to
every command. Put that value in `.agents/issue-tracker.md`.

## T1 — Fetch the issue

```bash
gh issue view "$ID" --json number,title,state,url,labels,assignees,closedByPullRequestsReferences,body,comments
```

One call returns everything the workflow needs, including T2 and the claim state. Do not
re-fetch.

If the command fails because the number is a pull request, `gh issue view` says so — stop.

## T2 — Detect existing work

Read `closedByPullRequestsReferences` from the T1 JSON. It is populated by closing keywords
(`Closes #N`) and by manual issue-to-PR links, which is exactly how this workflow opens PRs,
so it reliably catches a previous run.

The field carries only `number` and `url`. Resolve each PR's state:

```bash
gh pr view "$PR_NUMBER" --json number,state,isDraft,url,title,headRefName
```

Secondary, weaker check — PRs that mention the issue without a closing keyword, so they never
appear in the field above:

```bash
gh pr list --state open --search "$ID in:body" --json number,title,url,headRefName
```

A bare `#N` mention is weaker evidence than a real link. Surface it and confirm; do not stop
outright.

## T3 — Claim the issue

Read `assignees` from the T1 JSON.

- Empty, or already contains you:
  ```bash
  gh issue edit "$ID" --add-assignee @me
  ```
- Assigned to someone else: do not assign yourself. Surface it and ask.

## T4 — Branch id

The issue number, unchanged: `123`.

## T5 — Close reference

`Closes #<number>` in the pull request body. GitHub closes the issue on merge. No follow-up
command.

## T6 — Create an issue

Inputs: a title, a body, labels, and optionally a parent issue. Write the body to a file
first, so quoting cannot mangle it. Create each label first: `gh issue create` rejects a label
the repo does not have.

```bash
gh label create "$LABEL" 2>/dev/null || true   # once per label; fails harmlessly if it exists
gh issue create --title "$TITLE" --body-file "$BODY_FILE" --label "$LABELS" [--parent "$PARENT"]
```

`$LABELS` is comma-separated. `--parent` files the new issue as a native sub-issue; if
`gh issue create --help` lists no `--parent`, or the server rejects it, put the line
`Parent: #$PARENT` in the body instead. The command prints the new issue's URL; its last path
segment is the number.

## T7 — Link blocking

`$BLOCKER` blocks `$ID`, both already filed:

```bash
gh issue edit "$ID" --add-blocked-by "$BLOCKER"
```

GitHub then shows the link on both issues. If `gh issue edit --help` lists no
`--add-blocked-by` (an older `gh`), or the command fails (a GitHub Enterprise Server without
issue dependencies), append the line `Blocked by #$BLOCKER` to the body of `$ID` instead —
read it with `gh issue view "$ID" --json body -q .body`, write it back with
`gh issue edit "$ID" --body-file` — and say that the link is text only.
