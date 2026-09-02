---
allowed-tools: Bash(c4ai *), Read, Write, Edit, Glob, Grep
description: Update c4ai documentation to reflect current project state
---

## Your task

Update existing c4ai documentation to reflect the current state of the project. This re-analyzes the codebase and brings docs in sync with reality.

### Step 1: Load current documentation

Run `c4ai tree` to see the current document hierarchy. Then read each document to understand what's already documented.

### Step 2: Analyze the project

Examine the current project state:
- Build files (Cargo.toml, package.json, go.mod, pyproject.toml, etc.)
- Source directory structure — look for new modules, renamed components, or removed code
- README and other top-level docs for changed descriptions or goals
- Git log (recent commits) for significant structural changes

### Step 3: Identify drift

Compare what the docs describe vs what the code actually contains. Look for:
- **Stale docs**: services/components that no longer exist in code
- **Missing docs**: new modules or services that have no documentation
- **Outdated content**: descriptions, dependencies, or APIs that have changed
- **Wrong hierarchy**: `parent:` ids that no longer make sense
- **Stale `related:` edges**: outgoing references that no longer reflect real code-level dependencies

### Step 4: Update documents

For each piece of drift found:
- **Stale docs**: Ask the user before removing. They may want to keep them with a deprecation note.
- **Missing docs**: Create new documents following the C4 layer model. Analyze the code to fill in real content (don't use placeholder templates).
- **Outdated content**: Update in place. Preserve any human-written prose that's still accurate — only change what's actually wrong.
- **Wrong hierarchy**: Fix the `parent:` id in frontmatter. `parent:` and `related:` name other documents' `id:` values, never paths — **never edit another document's references because a file moved**. A move changes nothing; that is what the `id:` field is for.
- **`related:` drift**: For each touched document, reconcile its `related:` list with real outgoing dependencies in the code. `related:` entries are the target documents' `id:` values and are **directed outgoing** (`A related: [B]` = arrow A → B); they may cross layers. Add new edges when imports/calls appeared; drop edges whose target no longer exists or is no longer used. Do not list `parent:` here; do not add reciprocal entries — let the other side declare its own outgoing edges.

### Step 5: Validate

Run `c4ai validate` and fix any issues.

### Output

Show the user a summary of changes:
- Documents added
- Documents updated (with brief description of what changed)
- Documents flagged for removal (if any)
- Any issues that need human decision
