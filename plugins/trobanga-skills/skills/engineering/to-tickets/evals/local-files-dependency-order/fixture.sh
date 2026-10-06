#!/usr/bin/env bash
# A small shop: pricing logic inlined in the cart handler (a prefactoring
# opportunity), a SQL schema, an HTTP API and a cart page. Tracker none: tickets
# are kept as local Markdown files under .agents/issues/. Runs in the empty run
# workspace (claude plugin eval --scaffold).
set -euo pipefail
export GIT_AUTHOR_NAME="Eval Dev" GIT_AUTHOR_EMAIL="dev@example.com"
export GIT_COMMITTER_NAME="Eval Dev" GIT_COMMITTER_EMAIL="dev@example.com"

git init -q -b main .
git config user.name "Eval Dev"
git config user.email "dev@example.com"
mkdir -p .agents shop/api shop/web db tests
cat > .agents/issue-tracker.md <<'EOF'
# Issue tracker

**Tracker: none.** This project keeps tickets as local Markdown files under
`.agents/issues/`, one file per ticket. **Forge: none** (plain git).

Branch names are `{id}--{slug}`.
EOF
cat > GLOSSARY.md <<'EOF'
# Glossary

**Line** — one product in a cart, with a quantity.
**Unit price** — the price of one item of a product.
**Price tier** — a unit price that applies from a minimum quantity upward.
EOF
cat > db/schema.sql <<'EOF'
CREATE TABLE product (id INTEGER PRIMARY KEY, name TEXT, unit_price_cents INTEGER);
CREATE TABLE cart_line (cart_id INTEGER, product_id INTEGER, quantity INTEGER);
EOF
cat > shop/api/cart.py <<'EOF'
def cart_total(db, cart_id):
    total = 0
    for line in db.lines(cart_id):
        product = db.product(line.product_id)
        # pricing is computed inline here, and again in shop/web/cart_page.py
        total += product.unit_price_cents * line.quantity
    return total
EOF
cat > shop/web/cart_page.py <<'EOF'
def render(db, cart_id):
    rows = []
    for line in db.lines(cart_id):
        product = db.product(line.product_id)
        rows.append((product.name, line.quantity, product.unit_price_cents * line.quantity))
    return rows
EOF
echo 'def test_placeholder(): pass' > tests/test_cart.py
git add -A
git commit -q -m "Shop: cart API and page"
