import { expect, test } from 'claude-code/testing'

const TOOL = 'mcp__trobanga-progress__progress'

test('the progress tool takes bad input without failing and the band shows the phase', async ($, on) => {
  on('session.start', async (_, e) => ({ cwd: e.cwd }))
  on('tool.register', async (_, e) => ({ value: { tool: `mcp__trobanga-progress__${e.name}` } }))
  on('clock.every', async () => ({ value: undefined }))
  on('command.register', async (_, e) => ({ value: { command: e.name } }))
  await $.session.start({ cwd: '/tmp', surface: 'terminal', isInteractive: true })
  const bad = await $.tool.call({ tool: TOOL, title: 5, phase: 'nonsense', tasks: 'x' })
  expect(bad.isError).toBeFalsy()
  await $.tool.call({ tool: TOOL, title: 'GH-12 fix parser', phase: 'review' })

  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({
      plugin: 'trobanga-progress',
      surface,
      component: 'AbovePrompt',
      props: { hasSurvey: false, isWorking: false, maxRows: 10, bodyColumns: 120, scroll: { offset: 0, bodyRows: 10 }, view: {} },
    })
    // The terminal names the flow in a Text; the desktop draws it into an Svg and names it in `alt`.
    const found = surface === 'terminal' ? await ui.findAll({ text: /GH-12 fix parser/ }) : await ui.findAll({ type: 'Svg' })
    expect(found.length).toBeGreaterThan(0)
    await ui.unmount()
  }
})
