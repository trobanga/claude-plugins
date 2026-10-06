# webshop

Write clean, maintainable, well-structured code.

- HTTP routes are registered in `src/server/routes.ts`.
- Never use `var`; use `const` or `let`.
- Run `npm test` before every commit.
- Before you change payment code, read `docs/payments.md`.
- Database migrations: create them with `npm run migrate:new <name>`, never
  edit an applied migration, and run `npm run migrate` against the local
  database before the tests.
- Always run `npm test` before you commit.
