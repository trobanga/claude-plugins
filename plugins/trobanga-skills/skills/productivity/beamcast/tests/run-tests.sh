#!/usr/bin/env bash
# Tests for bc.sh. No test framework is necessary. Run this file:
#
#   ./tests/run-tests.sh
#
# The exit code is 0 if every test passes.
#
# No test touches the network. `BEAMCAST_CURL` points bc.sh at a fake curl
# that writes its arguments to $ARGS and answers with the canned body in
# $REPLY_BODY and the status in $REPLY_CODE.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BC="$(cd "$HERE/../scripts" && pwd)/bc.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

export BEAMCAST_CURL="$HERE/fake-curl.sh"
export BEAMCAST_TOKEN="t0ken"
export BEAMCAST_HOST="https://beamcast.example"
export ARGS="$WORK/args"
export REPLY_BODY="$WORK/body"
export REPLY_CODE="$WORK/code"

PASS=0
FAIL=0

report() {
    if [[ "$1" == "ok" ]]; then
        PASS=$((PASS + 1))
        echo "PASS: $2"
    else
        FAIL=$((FAIL + 1))
        echo "FAIL: $2"
        echo "----- output -----"
        echo "$3"
        echo "------------------"
    fi
}

# Arrange the next reply, and forget the arguments of the run before it.
reply() {
    printf '%s' "$1" >"$REPLY_BODY"
    printf '%s' "${2:-200}" >"$REPLY_CODE"
    : >"$ARGS"
}

