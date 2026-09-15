---
name: worktree-cleanup
description: Review and remove git worktrees left behind by finished issues, under .claude/worktrees/ and the legacy .worktrees/ location. Works with GitHub, Linear or beads. Reports issue state, PR state, local changes, and merge status per worktree before deleting anything. Use when the user asks to clean up worktrees, remove stale issue branches, or tidy up after merged PRs.
---

# Clean Up Issue Worktrees

**Goal:** Review and clean up worktrees in `.claude/worktrees/` (and the legacy `.worktrees/`
location) that are no longer needed.

This skill is the counterpart of `Skill(trobanga-skills:implement)`. The branch format and the
worktree location are a shared contract; changing either here requires changing it there too.

**Steps:**

1. **Resolve the tracker, the forge and the branch format**, exactly as `implement` Phase 0
   does: `.agents/issue-tracker.local.md`, then `.agents/issue-tracker.md`, then `CLAUDE.md`
   prose, then detection. Read the adapter files for the resolved axes:
   - `../implement/references/trackers/{TRACKER}.md` — you need **T1** (issue state) only
   - `../implement/references/forges/{FORGE}.md`

   If the tracker cannot be resolved, do not stop. Continue with git-level facts alone and
   report `Issue: unknown` for every worktree. Local changes and merge status already decide
   most cases.

2. **Find the project root**, the default branch, and list all worktrees:
   ```bash
   git rev-parse --show-toplevel
   git worktree list
   ```
   Take the default branch from the forge adapter's **F1**.

3. **Identify managed worktrees**:
   - Filter for worktrees in `.claude/worktrees/`, or in the legacy `.worktrees/` directory
     (created by older versions of this workflow)
   - Extract the branch name for each
   - Mark legacy-location worktrees as such in the report

4. **For each worktree, gather status information**:

   a. **Check for uncommitted changes**:
      ```bash
      git -C {worktree-path} status --porcelain
      ```

   b. **Extract the issue id** from the branch name. Try these in order and stop at the first
      that matches:

      1. **The configured format** from step 1, if the config sets one.
      2. **`{id}--{slug}`** — split on the **last** `--`. The part before it is the id. This
         works for every tracker, including ids that contain `--` themselves (beads uses ids
         such as `gt--xyz`), because `implement` guarantees the slug never contains `--`.
      3. **Legacy numeric** — `^(issue-)?([0-9]+)(-|$)`, taking the digits. Covers branches
         created before the format change, and GitHub repos that keep `{id}-{slug}`.
      4. **No match** — report `Issue: unknown` and judge the worktree on the git facts alone.
         Do not guess an id.

      One combination is genuinely ambiguous: the format `{id}-{slug}` together with a
      non-numeric id, for example `bd-42-fix-login`. No parser resolves it. Fall through to
      case 4 for those.

      For a Linear id, uppercase it again before querying the tracker: `giam-123` becomes
      `GIAM-123`.

   c. **Check the issue state** with the tracker's **T1**, and the PR state on the forge:
      ```bash
      gh pr list --head {branch-name} --json number,state,merged
      ```
      Skip the PR half when the forge is `none`.

   d. **Check whether the branch is merged into the default branch**:
      ```bash
      git branch --merged "origin/$DEFAULT_BRANCH" | grep {branch-name}
      ```

5. **Build a status report** for each worktree:
   ```
   ## Worktree: {branch-name}
   Path: {worktree-path} (note if legacy `.worktrees/` location)
   Issue: {id} - {state}          (or "unknown")
   PR: {pr-number} - {merged/open/none}
   Local changes: {yes/no}
   Merged to default branch: {yes/no}
   Safe to remove: {yes/no/caution}
   ```

6. **Categorize worktrees**:
   - **Safe to remove**: PR merged (or branch merged, when there is no forge), no local changes
   - **Review first**: Issue closed but PR not merged, or has local changes
   - **Keep**: Issue still open, or has uncommitted work

   With an unknown issue, decide on the git facts: merged and clean is safe to remove;
   anything else is "review first".

7. **Present findings to the user** and ask which to clean up:
   - Show the categorized list
   - Use AskUserQuestion to let the user select which to remove
   - Offer "Remove all safe" as a convenient option

8. **For selected worktrees, clean up**:
   ```bash
   git worktree remove {worktree-path}
   ```
   - If the branch is fully merged, also delete it:
     ```bash
     git branch -d {branch-name}
     ```
   - If the branch has unmerged commits, warn before using `-D`

9. **Migrate kept legacy worktrees.** For each worktree that stays in the legacy `.worktrees/`
   location, offer to move it:
   ```bash
   mkdir -p "{main-repo}/.claude/worktrees"
   git worktree move "{main-repo}/.worktrees/{branch-name}" "{main-repo}/.claude/worktrees/{branch-name}"
   ```
   `implement` only enters worktrees under `.claude/worktrees/` without a permission prompt,
   so a resumed issue works only after this move. Remove `.worktrees/` if it becomes empty.

10. **Final summary**:
    - Report what was removed and what was moved
    - List any remaining worktrees

**Safety Measures:**
- Never force-remove worktrees with uncommitted changes without explicit confirmation
- Always show what will be deleted before doing it
- Preserve branches with unmerged work unless the user explicitly confirms deletion

**Edge Cases:**
- Worktree directory exists but the branch was deleted: `git worktree prune`
- Branch exists but the worktree was manually deleted: offer to recreate or delete the branch
- Branch name matching none of the patterns in step 4b: list separately, don't auto-categorize
