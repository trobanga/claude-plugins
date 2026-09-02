---
name: gauntlet-loop
description: Run a goal through builder/blind-critic rounds until every part beats a concrete reference bar.
disable-model-invocation: true
---

The **gauntlet**: builders make each part, fresh-context **blind** critics judge it side by side against a real **bar**, and losing parts go back in. Three rules hold everywhere:

- The critic is always a fresh agent — it never built the part and never saw an earlier draft. Self-grading defends old decisions; blindness is what makes the verdict real.
- The critic compares against the bar side by side and defaults to *lose*. A critic with nothing concrete to compare approves everything.
- The run ends on the **budget** or on victory — never on a round count.

## 1. Pin the bar and the budget

Elicit both from the user (AskUserQuestion) before any build:

- **Bar** — a concrete reference the critic can inspect next to the artifact: a named product, reference footage/screenshots, an existing file, or a spec with measurable criteria. "Make it polished" is not a bar; "indistinguishable from `reference/demo.png` at a glance" is.
- **Budget** — a token target or wall-clock ceiling for the whole run.

Done when: the bar names an inspectable reference, and the budget is a number.

## 2. Decompose

Split the goal into parts a critic can judge independently. Each part gets:

- a spec (what the builder makes),
- an inspection route (file path, command to run, screenshot to take) so the critic examines the *actual artifact*, not the builder's summary.

Done when: every part has a spec and an inspection route, and no part's verdict depends on another part being finished.

## 3. Author and run the workflow

Author a Workflow script from [`workflow-template.md`](workflow-template.md), filling in the parts, bar, and budget, then run it. The template already encodes the loop: build → blind judge → feed the *largest gap* (only that) back to a fresh build round, per part, until the part wins or the budget runs dry.

Done when: the workflow has returned a verdict for every part.

## 4. Report

For each part: won or lost, rounds taken, and — for losers — the last largest gap. State budget spent versus the ceiling. If parts lost on budget, say so plainly and offer another gauntlet run as the follow-up.

Done when: every part from step 2 is accounted for in the report.