# --- Test 1: check posts the file as the source field ------------------------
printf '# Hello\n' >"$WORK/slides.bc"
reply '{"slides":1}'
OUT=$("$BC" check "$WORK/slides.bc" 2>&1) || true
SENT=$(cat "$ARGS")
if [[ "$SENT" == *"https://beamcast.example/api/v1/parse"* ]] &&
    [[ "$(grep -c '"source": "# Hello\\n"' "$WORK/args")" == 1 ]]; then
    report ok "check posts the file as the source field"
else
    report no "check posts the file as the source field" "$SENT"$'\n'"$OUT"
fi

# --- Test 2: a parse error prints its line and fails -------------------------
reply '{"errors":[{"line":4,"message":"unknown directive @aera"}]}' 422
OUT=$("$BC" check "$WORK/slides.bc" 2>&1)
CODE=$?
if [[ "$OUT" == *"line 4: unknown directive @aera"* && "$CODE" == 1 ]]; then
    report ok "a parse error prints its line and fails"
else
    report no "a parse error prints its line and fails" "exit $CODE"$'\n'"$OUT"
fi

# --- Test 3: a successful check reports the slide count ----------------------
reply '{"slides":28}'
OUT=$("$BC" check "$WORK/slides.bc" 2>&1)
CODE=$?
if [[ "$OUT" == "28 slides" && "$CODE" == 0 ]]; then
    report ok "a successful check reports the slide count"
else
    report no "a successful check reports the slide count" "exit $CODE"$'\n'"$OUT"
fi

# --- Test 4: push puts the source on the presentation ------------------------
reply '{"ok":true}'
OUT=$("$BC" push my-talk "$WORK/slides.bc" 2>&1) || true
SENT=$(cat "$ARGS")
if [[ "$SENT" == *"PUT"* ]] &&
    [[ "$SENT" == *"https://beamcast.example/api/v1/presentations/my-talk/source"* ]] &&
    [[ "$(grep -c '"source": "# Hello\\n"' "$ARGS")" == 1 ]]; then
    report ok "push puts the source on the presentation"
else
    report no "push puts the source on the presentation" "$SENT"$'\n'"$OUT"
fi

# --- Test 5: pull writes the raw deck source, not JSON -----------------------
reply '@deck
@palette mono'
OUT=$("$BC" pull my-talk 2>&1) || true
if [[ "$OUT" == '@deck
@palette mono' ]]; then
    report ok "pull writes the raw deck source"
else
    report no "pull writes the raw deck source" "$OUT"
fi

# --- Test 6: image sends raw bytes and prints the mark to paste --------------
printf '<svg/>' >"$WORK/plot.svg"
reply '{"id":"Jz7qP0aXm2Kd8Rue","url":"/i/Jz7qP0aXm2Kd8Rue"}' 201
OUT=$("$BC" image "$WORK/plot.svg" 2>&1) || true
SENT=$(cat "$ARGS")
if [[ "$OUT" == *"/i/Jz7qP0aXm2Kd8Rue"* ]] &&
    [[ "$SENT" == *"--data-binary"* && "$SENT" == *"@$WORK/plot.svg"* ]] &&
    [[ "$SENT" == *"X-Filename: plot.svg"* ]]; then
    report ok "image sends raw bytes and prints the mark to paste"
else
    report no "image sends raw bytes and prints the mark to paste" "$SENT"$'\n'"$OUT"
fi

# --- Test 7: new creates a presentation with a title alone -------------------
reply '{"slug":"my-talk","title":"My Talk"}' 201
OUT=$("$BC" new "My Talk" 2>&1) || true
if [[ "$(grep -c '"title": "My Talk"' "$ARGS")" == 1 ]] &&
    [[ "$(grep -c '"source"' "$ARGS")" == 0 ]] && [[ "$OUT" == *"my-talk"* ]]; then
    report ok "new creates a presentation with a title alone"
else
    report no "new creates a presentation with a title alone" "$(cat "$ARGS")"$'\n'"$OUT"
fi

# --- Test 8: new carries the deck source when a file is named ----------------
reply '{"slug":"my-talk","title":"My Talk"}' 201
OUT=$("$BC" new "My Talk" "$WORK/slides.bc" 2>&1) || true
if [[ "$(grep -c '"title": "My Talk"' "$ARGS")" == 1 ]] &&
    [[ "$(grep -c '"source": "# Hello\\n"' "$ARGS")" == 1 ]]; then
    report ok "new carries the deck source when a file is named"
else
    report no "new carries the deck source when a file is named" "$(cat "$ARGS")"$'\n'"$OUT"
fi

# --- Test 9: list names each presentation with its slug ----------------------
reply '{"presentations":[{"slug":"my-talk","title":"My Talk","updated_at":"2026-09-18T10:00:00Z"}]}'
OUT=$("$BC" list 2>&1) || true
if [[ "$OUT" == *"my-talk"* && "$OUT" == *"My Talk"* ]]; then
    report ok "list names each presentation with its slug"
else
    report no "list names each presentation with its slug" "$OUT"
fi

# --- Test 10: images lists each stored picture by its mark -------------------
reply '{"images":[{"id":"Jz7qP0aXm2Kd8Rue","url":"/i/Jz7qP0aXm2Kd8Rue","filename":"plot.svg","byte_size":812}]}'
OUT=$("$BC" images 2>&1) || true
if [[ "$OUT" == *"/i/Jz7qP0aXm2Kd8Rue"* && "$OUT" == *"plot.svg"* ]]; then
    report ok "images lists each stored picture by its mark"
else
    report no "images lists each stored picture by its mark" "$OUT"
fi

# --- Test 11: rename patches the title -------------------------------------
reply '{"slug":"my-talk","title":"Better Title"}'
OUT=$("$BC" rename my-talk "Better Title" 2>&1) || true
SENT=$(cat "$ARGS")
if [[ "$SENT" == *"PATCH"* ]] &&
    [[ "$SENT" == *"https://beamcast.example/api/v1/presentations/my-talk"* ]] &&
    [[ "$(grep -c '"title": "Better Title"' "$ARGS")" == 1 ]]; then
    report ok "rename patches the title"
else
    report no "rename patches the title" "$SENT"$'\n'"$OUT"
fi

# --- Test 12: rm deletes the presentation ------------------------------------
reply '' 204
OUT=$("$BC" rm my-talk 2>&1) || true
SENT=$(cat "$ARGS")
if [[ "$SENT" == *"DELETE"* ]] &&
    [[ "$SENT" == *"https://beamcast.example/api/v1/presentations/my-talk"* ]]; then
    report ok "rm deletes the presentation"
else
    report no "rm deletes the presentation" "$SENT"$'\n'"$OUT"
fi

# --- Test 13: rm-image deletes the stored picture ----------------------------
reply '' 204
OUT=$("$BC" rm-image Jz7qP0aXm2Kd8Rue 2>&1) || true
SENT=$(cat "$ARGS")
if [[ "$SENT" == *"DELETE"* ]] &&
    [[ "$SENT" == *"https://beamcast.example/api/v1/images/Jz7qP0aXm2Kd8Rue"* ]]; then
    report ok "rm-image deletes the stored picture"
else
    report no "rm-image deletes the stored picture" "$SENT"$'\n'"$OUT"
fi

# --- Test 14: a missing token stops the run before any request ---------------
reply '{"presentations":[]}'
OUT=$(env -u BEAMCAST_TOKEN "$BC" list 2>&1) || true
if [[ "$OUT" == *"BEAMCAST_TOKEN"* && ! -s "$ARGS" ]]; then
    report ok "a missing token stops the run before any request"
else
    report no "a missing token stops the run before any request" "$OUT"
fi

# --- Test 15: a refusal without an errors array still says something ---------
# A refusal that is valid JSON but carries no `errors` array would otherwise
# leave the caller with an exit code and no word about what happened.
reply '{"detail":"rate limited"}' 429
OUT=$("$BC" list 2>&1) || true
if [[ "$OUT" == *"429"* && "$OUT" == *"rate limited"* ]]; then
    report ok "a refusal without an errors array still says something"
else
    report no "a refusal without an errors array still says something" "$OUT"
fi

# --- Test 16: an HTML refusal reports its status too -------------------------
# Cloudflare answers an HTML page, not JSON.
reply '<html>Forbidden</html>' 403
OUT=$("$BC" list 2>&1) || true
if [[ "$OUT" == *"403"* ]]; then
    report ok "an HTML refusal reports its status too"
else
    report no "an HTML refusal reports its status too" "$OUT"
fi

# --- Test 17: no arguments explains the script, token or not -----------------
OUT=$(env -u BEAMCAST_TOKEN "$BC" 2>&1) || true
if [[ "$OUT" == *"check <file>"* && "$OUT" == *"push <slug> <file>"* ]]; then
    report ok "no arguments explains the script"
else
    report no "no arguments explains the script" "$OUT"
fi

echo
echo "passed: $PASS  failed: $FAIL"
[[ "$FAIL" == 0 ]]
