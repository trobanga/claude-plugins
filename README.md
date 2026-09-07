# trobanga marketplace

A [Claude Code](https://docs.claude.com/en/docs/claude-code) plugin marketplace.
It holds two plugins: a set of engineering and gamedev skills, and a
mutation-testing gate for pull requests.

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

## Hooks and safety

`pr-mutants` installs a **hook**. A hook is a shell script that Claude Code runs
on your machine at a given event. Read the script before you install the plugin:

- `plugins/pr-mutants/scripts/pre-pr-mutants.sh` — runs on every `Bash` tool
  call, and exits immediately unless the command contains `gh pr create`. Set
  `PR_MUTANTS_SKIP=1` to disable it.

`trobanga-skills` installs no hooks.

## Repository layout

```
.claude-plugin/marketplace.json     the marketplace manifest
plugins/<name>/.claude-plugin/      the plugin manifest
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
