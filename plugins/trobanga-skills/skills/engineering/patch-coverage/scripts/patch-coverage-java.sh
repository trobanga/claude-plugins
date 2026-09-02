#!/usr/bin/env bash
set -euo pipefail

# Detect changed Java files (source, not test) compared to origin/main
CHANGED_FILES=$(git diff --name-only origin/main -- '*.java' | grep -v '/test/' || true)

if [[ -z "$CHANGED_FILES" ]]; then
    echo "No Java source files changed compared to origin/main"
    exit 0
fi

# Extract unique module paths from changed files
CHANGED_MODULES=$(echo "$CHANGED_FILES" | cut -d'/' -f1 | sort -u | tr '\n' ',' | sed 's/,$//')

if [[ -z "$CHANGED_MODULES" ]]; then
    echo "No Maven modules detected in changed files"
    exit 0
fi

echo "Changed modules: $CHANGED_MODULES"
echo ""

# Check if jacoco unit test data exists, if not run tests
NEED_TESTS=false
for module in $(echo "$CHANGED_MODULES" | tr ',' '\n'); do
    if [[ -d "$module" && ! -f "$module/target/jacoco-unit.exec" ]]; then
        NEED_TESTS=true
        break
    fi
done

if $NEED_TESTS; then
    echo "Running tests for changed modules..."
    mvn test -pl "$CHANGED_MODULES" --also-make -q
fi

# Generate coverage reports for each changed module
echo "Generating coverage reports..."
SRC_ROOTS=""
COVERAGE_FILES=""

for module in $(echo "$CHANGED_MODULES" | tr ',' '\n'); do
    if [[ -d "$module" && -f "$module/target/jacoco-unit.exec" ]]; then
        # Generate XML report
        mvn jacoco:report -pl "$module" -Djacoco.dataFile=target/jacoco-unit.exec -q 2>/dev/null || true

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
    # Build filter patterns from changed class names
    CHANGED_CLASSES=$(echo "$CHANGED_FILES" | sed 's|.*/||; s|\.java$||' | sort -u)

    echo ""
    echo "=== Per-Class Branch Analysis (changed files only) ==="
    for xml in $COVERAGE_FILES; do
        for cls in $CHANGED_CLASSES; do
            "$JACOCO_SCRIPT" "$xml" --filter "$cls" --branches-only 2>/dev/null | grep -v "^===" | grep -v "^$" | grep -v "None!" || true
        done
    done

    # Show summary if any missed branches were found
    HAS_GAPS=false
    for xml in $COVERAGE_FILES; do
        for cls in $CHANGED_CLASSES; do
            if "$JACOCO_SCRIPT" "$xml" --filter "$cls" --branches-only 2>/dev/null | grep -q "missing"; then
                HAS_GAPS=true
                break 2
            fi
        done
    done

    if $HAS_GAPS; then
        echo ""
        echo "Tip: Run for details on a specific class:"
        echo "  $JACOCO_SCRIPT <jacoco.xml> --filter ClassName"
    else
        echo "All changed classes have full branch coverage."
    fi
fi
