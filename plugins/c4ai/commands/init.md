---
allowed-tools: Bash(c4ai init:*), Bash(c4ai validate:*), Read, Write, Edit, Glob, Grep
description: Initialize c4ai documentation in a project
---

## Your task

Initialize c4ai documentation for the current project by scaffolding the structure and populating it with real project content.

### Step 1: Scaffold

Run `c4ai init` to create the initial directory structure.

If it fails because `docs/c4ai/` already exists, inform the user and stop.

### Step 2: Analyze the project

Gather project context by examining:
- README, CLAUDE.md, or similar top-level docs
- Build files (Cargo.toml, package.json, go.mod, pyproject.toml, etc.) for project name, description, and dependencies
- Source directory structure (top-level dirs, key entry points)
- Any existing architecture docs

### Step 3: Populate the overview

Rewrite `docs/c4ai/overview.md` with real content based on your analysis:
- **id**: Leave `overview` as-is. Every document needs a stable `id:` (see below).
- **title**: The actual project name
- **ai_summary**: A concise one-line description of what the project does
- **Purpose**: What the system does and who uses it
- **External Systems**: Any external dependencies or integrations
- **Key Decisions**: Notable architectural choices (language, framework, patterns)

### Step 4: Populate services/containers

Identify the main services, modules, or components of the project. For each one:
1. Rename the example service file (`docs/c4ai/services/example-service.md`) to match the first real service/module, or create additional files for each
2. Fill in real responsibilities, dependencies, and API surface
3. Remove the example service files if they were replaced

Use the C4 layer model:
- **Container** (L2): Deployable units, services, major modules → `docs/c4ai/services/<name>.md`
- **Component** (L3): Internal components within a container → `docs/c4ai/services/<name>/<component>.md`

Only create documentation for components you can identify from the code. Do not fabricate details — if something is unclear, leave a TODO placeholder.

**Give every document a stable `id:`.** The id is the document's identity and it must **not** encode the file's location: moving or renaming a file must never require editing another document. Ids are short slugs matching `[a-z0-9][a-z0-9._-]*` (max 64 chars) — `/` and `:` are illegal, precisely so an id can never be mistaken for, or "corrected" to match, a path. Derive it from the subject, e.g. `app`, `c4ai-core`, `request-handler`. `parent:` and `related:` reference these ids.

```yaml
---
id: request-handler
title: Request Handler
layer: component
parent: example-service
---
```

### Step 5: L4 (Code layer)

Source code docstrings are the source of truth for the Code layer — they don't rot the way hand-written L4 prose does. Default to pointing at them rather than restating them.

**The default: point an L3 component doc at its source file.**

When an L3 component doc has a clear primary source file, add a `source:` field to *that component doc's* frontmatter (path relative to project root). Optionally add `source_symbol:` to narrow to a single item.

```yaml
---
id: app
title: AppState
layer: component
parent: c4ai-gui
source: crates/c4ai-gui/src/app.rs
---
```

The GUI extracts the file's doc comments and renders each one as a synthesized L4 child node under the component. `c4ai context` emits the path so an agent knows where to read. `c4ai validate` errors if the path doesn't resolve.

**The exception: a hand-written `layer: code` doc.**

Create one only when the documentation must say something the code's docstrings cannot — a worked example, a rationale, a caveat that doesn't belong in a doc comment. This is a deliberate escape hatch, not the normal path.

```yaml
---
id: frontmatter
title: Frontmatter struct
layer: code
parent: document
ai_summary: YAML frontmatter fields and how they parse
source: crates/c4ai-core/src/frontmatter.rs
source_symbol: Frontmatter
---

[Source](../../../crates/c4ai-core/src/frontmatter.rs)
```

Two things differ on a `layer: code` doc:

- `source:` is a **plain pointer**. The GUI shows the docstrings in the detail pane and `validate` still checks the path, but no child nodes are synthesized — nesting L4 under L4 has nowhere to go.
- You must write your own `ai_summary:`. Component docs can fall back to the module-level docstring for their summary; Code docs can't, because that fallback rides on the same synthesis that's disabled here.

Supported source languages for the docstring viewer: Rust (`///`, `//!`), Python (`"""..."""`), TypeScript/JavaScript (`/** */`), Go (`// Doc` lines above declarations).

### Step 6: Populate `related:` (cross-document dependencies)

For each document you wrote in steps 3–5, set the `related:` frontmatter list to its outgoing dependencies on neighbouring documents. This drives the GUI's Focus view: an entry in `A.related: [B]` is rendered as a directed arrow `A → B`.

Rules:
- `related:` is **directed outgoing**. List things this document *uses, calls, depends on, or sends data to*. Do not list incoming references — the other side declares them.
- Targets are the `id:` values declared in each document's frontmatter, never paths. Any layer is allowed; cross-layer is fine.
- Use evidence: imports, function calls, schema references, message flows in code. If you cannot point to a concrete dependency, leave it empty.
- Do not list `parent:` again — the parent relationship is separate.
- Avoid `related:` from a doc to itself.

Example:

```yaml
related:
  - document
  - project
```

### Step 7: Clean up

- Remove any remaining example files that weren't replaced
- Ensure every document declares a unique `id:`, and that all `parent:`/`related:` references name those ids
- Ensure all `parent:` references in frontmatter are correct
- Run `c4ai validate` and fix any issues

### Output

Show the user a table of created files and their purpose. Include a brief educational insight about the C4 layering model as it applies to their specific project.
