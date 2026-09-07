# c4ai

Layered project documentation for AI and humans, based on the
[C4 model](https://c4model.com/). The plugin gives Claude Code eight slash
commands that scaffold, read, validate and update a `docs/c4ai/` tree.

## Requirement

The commands call an external `c4ai` command line program, a Rust binary that is
not part of this plugin. Without it every command fails.

**The program is not published yet.** Until it is, this plugin only works on a
machine that already has `c4ai` on `PATH`. Check with:

```
c4ai --version
```

## Install

```
/plugin marketplace add trobanga/claude-plugins
/plugin install c4ai@trobanga
```

## Commands

| Command | What it does |
| --- | --- |
| `/c4ai:init` | Scaffolds `docs/c4ai/` and fills it from the real project. |
| `/c4ai:context` | Loads a focused slice of the documentation into the session. |
| `/c4ai:show` | Prints one document. |
| `/c4ai:list` | Lists all documents, filtered by layer. |
| `/c4ai:tree` | Prints the document hierarchy. |
| `/c4ai:diff` | Shows what changed architecturally between two git refs. |
| `/c4ai:update` | Rewrites the documentation to match the current code. |
| `/c4ai:validate` | Checks the documentation for broken links and missing layers. |

## Typical use

1. Run `/c4ai:init` once per project.
2. Run `/c4ai:context` at the start of a task, so Claude reads the architecture
   before it reads the code.
3. Run `/c4ai:update` after a change that moves a component boundary.
4. Run `/c4ai:validate` in CI.

## Hooks

None. The plugin adds commands only.

## License

Apache-2.0. See the [LICENSE](../../LICENSE) at the repository root.
