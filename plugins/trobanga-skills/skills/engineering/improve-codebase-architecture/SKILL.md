---
name: improve-codebase-architecture
description: Find deepening opportunities in a codebase, informed by the domain language in GLOSSARY.md and the decisions in docs/adr/. Use when the user wants to improve architecture, find refactoring opportunities, consolidate tightly-coupled modules, or make a codebase more testable and AI-navigable.
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities** — refactors that turn shallow modules into deep ones. The aim is testability and AI-navigability.

## Vocabulary

Read [LANGUAGE.md](LANGUAGE.md) before step 1 and use its terms exactly in every suggestion. The project's domain language names good seams; its ADRs record decisions not to re-litigate.

## Process

### 1. Explore

Read the project's domain glossary and any ADRs in the area you're touching first.

Then use the Agent tool with `subagent_type=Explore` to walk the codebase. Don't follow rigid heuristics — explore organically and note where you experience friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow** — interface nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their current interface?

Apply the **deletion test** to anything you suspect is shallow: would deleting it concentrate complexity, or just move it? A "yes, concentrates" is the signal you want.

Done when every module you suspect is shallow has a deletion-test verdict.

### 2. Present candidates

Present a numbered list of deepening opportunities. For each candidate:

- **Files** — which files/modules are involved
- **Problem** — why the current architecture is causing friction
- **Solution** — plain English description of what would change
- **Benefits** — explained in terms of locality and leverage, and also in how tests would improve

**Use GLOSSARY.md vocabulary for the domain, and [LANGUAGE.md](LANGUAGE.md) vocabulary for the architecture.** If `GLOSSARY.md` defines "Order," talk about "the Order intake module" — not "the FooBarHandler," and not "the Order service."

**ADR conflicts**: if a candidate contradicts an existing ADR, only surface it when the friction is real enough to warrant revisiting the ADR. Mark it clearly (e.g. _"contradicts ADR-0007 — but worth reopening because…"_). Don't list every theoretical refactor an ADR forbids.

Do NOT propose interfaces yet. Ask the user: "Which of these would you like to explore?"

Done when the user has picked a candidate.

### 3. Grilling loop

Once the user picks a candidate, drop into a grilling conversation. Walk the design tree with them — constraints, dependencies, the shape of the deepened module, what sits behind the seam, what tests survive.

When classifying the candidate's dependencies or planning its tests, read [DEEPENING.md](DEEPENING.md). When the user wants to explore alternative interfaces for the deepened module, follow [INTERFACE-DESIGN.md](INTERFACE-DESIGN.md).

Invoke `Skill(trobanga-skills:domain-modeling)`, which owns `GLOSSARY.md` and the ADRs, the moment one of these happens:

- **The deepened module is named after a concept not in `GLOSSARY.md`, or a fuzzy term gets sharpened** — record the term.
- **The user rejects the candidate with a load-bearing reason** — offer an ADR: _"Want me to record this as an ADR so future architecture reviews don't re-suggest it?"_ Offer it only when a future explorer would need the reason to avoid re-suggesting the candidate; skip ephemeral reasons ("not worth it right now") and self-evident ones. Then offer the remaining candidates from step 2.

Done when the user has agreed an interface for the deepened module.

### 4. Hand off

Summarise the agreed interface, its seam and adapters, and the `GLOSSARY.md` and ADR entries written in step 3. Offer `/to-spec` to turn it into a spec or `/to-tickets` to break it into tickets.

Done when the chosen candidate has an agreed interface, every `GLOSSARY.md` and ADR update from step 3 is written, and the offer is made.
