#!/usr/bin/env bash
set -euo pipefail

echo "Running tests with coverage..."
cargo tarpaulin --out xml --output-dir .

echo "Generating patch coverage report..."
diff-cover cobertura.xml --compare-branch=origin/main | grep -v '^$'
