# trobanga marketplace

A [Claude Code](https://docs.claude.com/en/docs/claude-code) plugin marketplace.
It holds one plugin: a set of engineering and gamedev skills.

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
| [trobanga-skills](plugins/trobanga-skills) | 0.1.0 | 30+ skills: TDD, coverage, CRAP score, mutation testing, architecture review, Bevy, Godot, Unity, writing. |

## Hooks and safety

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

## Credits

> "Good coders copy, great coders steal."
>
> — attributed to Pablo Picasso

Fourteen skills in `trobanga-skills` are derived from
[mattpocock/skills](https://github.com/mattpocock/skills) by Matt Pocock. Some
are close to the original, some are rewritten, all started there:

`claude-handoff`, `conformance-review`, `domain-modeling`, `grill-with-docs`,
`grilling`, `handoff`, `improve-codebase-architecture`, `prototype`, `research`,
`tdd`, `teach`, `to-spec`, `to-tickets`, `wayfinder`.

That work is MIT licensed. The notice is at
[LICENSES/mattpocock-skills-MIT.txt](LICENSES/mattpocock-skills-MIT.txt), and it
governs those skills. Everything else here is Apache-2.0.

`improve-codebase-architecture` also draws on "Design It Twice" from John
Ousterhout, *A Philosophy of Software Design*.

## License

Apache-2.0, except the skills credited above. See [LICENSE](LICENSE) and
[LICENSES/](LICENSES).
