# trobanga-progress

A Claude Code mod: a progress bar above the prompt for the `implement` skill of
[trobanga-skills](../trobanga-skills), and a live panel of subagents.

- **Progress bar.** It shows the issue title, the current phase of `implement` and
  its position in the phase list (`setup`, `explore`, `design`, `implement`,
  `simplify`, `crap`, `mutants`, `review`, `ship`). The button with the crew size
  opens the panel. The bar appears when something calls the `progress` tool.
- **Agents panel** (`/agents-info` opens and closes it). It lists the running,
  finished and planned subagents with model, effort, step progress, context,
  estimated cost and time. Each agent of trobanga-skills has its own color, a crab
  costume on the desktop and a glyph in the terminal:

  | Agent | Costume | Glyph |
  | --- | --- | --- |
  | `tdd-implementer-low` | racer | `◆` green |
  | `tdd-implementer-medium` | chef | `◆` blue |
  | `tdd-implementer-high` | engineer | `◆` amber |
  | `crap-agent` | detective | `◈` orange |
  | `mutant-agent` | astronaut | `✱` violet |
  | `Explore`, `code-explorer` | pirate | `◎` teal |

  Other agents get the plain crab and a grey `▣`. Grey is kept for the context
  bar, so a role's own progress bar never looks like it. `prefers-reduced-motion`
  stops the animations.

## Tools it adds

- `mcp__trobanga-progress__progress`: the main session reports the title, the
  phase, the planned agents and the end of the flow.
- `mcp__trobanga-progress__step`: a subagent reports its own steps (`done`,
  `total`, `note`). A subagent that does not report shows its context fill in
  grey instead.

Both tools are deferred: a model loads them with `ToolSearch` first.

Cost is a rough estimate from token counts and a built-in price table (`PRICES` in
`hooks/register.tsx`), not a bill.

## Input limits

Tool input comes from the model, so the mod checks it. A field of the wrong
type is ignored. Titles are cut at 80 characters, notes at 60, the task list at
30 entries and step counts at 100. Agent types are looked up in a `Map`, so a
type such as `toString` cannot reach the prototype.

## Development

```
claude plugin validate plugins/trobanga-progress
claude plugin test plugins/trobanga-progress
claude --plugin-dir plugins/trobanga-progress
```

## Credits

Derived from `savvy-progress` 1.2.0 in
[johnnyvizz/claude-kit](https://github.com/johnnyvizz/claude-kit), MIT. The pixel
crab is Clawd from DockCrab.
