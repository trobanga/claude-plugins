---
name: writing-great-skills
description: Reference for writing, editing and reviewing skills well — the vocabulary, principles and checklist that make a skill predictable.
disable-model-invocation: true
---

A skill exists to wrangle determinism out of a stochastic system. **Predictability** — the agent taking the same _process_ every run, not producing the same output — is the root virtue; every lever below serves it.

Bold terms are defined in [`GLOSSARY.md`](GLOSSARY.md); look them up there for the full meaning. [`CHECKLIST.md`](CHECKLIST.md) turns these rules, plus the platform's hard limits, into checks; read it whenever you review a skill or finish writing one. A skill you write is done when the review below finds no fail.

## Reviewing a skill

When the user asks you to review, audit or check a skill:

1. Read `SKILL.md` and every file it points at, in full.
2. Run `python3 ${CLAUDE_SKILL_DIR}/scripts/check_skill.py <skill-folder>`. It answers the items marked _(script)_ in the checklist; each `FAIL` line is a fail verdict.
3. Answer every other item of [`CHECKLIST.md`](CHECKLIST.md) against the skill. Done when each item has a verdict — pass, fail with `file:line`, or not applicable with the reason — and each fail has a concrete fix.
4. If the user reports a misbehaviour, map it to a _failure mode_ below and read that entry in `GLOSSARY.md` for its cure. Done when each reported misbehaviour has a named failure mode and the lever that cures it.

## Invocation

Three states, trading different costs:

- A **model-invoked** skill (the default) keeps its **description** in the agent's context, so the agent can fire it autonomously _and_ other skills can reach it (you can still type its name too). It contributes to **context load** — the description sits in the window every turn. Mechanics: write a model-facing description (see below).
- A **user-invoked** skill holds its description out of the agent's context: only you, typing its name, can invoke it — and no other skill can. Zero context load, but it spends **cognitive load**: _you_ must remember it exists. Mechanics: set `disable-model-invocation: true`; the `description` becomes human-facing — a one-line summary for the `/` menu.
- A model-only skill is model-invoked with your reach removed: set `user-invocable: false` to hide it from the `/` menu. Use it for a skill that only the agent or other skills should fire.

Pick model-invocation only when the agent must reach the skill on its own, or another skill must. If it only ever fires by hand, make it user-invoked and pay no context load.

When user-invoked skills multiply past what you can remember, that piled-up cognitive load is cured by a **router skill**: one user-invoked skill that names the others and when to reach for each.

## Writing the description

The agent picks a skill from its **description** alone — the body is not loaded until the skill fires. So a model-invoked description does two jobs: say _what_ the skill does, and list the **branches** that should trigger it. Every word increases **context load**, so a description earns even harder pruning than the body:

- _Open with what the skill does, front-loading its leading word_, in the third person: "Drafts one issue…", not "I can…" or "You can…". One clause; the body carries the rest.
- _One trigger per branch._ Synonyms that rename a single branch are **duplication** — "build features using TDD … asks for test-first development" is one branch written twice. Collapse them; keep only genuinely distinct branches.
- _Add a "when another skill needs…" reach clause_ if other skills must find it.

## Degrees of freedom

Match how tightly a passage constrains the agent to how fragile the work is — its **degree of freedom**:

- _High_ — prose heuristics, when many approaches are valid and context decides (a code review).
- _Medium_ — a template or pseudocode, when a preferred pattern exists but variation is fine.
- _Low_ — an exact script, when a step is fragile, its order matters, or its result must be identical every run.

A script is the strongest predictability lever there is: code does not sample. Move every deterministic operation — parsing, validation, fixed-shape API calls, file layout — into a bundled script. Make the script _solve, not defer_: it handles its own errors and justifies its constants, instead of failing and leaving the agent to improvise. At each pointer, say whether the agent should _run_ the script (only its output enters context) or _read_ it as reference.

## Information hierarchy

A skill is built from two content types — **steps** and **reference** — that mix freely: a skill can be all steps, all reference, or both. The core decision is which to use and where each sits on the **information hierarchy**, a ladder ranked by how immediately the agent needs the material:

1. _In-skill step_ — an ordered action in `SKILL.md`, the primary tier: what the agent does, in order. Each step ends on a **completion criterion**, the condition that tells the agent the work is done. Make it _checkable_ (can the agent tell done from not-done?) and, where it matters, _exhaustive_ ("every modified model accounted for", not "produce a change list") — a vague criterion invites **premature completion**. The most checkable criterion is one a script checks: run the validator, fix, repeat until it passes.
2. _In-skill reference_ — a definition, rule, or fact in `SKILL.md`, consulted on demand. Often a legitimately flat peer-set (every rule of a review on one rung) — a fine arrangement, not a smell.
3. _Disclosed reference_ — reference pushed out of `SKILL.md` into a sibling file, reached by a **context pointer**, loaded only when the pointer fires. Fully **external reference** lives outside the skill system, where any skill can point at it.

A demanding completion criterion drives thorough **legwork** — the digging the agent does within the work — whether the skill has steps or not, since "every rule applied" binds flat reference just as "every step done" binds a sequence.

Push too little down and the top bloats; push too much and you hide material the agent actually needs. That tension is the whole decision.

**Progressive disclosure** is the move down the ladder — out of `SKILL.md` into a linked file — so the top stays legible. Mechanics: a linked `.md` file in the skill folder, named for what it holds (this skill discloses its full definitions to `GLOSSARY.md`). Point at every disclosed file directly from `SKILL.md` — one level deep — since the agent may only skim a file it reaches through another. Open any disclosed file over 100 lines with a table of contents, so a partial read still shows its whole scope.

