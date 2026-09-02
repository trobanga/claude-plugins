#!/usr/bin/env bash
# SessionStart hook:
#   1. Backfill a log stub for the previous transcript if no log references it
#      (covers cases where SessionEnd did not fire, e.g. SIGKILL / terminal close).
#      If the prior session had tool calls (= real work), also generate an LLM
#      summary via `claude -p`. Disable with VAULT_SESSION_LLM_SUMMARY=0.
#   2. Emit recent vault log summaries as additional context.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

hook_init

LLM_SUMMARY="${VAULT_SESSION_LLM_SUMMARY:-1}"

# --- 1. Backfill prior transcript stub if missing ----------------------------
ENCODED_CWD="$(printf '%s' "$HOOK_CWD" | sed 's|/|-|g')"
PROJECT_DIR="$HOME/.claude/projects/$ENCODED_CWD"

if [ -d "$PROJECT_DIR" ]; then
    PRIOR_TRANSCRIPT="$(
        find "$PROJECT_DIR" -maxdepth 1 -type f -name '*.jsonl' \
            ! -name "${HOOK_SID}.jsonl" \
            -printf '%T@ %p\n' 2>/dev/null \
            | sort -rn | head -1 | cut -d' ' -f2-
    )"

    if [ -n "$PRIOR_TRANSCRIPT" ] && [ -f "$PRIOR_TRANSCRIPT" ]; then
        PRIOR_SID="$(basename "$PRIOR_TRANSCRIPT" .jsonl)"

        if ! grep -lF "session_id: $PRIOR_SID" "$LOGS_DIR"/*.md >/dev/null 2>&1; then
            CONDENSED="$(mktemp)"
            META="$(python3 "$SCRIPT_DIR/../lib/parse_transcript.py" \
                "$PRIOR_TRANSCRIPT" "$CONDENSED" 2>/dev/null || true)"

            FIRST="$(printf '%s\n' "$META" | sed -n 's/^FIRST=//p')"
            LAST="$(printf '%s\n' "$META" | sed -n 's/^LAST=//p')"
            COUNT="$(printf '%s\n' "$META" | sed -n 's/^COUNT=//p')"
            TOOLS="$(printf '%s\n' "$META" | sed -n 's/^TOOLS=//p')"
            FILES_LIST="$(printf '%s\n' "$META" | sed -n 's/^FILE=//p')"

            DATE="$(date -r "$PRIOR_TRANSCRIPT" +%F 2>/dev/null || date +%F)"
            TIME="$(date -r "$PRIOR_TRANSCRIPT" +%H%M 2>/dev/null || date +%H%M)"

            # Optional LLM summary — only if there were tool calls (real changes)
            SUMMARY=""
            if [ "${TOOLS:-0}" -gt 0 ] && [ "$LLM_SUMMARY" = "1" ] \
               && command -v claude >/dev/null 2>&1 \
               && [ -s "$CONDENSED" ]; then
                SUMMARY="$(VAULT_SESSION_BG=1 claude -p --model haiku \
                    --no-session-persistence --disable-slash-commands \
                    "Summarize this Claude Code session transcript in markdown. Sections: ### What user asked, ### What was done, ### Decisions / open questions, ### Pending. Be concise (~250 words). Output markdown only, no preamble, no top-level heading." \
                    < "$CONDENSED" 2>/dev/null || true)"
            fi
            rm -f "$CONDENSED"

            STUB_BODY="$(
                {
                    echo "Reconstructed on session start because no log existed for this session_id."
                    echo
                    [ -n "$FIRST" ]  && echo "First message: \`${FIRST}\`"
                    [ -n "$LAST" ]   && echo "Last message: \`${LAST}\`"
                    [ -n "$COUNT" ]  && echo "Message count: ${COUNT}"
                    [ -n "$TOOLS" ]  && echo "Tool calls: ${TOOLS}"
                    echo
                    echo "Transcript: \`${PRIOR_TRANSCRIPT}\`"
                    echo
                    if [ -n "$SUMMARY" ]; then
                        echo "## Summary (LLM-generated)"
                        echo
                        echo "$SUMMARY"
                        echo
                    fi
                    if [ -n "$FILES_LIST" ]; then
                        echo "## Files touched (from tool calls)"
                        echo
                        printf '%s\n' "$FILES_LIST" | sed 's|^|- `|; s|$|`|'
                        echo
                    fi
                    echo "## Notes"
                    echo
                    if [ -n "$SUMMARY" ]; then
                        echo "_Backfill stub with LLM summary. Edit as needed._"
                    else
                        echo "_Backfill stub. Fill in summary, decisions, and wikilinks._"
                    fi
                }
            )"

            STUB="$(printf '%s\n' "$STUB_BODY" \
                | write_session_stub "$PRIOR_SID" "unknown" "$DATE" "$TIME" "backfilled" "backfill")"

            echo "## vault-session: backfilled prior session log"
            echo
            echo "Wrote \`${STUB}\` (no SessionEnd fired for previous session)."
            [ -n "$SUMMARY" ] && echo "LLM summary included (transcript had ${TOOLS} tool call(s))."
            echo
        fi
    fi
fi

# --- 2. Emit recent log heads as context ------------------------------------
mapfile -t RECENT < <(ls -1t "$LOGS_DIR"/*.md 2>/dev/null | head -3)
if [ "${#RECENT[@]}" -gt 0 ]; then
    echo "## Recent vault session logs (auto-loaded by vault-session plugin)"
    echo
    for f in "${RECENT[@]}"; do
        echo "### $(basename "$f")"
        echo
        head -40 "$f"
        echo
        echo "---"
        echo
    done
fi

# Surface logs whose background summary never landed (bg job died / killed).
mapfile -t PENDING < <(grep -lF "$PENDING_MARKER" "$LOGS_DIR"/*.md 2>/dev/null)
if [ "${#PENDING[@]}" -gt 0 ]; then
    echo "## vault-session: logs with stalled summaries"
    echo
    echo "Background \`claude -p\` did not finish for these logs (likely killed before completion):"
    echo
    for f in "${PENDING[@]}"; do
        echo "- \`$(basename "$f")\`"
    done
    echo
fi

DEC="$VAULT/architecture/decisions.md"
if [ -f "$DEC" ]; then
    echo "### architecture/decisions.md (head)"
    echo
    head -60 "$DEC"
fi
