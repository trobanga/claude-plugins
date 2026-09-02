---
name: gh-issue
description: Work on a GitHub issue in a fresh git worktree based on the default branch. Claims the issue, creates the worktree, explores, designs, implements test-first, reviews, and opens a PR that closes the issue. Use when the user asks to start, pick up, or work on an issue by number ("work on #123", "take issue 45", "start on that issue").
allowed-tools: Bash, Read, Grep, Glob, Edit, Write, Agent, Skill, TodoWrite, AskUserQuestion, EnterPlanMode, ExitPlanMode, EnterWorktree, ExitWorktree
---

# Work on a GitHub Issue in a New Worktree

The issue number comes from the skill arguments. If the user gives no number, ask for one.
Remove a leading `#` before use.

## Phase 0 — Read the issue

Run this first. Do not continue until you have the JSON:

```bash
gh issue view "$NUMBER" --json number,title,state,url,labels,assignees,closedByPullRequestsReferences,body,comments
```

If the command errors instead of returning issue JSON, handle it per **Error Handling** below.
Otherwise use the JSON as the source of truth — do not re-fetch. Read the `comments` carefully:
requirements are frequently refined in discussion rather than in the original body.

---

## Phase 1 — Check for existing work, claim, set up the worktree

1. **Stop if the issue already has a pull request.** This runs *first* — before assigning,
   before creating anything. Check `closedByPullRequestsReferences` from the JSON above; it is
   populated by closing keywords (`Closes #N`) and manual issue↔PR links, which is exactly how
   this skill opens PRs, so it reliably catches a previous run.

   If it is non-empty, resolve each referenced PR's state (the field itself carries only
   `number`/`url`):
   ```bash
   gh pr view "$PR_NUMBER" --json number,state,isDraft,url,title,headRefName
   ```
   - **Any linked PR is `OPEN`** (draft included) — **stop.** Report the PR number, title, URL,
     and branch, and point the user at it. Do not assign, do not create a worktree, do not open
     a second PR. If they want to keep working on it, the existing branch is where that happens.
   - **All linked PRs are `MERGED` or `CLOSED`** — the work may have been reverted or the issue
     reopened. Report them and ask whether to start fresh work before continuing.

   As a secondary check for PRs that reference the issue without a closing keyword (so they
   never appear in `closedByPullRequestsReferences`):
   ```bash
   gh pr list --state open --search "$NUMBER in:body" --json number,title,url,headRefName
   ```
   Treat a hit as *likely* duplicate work: surface it and confirm before proceeding, rather
   than stopping outright — a bare `#N` mention is weaker evidence than a real link.

2. **Claim the issue.** Only once step 1 has cleared. Check the `assignees` field from the
   JSON above:
   - Empty, or already contains you — assign yourself and continue:
     ```bash
     gh issue edit "$NUMBER" --add-assignee @me
     ```
   - Assigned to someone else — do **not** assign yourself. Surface it and ask whether to
     proceed anyway, per **Error Handling**.

   Claim before creating the worktree, so the issue is visibly taken while work is in flight.

3. **Establish repo context:**
   ```bash
   git rev-parse --show-toplevel
   ```
   Store this as `MAIN_REPO`. Every command in Phase 1 runs from here.

4. **Determine the default branch** (do not assume `main`):
   ```bash
   DEFAULT_BRANCH="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null \
     || git symbolic-ref --quiet --short refs/remotes/origin/HEAD | sed 's|^origin/||')"
   DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
   git fetch origin "$DEFAULT_BRANCH"
   ```

5. **Derive the branch name** from the issue number and title:
   ```bash
   SLUG="$(printf '%s' "$TITLE" \
     | tr '[:upper:]' '[:lower:]' \
     | sed -E 's/[^a-z0-9]+/-/g; s/-+/-/g; s/^-//; s/-$//' \
     | cut -c1-40 | sed -E 's/-$//')"
   BRANCH="${NUMBER}${SLUG:+-$SLUG}"
   ```
   The leading `{number}-` is a hard requirement: `gh-issue-cleanup` parses it to
   match worktrees back to their issues. Do not change this format in isolation.

