---
name: evaluate-skill
description: Measure whether a skill changes the agent's behaviour — run its eval cases with and without it on each target model, and ablate passages — with claude plugin eval.
argument-hint: <skill-folder> [model ...] [--drop START:END]
disable-model-invocation: true
---

A skill's every line is a hypothesis about what the model does without it. This skill tests the hypotheses: it runs the skill's eval cases in a with-arm (skill loaded) and a baseline arm (no skill), reports the delta between them, and ablates passages to find the lines that earn their place. It drives `claude plugin eval`; `scripts/skill_eval.py` does the deterministic parts.

Arguments: $ARGUMENTS — the skill folder, the models to test (default: `sonnet`), and an optional `--drop START:END` line range of `SKILL.md` to ablate.

Each run is a full Claude session on the user's account. Before the first run, tell the user the run count (cases × 2 arms × runs × models) and pass `--max-cost-usd` with the cap they accept.

## Steps

1. **Cases.** Read every `<skill-folder>/evals/<case>/case.yaml`. If there are fewer than three cases, write them first (see Writing cases). Done when at least three cases exist and each expected behaviour has its own grader.
2. **Prepare.** Run `python3 ${CLAUDE_SKILL_DIR}/scripts/skill_eval.py prepare <skill-folder> <tmp>/full`, with `<tmp>` a fresh folder under `$TMPDIR`. The copy drops `disable-model-invocation`, so the agent can fire a user-invoked skill in the with-arm, and it copies beside the skill every sibling skill it reaches through `${CLAUDE_SKILL_DIR}/../<skill>/`; the original stays untouched.
3. **Run** each model:

   ```bash
   claude plugin eval <tmp>/full/<skill> --model <model> --runs 3 \
     --judge-model sonnet --output-dir <tmp>/results/full-<model> --threshold 0 \
     --no-publish --trust-plugin --max-cost-usd <cap> [--allow-tools …] [--scaffold]
   ```

   Pass the `--allow-tools` grants and `--scaffold` that the case descriptions name. To check the cases for free first, run the same command with `--max-cost-usd 0`: it loads every case, reports each invalid `case.yaml` and each grader the granted tools cannot satisfy, and runs nothing.

   Keep `--judge-model sonnet`: the default judge failed every grader of a with-arm answer that met them all. In the sandbox, allow the host `api.anthropic.com`. Done when each model has an `aggregate-result.json` that is not `partial`.
4. **Report.** Run `python3 ${CLAUDE_SKILL_DIR}/scripts/skill_eval.py report <tmp>/results/full-<model>/aggregate-result.json` for each model. Before you trust a delta, check two things in the eval's own output: the `skill-fired` line, and the final answer of one with-arm run whenever a score is 0 or 1. `tool_used: Skill` also counts a call that failed with `Unknown skill`, so read the trace when in doubt; the skill's name in the run is `<skill>:<skill>`.
5. **Ablate**, if asked. Prepare with `--drop START:END` into `<tmp>/ablated`, run the same model and runs, then `skill_eval.py report <full.json> <ablated.json>`. A case marked `WORSE` shows the passage earns its place; no change makes it a no-op candidate on that model.
6. **Verdict.** Done when the user has, per model, the table of with, without and delta for every case, each case with delta ≤ 0 named as a place where the skill adds nothing on that model, and any ablation table.

## Writing cases

- Start from failures you observed in the baseline, not imagined ones: run the prompt without the skill first.
- Give both arms the same prompt, naming the skill ("Use the X skill"); the baseline has no such skill and proceeds without it.
- Put fixtures inside the case folder and list them in `context.add_dirs`; paths outside the case folder are refused.
- Give each expected behaviour its own grader, so the score is the fraction of behaviours met. Prefer `regex` and `file_exists` where the output allows; `llm` graders are noisier.
- Add `{type: tool_used, tool: Skill, arm: with-only}` as the indicator that the skill fired.
- The field reference is at https://code.claude.com/docs/en/plugin-evals.

## Reading the numbers

With g graders and r runs, one grader flipping in one run moves a case score by 1/(g·r) — 1/18 for six graders and three runs. Treat a delta or an ablation change within that step as noise, and raise `--runs` before you conclude from it. Graders that encode the skill's own doctrine show that the skill transmits the doctrine, not that the doctrine is right.
