# billing

Invoicing service for the shop. Go 1.23, Postgres 16.

## Commands

- Build: `make build`
- Test: `make test`
- Lint: `make lint`
- Run locally: `make run`

## General principles

- Write clean, readable code.
- Follow best practices.
- Keep functions small.
- Be careful with money.
- Think before you code.
- Prefer simple solutions.

## Invoices

- Code for invoices lives in `internal/invoices/`.
- Write tests for every change to invoices.
- Keep the invoices code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about invoices.

## Credit notes

- Code for credit notes lives in `internal/creditnotes/`.
- Write tests for every change to credit notes.
- Keep the credit notes code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about credit notes.

## Tax

- Code for tax lives in `internal/tax/`.
- Write tests for every change to tax.
- Keep the tax code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about tax.

## Currencies

- Code for currencies lives in `internal/currencies/`.
- Write tests for every change to currencies.
- Keep the currencies code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about currencies.

## Payment terms

- Code for payment terms lives in `internal/paymentterms/`.
- Write tests for every change to payment terms.
- Keep the payment terms code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about payment terms.

## Dunning

- Code for dunning lives in `internal/dunning/`.
- Write tests for every change to dunning.
- Keep the dunning code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about dunning.

## Exports

- Code for exports lives in `internal/exports/`.
- Write tests for every change to exports.
- Keep the exports code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about exports.

## Webhooks

- Code for webhooks lives in `internal/webhooks/`.
- Write tests for every change to webhooks.
- Keep the webhooks code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about webhooks.

## Pdf rendering

- Code for PDF rendering lives in `internal/PDFrendering/`.
- Write tests for every change to PDF rendering.
- Keep the PDF rendering code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about PDF rendering.

## Numbering

- Code for numbering lives in `internal/numbering/`.
- Write tests for every change to numbering.
- Keep the numbering code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about numbering.

## Audit log

- Code for audit log lives in `internal/auditlog/`.
- Write tests for every change to audit log.
- Keep the audit log code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about audit log.

## Retries

- Code for retries lives in `internal/retries/`.
- Write tests for every change to retries.
- Keep the retries code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about retries.

## Time zones

- Code for time zones lives in `internal/timezones/`.
- Write tests for every change to time zones.
- Keep the time zones code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about time zones.

## Rounding

- Code for rounding lives in `internal/rounding/`.
- Write tests for every change to rounding.
- Keep the rounding code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about rounding.

## Customers

- Code for customers lives in `internal/customers/`.
- Write tests for every change to customers.
- Keep the customers code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about customers.

## Discounts

- Code for discounts lives in `internal/discounts/`.
- Write tests for every change to discounts.
- Keep the discounts code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about discounts.

## Subscriptions

- Code for subscriptions lives in `internal/subscriptions/`.
- Write tests for every change to subscriptions.
- Keep the subscriptions code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about subscriptions.

## Refunds

- Code for refunds lives in `internal/refunds/`.
- Write tests for every change to refunds.
- Keep the refunds code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about refunds.

## Reports

- Code for reports lives in `internal/reports/`.
- Write tests for every change to reports.
- Keep the reports code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about reports.

## Migrations

- Code for migrations lives in `internal/migrations/`.
- Write tests for every change to migrations.
- Keep the migrations code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about migrations.

## Feature flags

- Code for feature flags lives in `internal/featureflags/`.
- Write tests for every change to feature flags.
- Keep the feature flags code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about feature flags.

## Logging

- Code for logging lives in `internal/logging/`.
- Write tests for every change to logging.
- Keep the logging code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about logging.

## Metrics

- Code for metrics lives in `internal/metrics/`.
- Write tests for every change to metrics.
- Keep the metrics code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about metrics.

## Errors

- Code for errors lives in `internal/errors/`.
- Write tests for every change to errors.
- Keep the errors code clean and well documented.
- Use `decimal.Decimal` for amounts, never float64.
- Ask the team if you are unsure about errors.
