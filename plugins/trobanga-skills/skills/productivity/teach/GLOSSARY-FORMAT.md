# GLOSSARY.md Format

`GLOSSARY.md` is the canonical language for this teaching workspace — the single, human-editable **source of truth**. All explainers, exercises, and learning records should adhere to its terminology. Building it is itself part of learning: compressing a concept into a tight definition is evidence the user understands it.

Two artifacts are **rendered from `GLOSSARY.md`** and regenerated whenever it changes (see "Rendering to `reference/`"):

- `reference/glossary.html` — the beautiful, print-friendly glossary reference doc, reachable from every page.
- `reference/glossary-terms.js` — the term bank that powers in-lesson tooltips.

`GLOSSARY.md` always wins: edit the source, then re-render. Never hand-patch the derived files in isolation — the next render overwrites them.

## Structure

```md
# {Topic} Glossary

{One or two sentence description of the topic this glossary covers.}

## Terms

**Hypertrophy**:
Muscle growth driven by mechanical tension and metabolic stress over repeated training sessions.
_Avoid_: Bulking, getting big

**Progressive overload**:
Systematically increasing the demand on a muscle over time — via load, volume, or intensity.
_Avoid_: Pushing harder, levelling up

**RPE (Rate of Perceived Exertion)**:
A 1–10 self-rating of how hard a set felt, where 10 is failure and 8 means two reps left in the tank.
_Avoid_: Effort score, intensity rating
```

## Rules

- **Add a term only when the user understands it.** The glossary is a record of compressed knowledge, not a dictionary the user reads to learn. If the user has just been introduced to a concept, wait until they can use it correctly before promoting it here.
- **Be opinionated.** When several words exist for the same concept, pick the best one and list the rest as aliases to avoid. This is how language compresses.
- **Anchor to what the learner knows (optional `_vs_:` line).** After a definition, an optional `_vs_:` line may carry a one-line analogy or contrast against a language/domain the learner already knows ("`_vs_`: ≈ the JVM in Clojure's stack — but built for millions of cheap actors"). Distinct from `_Avoid_:`, which lists aliases. Use whichever the term needs; both are optional.
- **Status is optional metadata.** A workspace may tag each term with course progress — e.g. `_(now)_` (covered in a lesson) / `_(soon)_` (coming up) — right after the term. Keep it consistent across the file if used.
- **Keep definitions tight.** One or two sentences. Define what the term IS, not what it does or how to do it.
- **Use the glossary's own terms inside definitions.** Once a term is in the glossary, prefer it everywhere — including inside other definitions. This is what makes complex terms easier to grasp later.
- **Group under subheadings** when natural clusters emerge (e.g. `## Anatomy`, `## Programming`). A flat list is fine when terms cohere.
- **Flag ambiguities explicitly.** If a term is used loosely in the wider field, note the resolution: "In this workspace, 'set' always means a working set — warm-ups are tracked separately."
- **Revise as understanding deepens.** A definition the user wrote in week one may be wrong by week six. Update in place; do not leave stale entries.

## Rendering to `reference/` (HTML + tooltips)

`GLOSSARY.md` is the source; the two files below are **rendered from it** and regenerated on every
change. Lessons **link every glossary term in their prose** to the HTML glossary with a hover tooltip
(see LESSON-FORMAT.md → "Glossary term tooltips"), which is what these two artifacts feed.

1. **`reference/glossary.html`** — the glossary as a beautiful, print-friendly reference doc, reachable
   from every page. Each term becomes a definition entry whose `<dt>` carries a stable kebab-case `id`
   derived from the term, so `glossary.html#id` lands on it: `<dt id="rpe">RPE …</dt>`. The markdown
   `**Term (Expansion)**:` / definition / `_Avoid_:` shape above maps to `<dt>` / `<dd>` / an aliases line.
2. **`reference/glossary-terms.js`** — the tooltip term bank the lessons load. One entry per linkable
   **surface**: `{ term, id, gloss }`, where `id` matches the `<dt>` anchor and `gloss` is a one-line
   summary (abbreviations spelled out; the full definition stays in the HTML). Copy
   `assets/glossary-terms.example.js` to start.

Choosing surfaces: matching is **case-sensitive, whole-word, longest-match**. Add a surface only if it's
distinctive enough not to false-match ordinary English — abbreviations (RPE, OTP) and proper/compound
terms are ideal; skip common words like "set" or "load". An abbreviation and its expansion (or a short
and a fully-qualified name) can be **two surfaces sharing one `id`**.

Keep it honest: a tiny test that asserts every `id` in `glossary-terms.js` resolves to a `<dt id>` in
`glossary.html` is cheap insurance against a dead tooltip link — regenerate both from `GLOSSARY.md` and
run it whenever the source changes.
