#!/usr/bin/env bash
# A teaching workspace with a mission, two learning records and one lesson.
set -euo pipefail

mkdir -p lessons learning-records

cat > MISSION.md <<'EOF'
# Mission: Elixir

## Why
Move our team's notification service from Node.js to Elixir by Q2, and own its supervision tree.

## Success looks like
- I design the supervision tree for the notification workers.
- I write a GenServer that rate-limits outbound pushes.

## Constraints
- One hour per day.

## Out of scope
- Phoenix front-end work.
EOF

cat > RESOURCES.md <<'EOF'
# Elixir Resources

## Knowledge

- [Elixir guide: GenServer](https://hexdocs.pm/elixir/genservers.html)
  Official guide. Use for: call, cast, handle_info, state.
- [Elixir guide: Supervisor and Application](https://hexdocs.pm/elixir/supervisor-and-application.html)
  Official guide. Use for: child specs, restart strategies.

## Wisdom (Communities)

- [Elixir Forum](https://elixirforum.com)
  Well-moderated official forum. Use for: design review of supervision trees.
EOF

cat > learning-records/0001-immutability.md <<'EOF'
# Data is immutable; rebinding is not mutation

The learner explained why `list = [0 | list]` leaves other references unchanged. Next: processes as the unit of state.
EOF

cat > learning-records/0002-processes-are-cheap.md <<'EOF'
# Processes are cheap and isolated

The learner spawned 10,000 processes in iex and explained why one crash does not take the others down. Next: hold state in a process.
EOF

cat > lessons/0001-immutable-data.html <<'EOF'
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Lesson 01 · Immutable data</title></head>
<body>
<h1>Immutable data</h1>
<p>Ask your teacher about anything that is unclear.</p>
<nav class="nextnav">
  <span class="nextnav-label">Next lesson</span>
  <span class="nextnav-card soon"><span class="nextnav-n">02</span>
  <span class="nextnav-t">Coming next<small>Not built yet — ask your teacher to generate it.</small></span></span>
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
  <li><a href="0001-immutable-data.html">01 · Immutable data</a> <strong>(frontier)</strong></li>
</ol>
</body>
</html>
EOF
