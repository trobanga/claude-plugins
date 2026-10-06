#!/usr/bin/env bash
# Builds a two-context repo: a CONTEXT-MAP.md at the root and one
# GLOSSARY.md per context, no root GLOSSARY.md.
set -euo pipefail

mkdir -p src/lending src/billing

cat > CONTEXT-MAP.md <<'EOF'
# Context Map

## Contexts

- [Lending](./src/lending/GLOSSARY.md) — Members borrow and return tools
- [Billing](./src/billing/GLOSSARY.md) — monthly membership charges and penalties

## Relationships

- **Lending → Billing**: Lending publishes `LoanClosed`; Billing consumes it.
EOF

cat > src/lending/GLOSSARY.md <<'EOF'
# Lending

Members borrow tools from the library and return them.

## Language

**Member**:
A person who pays a monthly fee and may borrow tools.
_Avoid_: User, account

**Loan**:
One borrowing of one tool by one Member, from pickup to return.
_Avoid_: Checkout, rental
EOF

cat > src/billing/GLOSSARY.md <<'EOF'
# Billing

Charges Members for their membership and for penalties.

## Language

**Invoice**:
The monthly document listing everything a Member owes for that month.
_Avoid_: Bill, statement
EOF

cat > src/billing/penalties.py <<'EOF'
def late_charge_cents(days_late: int) -> int:
    return 200 * days_late
EOF
