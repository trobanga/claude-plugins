---
name: pr
description: "Write a pull request body with three sections: Summary (a diagram or diff sketch), Evidence (before and after) and Merge Danger (door type and blast radius). Use when writing or editing a PR body, or before running `gh pr create`."
metadata:
  credits:
    skill: show-me
    author: Dex Horthy
    organisation: Humanlayer
    url: "https://github.com/humanlayer/skills/blob/main/plugins/show-me/skills/show-me/SKILL.md"
---

Use this template for writing the PR body:

```markdown
## Summary

<diagram, diff-sketch, or tree>

## Evidence

- **Before:** <screenshot/output/failing test run>
  **After:** <screenshot/output/passing test run>

## Merge Danger

**Door:** <one-way or two-way>

<optional: description>

**Blast Radius:** <one-word description>

<optional: potential ramifications of merge>
```

## Sections

Skip all preambles and keep prose brief. Use the project's domain language from `GLOSSARY.md` if the project has one.

If the PR is attached to an issue, the body must carry the tracker's close reference (for example `Closes #42`), so that merging the PR closes the issue.

### Summary

Pick the smallest view that makes the key point clear: pseudocode, a call tree, a component or file tree, a Mermaid diagram, or a `diff` of one of these. Read [`../show-me/SKILL.md`](../show-me/SKILL.md) for the views and when to use each. Write for the reviewer: keep only the calls, files, props, states and boundaries the change touches.

### Evidence

Concrete evidence that the change works. Show a before and after.

Screenshots are S-tier - when the environment is set up for it and the change is visual. `gh` cannot attach images to a PR body. If you have no way to upload an image, use execution-based evidence instead, and never write a placeholder for a missing screenshot.

Execution-based evidence is A-tier. Test results, console output. Name the exact test that failed before and passes now, and show what it checks as pseudocode.

### Merge Danger

Describe whether it's a one-way or two-way door. You can walk back through two-way doors, but not one-way doors. A PR that is cheap to roll back is lower risk. Changes that involve destructive actions or hard-to-reverse decisions are one-way doors.

The blast radius is the potential impact or scope of the changes introduced by this PR. Name it in one word on the **Blast Radius** line (for example `none`, `local`, `module`, `consumers`, `global`). Then list each concrete ramification you can find below it, for example layout shift, breakages for consumers, or mobile responsiveness.
