---
allowed-tools: Bash(c4ai show:*), Bash(c4ai tree:*)
argument-hint: [doc-id] [--path <dir>]
description: Show a specific c4ai document
---

## Your task

Run: `c4ai show $ARGUMENTS`

This displays a document's full content, including its frontmatter metadata, AI summary, and body.

If no arguments were provided, do not guess a document id. Run `c4ai tree` — it prints each document's `id:` alongside its title — and ask the user which document they want.

For anything beyond the document id, run `c4ai show --help` rather than assuming a flag exists.
