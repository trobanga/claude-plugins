---
allowed-tools: Bash(c4ai validate:*)
argument-hint: [path]
description: Validate c4ai documentation integrity
---

## Your task

Run: `c4ai validate $ARGUMENTS`

With no arguments this validates the current project, which is the common case — just run it.

Exit code 0 means no errors. Non-zero means issues were found; report them and offer to fix.

`c4ai validate --help` lists the integrity checks it performs, and is the authoritative list — don't restate it here.
