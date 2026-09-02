---
allowed-tools: Bash(c4ai tree:*)
argument-hint: [path]
description: Display c4ai document hierarchy
---

## Your task

Run: `c4ai tree $ARGUMENTS`

With no arguments this reads the current project, which is the common case — just run it.

Each line ends with the document's `id:` — that is the handle `c4ai show` and `c4ai context` take, and it is not derivable from the file's location.

Documents are organized by their parent-child relationships following the C4 model hierarchy: Context -> Container -> Component -> Code. Code-layer entries may be synthesized from a component's `source:` file rather than backed by a markdown document.

For anything beyond an optional path, run `c4ai tree --help`.
