---
allowed-tools: Bash(c4ai context:*), Bash(c4ai tree:*)
argument-hint: [doc-id | --topic <topic>] [--depth <n>]
description: Load AI-optimized project context from c4ai documentation
---

## Your task

Run: `c4ai context $ARGUMENTS`

If no arguments were provided, don't invoke the command — it requires either a document id or a topic. Run `c4ai tree` — it prints each document's `id:` — to show what's available and ask the user which they want.

Output is optimized for AI consumption: frontmatter summaries first, then body. A document with a `source:` pointer emits a `Source:` line — read that file directly if you need implementation detail, since the context output deliberately does not inline it.

For flags controlling traversal depth, related-document following, or topic search, run `c4ai context --help`.
