---
name: orchestrate
description: Implement a locked spec by slicing it into vertical slices and deciding, per slice, whether to build it in the main loop or delegate it to a subagent, optionally merging the green pull requests.
disable-model-invocation: true
---

You are the orchestrator for implementing a locked spec. The spec lives in the issue given as the argument. Resolve the tracker and forge by reading `${CLAUDE_SKILL_DIR}/../implement/references/resolve-config.md`, then fetch the issue with its adapter's T1.

## Setup

1. Read the full spec. It is LOCKED — implement it as written. For the reasoning behind a decision, follow the spec's references (decision map, research docs); the spec itself does not re-argue anything.
2. Read the ADRs the spec touches and the project's domain glossary. Use its terms exactly.
3. If the issue is an epic, its children are the candidate slices. Read each child and decide whether it needs further slicing — slice further only when a child is too large to build and verify in one pass. If the issue is not an epic, cut the spec into vertical slices (for a backend: migration + endpoint + tests + docs per slice). File each new slice with operation T6 of `${CLAUDE_SKILL_DIR}/../implement/references/trackers/{TRACKER}.md`, the spec issue as its parent, and wire each dependency between slices with T7.
4. Get the plan approved before the first build. Show the slice list with, per slice, the call (see **Own the call**) and its one-line reason, then ask with `AskUserQuestion`:
   - whether to merge green pull requests, and with which method (`merge`, `squash`, `rebase`) — off unless the user says so, and only on a forge with F6;
   - whether to post the run summary on the epic at the end.

   This approval is the user's consent to each delegation in it. A delegation you add later needs its own yes.

Completion criterion for setup: every requirement in the spec is covered by exactly one filed slice, and the user approved the plan. For a pre-sliced epic this is an audit: check the children against the spec for gaps and stale slices, and file or retire slices until the criterion holds.

## Own the call

You decide, per slice, whether to delegate or build it yourself. State the call and the reason in one line — this record is the point.

**Build it yourself** (main loop, `Skill(trobanga-skills:tdd)`) when the slice is small, depends on work still in flight, or needs context you have already built up. Expect this to be the common case: spec work is largely sequential, and one context beats the split for sequential work.

A single slice you could build yourself is still a delegation candidate when a cheaper model can do it. Weigh the saving against the cost of the handoff: writing the brief, the subagent re-reading the code, and your review of its diff. The saving wins only when the slice is large enough that its tokens dwarf the handoff. If in doubt, build it yourself.

**Delegate** when slices are genuinely independent and can run in parallel, when a slice is large and self-contained enough that a fresh context loses nothing, or when the slice needs far less model than the main loop is running on. Two shapes:

- **A whole slice as its own pull request:** a `general-purpose` agent with `isolation: "worktree"` runs `Skill(trobanga-skills:implement)` with `<id> --delegated`. It claims, builds, reviews, pushes, opens the PR and waits for the checks; it does not merge.
- **Part of a slice you own:** a named agent — `trobanga-skills:tdd-implementer-<effort>` for a test-first build, `feature-dev:code-explorer` or `feature-dev:code-reviewer` to read, `trobanga-skills:crap-agent` and `trobanga-skills:mutant-agent` for their steps. Their definitions carry the standing rules, so the brief carries only the scope.

Name the agent, model, and effort in the one-line record of the call.

## Pick the model

Use the cheapest model and effort that gets the slice done. That is a fit judgement, not a floor: a mechanical slice goes to the cheapest tier at low effort, and a slice where a wrong design is expensive goes to the best model at the highest effort. Both are correct when they match the slice.

- Judge the cost per completed slice, not per request. A cheap model that needs fixup rounds and a takeover costs more than the next tier landing first time. Pick the cheapest tier you expect to land first time.
- Signals for a cheap tier: the spec pins the design, the change is local, the acceptance criteria are mechanical to check, and the tests already exist or are obvious.
- Signals for a top tier: the slice makes design choices, cuts across modules, touches auth or data integrity, or has failed once already.
- When a delegated slice fails a fixup round, escalate one tier before the next round. The two-round limit below still applies.

## Briefs

Each brief is self-contained: goal, exact files, the project's hard rules, the relevant spec sections pasted in (pasting controls scope and removes any dependency on tracker access), the user decisions that bear on the slice, and acceptance criteria. Acceptance criteria are the whole verification instruction; the implementer checks its own work.

A brief adds context to a skill; it never overrides one. Do not tell a subagent to skip a step of a skill, to ignore or work around the user, or to turn off the sandbox or approvals. When a skill does not fit the slice as written, build the slice in the main loop. State environment needs as facts — "Postgres runs on localhost:5432; the sandbox blocks it" — and leave each command's handling to the subagent and its permission checks.

The auto-mode classifier reviews every delegation: the brief before the start, each action of the agent, and its final report. Briefs that override a skill's user checks were denied about half the time; plain briefs rarely are.

## Delegation rules

- Use `isolation: "worktree"` for every `/implement --delegated` agent, and for any other two agents that mutate files at the same time.
- For fixups on a delivered slice, `SendMessage` the same agent (a deferred tool: load it with `ToolSearch(query: "select:SendMessage")`) — its context is the asset. If the slice is still wrong after two fixup rounds, take it back and build it in the main loop; a third round on the same agent context is throwing good tokens after bad.
- You integrate and review every diff yourself, in the main loop.
- **If a delegation is denied**, do not rephrase the brief and launch it again: the classifier treats that as working around it. Build the slice in the main loop, or tell the user what was denied and let them start it again.

## Merge

Only when the user allowed it in setup step 4. Merge a slice's PR when its checks are green (F5), you reviewed its diff, and its head is the commit you reviewed. Merge with F6 of the forge adapter, in dependency order. After each merge, have every open PR that builds on it rebased onto the default branch and checked again before you merge it.

When a merge is blocked — a required review, a conflict, a red check — stop that slice and report it. Never pass `--admin` or weaken a check to get a merge through. Without merge permission, a green PR is done for this run, and the user merges.

## Final check

Before closing the run, review the combined work. You may run the review yourself or delegate it to a subagent; state which, and why, in one line. Pick the checks that match the run's risk:

- `Skill(trobanga-skills:conformance-review)` — documented standards and spec compliance side by side; the spec axis is the default check for a locked-spec run.
- `Skill(code-review)` — correctness bugs and cleanups; pick the effort level to match the risk of the change. The two skills do not overlap: conformance-review owns the written references, code-review owns everything without one.
- `Skill(security-review)` — when the run touched auth, input handling, secrets, or anything network-facing.
- `Skill(simplify)` — optional polish pass; it applies its fixes, so run it before the final quality gates.
- `Skill(trobanga-skills:patch-coverage)` — when you want a coverage number for the branch before closing.

Fix what the review finds before closing. When merge is on, run the final check before the last merge, so a finding still lands in a PR.

## Closing

A slice is done when its tests pass, its docs edit has shipped, and its PR is merged — or, without merge permission, green and handed to the user. Its issue closes through the T5 reference on merge. The run is done when every filed slice is done, the epic (or spec issue) is updated, and the project's session-completion protocol has run (quality gates, commit, push) for the work built in the main loop.

End with a short run summary: what shipped (outcome per slice, PR, deviations, open follow-ups) and how the run was orchestrated — per slice: main loop or delegated, and for delegations the agent, model, effort, fixup rounds, and any denial. The per-slice one-line decision records are the raw material; this is their roll-up. Show it to the user, and post it on the epic (or spec issue) only if the user said yes in setup.
