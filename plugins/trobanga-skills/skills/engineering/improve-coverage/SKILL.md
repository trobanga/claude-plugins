---
name: improve-coverage
description: Raise patch coverage on the current branch toward a target by looping a Workflow that writes real tests for the least-covered changed file and re-measures with diff-cover. Supports Java, Go, and Rust, refuses to write assertion-free or implementation-coupled tests, and reports lines not worth covering. Use when the user asks to add missing tests, improve or increase coverage, or reach a coverage percentage. To only measure, use patch-coverage instead.
allowed-tools: Bash, Read, Glob, Workflow, TodoWrite
---

# Improve Code Coverage

Improve patch coverage for the current branch with a Workflow loop. The loop stops when the coverage number reaches the target, not when the model prints a magic string.

**Quality rule:** the aim is 100% patch coverage, but never at the cost of bogus tests. A bogus test executes lines without asserting behavior, asserts implementation details instead of observable behavior, or duplicates an existing test path. When only bogus tests can cover the remaining lines, stop and report those lines as not-worth-covering instead of writing the tests.

## Arguments

The skill arguments are optional:
- A number sets the target coverage percentage (default: 100).
- `iterations=N` sets the maximum number of iterations (default: 5).
- Both can appear together, e.g. `85 iterations=8`.

## Instructions

### Step 1: Detect the project type

The scripts live in the sibling `patch-coverage` skill, under
`~/.agents/skills/engineering/patch-coverage/scripts/` (written as `$S` in the table below).

| Indicator    | Language | Coverage script                | Test guidance                                                                 |
|--------------|----------|--------------------------------|-------------------------------------------------------------------------------|
| `pom.xml`    | Java     | `$S/patch-coverage-java.sh`    | JUnit 5 + Mockito, follow existing test class conventions in `src/test/`. To find missed branches, run `$S/jacoco-coverage.py` on the generated `jacoco.xml` — never write inline Python to parse JaCoCo XML. |
| `go.mod`     | Go       | `$S/patch-coverage-go.sh`      | testify/assert; put tests where existing tests live (`tests/unit/`, `tests/integration/`, or `_test.go` next to the code — match the repo). |
| `Cargo.toml` | Rust     | `$S/patch-coverage-rust.sh`    | `#[cfg(test)]` modules or `tests/` directory, follow existing patterns.        |

Expand `$S` to the full path before putting it in a command or a workflow argument.

If none match, tell the user the project type is not supported and stop.

### Step 2: Early exit check

Run the coverage script once. Parse the `Coverage: N%` line from the `diff-cover` output.

- If the script reports no changed files, tell the user and stop.
- If N is at or above the target, tell the user coverage is already sufficient and stop.
- Otherwise note N as the start coverage and continue.

### Step 3: Run the workflow

Call the Workflow tool with the script below. Pass `args` as a JSON object:

```json
{
  "script": "<coverage script path>",
  "target": <target percent>,
  "maxIterations": <max iterations>,
  "startCoverage": <N from step 2>,
  "testGuidance": "<test guidance for the detected language>"
}
```

```js
export const meta = {
  name: 'improve-coverage',
  description: 'Raise patch coverage to a target, one focused agent per iteration',
  phases: [{ title: 'Improve', detail: 'write tests for the lowest-coverage file, re-measure' }],
}
phase('Improve')
let coverage = args.startCoverage
let iteration = 0
const history = [{ iteration: 0, coverage }]
while (coverage < args.target && iteration < args.maxIterations) {
  iteration++
  const result = await agent(
    `Improve patch coverage for the current branch. Current patch coverage: ${coverage}%. Target: ${args.target}%.\n` +
    `1. Run ${args.script} and read the diff-cover output.\n` +
    `2. Pick the changed file with the LOWEST coverage.\n` +
    `3. Write meaningful tests for its missed lines and branches. NEVER write bogus tests: no assertion-free tests that only execute lines, no assertions on implementation details, no duplicates of existing test paths. If a missed line can only be covered by a bogus test, skip it and list it in notWorthCovering with a short reason.\n` +
    `Test guidance: ${args.testGuidance}\n` +
    `4. Run the new tests and make them pass.\n` +
    `5. Re-run ${args.script} and report the new total from the "Coverage: N%" line.\n` +
    `If a test cannot pass because the production code has a bug, report the bug instead of bending the test.`,
    {
      label: `iteration ${iteration}`,
      schema: {
        type: 'object',
        properties: {
          coverage: { type: 'number', description: 'new total patch coverage percent from diff-cover' },
          filesTested: { type: 'array', items: { type: 'string' } },
          summary: { type: 'string', description: 'one or two sentences: what was tested, what remains' },
          suspectedBugs: { type: 'array', items: { type: 'string' }, description: 'production bugs found while testing, empty if none' },
          notWorthCovering: { type: 'array', items: { type: 'string' }, description: 'lines or branches that only a bogus test can cover, with a short reason each; empty if none' },
          onlyBogusRemain: { type: 'boolean', description: 'true if ALL remaining uncovered lines need bogus tests, so more iterations are pointless' },
        },
        required: ['coverage', 'filesTested', 'summary', 'suspectedBugs', 'notWorthCovering', 'onlyBogusRemain'],
      },
    }
  )
  if (!result) { log(`iteration ${iteration}: agent failed, retrying with next iteration`); continue }
  if (result.coverage < coverage) {
    log(`iteration ${iteration}: coverage FELL from ${coverage}% to ${result.coverage}% — investigate before continuing`)
  }
  coverage = result.coverage
  history.push({ iteration, coverage, files: result.filesTested, summary: result.summary, suspectedBugs: result.suspectedBugs, notWorthCovering: result.notWorthCovering })
  log(`iteration ${iteration}: ${coverage}% (target ${args.target}%)`)
  if (result.onlyBogusRemain) {
    log(`iteration ${iteration}: only bogus tests can cover the rest — stopping early`)
    break
  }
}
return { reached: coverage >= args.target, coverage, target: args.target, iterations: iteration, history }
```

### Step 4: Report

Read the workflow result and tell the user:
- Start coverage, final coverage, and the target.
- Which files got new tests, per iteration.
- Any suspected production bugs the iterations reported — surface these prominently, do not fix them without asking.
- The not-worth-covering lines and their reasons, so the user can accept the gap or overrule it.
- If the target was not reached, say how many iterations ran and why the loop stopped (iterations exhausted, or only bogus tests remained).

## Example invocations

- `/trobanga-skills:improve-coverage` — 100% target, at most 5 iterations
- `/trobanga-skills:improve-coverage 95` — 95% target
- `/trobanga-skills:improve-coverage iterations=10` — 10 iterations
- `/trobanga-skills:improve-coverage 85 iterations=8` — 85% target, 8 iterations
