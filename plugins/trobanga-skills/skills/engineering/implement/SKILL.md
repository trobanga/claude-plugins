---
name: implement
description: Work on a tracked issue in a fresh git worktree based on the default branch. Claims the issue, creates the worktree, explores, designs, implements test-first, drives the CRAP score down, reviews, and opens a PR that closes the issue. Works with GitHub, Linear or beads. Use when the user asks to start, pick up, implement, or work on an issue ("work on #123", "implement GIAM-45", "take bd-12", "start on that issue").
---

# Implement a Tracked Issue in a New Worktree

The issue id comes from the skill arguments. If the user gives no id, ask for one.

This skill is tracker-agnostic. Everything tracker-specific lives in an **adapter** file that
you read in Phase 0. The phases below never name a tracker.

---

## Phase 0 — Resolve tracker, forge and branch format

Two independent axes:

- **TRACKER** — where the issue lives: `github`, `linear`, `beads`, `none`.
- **FORGE** — where the code and the pull request go: `github`, `git`, `none`.

They are frequently different. A repo hosted on GitHub may track its work in Linear.

Resolve each axis by the first rule that hits:

1. **Project config**, in this order. Stop at the first file that answers the axis:
   1. `.agents/issue-tracker.local.md` — an untracked, personal override. Present in a repo
      you do not control, or where the team did not want a shared file.
   2. `.agents/issue-tracker.md` — the shared answer. Holds both axes, the branch format,
      and any project-specific deviation from the adapters (a `--repo owner/name`, a team key,
      an id prefix, an extra required field).
   3. `CLAUDE.md`, which is already in your context. Read it but never write it: a project may
      state the tracker as prose, for example "Issue tracking: Linear, team general iam (issue
      keys `GIAM-123`)". That is project documentation written for humans, and it counts.
2. **The shape of the id.** A URL identifies both host and tracker. `ABC-123` is Linear or
   Jira. A bare number or `#123` narrows to a forge-native tracker. A beads prefix
   (`bd-42`, or the prefix in `.beads/`) is beads.
3. **Repo evidence.** A `.beads/` directory means beads. The host of
   `git remote get-url origin` gives the FORGE with high confidence, and the TRACKER with low
   confidence.
4. **Tool availability.** `gh auth status`, `bd version`, a configured `linear` MCP server.
   This describes the machine, not the project. Weakest signal.

If rules 3 or 4 decided it, state the guess in one line and continue. If no rule decided the
TRACKER, ask the user, and offer to persist the answer with
`Skill(trobanga-skills:setup-project)`.

**Branch format.** Default `{id}--{slug}`. The double separator is what lets
`worktree-cleanup` split a non-numeric id such as `giam-123` from its slug. A project may
override it in the config — for example `{id}-{slug}` for a repo whose existing branches use
that shape. The config always wins over the default.

**Read the two adapter files** for the resolved axes before Phase 1:

- `references/trackers/{TRACKER}.md`
- `references/forges/{FORGE}.md`

The tracker adapter defines five operations, referenced below as **T1**–**T5**:

| | Operation |
|---|---|
| T1 | Fetch the issue: title, body, state, discussion, assignee or status |
| T2 | Detect existing work: linked pull requests or branches |
| T3 | Claim the issue |
| T4 | Give the branch id: the identifier as it appears in a branch name |
| T5 | Close reference: the text or command that closes the issue when the work merges |

The forge adapter defines four, **F1**–**F4**:

| | Operation |
|---|---|
| F1 | Determine the default branch |
| F2 | Push the branch |
| F3 | Open the pull request, carrying T5 |
| F4 | Review the pull request |

> **Tools.** This skill declares no `allowed-tools`. A tracker reached over MCP (Linear) needs
> tool names that are not known when this file is written, and a closed list would block them.

---

## Phase 1 — Read the issue

Run **T1**. Do not continue until you have the issue. Use it as the source of truth and do not
re-fetch.

Read the discussion carefully. Requirements are frequently refined in comments rather than in
the original body.

If T1 errors, handle it per **Error Handling** below.

---

## Phase 2 — Check for existing work, claim, set up the worktree