6. **Check whether this issue already has a worktree:**
   ```bash
   git worktree list --porcelain | grep -F "branch refs/heads/$BRANCH"
   ```
   If it exists, tell the user and ask whether to resume in it (skip to step 9) or start fresh.

7. **Create the worktree** off the freshly-fetched default branch. It must live under
   `.claude/worktrees/` — the harness pre-approves `EnterWorktree` for that directory only;
   any other location triggers a permission-root relocation prompt on every run:
   ```bash
   mkdir -p "$MAIN_REPO/.claude/worktrees"
   git worktree add -b "$BRANCH" ".claude/worktrees/$BRANCH" "origin/$DEFAULT_BRANCH"
   ```

8. **Carry local-only config into the worktree.** `.claude/` mixes tracked files (agents,
   commands, skills — these come across automatically) with untracked ones (`settings.json`,
   `settings.local.json`) that carry hooks and permissions. Only the untracked ones need copying:
   ```bash
   WORKTREE="$MAIN_REPO/.claude/worktrees/$BRANCH"
   mkdir -p "$WORKTREE/.claude"
   for f in settings.json settings.local.json; do
     if [ -f "$MAIN_REPO/.claude/$f" ] && ! git ls-files --error-unmatch "$MAIN_REPO/.claude/$f" >/dev/null 2>&1; then
       cp "$MAIN_REPO/.claude/$f" "$WORKTREE/.claude/$f"
       echo "Copied .claude/$f"
     fi
   done
   ```
   Then check whether `.claude/worktrees/` is ignored:
   ```bash
   git check-ignore -q .claude/worktrees/ && echo ignored || echo "NOT ignored"
   ```
   If not ignored, offer to add it to `.git/info/exclude` (local-only, leaves the repo clean).
   Only edit the tracked `.gitignore` if the user asks for it to be shared.

9. **Enter the worktree** so the session's working directory moves with the work:
   ```
   EnterWorktree(path: "<absolute path to .claude/worktrees/$BRANCH>")
   ```
   This is required, not cosmetic — it makes every later `git` call run in the worktree's own
   cwd. Passing `-C` or `cd`-ing instead triggers git's bare-repo sandbox protection and
   prompts on every command. The path must stay under `.claude/worktrees/`; other locations
   trigger a permission-root relocation prompt.

   Report the worktree path, branch, and base commit. Do **not** call `ExitWorktree` at the
   end; `gh-issue-cleanup` owns removal.

10. **Bootstrap the environment.** A fresh worktree has no build artifacts or local env files.
    Check what the project needs (`node_modules`, `target/`, `.env`, `.envrc`, `venv`) and
    install/copy as appropriate before assuming anything builds.

## Phase 2 — Understand and design

11. **Explore**, scaling the effort to the issue. A typo fix needs no agents; a feature does.
    For non-trivial issues, launch `feature-dev:code-explorer` agents in parallel to map:
    - Similar existing features and the patterns they follow
    - Architecture and abstractions the issue touches
    - Test layout and extension points

    Then read the key files they identify yourself — do not design off summaries alone.

12. **Design.** For issues with more than one plausible approach, launch 2–3
    `feature-dev:code-architect` agents in parallel, compare their blueprints, and form a
    single recommendation with the trade-offs made explicit.

13. **Resolve ambiguities.** If there are clarifying questions, unresolved ambiguities, or
    multiple viable approaches:
    - `EnterPlanMode` to present the plan and open questions
    - `AskUserQuestion` for anything selectable, so the user picks instead of typing
    - `ExitPlanMode` once approved

    Skip plan mode only when the issue has a single obvious approach and no open questions —
    state the plan in a sentence or two and continue.

