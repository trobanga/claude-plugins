---
name: pr
description: "Write a pull request body with three sections: Summary (one or two sentences, then a diagram or diff sketch), a section that shows the change running, with the kind of change as its heading (Bug Fix, New Behavior, Visual Change or Refactor) and, only when something can break, Risks. Use when writing or editing a PR body, or before running `gh pr create`."
license: MIT
metadata:
  credits:
    skill: show-me
    author: Dex Horthy
    organisation: HumanLayer
    url: "https://github.com/humanlayer/skills/blob/main/plugins/show-me/skills/show-me/SKILL.md"
---

Use this template for writing the PR body:

```markdown
## Summary

<one or two sentences: what the PR accomplishes>

<diagram, diff-sketch, or tree>

## <Bug Fix | New Behavior | Visual Change | Refactor>

<one real run that shows the outcome from the Summary: before and after for a fix, input and output for new behavior>

## Risks <!-- only if a trigger applies, see below -->

- <what can break> → <who notices> → <how to undo, if not `git revert`>
```

## Sections

Skip all preambles and keep prose brief. Use the project's domain language from `GLOSSARY.md` if the project has one.

If the PR is attached to an issue, the body must carry the tracker's close reference (for example `Closes #42`), so that merging the PR closes the issue.

### Summary

Start with one sentence, two at most, that says what the PR accomplishes: the outcome for the user or the system, not the list of changed files. A reviewer who reads only this sentence knows why the PR exists.

Then pick the smallest view that makes the key point clear: pseudocode, a call tree, a component or file tree, a Mermaid diagram, or a `diff` of one of these. Read [`../show-me/SKILL.md`](../show-me/SKILL.md) for the views and when to use each. Write for the reviewer: keep only the calls, files, props, states and boundaries the change touches.

### The run of the change

Show what the reviewer cannot see in the diff: the change working when it runs. CI already shows that the tests pass. Do not repeat it.

Use the kind of change as the heading, and show its content:

| Heading | Content |
|---|---|
| `## Bug Fix` | the wrong output before and the correct output after, from the same command or test |
| `## New Behavior` | one representative input and the output it now gives |
| `## Visual Change` | a screenshot before and after |
| `## Refactor` | the existing tests that cover the changed code, which the PR does not change |

The Summary already describes the change. Under this heading, show only the output, not a second description.

If a PR has two kinds, use the heading of the kind that the Summary names.

For New Behavior, use the real entry point (CLI, HTTP request, REPL) when one exists. If the code has no entry point yet, for example an internal slice of a larger feature, pick the one test that best shows the key behavior. Show its input and its expected output. Show one test, not the list.

`gh` cannot attach images to a PR body. If you have no way to upload an image, show the input and output as text, and never write a placeholder for a missing screenshot.

Paste real output, trimmed to the lines that matter, at most about ten lines. Do not paraphrase what a run showed. Do not add notes in a second column next to the output.

Leave out:

- lists of test names and counts of tests: the diff and CI show them
- coverage and mutation numbers, unless the PR exists to raise them
- a "before" that only says that the code did not exist yet

### Risks

Check the change against these triggers:

- a data or schema migration, or deleted data
- a removed or renamed public interface: API, CLI flag, config key, file format, event
- a deploy order dependency, for example "migrate first, then roll out"
- a change to auth, permissions or secrets
- a new or changed external dependency
- a hot path or a resource limit

If no trigger applies, leave out the whole section. Do not write "None".

If a trigger applies, write one line per risk: what can break, who notices, and how to undo it. Leave out the undo part when `git revert` is enough. A change that `git revert` cannot undo, such as dropped data, must say how to recover:

```text
Drops users.legacy_id → reporting jobs that read it fail → not revertible; restore from the backup taken before the migration
```
