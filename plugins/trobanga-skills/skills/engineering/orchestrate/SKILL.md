---
name: orchestrate
description: Implement a locked spec by slicing it into vertical slices and deciding, per slice, whether to delegate to a subagent or build it in the main loop.
disable-model-invocation: true
---

You are the orchestrator for implementing a locked spec. The spec lives in the issue given as the argument (`bd show <id>`).

## Setup

1. Read the full spec. It is LOCKED — implement it as written. For the reasoning behind a decision, follow the spec's references (decision map, research docs); the spec itself does not re-argue anything.
2. Read the ADRs the spec touches and the project's domain glossary. Use its terms exactly.
3. If the issue is an epic, its children are the candidate slices. Read each child and decide whether it needs further slicing — slice further only when a child is too large to build and verify in one pass. If the issue is not an epic, cut the spec into vertical slices (for a backend: migration + endpoint + tests + docs per slice). File each new slice in the issue tracker and add dependencies onto the spec issue and between slices. Show the user the slice list before building.

Completion criterion for setup: every requirement in the spec is covered by exactly one filed slice. For a pre-sliced epic this is an audit: check the children against the spec for gaps and stale slices, and file or retire slices until the criterion holds.

## Own the call

You decide, per slice, whether to delegate or build it yourself. State the call and the reason in one line — this record is the point.

**Build it yourself** (main loop, `Skill(trobanga-skills:tdd)`) when the slice is small, depends on work still in flight, or needs context you have already built up. Expect this to be the common case: spec work is largely sequential, and one context beats the split for sequential work.

A single slice you could build yourself is still a delegation candidate when a cheaper model can do it. Weigh the saving against the cost of the handoff: writing the self-contained spec, the subagent re-reading the code, and your review of its diff. The saving wins only when the slice is large enough that its tokens dwarf the handoff. If in doubt, build it yourself.

**Delegate** when slices are genuinely independent and can run in parallel, when a slice is large and self-contained enough that a fresh context loses nothing, or when the slice needs far less model than the main loop is running on. Pick whichever subagent fits the slice — implementation, exploration, review, or a general agent. Name the agent, model, and effort in the one-line record of the call.

## Pick the model

Use the cheapest model and effort that gets the slice done. That is a fit judgement, not a floor: a mechanical slice goes to the cheapest tier at low effort, and a slice where a wrong design is expensive goes to the best model at the highest effort. Both are correct when they match the slice.

- Judge the cost per completed slice, not per request. A cheap model that needs fixup rounds and a takeover costs more than the next tier landing first time. Pick the cheapest tier you expect to land first time.
- Signals for a cheap tier: the spec pins the design, the change is local, the acceptance criteria are mechanical to check, and the tests already exist or are obvious.
- Signals for a top tier: the slice makes design choices, cuts across modules, touches auth or data integrity, or has failed once already.
- When a delegated slice fails a fixup round, escalate one tier before the next round. The two-round limit below still applies.

## Delegation rules

- Each delegation is a complete, self-contained spec: goal, exact files, constraints (the project's hard rules, plus the relevant spec sections pasted in — pasting controls scope and removes any dependency on tracker access), and acceptance criteria. Acceptance criteria are the whole verification instruction; the implementer checks its own work.
- Use `isolation: 'worktree'` only when two implementers mutate files at the same time.
- For fixups on a delivered slice, `SendMessage` the same agent — its context is the asset. If the slice is still wrong after two fixup rounds, take it back and build it in the main loop; a third round on the same agent context is throwing good tokens after bad.
- You integrate and review every diff yourself, in the main loop.

## Final check

Before closing the run, review the combined work. You may run the review yourself or delegate it to a subagent; state which, and why, in one line. Pick the checks that match the run's risk:

- `Skill(trobanga-skills:conformance-review)` — documented standards and spec compliance side by side; the spec axis is the default check for a locked-spec run.
- `Skill(code-review)` — correctness bugs and cleanups; pick the effort level to match the risk of the change. The two skills do not overlap: conformance-review owns the written references, code-review owns everything without one.
- `Skill(security-review)` — when the run touched auth, input handling, secrets, or anything network-facing.
- `Skill(simplify)` — optional polish pass; it applies its fixes, so run it before the final quality gates.
- `Skill(trobanga-skills:patch-coverage)` — when you want a coverage number for the branch before closing.

Fix what the review finds before closing.

## Closing

A slice is done when its tests pass, its docs edit has shipped, and its issue is closed. The run is done when every filed slice is done, the epic (or spec issue) is updated and closed, and the project's session-completion protocol has run (quality gates, commit, push).

End with a short run summary: what shipped (outcome per slice, deviations, open follow-ups) and how the run was orchestrated — per slice: main loop or delegated, and for delegations the agent, model, effort, and fixup rounds. The per-slice one-line decision records are the raw material; this is their roll-up. Post the summary as a comment on the epic (or spec issue) and show it to the user.
