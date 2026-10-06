#!/usr/bin/env bash
# A repo with two ideas: one attacks the same problem as the new idea, one
# does not.
set -euo pipefail

git init -q .
mkdir -p ideas

cat > ideas/faster-product-pages.md <<'EOF'
# Faster product pages

**Problem:** Mobile shoppers wait more than four seconds for a product page at the 95th percentile, and a third of them leave before it renders.
**Idea:** Cut the page's JavaScript bundle from 900 KB to under 200 KB by splitting it per route.

The product page ships one 900 KB bundle that a mid-range phone takes two seconds to parse. Splitting it per route and deferring the reviews widget brings the bundle under 200 KB and the 95th-percentile load under two seconds, for about two weeks of front-end work.

## Contents
- [Problem](#problem)
- [Idea](#idea)
- [Details](#details)

## Problem
Mobile shoppers on mid-range Android phones, about 60 % of traffic. At the 95th percentile the page takes 4.2 s; 33 % of these sessions end before first render.

## Idea
Split the bundle per route, lazy-load the reviews widget, and drop the date library in favour of `Intl`.

## Details
Open question: does the checkout team accept a second bundle on their route?
EOF

cat > ideas/dark-mode.md <<'EOF'
# Dark mode for the storefront

**Problem:** Shoppers who browse at night find the white storefront glaring and shorten their sessions.
**Idea:** Add a dark theme that follows the operating system setting.

Night-time sessions are 20 % shorter than daytime ones. A dark theme that follows `prefers-color-scheme` removes the glare for about a week of work.

## Contents
- [Problem](#problem)
- [Idea](#idea)
- [Details](#details)

## Problem
Evening shoppers, 35 % of sessions.

## Idea
CSS custom properties for every colour, switched by `prefers-color-scheme`.

## Details
none
EOF

git add -A
git -c user.name=fixture -c user.email=fixture@example.invalid commit -qm "Add two ideas"
