# vault-session

Session logging into a Markdown vault (an Obsidian-style folder of linked `.md`
files). At the end of a Claude Code session the plugin writes a log note. At the
start of the next session it loads the recent notes as context.

The plugin only acts when the working directory is inside your vault. In every
other directory both hooks exit immediately.

## Requirements

- `bash`, `python3`, `git`.
- A vault directory. The default is `~/code/vault`. Logs go to `<vault>/logs/`.
- The `claude` command on `PATH`, for the background summaries.

## Install

```
/plugin marketplace add trobanga/claude-plugins
/plugin install vault-session@trobanga
```

## What the hooks do

**SessionEnd** (`scripts/session-end.sh`)

1. Exits when the reason is `resume`, because the conversation continues.
2. Parses the transcript for the files you touched and for the session metadata.
3. Writes `<vault>/logs/<date>-<time>-<short-session-id>.md` with frontmatter, a
   pointer to the transcript, a git snapshot, and the touched files as
   `[[wikilinks]]`.
4. Spawns a detached `claude -p` that writes the prose summary into the note
   later.

**SessionStart** (`scripts/session-start.sh`)

1. Finds the newest earlier transcript for this project.
2. Writes a log note for it if no note references that session. This covers a
   session that was killed, so SessionEnd never ran.
3. Prints a summary of the recent vault logs as additional context.

## Configuration

| Variable | Default | Effect |
| --- | --- | --- |
| `VAULT_DIR` | `~/code/vault` | The vault root. Logs go to `$VAULT_DIR/logs`. |
| `VAULT_SESSION_LLM_SUMMARY` | `1` | Set to `0` to stop the background `claude -p` summaries. |
| `VAULT_SESSION_BG` | unset | An internal marker. The hooks set it on the background call so they do not recurse. Do not set it yourself. |

## Privacy

The log notes hold your prompts, the files you touched, and a git snapshot. Keep
the vault private, or set `VAULT_SESSION_LLM_SUMMARY=0` and delete the notes you
do not want.

## License

Apache-2.0. See the [LICENSE](../../LICENSE) at the repository root.
