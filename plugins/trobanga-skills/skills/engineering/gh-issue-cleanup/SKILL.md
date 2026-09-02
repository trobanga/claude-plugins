---
name: gh-issue-cleanup
description: Review and remove git worktrees left behind by finished GitHub issues, under .claude/worktrees/ and the legacy .worktrees/ location. Reports issue state, PR state, local changes, and merge status per worktree before deleting anything. Use when the user asks to clean up worktrees, remove stale issue branches, or tidy up after merged PRs.
allowed-tools: Bash, AskUserQuestion, TodoWrite
---

# Clean Up GitHub Issue Worktrees

**Goal:** Review and clean up worktrees in `.claude/worktrees/` (and the legacy `.worktrees/`
location) that are no longer needed.

**Steps:**

1. **Find the project root**, the default branch, and list all worktrees:
   ```bash
   git rev-parse --show-toplevel
   DEFAULT_BRANCH="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD | sed 's|^origin/||')"
   DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
   git worktree list
   ```

2. **Identify managed worktrees**:
   - Filter for worktrees located in `.claude/worktrees/`, or in the legacy `.worktrees/`
     directory (created by older versions of `gh-issue`)
   - Extract the branch name for each
   - Mark legacy-location worktrees as such in the report

3. **For each worktree, gather status information**:

   a. **Check for uncommitted changes**:
      ```bash
      git -C {worktree-path} status --porcelain
      ```

   b. **Extract issue number** from branch name. Accept two patterns:
      - current: `{number}-{slug}` (for example `721-normalize-auth-configuration`)
      - legacy: `issue-{number}-{slug}` (created by older versions of `gh-issue`)

      Match with `^(issue-)?([0-9]+)(-|$)` and take the digits as the issue number.

   c. **Check GitHub issue/PR status** (if issue number found):
      ```bash
      gh issue view {issue-number} --json state,stateReason
      gh pr list --head {branch-name} --json number,state,merged
      ```

   d. **Check if branch is merged into the default branch**:
      ```bash
      git branch --merged "origin/$DEFAULT_BRANCH" | grep {branch-name}
      ```

4. **Build a status report** for each worktree:
   ```
   ## Worktree: {branch-name}
   Path: {worktree-path} (note if legacy `.worktrees/` location)
   Issue: #{number} - {state}
   PR: #{pr-number} - {merged/open/none}
   Local changes: {yes/no}
   Merged to default branch: {yes/no}
   Safe to remove: {yes/no/caution}
   ```

5. **Categorize worktrees**:
   - **Safe to remove**: PR merged, no local changes
   - **Review first**: Issue closed but PR not merged, or has local changes
   - **Keep**: Issue still open, or has uncommitted work

6. **Present findings to user** and ask which to clean up:
   - Show the categorized list
   - Use AskUserQuestion to let user select which to remove
   - Offer "Remove all safe" as a convenient option

7. **For selected worktrees, clean up**:
   ```bash
   git worktree remove {worktree-path}
   ```
   - If branch is fully merged, also delete the branch:
     ```bash
     git branch -d {branch-name}
     ```
   - If branch has unmerged commits, warn before using `-D`

8. **Migrate kept legacy worktrees.** For each worktree that stays in the legacy
   `.worktrees/` location, offer to move it:
   ```bash
   mkdir -p "{main-repo}/.claude/worktrees"
   git worktree move "{main-repo}/.worktrees/{branch-name}" "{main-repo}/.claude/worktrees/{branch-name}"
   ```
   `gh-issue` only enters worktrees under `.claude/worktrees/` without a permission prompt,
   so a resumed issue works only after this move. Remove `.worktrees/` if it becomes empty.

9. **Final summary**:
   - Report what was removed and what was moved
   - List any remaining worktrees

**Safety Measures:**
- Never force-remove worktrees with uncommitted changes without explicit confirmation
- Always show what will be deleted before doing it
- Preserve branches with unmerged work unless user explicitly confirms deletion

**Edge Cases:**
- Worktree directory exists but branch was deleted: `git worktree prune`
- Branch exists but worktree was manually deleted: offer to recreate or delete branch
- Worktrees not matching `^(issue-)?[0-9]+(-|$)`: list separately, don't auto-categorize
