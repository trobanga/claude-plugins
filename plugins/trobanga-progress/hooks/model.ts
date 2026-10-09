import type { Flow, Phase, PlannedTask } from '../types'

// Rough advance of system UI text, in em; good enough to size the title's slot.
const charEm = (ch: string): number => (/[\s.,:;'|!il1()[\]]/.test(ch) ? 0.3 : /[A-Zmw@%]/.test(ch) ? 0.72 : 0.56)

export const textWidth = (s: string, size: number): number => [...s].reduce((w, ch) => w + charEm(ch) * size, 0)

// Cuts `s` to fit `maxW` pixels, with an ellipsis when it had to cut.
export const fitText = (s: string, size: number, maxW: number): string => {
  if (textWidth(s, size) <= maxW) return s
  let out = ''
  for (const ch of s) {
    if (textWidth(out + ch + '…', size) > maxW) break
    out += ch
  }
  return out + '…'
}

// The steps of the implement skill, in order; the bar shows the position in this list.
export const PHASES: readonly Phase[] = ['setup', 'explore', 'design', 'implement', 'simplify', 'crap', 'mutants', 'review', 'ship']

export const MAX_TITLE = 80
export const MAX_TASKS = 30
export const MAX_NOTE = 60

export type ProgressInput = {
  title?: string
  phase?: Phase
  finished?: boolean
  tasks?: PlannedTask[]
}

// Tool input comes from the model: take a field only when it has the right type.
const str = (v: unknown, max: number): string | undefined =>
  typeof v === 'string' && v.trim() ? v.trim().slice(0, max) : undefined

const isPhase = (v: unknown): v is Phase => typeof v === 'string' && (PHASES as readonly string[]).includes(v)

const parseTask = (v: unknown): PlannedTask | undefined => {
  if (typeof v !== 'object' || v === null) return undefined
  const t = v as Record<string, unknown>
  const title = str(t.title, MAX_TITLE)
  if (!title) return undefined
  const after = Array.isArray(t.after) ? t.after.filter((n): n is number => Number.isInteger(n) && n > 0 && n <= MAX_TASKS) : []
  return { title, agent: str(t.agent, MAX_TITLE) ?? '', after: after.slice(0, MAX_TASKS) }
}

export const parseProgress = (raw: unknown): ProgressInput => {
  const r = typeof raw === 'object' && raw !== null ? (raw as Record<string, unknown>) : {}
  const out: ProgressInput = {}
  const title = str(r.title, MAX_TITLE)
  if (title) out.title = title
  if (isPhase(r.phase)) out.phase = r.phase
  if (typeof r.finished === 'boolean') out.finished = r.finished
  if (Array.isArray(r.tasks)) {
    out.tasks = r.tasks
      .slice(0, MAX_TASKS)
      .map(parseTask)
      .filter((t): t is PlannedTask => t !== undefined)
  }
  return out
}

export type Costume = 'astronaut' | 'detective' | 'engineer' | 'chef' | 'racer' | 'pirate' | 'other'

// `glyph` stands in for the crab on the terminal, which draws no SVG.
export type Role = { costume: Costume; color: string; glyph: string; label: string; model?: string }

const OTHER: Role = { costume: 'other', color: '#888780', glyph: '▣', label: '' }

// Each agent of trobanga-skills, its color distinct from the grey of the context bar, keyed by its bare name (the plugin prefix dropped).
// A Map, not an object literal: a type such as `toString` must not hit the prototype.
const ROLES = new Map<string, Role>([
  ['tdd-implementer-low', { costume: 'racer', color: '#1D9E75', glyph: '◆', label: 'tdd low', model: 'Sonnet · low' }],
  ['tdd-implementer-medium', { costume: 'chef', color: '#378ADD', glyph: '◆', label: 'tdd medium', model: 'Sonnet · medium' }],
  ['tdd-implementer-high', { costume: 'engineer', color: '#BA7517', glyph: '◆', label: 'tdd high', model: 'Sonnet · high' }],
  ['crap-agent', { costume: 'detective', color: '#D85A30', glyph: '◈', label: 'crap' }],
  ['mutant-agent', { costume: 'astronaut', color: '#7F77DD', glyph: '✱', label: 'mutants' }],
  ['Explore', { costume: 'pirate', color: '#0FA3B1', glyph: '◎', label: 'explore' }],
  ['code-explorer', { costume: 'pirate', color: '#0FA3B1', glyph: '◎', label: 'explore' }],
])

export const AGENTS = [...ROLES.keys()]

export const roleOf = (type: string): Role => ROLES.get(type.replace(/^[^:]*:/, '')) ?? OTHER

const blank = (): Flow => ({ title: 'implement', phase: 'setup', isFinished: false, tasks: [] })

export const isNewFlow = (prev: Flow | null, input: ProgressInput): boolean =>
  !prev || prev.isFinished || (input.title !== undefined && input.title !== prev.title)

export const merge = (prev: Flow | null, input: ProgressInput): Flow => {
  // A new title means a new flow: never carry state over from an earlier one.
  const base = !prev || isNewFlow(prev, input) ? blank() : prev
  return {
    title: input.title ?? base.title,
    phase: input.phase ?? base.phase,
    isFinished: input.finished === true,
    tasks: input.tasks ?? base.tasks,
  }
}

// Being in phase i means i phases are behind.
export const ratio = (f: Flow): number => (f.isFinished ? 1 : PHASES.indexOf(f.phase) / PHASES.length)

export const label = (f: Flow): string => (f.isFinished ? 'done' : `${f.phase} ${PHASES.indexOf(f.phase) + 1}/${PHASES.length}`)

export const MAX_STEPS = 100

export type StepState = { stepDone?: number; stepTotal?: number; stepNote?: string }

const count = (v: unknown, min: number): number | undefined =>
  typeof v === 'number' && Number.isFinite(v) && v >= min ? Math.min(MAX_STEPS, Math.round(v)) : undefined

// A worker's own report through the `step` tool; a field of the wrong type keeps the old value.
export const applyStep = (prev: StepState, raw: unknown): StepState => {
  const r = typeof raw === 'object' && raw !== null ? (raw as Record<string, unknown>) : {}
  const total = count(r.total, 1) ?? prev.stepTotal ?? 0
  const done = count(r.done, 0) ?? prev.stepDone ?? 0
  return { stepDone: total ? Math.min(total, done) : done, stepTotal: total, stepNote: str(r.note, MAX_NOTE) }
}
