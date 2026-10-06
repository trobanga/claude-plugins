#!/usr/bin/env python3
"""Print the evidence a reflection needs from Claude Code session logs.

Usage: session_digest.py [--last N] [SESSION]

SESSION is a .jsonl log, a session id, or a folder of logs. Without it, the
logs of the project in the current working directory are used. Without
--last, the digest covers one session: the named one, or the newest. With
--last N, it covers the N newest sessions, newest first.

For each session, the output lists the user's messages, the failed tool
calls, the tool calls per tool and the largest tool results. It skips
subagent (sidechain) entries and the messages the harness injects (hooks,
reminders), so what remains is what the user said and what the tools did.
"""

import argparse
import json
import os
import re
import sys
from collections import Counter
from pathlib import Path

USER_CHARS = 2000  # long enough for a full correction, short enough to skim
ERROR_CHARS = 200  # per end: a failed command shows its call first and its cause last
INPUT_CHARS = 160  # enough to see which file or command a call used
LARGEST = 10  # the expensive calls worth a look; the long tail is noise
TAIL_BYTES = 65536  # the end of a log always holds its last timestamped entry


def projects_dir() -> Path:
    base = os.environ.get("CLAUDE_CONFIG_DIR") or Path.home() / ".claude"
    return Path(base) / "projects"


def project_slug(cwd: str) -> str:
    # Claude Code names a project's log folder after its path, with every
    # character that is not a letter or a digit replaced by "-".
    return re.sub(r"[^A-Za-z0-9]", "-", cwd)


def last_activity(log: Path) -> str:
    """The last timestamp in the log; file times do not survive a copy."""
    with log.open("rb") as f:
        f.seek(max(0, log.stat().st_size - TAIL_BYTES))
        stamps = re.findall(rb'"timestamp"\s*:\s*"([^"]+)"', f.read())
    return stamps[-1].decode() if stamps else ""


def newest_first(folder: Path) -> list[Path]:
    logs = [p for p in folder.glob("*.jsonl") if p.is_file()]
    return sorted(logs, key=lambda p: (last_activity(p), p.stat().st_mtime), reverse=True)


def find_logs(arg: str | None, last: int | None) -> list[Path]:
    if arg and arg.endswith(".jsonl"):
        path = Path(arg).expanduser()
        if not path.is_file():
            sys.exit(f"No log at {path}. Pass an existing .jsonl path, a session id or a folder.")
        if last:
            sys.exit("--last needs a folder or no SESSION, not a single .jsonl file.")
        return [path]
    if arg and Path(arg).expanduser().is_dir():
        folder = Path(arg).expanduser()
    elif arg:
        hits = sorted(projects_dir().glob(f"*/{arg}.jsonl"))
        if not hits:
            sys.exit(f"No log for session id {arg} under {projects_dir()}. Pass the .jsonl path instead.")
        if last:
            sys.exit("--last needs a folder or no SESSION, not a session id.")
        return hits[:1]
    else:
        folder = projects_dir() / project_slug(os.getcwd())
    logs = newest_first(folder)
    if not logs:
        sys.exit(f"No logs in {folder}. Run from the project folder, or pass a folder or a .jsonl path.")
    return logs[: last or 1]


def text_of(content) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(
            b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text"
        )
    return ""


def clean_user_text(text: str) -> str | None:
    """Return what the user typed, or None for messages the harness wrote."""
    text = re.sub(r"<system-reminder>.*?</system-reminder>", "", text, flags=re.S)
    command = re.search(r"<command-name>(.*?)</command-name>", text, re.S)
    if command:
        args = re.search(r"<command-args>(.*?)</command-args>", text, re.S)
        return f"{command.group(1).strip()} {args.group(1).strip() if args else ''}".strip()
    if "<local-command-stdout>" in text or "<local-command-caveat>" in text:
        return None
    text = text.strip()
    return text or None


