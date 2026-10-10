---
name: reflect
description: Review a session, the last N sessions, or (with `audit`) the steering files, and propose ranked changes to checks, pointers, memory and skills; apply only the ones the user approves.
argument-hint: "[audit | last N [log folder] | session id | .jsonl path]"
disable-model-invocation: true
---

Make the next session cheaper and safer than the last ones. Each change you propose is a **candidate**: one edit to the agent's environment, backed by evidence from the sessions or the code. Find the candidates, rank them, show them to the user, and apply only the ones the user approves.

Arguments: $ARGUMENTS. If they start with `audit`, follow the [audit branch](#audit-branch). If they start with `last N`, review the N newest sessions of the project, or of the log folder that follows. Otherwise review one session: the one the arguments name by id or path, or else the current one.

## Levers

Give each candidate the strongest **lever** that prevents its problem. Strongest first:

1. **Check** — a lint rule, a type rule, a test, a pre-commit hook or a CI job. Use it for every _mechanical_ mistake: a banned API or import, a fixed code pattern, a file-location rule, a format. A check fires on every run; a line of prose is read and can still be ignored. First find the repo's own checks: its `package.json` scripts, `Makefile`, `justfile`, `.pre-commit-config.yaml` and `.github/workflows/`. A check that exists but that no hook or CI job runs is a candidate, and so is a repo where nothing runs automatically.
2. **Tool** — a script, a log the agent can read, read-only access to a service. Use it when the agent lacked information, or spent many tool calls or a large output to get it.
3. **Pointer** — one line in a CLAUDE.md that names a file and when to read it. Use it when the agent searched long for something.
4. **Skill** — a new skill, or an edit to an existing one. Use it for a workflow that recurs across projects. Before you write a skill's text, read `${CLAUDE_SKILL_DIR}/../writing-great-skills/SKILL.md`; the skill is done when `python3 ${CLAUDE_SKILL_DIR}/../writing-great-skills/scripts/check_skill.py <skill folder>` prints no `FAIL`.
5. **Rule** — a line of prose in a steering file. Use it only for a judgement call or a preference that no check can enforce.
6. **Deletion** — remove a steering line, or move it to where it belongs. Use it for a line that is a no-op, stale, stated twice, in the wrong file, or now enforced by a check.

Every rule and pointer costs context in every future session; a deletion gives context back.

## Destinations

| Destination | What goes there |
|---|---|
| `~/.claude/CLAUDE.md` | The user's preferences and tool conventions that hold across projects |
| `CLAUDE.md` or `.claude/CLAUDE.md` at the repo root | Project conventions, pointers and gotchas shared with the team |
| `<dir>/CLAUDE.md` | Knowledge about one component; it loads only when the agent works in that folder |
| `.claude/rules/<topic>.md` with `paths:` globs in its frontmatter | A rule for one file type or area; it loads only when the agent reads, writes or edits a matching file |
| `CLAUDE.local.md` | Private notes that stay out of version control |
| The auto-memory folder, `~/.claude/projects/<slug>/memory/` | Facts about the user and the project; follow the memory format that the system prompt gives |
| The project's coding-standards document, if one exists | Judgement rules for review: the reviewer reads a small diff, the implementer already carries the whole task |
| A skill folder | A reusable workflow |

## Steps

1. **Read the sessions.** If you review only the current session and it has no compaction, your context holds it. Otherwise run `python3 ${CLAUDE_SKILL_DIR}/scripts/session_digest.py` and read its output: per session, the user's messages, the failed tool calls, the tool calls per tool and the largest tool results. Pass a session id or `.jsonl` path for one session, or `--last N [<log folder>]` for the N newest. Without a folder, it reads the logs of the project in the working directory. Done when you have read every user message of every session in scope, including those before a compaction.
2. **Read the steering files**: `~/.claude/CLAUDE.md`, every `CLAUDE.md` and `CLAUDE.local.md` from the working directory up to the repo root and in each folder the session touched, every file in `~/.claude/rules/` and the repo's `.claude/rules/`, the project's `MEMORY.md`, and the repo's checks (see **Check**). If a steering file has more than 200 lines, the length Claude Code's documentation names as the point where adherence drops, add a candidate: run this skill with `audit` on it. For `MEMORY.md` this candidate ranks first, because Claude Code loads only its first 200 lines (or 25 KB) and the rest is already lost. Done when you can tell, for any candidate, whether a file already covers it.
3. **Find the signals** in each session:
   - the user corrected code, an API, an assumption or the approach;
   - a mistake surfaced late, through a test, a failed command or a review;
   - a mistake got past a review, by `code-review`, `conformance-review` or a person; if no check can catch it, its rule goes to the coding-standards document, which the reviewer reads;
   - the agent searched long for a file, a command or a value;
   - a tool call was expensive: a large output, repeated reads, many calls for one fact;
   - the agent lacked information it needed;
   - the user stated a preference;
   - the same friction came back;
   - a steering line proved wrong, stale or ignored.

   Over several sessions, merge the signals that share a cause and count the sessions each one occurs in; a signal from an older session counts only if the current code and steering files have not fixed it since. Done when every signal has a candidate, or a reason why it gets none.
4. **Shape the candidates.** Give each one its lever, its destination and the exact change: the text to add or delete, or the check's configuration. Drop a candidate that a steering file or the repo already holds, that matters only to this session's task, or that git history records. Merge candidates with one cause. If none remains, tell the user that the sessions yield nothing worth persisting, and stop. Done when each candidate has a lever, a destination, an exact change and its evidence.
5. **Present** the candidates, most severe first. Severity is how much the problem costs, times how likely it comes back; a problem seen in several sessions has already come back. Use this form:

   ```
   C1  <lever> → <destination>
       Evidence: <what happened, with the user message or the tool call; over several sessions, which ones (S1, S3)>
       Change:   <exact text, diff or check configuration>
   ```

   Then ask the user which candidates to apply. Done when the user has answered; until then, change no file.
6. **Apply** the approved candidates. If a check needs more than a small edit of a configuration (a custom lint rule, a new CI job), offer to file it as an issue with `file-issue` instead. Done when each approved candidate is written or filed, and you have told the user the file or issue for each.

## Audit branch

With `audit`, there is no session: the steering files are under review. Skip step 1. In step 3, read every `CLAUDE.md`, `CLAUDE.local.md`, rules file and memory file of the project in full and check each line against the code. The signals are:

- a path, command or API that does not exist or has changed;
- a line stated twice, in one file or across files;
- a line in the wrong file, such as component knowledge in the root file;
- a mechanical rule that a check could enforce;
- a **no-op**: a line the agent obeys without it, such as "write clean code".

Done when every line of every steering file is either kept or a candidate. Then continue at step 4.
