#!/usr/bin/env bash
# Tests for jacoco-coverage.py and for the branch-analysis block of
# patch-coverage-java.sh. No test framework is necessary. Run this file:
#
#   ./tests/run-tests.sh
#
# The exit code is 0 if every test passes.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$(cd "$HERE/../scripts" && pwd)"
S="$SCRIPTS/jacoco-coverage.py"
JAVA_SH="$SCRIPTS/patch-coverage-java.sh"
A="$HERE/fixtures/module-a.xml"
B="$HERE/fixtures/module-b.xml"
C="$HERE/fixtures/module-c.xml"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

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

# Fixture content:
#   module-a.xml  Alpha    misses 1 of 2 branches
#   module-b.xml  Beta          covers every branch
#                 Gamma         misses 2 of 2 branches
#   module-c.xml  Order         misses 1 of 2 branches
#                 OrderService  misses 3 of 3 branches
#                 Outer$Inner   misses 2 of 2 branches, source file Outer.java

# --- Test 1: the script reads more than one XML report -----------------------
OUT=$("$S" "$A" "$B" 2>&1) || true
if [[ "$OUT" == *"Alpha"* && "$OUT" == *"Gamma"* ]]; then
    report ok "reads two XML reports in one run"
else
    report no "reads two XML reports in one run" "$OUT"
fi

# --- Test 2: --filter is repeatable and matches the union --------------------
OUT=$("$S" "$A" "$B" --filter Alpha --filter Gamma 2>&1) || true
if [[ "$OUT" == *"Alpha"* && "$OUT" == *"Gamma"* && "$OUT" != *"Beta"* ]]; then
    report ok "repeated --filter matches the union of the patterns"
else
    report no "repeated --filter matches the union of the patterns" "$OUT"
fi

# --- Test 3: exit code 2 when a missed branch exists, 0 when none ------------
OUT=$("$S" "$A" --branches-only 2>&1)
RC=$?
if [[ $RC -eq 2 ]]; then
    report ok "exits 2 when a class has a missed branch"
else
    report no "exits 2 when a class has a missed branch (got $RC)" "$OUT"
fi

OUT=$("$S" "$B" --filter Beta --branches-only 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    report ok "exits 0 when every matched class is fully covered"
else
    report no "exits 0 when every matched class is fully covered (got $RC)" "$OUT"
fi

# --- Test 4: --quiet prints nothing when no gap exists -----------------------
OUT=$("$S" "$B" --filter Beta --branches-only --quiet 2>&1) || true
if [[ -z "$OUT" ]]; then
    report ok "--quiet prints nothing when every matched class is covered"
else
    report no "--quiet prints nothing when every matched class is covered" "$OUT"
fi

# --- Test 5: --quiet still prints the gaps -----------------------------------
OUT=$("$S" "$A" "$B" --branches-only --quiet 2>&1) || true
if [[ "$OUT" == *"Alpha.java"* && "$OUT" == *"Gamma.pick()"* && "$OUT" != *"None!"* ]]; then
    report ok "--quiet still prints every missed branch"
else
    report no "--quiet still prints every missed branch" "$OUT"
fi

# --- Test 6/7: the branch-analysis block of patch-coverage-java.sh -----------
# Extract the real block from the script and run it against the fixtures.
# The block derives SCRIPT_DIR from BASH_SOURCE, so remove that line and set
# SCRIPT_DIR here instead.
run_block() {
    local changed="$1"
    shift
    {
        echo 'set -uo pipefail'
        echo "CHANGED_FILES='$changed'"
        echo "COVERAGE_FILES='$*'"
        echo "SCRIPT_DIR='$SCRIPTS'"
        sed -n '/^# Extract class names/,$p' "$JAVA_SH" | tail -n +2 |
            grep -v 'BASH_SOURCE'
    } >"$WORK/block.sh"
    bash "$WORK/block.sh" 2>&1
}

OUT=$(run_block "src/main/java/com/example/b/Beta.java" "$B")
if [[ "$OUT" == *"All changed classes have full branch coverage."* && "$OUT" != *"Tip:"* ]]; then
    report ok "shell block reports full coverage for a covered class"
else
    report no "shell block reports full coverage for a covered class" "$OUT"
fi

OUT=$(run_block "src/main/java/com/example/a/Alpha.java" "$A" "$B")
if [[ "$OUT" == *"Alpha.check()"* && "$OUT" == *"Tip:"* && "$OUT" != *"Gamma"* ]]; then
    report ok "shell block prints the gaps of the changed class only, plus the tip"
else
    report no "shell block prints the gaps of the changed class only, plus the tip" "$OUT"
fi

# --- Test 8: --filter matches the class name exactly -------------------------
OUT=$("$S" "$C" --filter Order --branches-only 2>&1) || true
if [[ "$OUT" == *"Order.total()"* && "$OUT" != *"OrderService"* ]]; then
    report ok "--filter Order does not match OrderService"
else
    report no "--filter Order does not match OrderService" "$OUT"
fi

# --- Test 9: a nested class matches the name of its top-level class ----------
OUT=$("$S" "$C" --filter Outer --branches-only 2>&1) || true
if [[ "$OUT" == *"Outer\$Inner.decide()"* && "$OUT" == *"Outer.java"* ]]; then
    report ok "--filter Outer matches the nested class Outer\$Inner"
else
    report no "--filter Outer matches the nested class Outer\$Inner" "$OUT"
fi

echo ""
echo "passed: $PASS  failed: $FAIL"
[[ $FAIL -eq 0 ]]
