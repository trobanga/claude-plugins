# Payments

All amounts are integers in cents. Refunds go through `src/http/refunds.ts`,
which calls the provider and writes a `refund` row in one transaction.