def short(value, limit: int) -> str:
    s = value if isinstance(value, str) else json.dumps(value, ensure_ascii=False)
    s = " ".join(s.split())
    return s if len(s) <= limit else s[: limit - 1] + "…"


def ends(text: str, limit: int) -> str:
    s = " ".join(text.split())
    return s if len(s) <= 2 * limit else f"{s[:limit]} … {s[-limit:]}"


def digest(path: Path, level: int, label: str = "") -> None:
    user_messages: list[str] = []
    calls: dict[str, tuple[str, str]] = {}
    per_tool: Counter = Counter()
    errors: list[tuple[str, str, str]] = []
    results: list[tuple[int, str, str]] = []
    compactions = 0

    with path.open(encoding="utf-8") as log:
        for line_no, line in enumerate(log, 1):
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                print(f"warning: {path.name} line {line_no} is not JSON; skipped", file=sys.stderr)
                continue
            if entry.get("isSidechain"):
                continue
            if entry.get("type") == "system" and entry.get("subtype") == "compact_boundary":
                compactions += 1
                continue
            message = entry.get("message")
            if not isinstance(message, dict):
                continue
            content = message.get("content")
            if entry.get("type") == "assistant" and isinstance(content, list):
                for block in content:
                    if isinstance(block, dict) and block.get("type") == "tool_use":
                        name = block.get("name", "?")
                        calls[block.get("id", "")] = (name, short(block.get("input", {}), INPUT_CHARS))
                        per_tool[name] += 1
            if entry.get("type") != "user":
                continue
            if isinstance(content, list) and any(
                isinstance(b, dict) and b.get("type") == "tool_result" for b in content
            ):
                for block in content:
                    if not (isinstance(block, dict) and block.get("type") == "tool_result"):
                        continue
                    name, call_input = calls.get(block.get("tool_use_id", ""), ("?", ""))
                    body = text_of(block.get("content"))
                    results.append((len(body), name, call_input))
                    if block.get("is_error"):
                        errors.append((name, call_input, ends(body, ERROR_CHARS)))
                continue
            if entry.get("isMeta") or entry.get("isCompactSummary"):
                continue
            typed = clean_user_text(text_of(content))
            if typed:
                user_messages.append(short(typed, USER_CHARS))

    print(f"{'#' * level} {label}Session {path.stem}\n")
    print(f"Log: {path}")
    print(f"Last activity: {last_activity(path) or 'unknown'}")
    print(f"Compactions: {compactions}\n")

    sub = "#" * (level + 1)
    print(f"{sub} User messages ({len(user_messages)})\n")
    for i, text in enumerate(user_messages, 1):
        print(f"U{i}. {text}\n")

    print(f"{sub} Failed tool calls ({len(errors)})\n")
    for name, call_input, body in errors:
        print(f"- {name} {call_input}\n  → {body}")
    print()

    print(f"{sub} Tool calls per tool\n")
    for name, count in per_tool.most_common():
        chars = sum(size for size, n, _ in results if n == name)
        print(f"- {name}: {count} calls, {chars} result chars")
    print()

    print(f"{sub} Largest tool results (top {LARGEST})\n")
    for size, name, call_input in sorted(results, reverse=True)[:LARGEST]:
        print(f"- {size} chars — {name} {call_input}")
    print()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("session", nargs="?", help="a .jsonl log, a session id, or a folder of logs")
    parser.add_argument("--last", type=int, metavar="N", help="digest the N newest sessions")
    args = parser.parse_args()
    if args.last is not None and args.last < 1:
        sys.exit("--last needs a positive number of sessions.")

    logs = find_logs(args.session, args.last)
    if len(logs) == 1:
        digest(logs[0], 1)
        return
    print(f"# Digest of the {len(logs)} newest sessions, newest first\n")
    for i, log in enumerate(logs, 1):
        digest(log, 2, f"S{i}. ")


if __name__ == "__main__":
    main()
