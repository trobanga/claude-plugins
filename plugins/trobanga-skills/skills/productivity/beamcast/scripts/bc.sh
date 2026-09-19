#!/usr/bin/env bash
# A command-line client for the Beamcast JSON API.
set -euo pipefail

HOST="${BEAMCAST_HOST:-https://beamcast.trobanga.de}"
CURL="${BEAMCAST_CURL:-curl}"

STATUS=""
BODY=""

usage() {
    cat >&2 <<'TEXT'
bc.sh — a client for the Beamcast JSON API.

  check <file>              parse a deck without saving it
  list                      list your presentations
  new <title> [file]        create a presentation, optionally with a deck
  pull <slug> [file]        download the deck source
  push <slug> <file>        upload the deck source
  rename <slug> <title>     change the title
  rm <slug>                 delete a presentation
  images                    list your stored pictures
  image <file>              upload a picture, print its /i/<id> mark
  rm-image <id>             delete a stored picture

BEAMCAST_TOKEN holds the API token. BEAMCAST_HOST overrides the host.
TEXT
}

# A run with nothing to do explains itself, whether a token is set or not.
if [[ $# == 0 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 2
fi

if [[ -z "${BEAMCAST_TOKEN:-}" ]]; then
    echo "set BEAMCAST_TOKEN to your Beamcast API token" >&2
    exit 2
fi

# Send one request and split the answer: the body into BODY, the HTTP status
# code into STATUS. curl prints the code on a line of its own at the end.
send() {
    local method="$1" path="$2" answer
    shift 2
    answer="$("$CURL" -sS -X "$method" "$HOST$path" \
        -H "Authorization: Bearer $BEAMCAST_TOKEN" \
        -w '\n%{http_code}' "$@")"
    STATUS="${answer##*$'\n'}"
    BODY="${answer%$'\n'*}"
}

# The API answers a refusal with `errors: [{line, message}]`, where the line
# is the line of the deck source the parser stopped on.
check_status() {
    [[ "$STATUS" == 2* ]] && return 0

    local reported
    reported="$(jq -r '.errors[]? |
        if .line then "line \(.line): \(.message)" else .message end' \
        <<<"$BODY" 2>/dev/null)" || true

    # A refusal from Cloudflare is an HTML page, and one from an endpoint
    # that answers no `errors` array is JSON of another shape. Either way
    # the body itself is the only account of what happened.
    [[ -n "$reported" ]] || reported="$BODY"

    printf 'HTTP %s\n%s\n' "$STATUS" "$reported" >&2
    exit 1
}

# The deck source as a JSON object, escaped by jq rather than by hand.
source_body() {
    jq -Rs '{source: .}' "$1"
}

case "${1:-}" in
check)
    send POST /api/v1/parse \
        -H "Content-Type: application/json" \
        --data-binary "$(source_body "$2")"
    check_status
    jq -r '"\(.slides) slides"' <<<"$BODY"
    ;;
push)
    send PUT "/api/v1/presentations/$2/source" \
        -H "Content-Type: application/json" \
        --data-binary "$(source_body "$3")"
    check_status
    echo "pushed $3 to $2"
    ;;
pull)
    send GET "/api/v1/presentations/$2/source"
    check_status
    # The source endpoint answers text, so the body goes out as it arrived.
    if [[ -n "${3:-}" ]]; then
        printf '%s\n' "$BODY" >"$3"
        echo "pulled $2 into $3" >&2
    else
        printf '%s\n' "$BODY"
    fi
    ;;
image)
    # The store takes the raw bytes as the body. A multipart form does not
    # work: its envelope is not a picture.
    send POST /api/v1/images \
        -H "X-Filename: $(basename "$2")" \
        --data-binary "@$2"
    check_status
    jq -r '.url' <<<"$BODY"
    ;;
new)
    # The create endpoint parses the source too, so a deck that the parser
    # refuses creates no presentation.
    if [[ -n "${3:-}" ]]; then
        body="$(jq -Rs --arg title "$2" '{title: $title, source: .}' "$3")"
    else
        body="$(jq -n --arg title "$2" '{title: $title}')"
    fi
    send POST /api/v1/presentations \
        -H "Content-Type: application/json" \
        --data-binary "$body"
    check_status
    jq -r '.slug' <<<"$BODY"
    ;;
list)
    send GET /api/v1/presentations
    check_status
    jq -r '.presentations[] | "\(.slug)\t\(.title)\t\(.updated_at)"' <<<"$BODY"
    ;;
images)
    send GET /api/v1/images
    check_status
    jq -r '.images[] | "\(.url)\t\(.filename // "-")\t\(.byte_size) bytes"' <<<"$BODY"
    ;;
rename)
    # The presentation endpoint updates the title alone. It answers 200 to an
    # unknown field and changes nothing, so nothing else belongs here.
    send PATCH "/api/v1/presentations/$2" \
        -H "Content-Type: application/json" \
        --data-binary "$(jq -n --arg title "$3" '{title: $title}')"
    check_status
    jq -r '"\(.slug)\t\(.title)"' <<<"$BODY"
    ;;
rm)
    send DELETE "/api/v1/presentations/$2"
    check_status
    echo "deleted $2"
    ;;
rm-image)
    # Nothing sweeps the store, and a slide that names a deleted picture
    # draws nothing.
    send DELETE "/api/v1/images/$2"
    check_status
    echo "deleted /i/$2"
    ;;
*)
    echo "unknown command: ${1:-}" >&2
    usage
    exit 2
    ;;
esac
