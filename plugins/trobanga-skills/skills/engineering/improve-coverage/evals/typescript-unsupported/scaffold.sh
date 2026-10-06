#!/usr/bin/env bash
# Builds a TypeScript repository: main is origin/main, the branch "feature"
# makes the slug length of slugify() configurable. TypeScript is not a
# project type the skill supports.
set -euo pipefail

g() { git -c user.name=eval -c user.email=eval@example.com "$@"; }

git init -q -b main .
printf 'node_modules/\ncoverage/\n' > .gitignore

cat > package.json <<'EOF'
{
  "name": "slugs",
  "version": "1.0.0",
  "type": "module",
  "scripts": { "test": "vitest run" },
  "devDependencies": {
    "vitest": "^2.1.0",
    "@vitest/coverage-istanbul": "^2.1.0"
  }
}
EOF

cat > vitest.config.ts <<'EOF'
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: { coverage: { provider: "istanbul", reporter: ["json"] } },
});
EOF

mkdir -p src

# ---- base version (origin/main) ----
cat > src/slug.ts <<'EOF'
export function slugify(title: string): string {
  let s = title.toLowerCase().trim();
  s = s.replace(/[^a-z0-9]+/g, "-");
  if (s.length > 40) {
    s = s.slice(0, 40);
  }
  if (s.startsWith("-")) {
    s = s.slice(1);
  }
  if (s.endsWith("-")) {
    s = s.slice(0, -1);
  }
  if (s === "") {
    return "untitled";
  }
  return s;
}
EOF

cat > src/slug.test.ts <<'EOF'
import { expect, it } from "vitest";
import { slugify } from "./slug";

it.each(["Hello World", "a b", "Release 2", "Q3 plan", "Tea"])(
  "slugifies %j",
  (title) => expect(slugify(title)).toMatch(/^[a-z0-9-]+$/),
);
EOF

g add -A
g commit -q -m "Slugs for titles"
git update-ref refs/remotes/origin/main HEAD

git checkout -q -b feature

# ---- branch version (HEAD), same line count ----
cat > src/slug.ts <<'EOF'
export function slugify(title: string, max: number): string {
  let s = title.toLowerCase().trim();
  s = s.replace(/[^a-z0-9]+/g, "-");
  if (max > 0 && s.length > max) {
    s = s.slice(0, max);
  }
  if (s.startsWith("-")) {
    s = s.slice(1);
  }
  if (s.endsWith("-")) {
    s = s.slice(0, -1);
  }
  if (s === "") {
    return "untitled";
  }
  return s;
}
EOF

cat > src/slug.test.ts <<'EOF'
import { expect, it } from "vitest";
import { slugify } from "./slug";

it.each(["Hello World", "a b", "Release 2", "Q3 plan", "Tea"])(
  "slugifies %j",
  (title) => expect(slugify(title, 40)).toMatch(/^[a-z0-9-]+$/),
);
EOF

g add -A
g commit -q -m "Make the slug length configurable"
