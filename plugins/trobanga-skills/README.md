# trobanga-skills

A set of Claude Code skills for engineering work, game development, and writing,
plus one subagent. Claude loads a skill by itself when the task matches its
description. You can also call one by name, for example `/trobanga-skills:tdd`.

## Install

```
/plugin marketplace add trobanga/claude-plugins
/plugin install trobanga-skills@trobanga
```

The plugin installs no hooks.

## Engineering

| Skill | What it does |
| --- | --- |
| `tdd` | The red-green-refactor loop. One failing test, then the smallest code that passes it. |
| `patch-coverage` | Measures coverage of the branch diff with diff-cover. Java, Go, Rust, Elixir. Measures only. |
| `improve-coverage` | Raises patch coverage toward a target by writing real tests, file by file. |
| `crap-score` | Computes the CRAP score (complexity against coverage) of every changed function. Measures only. |
| `conformance-review` | Reviews a branch against the repo's coding standards and against the originating issue. |
| `improve-codebase-architecture` | Finds deepening opportunities, guided by `CONTEXT.md` and the ADRs. |
| `domain-modeling` | Pins down the ubiquitous language and records architectural decisions. |
| `c4-diff` | Draws before/after/diff C4 component diagrams in Mermaid between two commits. |
| `gh-issue` | Works a GitHub issue in a fresh worktree: claim, explore, design, test-first, PR. |
| `gh-issue-cleanup` | Removes worktrees left behind by finished issues, after it checks their state. |
| `orchestrate` | Slices a locked spec into vertical slices and decides per slice whether to delegate. |
| `wayfinder` | Maps work too large for one session as a set of decision tickets. |
| `to-spec` | Turns the current conversation into a spec and files it in the issue tracker. |
| `to-tickets` | Breaks a plan into tracer-bullet tickets. |
| `gauntlet-loop` | Runs a goal through builder and blind-critic rounds against a concrete bar. |
| `grill-with-docs` | Interviews you to sharpen a design, and writes ADRs and a glossary as it goes. |
| `prototype` | Builds a throwaway prototype to answer one design question. |
| `research` | Investigates a question against primary sources and writes the findings to a file. |
| `claude-handoff` | Hands the conversation to a fresh background agent. |
| `zoom-out` | Gives the broader context when the work has lost its frame. |

## Game development

| Skill | What it does |
| --- | --- |
| `bevy` | Bevy ECS architecture, system ordering, UI, build strategy, and common pitfalls. |
| `godot-best-practices` | Godot 4 GDScript standards: scenes, signals, resources, state machines, pooling, save systems. |
| `godot-development` | Scene creation, node management, and project structure in Godot. |
| `godot-gdscript-patterns` | GDScript patterns: signals, scenes, state machines, optimization. |
| `godot-ui` | Control nodes, themes, responsive layout, menus, HUDs, inventories, dialogue. |
| `unity-developer` | Unity 6 LTS, URP/HDRP, gameplay systems, and cross-platform builds. |

## Productivity and writing

| Skill | What it does |
| --- | --- |
| `grilling` | Stress-tests a plan or a decision with relentless questions. |
| `writing-great-skills` | The principles that make a skill load at the right time and act predictably. |
| `handoff` | Compacts the conversation into a handoff document. |
| `idea` | Captures an idea as a Markdown file that reads like a news article. |
| `ste` | Switches the session to ASD-STE100 Simplified Technical English. |
| `teach` | Teaches a concept inside this workspace, with a glossary and a learning record. |

## Design

| Skill | What it does |
| --- | --- |
| `refactoring-ui` | Audits and fixes visual hierarchy, spacing, color, and depth in web UIs. |

## Subagent

`crap-agent` computes the CRAP score of every changed function and then brings
each one below the threshold, by adding tests or by extracting functions. It
supports Java, Go, Rust, TypeScript, and Elixir.

## Requirements

Most skills need only `git`. These need more:

- `patch-coverage`, `improve-coverage`, `crap-score`: `python3`, `diff-cover`,
  and the coverage tool of the language (JaCoCo, `go test -cover`,
  `cargo-tarpaulin`, ExCoveralls).
- `gh-issue`, `gh-issue-cleanup`: the `gh` command line program.

## Credits

> "Good coders copy, great coders steal."
>
> — attributed to Pablo Picasso

These fourteen skills are derived from
[mattpocock/skills](https://github.com/mattpocock/skills) by Matt Pocock:

`claude-handoff`, `conformance-review`, `domain-modeling`, `grill-with-docs`,
`grilling`, `handoff`, `improve-codebase-architecture`, `prototype`, `research`,
`tdd`, `teach`, `to-spec`, `to-tickets`, `wayfinder`.

They stay under his MIT licence. See
[LICENSES/mattpocock-skills-MIT.txt](../../LICENSES/mattpocock-skills-MIT.txt).

`improve-codebase-architecture` also draws on "Design It Twice" from John
Ousterhout, *A Philosophy of Software Design*.

## License

The skills credited above are MIT, per their upstream licence. Everything else
is Apache-2.0. See the [LICENSE](../../LICENSE) at the repository root.
