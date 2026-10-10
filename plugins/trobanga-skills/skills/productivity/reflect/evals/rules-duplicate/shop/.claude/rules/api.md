---
paths:
  - "src/api/**/*.ts"
---

# API handlers

- Validate every request body with the zod schema from `src/api/schemas.ts`
  before you use it; on failure, answer 400 with the zod issues.