## Phase 3 — Implement

14. **Implement test-first via `Skill(trobanga-skills:tdd)`.** Invoke it before writing any
    implementation code; it owns the red-green-refactor loop. Do not write the implementation
    and then backfill tests, and do not write all the tests up front — one failing test,
    minimal code to pass it, refactor, repeat.

    Follow the codebase's existing conventions over general best practice.

15. **Simplify** with `/simplify`, which reviews the changed code for reuse, simplification,
    and efficiency and applies the fixes. It does not hunt for bugs — step 16 does. It runs
    first so the review sees the final code.

16. **Review** the final diff. Launch `feature-dev:code-reviewer` agents in parallel, each
    with one focus:
    - Bugs and functional correctness
    - Project conventions and existing abstractions
    - Test coverage and edge cases

    Present findings; fix high-severity issues. Note that these agents are read-only — they
    report, you edit. This is the single full review pass of the workflow; its value comes
    from the reviewers' fresh context, so do not skip it just because the code looks done.

## Phase 4 — Ship

17. **Commit, push, open the PR** via `/commit-commands:commit-push-pr`, passing `--signoff`
    (required for all commits in this environment). The PR body must reference the issue so it
    auto-closes on merge: `Closes #{number}`.

    **Capture the PR number** from the output — the next steps need it.

18. **Assign the PR to yourself:**
    ```bash
    gh pr edit "$PR_NUMBER" --add-assignee @me
    ```
    If assignment fails (e.g. the PR was opened from a fork, where the author may not be
    assignable), report it and continue — it is not worth blocking the review on.

19. **Review the PR** with `/code-review:code-review <PR_NUMBER>` — **only for large or risky changes** (wide
    diffs, migrations, auth/security-relevant code, data handling). The full review already
    ran in step 16; for routine changes, skip this and finish. If it runs and finds
    high-severity issues, fix them:
    - Prefer new follow-up commits: review history stays readable and no rewrite is needed.
    - If you do amend or rebase already-pushed commits, force-push with `--force-with-lease`,
      never `--force`.
    - Re-request review after pushing fixes.

---

## Error Handling

- **`gh` missing or unauthenticated** — report it and stop. `gh auth status` distinguishes the
  two cases; installation instructions differ per platform.
- **Not a git repository** — stop; this skill has nothing to operate on.
- **Argument is a PR, not an issue** — `gh issue view` fails on PR numbers. Say so and stop.
- **Issue is already closed** — report its state and confirm before proceeding.
- **Issue has an open linked PR** — hard stop (step 1). Report the PR and exit without
  assigning, creating a worktree, or opening a second PR. One issue, one PR.
- **Issue has only merged/closed linked PRs** — report them and confirm before starting fresh
  work; the issue may have been reopened after a revert.
- **Issue assigned to someone else** — surface this before starting work, so the user does not
  duplicate effort. Do not add yourself as an assignee unless the user confirms.
- **`gh issue edit --add-assignee` fails** — usually a permissions issue (no write access to
  the repo). Report it and ask whether to continue unassigned rather than stopping outright.
- **Multiple remotes / ambiguous repo** — pass `--repo owner/name` explicitly to `gh`.
- **Branch already exists** — offer: resume on it, pick a different name, or delete the
  existing worktree first (`gh-issue-cleanup` handles removal safely).

## Notes

- Each issue gets an isolated environment based on a freshly-fetched default branch, leaving
  the main working directory untouched.
- Branch naming (`{number}-{slug}`) and worktree location (`.claude/worktrees/`) are a
  shared contract with `Skill(trobanga-skills:gh-issue-cleanup)`. Changing either here
  requires changing it there too. The location is also a harness contract: `EnterWorktree` is
  pre-approved only for paths under `.claude/worktrees/`.
- Both the issue and the PR end up assigned to you (`@me`), so in-flight work is visible on
  your GitHub dashboard without manual bookkeeping.
