---
name: worktree-cleanup
description: Review and remove git worktrees left behind by finished issues, under .claude/worktrees/ and the legacy .worktrees/ location. Works with GitHub, Linear or beads. Reports issue state, PR state, local changes, and merge status per worktree before deleting anything. Use when the user asks to clean up worktrees, remove stale issue branches, or tidy up after merged PRs.
---

# Clean Up Issue Worktrees

**Goal:** Review and clean up worktrees in `.claude/worktrees/` (and the legacy `.worktrees/`
location) that are no longer needed.

This skill is the counterpart of `Skill(trobanga-skills:implement)`. The worktree location is
a shared contract; changing it here requires changing it there too.

**Steps:**

1. **Resolve the tracker, the forge and the branch format** by reading
   `${CLAUDE_SKILL_DIR}/../implement/references/resolve-config.md`. Then read the adapter
   files for the resolved axes:
   - `${CLAUDE_SKILL_DIR}/../implement/references/trackers/{TRACKER}.md` — you need **T1**
     (issue state) only
   - `${CLAUDE_SKILL_DIR}/../implement/references/forges/{FORGE}.md`

   If no rule there decides the tracker, do not ask and do not stop. Continue with git-level
   facts alone and report `Issue: unknown` for every worktree.

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

   b. **Extract the issue id** from the branch name. Run:
      ```bash
      python3 "${CLAUDE_SKILL_DIR}/../implement/scripts/branch_name.py" parse "{branch-name}" \
        --format "$BRANCH_FORMAT"
      ```
      It prints the id, or exits 1 when the branch carries none; report `Issue: unknown` then.
      For a Linear id, uppercase it again before querying the tracker: `giam-123` becomes
      `GIAM-123`.

   c. **Check the issue state** with the tracker's **T1**, and the PR state on the forge:
      ```bash
      gh pr list --head {branch-name} --state all --json number,state,mergedAt
      ```
      `state` is `OPEN`, `CLOSED` or `MERGED`. Skip the PR half when the forge is `none`.

   d. **Check whether the branch is merged into the default branch**:
      ```bash
      git merge-base --is-ancestor {branch-name} "origin/$DEFAULT_BRANCH" && echo merged || echo "not merged"
      ```
      A squash or rebase merge leaves the branch unmerged here; the PR state from c is the
      authority for those.

5. **Build a status report** for each worktree:
   ```
   ## Worktree: {branch-name}
   Path: {worktree-path} (note if legacy `.worktrees/` location)
   Issue: {id} - {state}          (or "unknown")
   PR: {pr-number} - {merged/open/closed/none}
   Local changes: {yes/no}
   Merged to default branch: {yes/no}
   Category: {safe to remove/keep/review first}
   ```

6. **Categorize each worktree** by the first rule that matches:
   1. Local changes → **review first**
   2. PR merged → **safe to remove**
   3. PR open, or issue open → **keep**
   4. Branch merged into the default branch → **safe to remove**
   5. Anything else (issue closed or unknown, nothing merged) → **review first**

7. **Present findings to the user** and ask which to clean up:
   - Show the categorized list
   - Use AskUserQuestion to let the user select which to remove
   - Offer "Remove all safe" as a convenient option

8. **For selected worktrees, clean up**:
   ```bash
   git worktree remove {worktree-path}
   ```
   - If the branch is merged, also delete it:
     ```bash
     git branch -d {branch-name}
     ```
     `-d` refuses a squash-merged branch; when its PR is merged, use `-D`.
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
