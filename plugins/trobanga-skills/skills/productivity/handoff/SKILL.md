---
name: handoff
description: Write the current conversation into a handoff document for another agent; with `bg`, also launch a background agent on it.
argument-hint: "[bg] [what the next session will focus on]"
disable-model-invocation: true
---

Write a handoff document so a fresh agent can continue the work. If the arguments start with `bg`, also launch a background agent on it (step 2). Treat the remaining arguments as what the next session will focus on, and tailor the document to it.

## 1. Write the document

Save it to `${TMPDIR:-/tmp}/handoff-<slug>.md`, outside the workspace, where `<slug>` is a few kebab-case words naming the work. Use exactly this structure, since the next agent parses it:

```markdown
# Handoff: <title>

## Goal
<what the work is for, and what done looks like>

## State
<what is finished, what is in progress, what is broken>

## Decisions
- <decision> — <reason>

## Open questions
- <question>

## Next steps
1. <first concrete action>

## Artifacts
- <path or URL> — <what it holds>

## Suggested skills
- <skill> — <when to invoke it>
```

Write `none` under a heading with nothing to say. List specs, plans, ADRs, issues, commits and diffs under Artifacts by path or URL instead of copying their content. Replace API keys, passwords and personally identifiable information with `<redacted>`.

Done when the file holds all seven headings and you have printed its absolute path.

## 2. Launch a background agent (`bg` only)

Run:

```bash
claude --bg --name "<descriptive name>" "Read <absolute path> and continue the work it describes."
```

Pass the file path as the prompt, never the document text: backticks and `$` in the text would expand in the shell. Make the name a few plain words (e.g. `--name "Fix login bug"`); it shows in the job list, session picker and terminal title. The agent starts in the current working directory, and `--bg` prints its id and returns at once.

Done when `claude agents --json` lists that id. Tell the user to manage the agent with `claude agents`.
