# trobanga marketplace

A [Claude Code](https://docs.claude.com/en/docs/claude-code) plugin marketplace.
It holds four plugins: a documentation system, a set of engineering and gamedev
skills, a mutation-testing gate for pull requests, and an Obsidian vault session
logger.

## Install

Add the marketplace, then install the plugins you want:

```
/plugin marketplace add trobanga/claude-plugins
/plugin install trobanga-skills@trobanga
```

Claude Code reads the plugins from the default branch. To get updates, run
`/plugin marketplace update trobanga`.

## Plugins

| Plugin | Version | What it does |
| --- | --- | --- |
| [trobanga-skills](plugins/trobanga-skills) | 0.1.0 | 30+ skills: TDD, coverage, CRAP score, architecture review, Bevy, Godot, Unity, writing. |
| [pr-mutants](plugins/pr-mutants) | 0.1.0 | Runs `cargo-mutants` on the changed lines before `gh pr create` and blocks the PR while a mutant survives. |
| [vault-session](plugins/vault-session) | 0.1.0 | Writes a session log into an Obsidian vault on SessionEnd and loads recent logs on SessionStart. |

## Hooks and safety

`pr-mutants` and `vault-session` install **hooks**. A hook is a shell script
that Claude Code runs on your machine at a given event. Read the scripts before
you install these two plugins:

- `plugins/pr-mutants/scripts/pre-pr-mutants.sh` — runs on every `Bash` tool
  call, and exits immediately unless the command contains `gh pr create`.
- `plugins/vault-session/scripts/session-start.sh` and `session-end.sh` — run at
  the start and the end of a session, and exit immediately unless the working
  directory is inside your vault.

Both plugins can spawn `claude -p` in the background. Each plugin README lists
the environment variables that disable this.

`trobanga-skills` installs no hooks.

## Repository layout

```
.claude-plugin/marketplace.json     the marketplace manifest
plugins/<name>/.claude-plugin/      the plugin manifest
plugins/<name>/commands/            slash commands
plugins/<name>/skills/              skills
plugins/<name>/agents/              subagents
plugins/<name>/hooks/hooks.json     hook registration
plugins/<name>/scripts/             hook scripts
```

## Contributing

Open an issue or a pull request. When you change a plugin, bump the `version` in
both `plugins/<name>/.claude-plugin/plugin.json` and the matching entry in
`.claude-plugin/marketplace.json`. CI checks that the two agree.

## License

Apache-2.0. See [LICENSE](LICENSE).
