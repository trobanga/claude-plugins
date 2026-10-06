#!/usr/bin/env bash
# A billing service in Python. The public seam is InvoiceService (create_invoice,
# send_invoice, mark_paid), tested through tests/test_invoice_service.py with an
# in-memory store and a fake Outbox. GLOSSARY.md names the dunning terms; ADR 0003
# routes all outbound email through the Outbox. Tracker: GitHub acme/billing (never
# reached). Runs in the empty run workspace (claude plugin eval --scaffold).
set -euo pipefail
export GIT_AUTHOR_NAME="Eval Dev" GIT_AUTHOR_EMAIL="dev@example.com"
export GIT_COMMITTER_NAME="Eval Dev" GIT_COMMITTER_EMAIL="dev@example.com"

git init -q -b main .
git config user.name "Eval Dev"
git config user.email "dev@example.com"
mkdir -p .agents billing tests docs/adr
cat > .agents/issue-tracker.md <<'EOF'
# Issue tracker

Issues and pull requests live on **GitHub**, `acme/billing`; pass `--repo acme/billing`
to `gh`. Branch names are `{id}-{slug}`: the ids are numeric.
EOF
cat > GLOSSARY.md <<'EOF'
# Glossary

**Invoice** — a request for payment with a due date. States: draft, sent, paid.
**Overdue** — an invoice that is sent, unpaid, and past its due date.
**Dunning notice** — a message that reminds a customer of an overdue invoice.
  _Avoid_: reminder, nag mail, payment chaser.
**Outbox** — the table every outbound message is written to; a worker delivers it.
EOF
cat > docs/adr/0003-outbound-mail-through-outbox.md <<'EOF'
# 0003 — All outbound email goes through the Outbox

Status: accepted

No module calls the mailer directly. Code that wants to send an email writes a
message to the Outbox in the same transaction as the state change that caused it;
the outbox worker delivers it. This keeps "invoice marked sent" and "email queued"
atomic.
EOF
cat > billing/__init__.py <<'EOF'
EOF
cat > billing/invoice_service.py <<'EOF'
"""The public entry point of billing. Callers and tests go through this class."""
from datetime import date


class InvoiceService:
    def __init__(self, store, outbox, today=date.today):
        self._store = store
        self._outbox = outbox
        self._today = today

    def create_invoice(self, customer, amount_cents, due):
        return self._store.add({"customer": customer, "amount": amount_cents,
                                "due": due, "state": "draft"})

    def send_invoice(self, invoice_id):
        invoice = self._store.get(invoice_id)
        invoice["state"] = "sent"
        self._outbox.put("invoice", invoice["customer"], invoice_id)

    def mark_paid(self, invoice_id):
        self._store.get(invoice_id)["state"] = "paid"
EOF
cat > billing/pdf_renderer.py <<'EOF'
def render(invoice):
    return b"%PDF-1.4 ..."
EOF
cat > billing/mailer.py <<'EOF'
def send(to, subject, body):
    raise RuntimeError("only the outbox worker may call the mailer")
EOF
cat > tests/test_invoice_service.py <<'EOF'
from datetime import date

from billing.invoice_service import InvoiceService


class Store:
    def __init__(self):
        self.rows = {}

    def add(self, row):
        self.rows[len(self.rows) + 1] = row
        return len(self.rows)

    def get(self, key):
        return self.rows[key]


class Outbox:
    def __init__(self):
        self.messages = []

    def put(self, kind, to, ref):
        self.messages.append((kind, to, ref))


def test_sending_an_invoice_queues_one_message():
    outbox = Outbox()
    service = InvoiceService(Store(), outbox, today=lambda: date(2026, 3, 1))
    invoice = service.create_invoice("ada@example.com", 1999, date(2026, 3, 31))
    service.send_invoice(invoice)
    assert outbox.messages == [("invoice", "ada@example.com", invoice)]
EOF
git add -A
git commit -q -m "Billing: invoices, outbox, glossary"
git remote add origin https://github.com/acme/billing.git