Some skills are used in more than one way, and each distinct way is a **branch** — different runs reading and doing different parts of the skill. Branching is the cleanest disclosure test: inline what every branch needs, and push behind a pointer what only some branches reach. A **context pointer**'s _wording_, not its target, decides when and how reliably the agent reaches the material: if must-have material behind a pointer is missed, sharpen the wording first, and pull the material inline only if that fails. Watch the agent navigate: a file it reads on every run belongs inline; a file it never opens is either unneeded or behind a weak pointer.

Where the ladder decides _how far down_ a piece sits, **co-location** decides _what sits beside it_ once there: keep a concept's definition, rules, and caveats under one heading rather than scattered, so reading one part brings its neighbours with it.

## Steering

- _Prompt the positive_ — state the target behaviour, so the banned one is never named (**negation**). Keep a prohibition only as a hard guardrail you cannot phrase positively, and pair it with what to do instead.
- _Examples_ — where output quality depends on a style, give two or three input/output pairs; they carry format and level of detail more precisely than any description of them. Vary them, so the agent copies the pattern rather than one instance.
- _One default_ — name one approach and one escape hatch for the case where it fails ("use pdfplumber; for scanned PDFs, OCR with pytesseract"). A menu of equal options is variance written into the skill.
- _Templates_ — strict ("use exactly this structure") when something downstream parses the output; otherwise a default the agent may adapt.

## When to split

**Granularity** is how finely you divide skills, and each cut spends one of the two loads, so split only when the cut earns it. Two cuts:

- _By invocation_ — split off a **model-invoked** skill when you have a distinct **leading word** that should trigger it on its own, or another skill must reach it. You pay **context load** for the new always-loaded **description**, so that independent reach has to be worth it.
- _By sequence_ — split a run of **steps** when the steps still ahead (a step's **post-completion steps**) pull the agent into **premature completion** of the one in front of it and a sharper criterion or a progress list has not held it. Keeping them out of view encourages the agent to do more **legwork** on the current task. Hiding needs a real context boundary: a user-invoked hand-off, a subagent, or `context: fork` in the frontmatter.

## Pruning

Keep each meaning in a **single source of truth**: one authoritative place, so changing the behaviour is a one-place edit.

Keep `SKILL.md` under 500 lines — an outer bound, not a target; **sprawl** starts far below it.

Check every line for **relevance**: does it still bear on what the skill does? A line that names a date ("before August 2025, use the old API") is **sediment** you can see coming: state the current method, and move a legacy one that still matters into an "Old patterns" section.

Then hunt **no-ops** sentence by sentence, not just line by line: run the no-op test on each sentence in isolation, and when one fails, delete the whole sentence rather than trim words from it. Be aggressive — most prose that fails should go, not be rewritten.

## Leading words

A **leading word** is a compact concept already living in the model's pretraining that the agent thinks with while running the skill (e.g. _lesson_, _rubber duck_, _tracer bullets_). Repeated throughout the text, it accumulates a distributed definition and anchors a whole region of behaviour in the fewest tokens, by recruiting priors the model already holds.

It serves predictability twice. In the body it anchors _execution_: the agent reaches for the same behaviour every time the word appears. In the description it anchors _invocation_: when the same word lives in your prompts, docs, and code, the agent links that shared language to the skill and fires it more reliably.

Hunt for opportunities to refactor skills to use leading words. A triad spelled out at three sites (**duplication**), a description spending a sentence to gesture at one idea — each is a passage begging to _collapse_ into a single token. Examples include:

- "fast, deterministic, low-overhead" -> _tight_ — one quality restated across a phase — into a single pretrained word (a _tight_ loop).
- "a loop you believe in" -> _red_ — converts a fuzzy gate into a binary observable state (the loop goes _red_ on the bug, or it doesn't).

## Evaluation

Every line of a skill is a hypothesis about what the model does without it. **Evaluation** tests the hypotheses; build it before the skill grows:

1. Run representative tasks with no skill and record the specific failures — the **baseline**.
2. Write at least three scenarios that hit those failures, each with a query, input files, and expected behaviour you can grade a run against.
3. Write the least text that fixes the failures.
4. Run every scenario in a fresh agent — not the one that wrote the skill — with the skill loaded, and watch its navigation as well as its result. Done when every scenario beats the baseline on every model that will run the skill.

`/evaluate-skill` runs this loop with `claude plugin eval`, which gives every case a baseline arm and a delta; the eval cases live in the skill's `evals/` folder (this skill's own are in [`evals/`](evals/)).

The no-op verdict is per model: a line Opus obeys by default may be the line that keeps Haiku on track. Grade a skill dispatched to subagents against the subagents' model. To settle whether a line earns its place, **ablate** it: delete it, rerun the scenarios, and keep it only if a result gets worse. This skill is no exception — it earns its place only if skills written with it beat skills written without it.

## Failure modes

Diagnose a misbehaviour by its symptom; each failure mode's entry in [`GLOSSARY.md`](GLOSSARY.md) holds its cure, in the order to try it.

| Symptom | Failure mode |
|---|---|
| A step ends before its work is done | **Premature completion** |
| One meaning stated in two places, which drift apart | **Duplication** |
| Stale lines that nobody dares delete | **Sediment** |
| Too long, though every line is live and unique | **Sprawl** |
| A line the agent would obey without it (a weak word like _be thorough_) | **No-op** |
| A ban that makes the banned behaviour more likely | **Negation** |
