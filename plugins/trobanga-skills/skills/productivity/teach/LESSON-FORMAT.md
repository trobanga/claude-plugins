# Lesson Format

Lessons live in `./lessons/` as `NNNN-<dash-case-name>.html`, where `NNNN` increments
(`0001`, `0002`, …). A lesson is **one self-contained HTML file** — all CSS and JS inlined,
no external assets — so it opens with a single command and prints well. It teaches ONE thing
tied to the mission, in the user's zone of proximal development.

This document defines the required anatomy of a lesson and, in particular, the navigation that
links lessons into a coherent course.

## Anatomy

Every lesson should contain, in order:

1. **Header** — kicker (`Lesson NN · {Topic}`), title, one-line subtitle, rough time-to-complete.
2. **The win** — a short highlighted box stating the tangible thing the user can do by the end.
3. **Knowledge** — only what the skill requires, with **citations** (footnote links to sources in `RESOURCES.md`).
4. **Skill practice** — an interactive feedback loop: a checklist of real steps, and/or a quiz
   graded instantly by inlined JS. Feedback must be immediate.
5. **Ask your teacher** — a reminder that the agent is their teacher and can help with anything unclear.
6. **Citations** — a footnote list backing every claim, plus a link to the workspace glossary.
7. **Navigation** — prev/next block (see below). Always last, just before or after the footer.

## Navigation (required)

Two layers, both kept in sync whenever a lesson is added:

### a. Per-lesson prev/next block

Inlined at the bottom of every lesson. The **next** card links to `NNNN+1-*.html`. When the next
lesson does not exist yet, render it as a non-link `soon` placeholder — **never a dead link**.
A `prev` back-link points to `NNNN-1-*.html` (omit on the first lesson).

Reusable snippet — inline this CSS in the lesson's `<style>`:

```css
.nextnav{margin-top:2.6rem}
.nextnav-label{font:600 .7rem/1 ui-sans-serif,system-ui,sans-serif;letter-spacing:.14em;
  text-transform:uppercase;color:var(--muted);display:block;margin-bottom:.5rem}
.nextnav-card{display:flex;align-items:center;gap:1rem;text-decoration:none;color:inherit;
  border:1px solid var(--rule);border-radius:12px;padding:1rem 1.2rem;background:#fff;transition:.15s}
.nextnav-card:hover{border-color:var(--accent);box-shadow:0 2px 10px rgba(0,0,0,.10);transform:translateY(-1px)}
.nextnav-n{font:700 1rem ui-sans-serif,system-ui,sans-serif;color:#fff;background:var(--accent);
  width:2.4em;height:2.4em;border-radius:10px;display:flex;align-items:center;justify-content:center;flex:none}
.nextnav-t{flex:1;font-weight:700;font-size:1.05rem}
.nextnav-t small{display:block;font-weight:400;font-size:.85rem;color:var(--muted);margin-top:.15rem}
.nextnav-arrow{font-size:1.4rem;color:var(--accent);flex:none}
.nextnav-card.soon{cursor:default;background:#f5f3ef;border-style:dashed}
.nextnav-card.soon:hover{border-color:var(--rule);box-shadow:none;transform:none}
.nextnav-card.soon .nextnav-n,.nextnav-card.soon .nextnav-arrow{background:var(--muted);color:var(--muted)}
.nextnav-card.soon .nextnav-n{color:#fff}
.prevnav{margin-top:1rem;font:.85rem ui-sans-serif,system-ui,sans-serif}
.prevnav a{color:var(--muted);text-decoration:none}.prevnav a:hover{color:var(--accent)}
@media print{.nextnav,.prevnav{display:none}}
```

And the markup (next exists):

```html
<nav class="nextnav">
  <span class="nextnav-label">Next lesson</span>
  <a class="nextnav-card" href="0003-some-slug.html">
    <span class="nextnav-n">03</span>
    <span class="nextnav-t">Lesson title<small>One-line teaser.</small></span>
    <span class="nextnav-arrow">→</span>
  </a>
  <div class="prevnav">← Previous: <a href="0001-prev-slug.html">01 · Previous title</a></div>
</nav>
```

When the next lesson does not exist yet, swap the `<a class="nextnav-card" href=…>` for a
`<span class="nextnav-card soon">` (no `href`) whose teaser reads e.g. *"Not built yet — ask
your teacher to generate it."*

