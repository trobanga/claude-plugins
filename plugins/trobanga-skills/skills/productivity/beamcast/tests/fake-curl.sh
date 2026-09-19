#!/usr/bin/env bash
# Stands in for curl while the tests run. It records every argument it was
# given, one per line, then answers with the canned reply the test arranged.
# bc.sh asks curl to print the status code on a line of its own, so this
# does the same.

printf '%s\n' "$@" >>"$ARGS"

cat "$REPLY_BODY"
printf '\n'
cat "$REPLY_CODE"
