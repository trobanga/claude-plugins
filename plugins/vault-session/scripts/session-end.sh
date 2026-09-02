#!/usr/bin/env bash
# SessionEnd hook: write a full session log (frontmatter, transcript pointer,
# git snapshot, files-touched-as-wikilinks). Spawn detached `claude -p` to
# generate the prose summary and append it to the log when ready.
# Reads JSON {session_id, transcript_path, cwd, reason, ...} on stdin.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

hook_init

REASON="$(hook_field reason)"
TRANSCRIPT="$(hook_field transcript_path)"

# `resume` = same conversation continuing, no new log. `clear` = real boundary.
case "$REASON" in
    resume) exit 0 ;;
esac

DATE="$(date +%F)"
TIME="$(date +%H%M)"

# --- Parse transcript for files & metadata ----------------------------------
CONDENSED="$(mktemp)"
META=""
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    META="$(python3 "$SCRIPT_DIR/../lib/parse_transcript.py" \
        "$TRANSCRIPT" "$CONDENSED" 2>/dev/null || true)"
fi

FIRST="$(printf '%s\n' "$META" | sed -n 's/^FIRST=//p')"
LAST="$(printf '%s\n' "$META" | sed -n 's/^LAST=//p')"
COUNT="$(printf '%s\n' "$META" | sed -n 's/^COUNT=//p')"
TOOLS="$(printf '%s\n' "$META" | sed -n 's/^TOOLS=//p')"
FILES_LIST="$(printf '%s\n' "$META" | sed -n 's/^FILE=//p')"

GIT_STATUS=""
GIT_LOG=""
if [ -d "$VAULT/.git" ]; then
    GIT_STATUS="$(cd "$VAULT" && git status --short 2>/dev/null || true)"
    GIT_LOG="$(cd "$VAULT" && git log --oneline -10 2>/dev/null || true)"
fi

# --- Sync write log file ----------------------------------------------------
LOG_PATH="$(
    {
        echo "End reason: \`${REASON:-other}\`"
        echo
        [ -n "$FIRST" ] && echo "First message: \`${FIRST}\`"
        [ -n "$LAST" ]  && echo "Last message: \`${LAST}\`"
        [ -n "$COUNT" ] && echo "Message count: ${COUNT}"
        [ -n "$TOOLS" ] && echo "Tool calls: ${TOOLS}"
        echo
        if [ -n "$TRANSCRIPT" ]; then
            echo "Transcript: \`${TRANSCRIPT}\`"
            echo
        fi
        if [ -n "$FILES_LIST" ]; then
            echo "## Files touched"
            echo
            while IFS= read -r f; do
                [ -z "$f" ] && continue
                echo "- $(path_to_wikilink "$f")"
            done <<<"$FILES_LIST"
            echo
        fi
        if [ -n "$GIT_STATUS" ]; then
            echo "## Working tree"
            echo
            echo '```'
            echo "$GIT_STATUS"
            echo '```'
            echo
        fi
        if [ -n "$GIT_LOG" ]; then
            echo "## Recent commits"
            echo
            echo '```'
            echo "$GIT_LOG"
            echo '```'
            echo
        fi
        echo "## Summary"
        echo
        echo "$PENDING_MARKER"
    } | write_session_stub "$HOOK_SID" "${REASON:-other}" "$DATE" "$TIME" "" ""
)"

# --- Background summary generation ------------------------------------------
# Skip if no tool calls (no real work) or claude unavailable.
if [ "${TOOLS:-0}" -gt 0 ] && [ -s "$CONDENSED" ] \
   && command -v claude >/dev/null 2>&1; then
    PROMPT="Summarize this Claude Code session transcript in markdown. Sections: ### What user asked, ### What was done, ### Decisions / open questions, ### Pending. Be concise (~250 words). Output markdown only, no preamble, no top-level heading."
    (
        export VAULT_SESSION_BG=1
        SUMMARY="$(claude -p --model haiku --no-session-persistence \
            --disable-slash-commands "$PROMPT" \
            < "$CONDENSED" 2>/dev/null || true)"
        rm -f "$CONDENSED"
        if [ -n "$SUMMARY" ]; then
            TMP="$(mktemp)"
            # Replace pending marker with real summary.
            awk -v marker="$PENDING_MARKER" -v repl="$SUMMARY" '
                $0 == marker { print repl; next }
                { print }
            ' "$LOG_PATH" > "$TMP" && mv "$TMP" "$LOG_PATH"
            # Flip status to active.
            sed -i 's/^status: draft$/status: active/' "$LOG_PATH"
        fi
    ) </dev/null >/dev/null 2>&1 &
    disown 2>/dev/null || true
else
    rm -f "$CONDENSED"
    # No bg job — replace pending marker with note.
    TMP="$(mktemp)"
    awk -v marker="$PENDING_MARKER" '
        $0 == marker { print "_No tool calls in this session — skipping LLM summary._"; next }
        { print }
    ' "$LOG_PATH" > "$TMP" && mv "$TMP" "$LOG_PATH"
fi
