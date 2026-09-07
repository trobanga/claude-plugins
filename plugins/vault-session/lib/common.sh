#!/usr/bin/env bash
# Shared helpers for vault-session hook scripts.
# Source with: . "$(dirname "$0")/../lib/common.sh"
# Defines:
#   VAULT, LOGS_DIR, HOOK_INPUT
#   hook_init           — read stdin JSON, set HOOK_INPUT, gate cwd to vault
#   hook_field <name>   — extract a top-level string field from HOOK_INPUT
#   write_session_stub  — write a frontmatter+body log file (body from stdin)
#   path_to_wikilink    — vault `.md` path -> [[name]], else `path`
#
# Globals set by hook_init: VAULT, LOGS_DIR, HOOK_INPUT, HOOK_CWD, HOOK_SID

# This file is sourced. The globals below are read by the hook scripts.
# shellcheck disable=SC2034
VAULT="${VAULT_DIR:-$HOME/code/vault}"
LOGS_DIR="$VAULT/logs"
PENDING_MARKER="_summary generating in background_"

hook_field() {
    printf '%s' "$HOOK_INPUT" | python3 -c \
        "import sys,json; print(json.load(sys.stdin).get(\"$1\",\"\"))" 2>/dev/null || true
}

# Read JSON from stdin, set HOOK_INPUT/HOOK_CWD/HOOK_SID, exit 0 if cwd is
# outside the vault or if running inside a vault-session-spawned `claude -p`
# (sentinel VAULT_SESSION_BG prevents recursion).
hook_init() {
    [ -n "${VAULT_SESSION_BG:-}" ] && exit 0
    HOOK_INPUT="$(cat)"
    HOOK_CWD="$(hook_field cwd)"
    HOOK_SID="$(hook_field session_id)"
    case "$HOOK_CWD" in
        "$VAULT"|"$VAULT"/*) ;;
        *) exit 0 ;;
    esac
    mkdir -p "$LOGS_DIR"
}

# write_session_stub <sid> <reason> <date> <time> <title_suffix> <extra_tag>
# Body is read from stdin and appended after the frontmatter block.
# Echoes the path written.
write_session_stub() {
    local sid="$1" reason="$2" date="$3" time="$4" suffix="$5" extra_tag="$6"
    local short_sid="${sid:0:8}"
    [ -z "$short_sid" ] && short_sid="session"
    local path="$LOGS_DIR/${date}-${time}-${short_sid}.md"
    local counter=1
    while [ -e "$path" ]; do
        path="$LOGS_DIR/${date}-${time}-${short_sid}-${counter}.md"
        counter=$((counter + 1))
    done

    local tags="session-log, auto"
    [ -n "$extra_tag" ] && tags="${tags}, ${extra_tag}"

    {
        echo "---"
        echo "title: Session ${date} ${time}${suffix:+ ($suffix)}"
        echo "tags: [${tags}]"
        echo "created: ${date}"
        echo "updated: ${date}"
        echo "status: draft"
        echo "type: session-log"
        echo "session_id: ${sid}"
        echo "end_reason: ${reason}"
        echo "---"
        echo
        echo "# Session ${date} ${time}${suffix:+ ($suffix)}"
        echo
        cat   # body from stdin
    } > "$path"

    printf '%s\n' "$path"
}

# path_to_wikilink <abs_path>
# Vault-internal `.md` -> [[basename-without-ext]]; else `path`.
path_to_wikilink() {
    local p="$1"
    case "$p" in
        "$VAULT"/*.md|"$VAULT"/*/*.md)
            local base
            base="$(basename "$p" .md)"
            printf '[[%s]]' "$base"
            ;;
        *)
            printf '`%s`' "$p"
            ;;
    esac
}