1. **Stop if the issue already has a pull request.** This runs *first* — before claiming,
   before creating anything. Run **T2**.

   - **Any linked PR is open** (draft included) — **stop.** Report the PR number, title, URL
     and branch, and point the user at it. Do not claim, do not create a worktree, do not open
     a second PR. If they want to keep working on it, the existing branch is where that
     happens.
   - **All linked PRs are merged or closed** — the work may have been reverted or the issue
     reopened. Report them and ask whether to start fresh work before continuing.
   - **A weaker match** (a PR that mentions the id without a closing reference) — surface it
     and confirm before proceeding, rather than stopping outright.

2. **Claim the issue.** Only once step 1 has cleared. Run **T3**.

   If the issue is already claimed by someone else, do **not** claim it. Surface it and ask
   whether to proceed anyway.

   Claim before creating the worktree, so the issue is visibly taken while work is in flight.

3. **Establish repo context:**
   ```bash
   git rev-parse --show-toplevel
   ```
   Store this as `MAIN_REPO`. Every command in Phase 2 runs from here.

4. **Determine the default branch** with **F1**, then fetch it:
   ```bash
   git fetch origin "$DEFAULT_BRANCH"
   ```

5. **Derive the branch name** from the branch id (**T4**) and the issue title:
   ```bash
   SLUG="$(printf '%s' "$TITLE" \
     | tr '[:upper:]' '[:lower:]' \
     | sed -E 's/[^a-z0-9]+/-/g; s/-+/-/g; s/^-//; s/-$//' \
     | cut -c1-40 | sed -E 's/-$//')"
   ```
   The `s/-+/-/g` collapse is required: it guarantees the slug contains no `--`, so the
   **last** `--` in the branch name is always the separator. Split on the last one, not the
   first — some tracker ids contain `--` themselves (beads uses ids such as `gt--xyz`).

   Then apply the configured branch format:
   ```bash
   BRANCH="${BRANCH_ID}--${SLUG}"     # default format
   BRANCH="${BRANCH_ID}-${SLUG}"      # only when the config sets {id}-{slug}
   ```
   The format is a shared contract with `Skill(trobanga-skills:worktree-cleanup)`, which
   parses it back. Do not invent a third shape.

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
   `settings.local.json`) that carry hooks and permissions. Only the untracked ones need
   copying. `.mcp.json` is usually tracked, but copy it when it is not — a Linear tracker is
   unreachable from the worktree without it. The same holds for an untracked
   `.agents/issue-tracker.local.md`:
   ```bash
   WORKTREE="$MAIN_REPO/.claude/worktrees/$BRANCH"
   for f in .claude/settings.json .claude/settings.local.json .agents/issue-tracker.local.md .mcp.json; do
     if [ -f "$MAIN_REPO/$f" ] && ! git ls-files --error-unmatch "$MAIN_REPO/$f" >/dev/null 2>&1; then
       mkdir -p "$WORKTREE/$(dirname "$f")"
       cp "$MAIN_REPO/$f" "$WORKTREE/$f"
       echo "Copied $f"
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

   Report the worktree path, branch and base commit. Do **not** call `ExitWorktree` at the
   end; `worktree-cleanup` owns removal.

10. **Bootstrap the environment.** A fresh worktree has no build artifacts or local env files.
    Check what the project needs (`node_modules`, `target/`, `.env`, `.envrc`, `venv`) and
    install or copy as appropriate before assuming anything builds.

---

## Phase 3 — Understand and design

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

---

## Phase 4 — Implement

14. **Implement test-first via `Skill(trobanga-skills:tdd)`.** Invoke it before writing any
    implementation code; it owns the red-green-refactor loop. Do not write the implementation
    and then backfill tests, and do not write all the tests up front — one failing test,
    minimal code to pass it, refactor, repeat.

    Follow the codebase's existing conventions over general best practice.

15. **Simplify** with `/simplify`, which reviews the changed code for reuse, simplification
    and efficiency and applies the fixes. It does not hunt for bugs — step 17 does.

16. **Drive the CRAP score down** with the `trobanga-skills:crap-agent` agent. It measures
    every function changed against the default branch and brings each one below the threshold
    by adding tests or extracting functions.

    **This step is conditional.** The agent supports Java, Go, Rust, TypeScript, JavaScript
    and Elixir, and needs a working coverage build. Detect the language from the build file
    (`pom.xml`, `go.mod`, `Cargo.toml`, `mix.exs`, `package.json`). If none matches, or the
    coverage build fails, report one line — "CRAP step skipped: no supported build file" —
    and continue. Do not block shipping on it.

    It runs before the review, not after, so the reviewers see the tests it wrote and the
    functions it extracted.

17. **Review** the final diff. Launch `feature-dev:code-reviewer` agents in parallel, each
    with one focus:
    - Bugs and functional correctness
    - Project conventions and existing abstractions
    - Test coverage and edge cases

    Present findings; fix high-severity issues. These agents are read-only — they report, you
    edit. This is the single full review pass of the workflow; its value comes from the
    reviewers' fresh context, so do not skip it just because the code looks done.

---

## Phase 5 — Ship

> **One commit per pull request.** The branch carries exactly one commit. If an earlier phase
> (for example the TDD loop) made more than one, squash them into one before you push. Every
> later fix — from a reviewer agent, from **F4**, or from any other part of the workflow —
> amends that commit. Do not add a fix as an extra commit.

18. **Commit, push and open the pull request** per **F2** and **F3**, passing `--signoff`
    (required for all commits in this environment). The PR body must carry the **T5** close
    reference.

    When T5 is not a PR-body reference — a tracker that closes through its own API — open the
    PR with a plain reference to the issue id, and run the T5 command after the PR merges.
    Tell the user that closing is a separate step in that case.

    **Capture the PR number** from the output — the next steps need it.

19. **Assign the PR to yourself** per the forge adapter. If assignment fails (for example the
    PR was opened from a fork, where the author may not be assignable), report it and
    continue — it is not worth blocking the review on.

20. **Review the pull request** with **F4** — **only for large or risky changes** (wide diffs,
    migrations, auth or security-relevant code, data handling). The full review already ran in
    step 17; for routine changes, skip this and finish. If it runs and finds high-severity
    issues, fix them:
    - Amend the fix into the single commit with `git commit --amend --signoff`. Never add a
      follow-up commit.
    - Push with `--force-with-lease`, never `--force`.
    - Re-request review after pushing fixes.

---

## Error Handling

- **Tracker cannot be resolved** — ask the user, and offer `Skill(trobanga-skills:setup-project)`.
- **Tracker tool missing or unauthenticated** — report it and stop. The adapter names the
  check command for its tracker.
- **Not a git repository** — stop; this skill has nothing to operate on.
- **The id is a pull request, not an issue** — say so and stop.
- **Issue is already closed** — report its state and confirm before proceeding.
- **Issue has an open linked PR** — hard stop (Phase 2, step 1). Report the PR and exit
  without claiming, creating a worktree, or opening a second PR. One issue, one PR.
- **Issue has only merged or closed linked PRs** — report them and confirm before starting
  fresh work; the issue may have been reopened after a revert.
- **Issue claimed by someone else** — surface this before starting work, so the user does not
  duplicate effort. Do not claim it unless the user confirms.
- **Claiming fails** — usually a permissions problem. Report it and ask whether to continue
  unclaimed rather than stopping outright.
- **Multiple remotes or ambiguous repo** — the forge adapter names the explicit-repo flag.
- **Branch already exists** — offer: resume on it, pick a different name, or delete the
  existing worktree first (`worktree-cleanup` handles removal safely).

## Notes

- Each issue gets an isolated environment based on a freshly-fetched default branch, leaving
  the main working directory untouched.
- Branch format and worktree location (`.claude/worktrees/`) are a shared contract with
  `Skill(trobanga-skills:worktree-cleanup)`. Changing either here requires changing it there
  too. The location is also a harness contract: `EnterWorktree` is pre-approved only for paths
  under `.claude/worktrees/`.
- Both the issue and the PR end up claimed by you, so in-flight work is visible without manual
  bookkeeping.
- `Skill(trobanga-skills:gh-issue)` is a thin entry point that calls this skill with
  TRACKER `github` and FORGE `github`.
