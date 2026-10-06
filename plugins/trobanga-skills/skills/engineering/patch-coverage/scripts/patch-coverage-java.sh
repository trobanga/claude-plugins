#!/usr/bin/env bash
set -euo pipefail

# The JaCoCo data file that the test run writes, inside <module>/target/.
# jacoco.exec is the default of jacoco-maven-plugin's prepare-agent goal; set
# JACOCO_EXEC when the pom names it otherwise (e.g. jacoco-unit.exec).
JACOCO_EXEC="${JACOCO_EXEC:-jacoco.exec}"

# Detect changed Java files (source, not test) compared to origin/main
CHANGED_FILES=$(git diff --name-only origin/main -- '*.java' | grep -v '/test/' || true)

if [[ -z "$CHANGED_FILES" ]]; then
    echo "No Java source files changed compared to origin/main"
    exit 0
fi

# The module of a file is the nearest directory above it that holds a
# pom.xml; "." is the root module. Paths are relative to the repository root,
# so run the script from there.
module_of() {
    local dir
    dir=$(dirname "$1")
    while [[ "$dir" != "." && ! -f "$dir/pom.xml" ]]; do
        dir=$(dirname "$dir")
    done
    echo "$dir"
}

CHANGED_MODULES=$(while read -r f; do module_of "$f"; done <<<"$CHANGED_FILES" |
    sort -u | tr '\n' ',' | sed 's/,$//')

# Maven selects modules by directory; the root module needs no -pl.
pl_args() {
    if [[ "$1" == "." ]]; then return; fi
    echo "-pl $1"
}

if [[ -z "$CHANGED_MODULES" ]]; then
    echo "No Maven modules detected in changed files"
    exit 0
fi

echo "Changed modules: $CHANGED_MODULES"
echo ""

# Always run the tests: an exec file left by an earlier run describes old code.
echo "Running tests for changed modules..."
# shellcheck disable=SC2046
mvn test $(pl_args "$CHANGED_MODULES") --also-make -q

# Generate coverage reports for each changed module
echo "Generating coverage reports..."
SRC_ROOTS=""
COVERAGE_FILES=""

for module in $(echo "$CHANGED_MODULES" | tr ',' '\n'); do
    if [[ ! -f "$module/target/$JACOCO_EXEC" ]]; then
        echo "WARNING: the test run wrote no $module/target/$JACOCO_EXEC. Bind" >&2
        echo "jacoco-maven-plugin's prepare-agent goal in the pom, or set JACOCO_EXEC" >&2
        echo "to the data file name the pom configures." >&2
    else
        # Generate XML report
        # shellcheck disable=SC2046
        mvn jacoco:report $(pl_args "$module") -Djacoco.dataFile="target/$JACOCO_EXEC" -q

        JACOCO_XML="$module/target/site/jacoco/jacoco.xml"
        SRC_DIR="$module/src/main/java"

        if [[ -f "$JACOCO_XML" && -d "$SRC_DIR" ]]; then
            COVERAGE_FILES="$COVERAGE_FILES $JACOCO_XML"
            SRC_ROOTS="$SRC_ROOTS $SRC_DIR"
        fi
    fi
done

if [[ -z "$COVERAGE_FILES" ]]; then
    echo "No coverage data found for changed modules"
    exit 1
fi

echo ""
echo "Running diff-cover..."
# shellcheck disable=SC2086
diff-cover $COVERAGE_FILES --compare-branch=origin/main --src-roots $SRC_ROOTS

# Extract class names from changed source files for targeted branch analysis
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JACOCO_SCRIPT="$SCRIPT_DIR/jacoco-coverage.py"

if [[ -x "$JACOCO_SCRIPT" ]]; then
    # Build one --filter argument per changed class name
    FILTER_ARGS=()
    for cls in $(echo "$CHANGED_FILES" | sed 's|.*/||; s|\.java$||' | sort -u); do
        FILTER_ARGS+=(--filter "$cls")
    done

    echo ""
    echo "=== Per-Class Branch Analysis (changed files only) ==="

    # The script exits 2 if it finds a missed branch, 0 if it finds none.
    RC=0
    # shellcheck disable=SC2086
    "$JACOCO_SCRIPT" $COVERAGE_FILES "${FILTER_ARGS[@]}" --branches-only --quiet || RC=$?

    case $RC in
        0)
            echo "All changed classes have full branch coverage."
            ;;
        2)
            echo ""
            echo "Tip: Run for details on a specific class:"
            echo "  $JACOCO_SCRIPT <jacoco.xml> --filter ClassName"
            ;;
        *)
            echo "Branch analysis failed (exit $RC)"
            ;;
    esac
fi
