---
name: crap-score
description: Compute the CRAP score (Change Risk Anti-Patterns) of every Java method changed on the current branch, from a JaCoCo XML report and a git diff, and fail above a threshold. Measures only and writes no tests. Use when the user asks for a CRAP score, a complexity-times-coverage check, or which changed methods are risky. To fix the violations, use the crap-agent.
allowed-tools: Bash, Read, Glob
---

# CRAP score of changed methods

    CRAP(m) = cc(m)^2 * (1 - coverage(m))^3 + cc(m)

`cc` is the cyclomatic complexity from the JaCoCo `COMPLEXITY` counter.
`coverage` is the branch coverage from the `BRANCH` counter. Methods
without branches have no such counter and use line coverage instead. With
full coverage the score equals `cc`.

Only methods that contain a line added by the diff are scored. Lambdas are
excluded by default. Default threshold: 8.

## Prerequisites

- Java project with the JaCoCo Maven plugin.
- Python 3, no third-party packages.

## Instructions

1. Find the changed modules: first path segment of
   `git diff --name-only origin/main...HEAD -- '*.java'`.
2. Build fresh coverage. Do not reuse existing `.exec` files, they may
   describe old code. The report guard cannot see a stale exec because
   `jacoco:report` writes a fresh XML from it.

       mvn verify -pl <m1>,<m2> --also-make -Dmaven.test.failure.ignore=true -q

3. Write the report per module from the merged exec, if the project merges
   unit and integration data, else from `target/jacoco.exec`:

       mvn jacoco:report -pl <m> -Djacoco.dataFile=target/jacoco.exec -q

4. Score per module:

       python3 ~/.agents/skills/engineering/crap-score/scripts/crap_score.py \
         --report <m>/target/site/jacoco/jacoco.xml \
         --range origin/main...HEAD --threshold 8

   `--diff FILE` or `--diff -` takes a unified diff instead of a range.
   With `--range`, the script exits with an error when the report is older
   than any changed Java file. Rebuild the report then.

Show the table verbatim. Exit code 1 means at least one method is at or
above the threshold.

## How methods are mapped to diff lines

JaCoCo gives only the first code line of a method. A method ends where the
next method in the same source file starts, across inner classes. The last
method of a file is open-ended. Known limits:

- An edit above the first code line of a method (annotation, signature,
  Javadoc) maps to the preceding method.
- Only files under `src/main/java` are matched.

## Tests

    python3 -m unittest discover -s ~/.agents/skills/engineering/crap-score/scripts
