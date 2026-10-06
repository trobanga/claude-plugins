#!/bin/bash
set -e

echo "Running tests with coverage..."
# -coverpkg=./... credits every package of the module with the lines that any
# test reaches, so tests kept in a package of their own (tests/unit/, ...)
# count. Without it, a package's coverage comes from its own tests only.
go test -count=1 -coverpkg=./... -coverprofile=coverage.out ./...

echo "Converting to Cobertura format..."
gocover-cobertura < coverage.out > coverage.xml

echo "Generating patch coverage report..."
diff-cover coverage.xml --compare-branch=origin/main | grep -v '^$'
