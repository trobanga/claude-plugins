---
allowed-tools: Bash(c4ai list:*)
argument-hint: [path] [--layer <layer>]
description: List all c4ai documents
---

## Your task

Run: `c4ai list $ARGUMENTS`

With no arguments this lists every document in the current project, which is the common case — just run it.

If the user asked for a filtered view (by layer, for example), run `c4ai list --help` first to find the right flag rather than filtering the output yourself.