### b. Course index

Keep `./lessons/index.html` — a self-contained contents page listing every lesson in order
(number, title, one-line teaser, link), with the current frontier marked. It is the robust
source of truth and survives missed backfills. Regenerate it whenever a lesson is added.

## The backfill rule (do not skip)

Creating lesson **N** is not finished until you have:

1. Built `NNNN-*.html` with its own `next` card as a `soon` placeholder (N+1 doesn't exist yet)
   and a `prev` link to N−1.
2. **Edited lesson N−1** to flip its `soon` placeholder into a real `<a>` link to lesson N.
3. **Regenerated `./lessons/index.html`** to include lesson N.

Step 2 is the one most easily forgotten — a lesson left with a stale `soon` card is a broken
course. Treat it as part of "create a lesson", not an optional follow-up.

## Code blocks (copy button — required)

Every code block (`<pre class="code">`) must carry a **copy button** so the user can lift a snippet
in one click. The button injects itself via inlined JS over all code blocks on load — authors just
write `<pre class="code">` as usual; no per-block markup needed. It stays self-contained (no deps),
works from `file://` (clipboard API with a `execCommand` fallback), and is hidden in print.

Opt-out: a pure-output or log block that shouldn't be copied whole can be marked
`<pre class="code" data-nocopy>` — it renders without a button.

Inline this CSS in the lesson's `<style>` (it also makes `pre.code` a positioning context):

```css
pre.code{position:relative}
.copy-btn{position:absolute;top:.5rem;right:.5rem;border:1px solid #3a3350;background:#2a2438;
  color:#cbb8e6;font:600 .72rem/1 ui-sans-serif,system-ui,sans-serif;padding:.4em .6em;border-radius:7px;
  cursor:pointer;opacity:0;transition:opacity .12s,background .12s;letter-spacing:.02em}
pre.code:hover .copy-btn,.copy-btn:focus{opacity:1}
.copy-btn:hover{background:#3a3350}
.copy-btn.copied{color:#69d39b;border-color:#2e6f4e}
@media (hover:none){.copy-btn{opacity:1}}
@media print{.copy-btn{display:none}}
```

Inline this JS before `</body>` (alongside the lesson's other scripts):

```html
<script>
  (function(){
    function fallback(text, done){
      var ta = document.createElement('textarea');
      ta.value = text; ta.style.position='fixed'; ta.style.opacity='0';
      document.body.appendChild(ta); ta.focus(); ta.select();
      try{ document.execCommand('copy'); done(); }catch(e){}
      document.body.removeChild(ta);
    }
    document.querySelectorAll('pre.code:not([data-nocopy])').forEach(function(pre){
      var btn = document.createElement('button');
      btn.type = 'button'; btn.className = 'copy-btn'; btn.textContent = 'Copy';
      btn.setAttribute('aria-label', 'Copy code to clipboard');
      btn.addEventListener('click', function(){
        var text = Array.prototype.map.call(pre.querySelectorAll('code'),
          function(c){ return c.textContent; }).join('\n') || pre.textContent;
        var done = function(){ btn.textContent = 'Copied!'; btn.classList.add('copied');
          setTimeout(function(){ btn.textContent = 'Copy'; btn.classList.remove('copied'); }, 1500); };
        if(navigator.clipboard && navigator.clipboard.writeText){
          navigator.clipboard.writeText(text).then(done, function(){ fallback(text, done); });
        } else { fallback(text, done); }
      });
      pre.appendChild(btn);
    });
  })();
</script>
```

The button reads from the inner `<code>` element(s), so syntax-highlight spans are stripped to plain
text and the button's own label never leaks into the copied string.

## Glossary term tooltips (required)

Every glossary term that appears in a lesson's **prose** links to its glossary entry, with a
hover/focus tooltip showing a one-line gloss (abbreviations spelled out) and clicking it jumps to
`glossary.html#id`. This is how a learner meets "OTP" or "RPE" mid-sentence and resolves it without
leaving the page. It runs on top of the existing "glossary reachable from every page" rule.

It is delivered by a **shared pair in `reference/`** (the one allowed exception to the inline rule):

- **`reference/glossify.js`** — the generic engine. Copied **verbatim** from the skill's
  `assets/glossify.js`; never hand-edit per workspace. It carries no term data.
- **`reference/glossary-terms.js`** — the term bank for _this_ topic. Sets `self.GLOSSIFY_TERMS` to an
  array of `{ term, id, gloss }`. Rendered from `GLOSSARY.md` alongside `glossary.html`, and kept in
  sync with its `<dt id>` anchors (see GLOSSARY-FORMAT.md).

Each lesson (and `index.html`) includes both, in this order, before `</body>` alongside the other
scripts — terms first so the engine sees them:

```html
<script src="../reference/glossary-terms.js" defer></script>
<script src="../reference/glossify.js" defer></script>
```

For this to resolve, `reference/glossary.html` must give every linkable term a stable anchor:
`<dt id="otp">OTP …</dt>`, and each `glossary-terms.js` entry's `id` must match one.

Behaviour, for authors:
- **Prose only.** The engine skips `<code>`, `<pre>`, and existing `<a>`, so code samples and links are
  never rewritten. A term you want linked must appear as plain prose text somewhere.
- **Case-sensitive, whole-word, longest-match, every occurrence.** "OTP" won't match inside "OTPX";
  "delta-CRDT" wins over the "CRDT" inside it. Only add surfaces distinctive enough not to false-match
  ordinary English — skip common words.
- **Degrades cleanly.** No JS / print → plain text (the dotted underline and tooltip drop out); a lesson
  opened without the `reference/` folder simply shows unlinked prose.

Bootstrapping a workspace: copy `assets/glossify.js` → `reference/glossify.js`, copy
`assets/glossary-terms.example.js` → `reference/glossary-terms.js` and replace its entries. The engine
ships with `assets/glossify.test.js` (`node --test`) — keep it green if you ever touch the engine.

## Favicon (required)

Every lesson and the index carry the same **inlined SVG favicon** — a data-URI `<link rel="icon">`
in `<head>` (no external `.ico`, keeping the self-contained rule). It uses the workspace accent colour
so tabs read as one course. Place it right after the `<meta name="viewport">` line:

```html
<link rel="icon" href='data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><rect width="24" height="24" rx="5" fill="%236d3fb3"/><path d="M12 3.5c0 0 -5.6 7 -5.6 11a5.6 5.6 0 0 0 11.2 0c0 -4 -5.6 -11 -5.6 -11z" fill="%23fff"/></svg>'>
```

Note `#` must be percent-encoded as `%23` inside the data-URI (`%236d3fb3` = `#6d3fb3`). Swap the fill
colour / glyph per workspace, but keep it identical across every page of one course.

## Visual consistency

Lessons should read as one set. Define the same CSS custom properties at the top of each file —
at minimum `--ink`, `--muted`, `--rule`, `--bg`, `--accent` — and reuse them. Pick the palette
once for the workspace and record it in `NOTES.md`; later lessons inherit it.

## Rules

- **Self-contained, always.** Inline all CSS/JS. No shared stylesheet, no CDN — it breaks the
  one-command-open and print-to-PDF properties, and lessons are meant to outlive the workspace tooling.
  _One deliberate exception:_ the glossary-tooltip pair in `reference/` (`glossary-terms.js` +
  `glossify.js`) — see "Glossary term tooltips". It is a workspace-relative dependency, identical in
  kind to the required glossary link every lesson already carries, and a shared term bank is the point:
  grow the glossary once and every lesson (old ones included) gains the new tooltips. Do not add any
  _other_ external asset.
- **Never ship a dead link.** A not-yet-built next lesson is a `soon` placeholder, not a 404.
- **Backfill on every addition.** See above. Also update the index.
- **Navigation is not optional.** A lesson without prev/next is incomplete.
- **One palette per workspace.** Consistency signals "course", not "pile of pages".
- **Every code block gets a copy button.** Inline the copy-button CSS + JS (see "Code blocks"); it
  self-injects over all `pre.code`. Mark pure-output blocks `data-nocopy` to skip them.
- **Every page carries the inlined favicon.** Same data-URI `<link rel="icon">` on every lesson and
  the index (see "Favicon").
- **Every page wires the glossary tooltips.** Include the `glossary-terms.js` + `glossify.js` pair on
  every lesson and the index (see "Glossary term tooltips"). New glossary terms get an anchor + a
  `glossary-terms.js` entry, not a re-edit of past lessons.
