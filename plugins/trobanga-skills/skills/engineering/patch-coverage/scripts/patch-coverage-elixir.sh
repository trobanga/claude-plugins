#!/bin/bash
set -e

if ! grep -q excoveralls mix.exs; then
    echo "ERROR: excoveralls is not in mix.exs." >&2
    echo 'Add {:excoveralls, "~> 0.18", only: :test} to deps and' >&2
    echo 'test_coverage: [tool: ExCoveralls] to project/0, then run mix deps.get.' >&2
    exit 1
fi

echo "Running tests with coverage..."
MIX_ENV=test mix coveralls.lcov

echo "Generating patch coverage report..."
diff-cover cover/lcov.info --compare-branch=origin/main | grep -v '^$'
