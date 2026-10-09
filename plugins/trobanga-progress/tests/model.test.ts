import { describe, expect, test } from 'claude-code/testing'

import { applyStep, fitText, MAX_NOTE, MAX_STEPS, MAX_TASKS, MAX_TITLE, label, merge, parseProgress, ratio, roleOf } from '../hooks/model'

describe('fitText', () => {
  test('cuts a very long title to the width in linear time', () => {
    const started = Date.now()
    const out = fitText('x'.repeat(100_000), 13, 200)
    expect(Date.now() - started).toBeLessThan(200)
    expect(out.endsWith('…')).toBe(true)
    expect(out.length).toBeLessThan(40)
  })

  test('keeps a title that fits', () => {
    expect(fitText('short', 13, 200)).toBe('short')
  })
})

describe('parseProgress', () => {
  test('drops fields of the wrong type', () => {
    expect(parseProgress({ title: 5, phase: 'nonsense', finished: 'yes', tasks: 'x' })).toEqual({})
  })

  test('clamps the title and the number of tasks', () => {
    const p = parseProgress({
      title: 'a'.repeat(500),
      tasks: Array.from({ length: 500 }, (_, i) => ({ title: `t${i}`, agent: 'crap-agent', after: [1, 2.5, -1, 'x'] })),
    })
    expect(p.title?.length).toBe(MAX_TITLE)
    expect(p.tasks?.length).toBe(MAX_TASKS)
    expect(p.tasks?.[0]).toEqual({ title: 't0', agent: 'crap-agent', after: [1] })
  })

  test('keeps a valid phase and finished flag', () => {
    expect(parseProgress({ phase: 'review', finished: true })).toEqual({ phase: 'review', finished: true })
  })
})

describe('roleOf', () => {
  test('maps a plugin-qualified implementer to its costume and model', () => {
    const r = roleOf('trobanga-skills:tdd-implementer-medium')
    expect(r.costume).toBe('chef')
    expect(r.label).toBe('tdd medium')
    expect(r.model).toBe('Sonnet · medium')
  })

  test('maps the bare CRAP and mutant agents and Explore', () => {
    expect(roleOf('crap-agent').costume).toBe('detective')
    expect(roleOf('mutant-agent').costume).toBe('astronaut')
    expect(roleOf('Explore').costume).toBe('pirate')
  })

  test('gives every role a color other than the grey of the context bar', () => {
    for (const t of ['tdd-implementer-low', 'tdd-implementer-medium', 'tdd-implementer-high', 'crap-agent', 'mutant-agent', 'Explore', 'code-explorer']) {
      expect(roleOf(t).color).not.toBe(roleOf('general-purpose').color)
    }
  })

  test('gives the roles distinct one-character terminal glyphs', () => {
    const glyphs = ['tdd-implementer-low', 'crap-agent', 'mutant-agent', 'Explore', 'general-purpose'].map(t => roleOf(t).glyph)
    expect(new Set(glyphs).size).toBe(glyphs.length)
    for (const g of glyphs) expect([...g].length).toBe(1)
  })

  test('treats prototype keys and unknown types as other', () => {
    for (const t of ['toString', 'constructor', '__proto__', 'x:hasOwnProperty', 'general-purpose']) {
      expect(roleOf(t).costume).toBe('other')
      expect(typeof roleOf(t).color).toBe('string')
    }
  })
})

describe('merge', () => {
  test('a first report starts a flow at its phase', () => {
    const f = merge(null, { title: 'GH-12 fix parser', phase: 'design' })
    expect(f.title).toBe('GH-12 fix parser')
    expect(label(f)).toBe('design 3/9')
    expect(ratio(f)).toBe(2 / 9)
  })

  test('fields left out keep their value', () => {
    const a = merge(null, { title: 'A', phase: 'crap', tasks: [{ title: 't', agent: 'crap-agent', after: [] }] })
    const b = merge(a, { phase: 'review' })
    expect(b.title).toBe('A')
    expect(b.tasks).toEqual(a.tasks)
    expect(b.phase).toBe('review')
  })

  test('a new title starts over', () => {
    const a = merge(null, { title: 'A', phase: 'review', tasks: [{ title: 't', agent: '', after: [] }] })
    const b = merge(a, { title: 'B' })
    expect(b.phase).toBe('setup')
    expect(b.tasks).toEqual([])
  })

  test('finished fills the bar', () => {
    const f = merge(null, { title: 'A', phase: 'review', finished: true })
    expect(ratio(f)).toBe(1)
    expect(label(f)).toBe('done')
  })
})

describe('applyStep', () => {
  const run = { stepDone: 1, stepTotal: 4, stepNote: 'old' }

  test('takes valid counts and clamps done to total', () => {
    expect(applyStep(run, { done: 9, total: 5, note: 'parse' })).toEqual({ stepDone: 5, stepTotal: 5, stepNote: 'parse' })
  })

  test('ignores fields of the wrong type and keeps the old counts', () => {
    expect(applyStep(run, { done: 'x', total: -3, note: 7 })).toEqual({ stepDone: 1, stepTotal: 4, stepNote: undefined })
  })

  test('caps a huge total and a long note', () => {
    const s = applyStep({}, { done: 2, total: 1e9, note: 'n'.repeat(500) })
    expect(s.stepTotal).toBe(MAX_STEPS)
    expect(s.stepNote?.length).toBe(MAX_NOTE)
  })
})
