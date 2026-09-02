#!/usr/bin/env python3
"""Parse a Claude Code transcript JSONL.

Usage:
    parse_transcript.py <transcript.jsonl> <condensed_out.txt>

Writes a condensed transcript (USER / ASSISTANT / TOOL lines) to <condensed_out.txt>
and prints metadata to stdout in `KEY=value` form:

    FIRST=<iso timestamp of first message>
    LAST=<iso timestamp of last message>
    COUNT=<total messages>
    TOOLS=<tool_use block count>
    FILE=<path>          (zero or more lines, max 30, sorted)
"""

from __future__ import annotations

import datetime
import json
import sys


SHORT_LIMIT = 300
TOOL_DETAIL_LIMIT = 120
MAX_FILES = 30


def short(text: str | None, limit: int = SHORT_LIMIT) -> str:
    s = (text or "").strip().replace("\n", " ")
    return s if len(s) <= limit else s[:limit] + "..."


def fmt_ts(ts: str | None) -> str:
    if not ts:
        return ""
    try:
        dt = datetime.datetime.fromisoformat(ts.replace("Z", "+00:00"))
        return dt.strftime("%Y-%m-%d %H:%M:%S %z").strip()
    except Exception:
        return ts


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    src, out_path = sys.argv[1], sys.argv[2]

    first_ts: str | None = None
    last_ts: str | None = None
    n = 0
    n_tool = 0
    files: set[str] = set()
    condensed: list[str] = []

    with open(src, "r", encoding="utf-8") as fh:
        for raw in fh:
            line = raw.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue

            n += 1
            ts = obj.get("timestamp")
            if ts:
                if first_ts is None:
                    first_ts = ts
                last_ts = ts

            msg = obj.get("message") or {}
            if not isinstance(msg, dict):
                continue
            role = msg.get("role")
            content = msg.get("content")

            if role == "user" and isinstance(content, str):
                condensed.append(f"USER: {short(content)}")
                continue

            if not isinstance(content, list):
                continue

            for block in content:
                if not isinstance(block, dict):
                    continue
                btype = block.get("type")

                if btype == "text":
                    text = block.get("text", "")
                    if role == "assistant":
                        condensed.append(f"ASSISTANT: {short(text)}")
                    elif role == "user":
                        condensed.append(f"USER: {short(text)}")
                elif btype == "tool_use":
                    n_tool += 1
                    name = block.get("name", "?")
                    inp = block.get("input", {})
                    if not isinstance(inp, dict):
                        inp = {}
                    fp = (
                        inp.get("file_path")
                        or inp.get("path")
                        or inp.get("notebook_path")
                    )
                    if isinstance(fp, str):
                        files.add(fp)
                    detail = fp or inp.get("command") or ""
                    if isinstance(detail, str):
                        detail = short(detail, TOOL_DETAIL_LIMIT)
                    condensed.append(f"TOOL[{name}]: {detail}")

    with open(out_path, "w", encoding="utf-8") as out:
        out.write("\n".join(condensed))

    print(f"FIRST={fmt_ts(first_ts)}")
    print(f"LAST={fmt_ts(last_ts)}")
    print(f"COUNT={n}")
    print(f"TOOLS={n_tool}")
    for fp in sorted(files)[:MAX_FILES]:
        print(f"FILE={fp}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
