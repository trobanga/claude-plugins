#!/usr/bin/env bash
# Builds a repo whose GLOSSARY.md and code both contradict the answer the
# user is about to give.
set -euo pipefail

mkdir -p src

cat > GLOSSARY.md <<'EOF'
# Lending

Members borrow tools from the library and return them.

## Language

**Loan**:
One borrowing of one tool by one Member, from pickup to return.
_Avoid_: Checkout, rental

**Reservation**:
A Member's claim on a tool that is out on Loan, to be served when it returns.

**Hold**:
The 48 hours a returned tool is kept aside for the Member whose Reservation is next.
_Avoid_: Reservation window, lock

**Cancellation**:
A Member withdrawing their own Reservation before its Hold starts.
EOF

cat > src/reservations.py <<'EOF'
from dataclasses import dataclass
from datetime import datetime


@dataclass
class Reservation:
    member_id: str
    tool_id: str
    hold_started_at: datetime | None = None


def cancel(reservation: Reservation) -> None:
    """A Member withdraws their Reservation. Only allowed before the Hold starts."""
    if reservation.hold_started_at is not None:
        raise ValueError("cannot cancel once the Hold has started")
    # delete from store ...
EOF
