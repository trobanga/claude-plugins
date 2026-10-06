#!/usr/bin/env bash
# A teaching workspace with a mission, resources and one lesson whose next
# card is still a `soon` placeholder.
set -euo pipefail

mkdir -p lessons learning-records

cat > MISSION.md <<'EOF'
# Mission: Elixir

## Why
Ship a Phoenix LiveView app that tracks my climbing sessions, by March.

## Success looks like
- I write and test the session-logging context myself.
- I read a stack trace and find the failing clause.

## Constraints
- 30 minutes on weekday evenings.
- I know Python well; no functional programming yet.

## Out of scope
- OTP internals, clustering.
EOF

cat > RESOURCES.md <<'EOF'
# Elixir Resources

## Knowledge

- [Elixir getting-started guide: Pattern matching](https://hexdocs.pm/elixir/pattern-matching.html)
  Official guide. Use for: match operator, pin operator.
- [Elixir getting-started guide: Enumerables and streams](https://hexdocs.pm/elixir/enumerable-and-streams.html)
  Official guide, includes the pipe operator. Use for: Enum, |>, lazy streams.
- [Kernel.|>/2](https://hexdocs.pm/elixir/Kernel.html#%7C%3E/2)
  Reference for the pipe operator.

## Wisdom (Communities)

- [Elixir Forum](https://elixirforum.com)
  Well-moderated official forum. Use for: code review, idiom questions.
EOF

cat > NOTES.md <<'EOF'
# Notes

- Palette: --ink #1f1b2e, --muted #6b6680, --rule #e4e0ec, --bg #fbfaf7, --accent #6d3fb3.
- Prefers short lessons with one runnable iex snippet.
EOF

cat > learning-records/0001-match-operator.md <<'EOF'
# The `=` operator matches, it does not assign

The learner rewrote `{:ok, user} = fetch(id)` by hand and explained why a `{:error, _}` return raises a MatchError. Next: chain transformations without temporary variables.
EOF

cat > lessons/0001-pattern-matching.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Lesson 01 · Pattern matching</title>
<style>
:root{--ink:#1f1b2e;--muted:#6b6680;--rule:#e4e0ec;--bg:#fbfaf7;--accent:#6d3fb3}
body{font:17px/1.6 Georgia,serif;color:var(--ink);background:var(--bg);max-width:42rem;margin:3rem auto;padding:0 1rem}
.nextnav{margin-top:2.6rem}
.nextnav-card{display:flex;gap:1rem;border:1px solid var(--rule);border-radius:12px;padding:1rem 1.2rem;text-decoration:none;color:inherit}
.nextnav-card.soon{background:#f5f3ef;border-style:dashed}
</style>
</head>
<body>
<p>Lesson 01 · Elixir</p>
<h1>Pattern matching</h1>
<p>In Elixir, <code>=</code> is the match operator. <a href="https://hexdocs.pm/elixir/pattern-matching.html">[1]</a></p>
<pre class="code"><code>{:ok, user} = {:ok, "ana"}</code></pre>
<p>Ask your teacher about anything that is unclear.</p>
<nav class="nextnav">
  <span class="nextnav-label">Next lesson</span>
  <span class="nextnav-card soon">
    <span class="nextnav-n">02</span>
    <span class="nextnav-t">Coming next<small>Not built yet — ask your teacher to generate it.</small></span>
  </span>
</nav>
</body>
</html>
EOF

cat > lessons/index.html <<'EOF'
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Elixir · Lessons</title></head>
<body>
<h1>Elixir lessons</h1>
<ol>
  <li><a href="0001-pattern-matching.html">01 · Pattern matching</a> — the match operator. <strong>(frontier)</strong></li>
</ol>
</body>
</html>
EOF
