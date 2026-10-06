# Checklist — Reviewing a Skill

The checkable form of [`writing-great-skills`](SKILL.md). Give every item a verdict: pass, fail with `file:line` and a concrete fix, or not applicable with the reason. Bold terms are defined in [`GLOSSARY.md`](GLOSSARY.md). `scripts/check_skill.py` answers the items marked _(script)_.

## Frontmatter

- [ ] _(script)_ `name` is at most 64 characters of lowercase letters, digits and hyphens, without "anthropic" or "claude".
- [ ] `name` follows the naming pattern of its sibling skills.
- [ ] _(script)_ `description` is non-empty, at most 1,024 characters, and holds no XML tags.
- [ ] The invocation state is deliberate: `disable-model-invocation: true` only if nothing but the human fires the skill; `user-invocable: false` only if nothing but the agent or other skills does.

## Description

- [ ] A model-invoked description opens with what the skill does, in the third person, front-loading the **leading word**.
- [ ] A model-invoked description lists one trigger per **branch**, with no synonyms for the same branch.
- [ ] A model-invoked skill that other skills must reach carries a "when another skill needs…" reach clause.
- [ ] A user-invoked description is a one-line summary for the human, with no trigger list.

## Information hierarchy

- [ ] _(script)_ The body of `SKILL.md` is under 500 lines.
- [ ] `SKILL.md` shows no **sprawl** below that bound.
- [ ] Every step ends on a **completion criterion** that is checkable and, where it matters, exhaustive.
- [ ] Reference that only some branches need sits behind a **context pointer**, not inline.
- [ ] _(script)_ Every file a pointer names exists: Markdown links, paths in backticks whose first folder is in the skill, and `${CLAUDE_SKILL_DIR}/` paths.
- [ ] _(script)_ Every disclosed file is linked directly from `SKILL.md` — one level deep.
- [ ] _(script)_ Every disclosed file over 100 lines opens with a table of contents.
- [ ] Each pointer's wording names the condition for following it.
- [ ] Each concept's definition, rules and caveats sit under one heading (**co-location**).
- [ ] File names say what the file holds (`form-validation-rules.md`, not `doc2.md`).
- [ ] _(script)_ Link paths use forward slashes.

## Steering

- [ ] The **degree of freedom** of each passage matches the fragility of its work.
- [ ] Each fragile or deterministic operation is a bundled script, and each pointer to a script says whether to run or to read it.
- [ ] Where output style matters, two or three varied input/output examples show it.
- [ ] Where several approaches exist, the skill names one default and one escape hatch.
- [ ] Each prohibition is a hard guardrail and is paired with the positive target (**negation**).
- [ ] Each thing has one name throughout the skill.

## Scripts

- [ ] Each script handles its own errors with messages that tell the agent how to fix the input.
- [ ] Each constant in a script carries the reason for its value.
- [ ] Every required package is named in the skill, and the skill tells the agent how to install it where the environment allows.
- [ ] MCP tools are named in full, as `Server:tool`.
- [ ] A batch, destructive or high-stakes operation runs plan → validate → execute, with the plan in a file a script validates.

## Pruning

- [ ] Each meaning has a **single source of truth**.
- [ ] No line depends on a date; legacy methods that still matter sit in an "Old patterns" section.
- [ ] Each sentence passes the **no-op** test on the model that runs the skill.
- [ ] Each restated triad or gesturing sentence has been tried as a single leading word.

## Evaluation

`/evaluate-skill` runs these; its results are the evidence.

- [ ] A **baseline** without the skill is recorded.
- [ ] At least three scenarios exist, each with a query, inputs and gradeable expected behaviour.
- [ ] Each scenario beats the baseline in a fresh agent on every model that will run the skill, including the model of any subagent it dispatches to.
- [ ] Each line kept on doubt has survived **ablation**.
