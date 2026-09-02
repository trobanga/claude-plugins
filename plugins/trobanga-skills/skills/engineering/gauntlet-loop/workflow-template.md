# Gauntlet workflow template

Fill the `args` (parts, bar, budgetFloor) and pass them via the Workflow tool's `args` input — do not inline them into the script. Adjust builder/critic prompts to the domain (code, UI, prose), but keep the three invariants: fresh critic every round, critic defaults to lose, loop bounded by budget rather than round count. `MAX_ROUNDS` is a runaway backstop, not a schedule — set it well above what you expect to need.

```js
export const meta = {
  name: 'gauntlet-loop',
  description: 'Builder/blind-critic rounds per part until each beats the bar or the budget runs dry',
  phases: [{ title: 'Build' }, { title: 'Judge' }],
}
// args: {
//   bar: string,          // concrete reference + criteria the critic compares against
//   budgetFloor: number,  // stop starting new rounds below this many remaining tokens
//   parts: [{ id, spec, inspect }],  // inspect: how the critic examines the real artifact
// }
const VERDICT = {
  type: 'object',
  required: ['wins', 'largestGap'],
  properties: {
    wins: { type: 'boolean' },
    largestGap: { type: 'string', description: 'The single largest meaningful gap versus the bar; empty if wins' },
  },
}
const MAX_ROUNDS = 25

const results = await pipeline(args.parts, async (part) => {
  let gap = ''
  for (let round = 1; round <= MAX_ROUNDS; round++) {
    if (budget.total && budget.remaining() < args.budgetFloor) {
      return { part: part.id, wins: false, rounds: round - 1, lastGap: gap, stopped: 'budget' }
    }
    await agent(
      `Build or revise this part of the project.\n\nSpec: ${part.spec}\n` +
      (gap ? `\nA critic judged the current artifact against the bar and found this largest gap. Fix it first, then anything else the spec needs:\n${gap}\n` : '') +
      `\nWork on the real files. Return the paths you touched and how to inspect the result.`,
      { label: `build:${part.id}#${round}`, phase: 'Build' })
    const verdict = await agent(
      `You are a blind critic. You have not seen any draft of this work and you do not trust any summary of it.\n` +
      `Inspect the actual artifact: ${part.inspect}\n` +
      `Compare it side by side against this bar: ${args.bar}\n` +
      `It wins only if it genuinely holds up next to the reference. When uncertain, it loses. ` +
      `If it loses, name the single largest meaningful gap.`,
      { label: `judge:${part.id}#${round}`, phase: 'Judge', schema: VERDICT })
    if (verdict?.wins) return { part: part.id, wins: true, rounds: round }
    gap = verdict?.largestGap ?? gap
    log(`${part.id}: lost round ${round} — ${gap}`)
  }
  return { part: part.id, wins: false, rounds: MAX_ROUNDS, lastGap: gap, stopped: 'backstop' }
})

return { bar: args.bar, results: results.filter(Boolean) }
```
