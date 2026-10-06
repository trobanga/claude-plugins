# Incident 2026-09-30: members charged twice for late fees

Timeline (all times CEST)

- 09:12 First support ticket: Member charged 6 EUR twice for one late Loan.
- 09:40 31 more tickets. Billing paused the late-fee run.
- 10:05 Found it: `billing/payments.py`, `PaymentClient.charge()` retries on
  every non-2xx response, three times, with backoff.
- 10:20 The provider answers **409 Conflict** when the idempotency key was
  already used, i.e. the charge already went through. We retried on 409 and
  sent a *new* idempotency key on each retry, so the provider charged again.
- 10:45 Refunds issued for 32 Members by hand.

Findings

- Retrying on 5xx and timeouts is right and must stay.
- A 409 means "already charged": treat it as success, never retry it.
- Each retry must reuse the first attempt's idempotency key.

Open question for later (not part of the fix): should we alert on-call
when a late-fee run sees more than 10 failures?
