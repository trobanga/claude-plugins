#!/usr/bin/env bash
# Builds a TypeScript repository: main is origin/main, the branch "feature"
# rewrites three lines of slugify() in place. The Istanbul report in
# coverage/ was left by an old run on the base version: its line ranges
# still fit, but it is older than the changed source.
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

mkdir -p src coverage

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

# ---- report of an old run on the base version ----
cat > coverage/coverage-final.json <<'EOF'
{"/builds/acme/slugs/src/slug.ts":{"path":"/builds/acme/slugs/src/slug.ts","statementMap":{"0":{"start":{"line":2,"column":2},"end":{"line":2,"column":80}},"1":{"start":{"line":3,"column":2},"end":{"line":3,"column":80}},"2":{"start":{"line":4,"column":2},"end":{"line":4,"column":80}},"3":{"start":{"line":5,"column":2},"end":{"line":5,"column":80}},"4":{"start":{"line":7,"column":2},"end":{"line":7,"column":80}},"5":{"start":{"line":8,"column":2},"end":{"line":8,"column":80}},"6":{"start":{"line":10,"column":2},"end":{"line":10,"column":80}},"7":{"start":{"line":11,"column":2},"end":{"line":11,"column":80}},"8":{"start":{"line":13,"column":2},"end":{"line":13,"column":80}},"9":{"start":{"line":14,"column":2},"end":{"line":14,"column":80}},"10":{"start":{"line":16,"column":2},"end":{"line":16,"column":80}}},"fnMap":{"0":{"name":"slugify","decl":{"start":{"line":1,"column":0},"end":{"line":1,"column":80}},"loc":{"start":{"line":1,"column":0},"end":{"line":17,"column":1}},"line":1}},"branchMap":{"0":{"loc":{"start":{"line":4,"column":0},"end":{"line":4,"column":80}},"type":"if","locations":[{"start":{"line":4,"column":0},"end":{"line":4,"column":80}},{"start":{"line":4,"column":0},"end":{"line":4,"column":80}}],"line":4},"1":{"loc":{"start":{"line":7,"column":0},"end":{"line":7,"column":80}},"type":"if","locations":[{"start":{"line":7,"column":0},"end":{"line":7,"column":80}},{"start":{"line":7,"column":0},"end":{"line":7,"column":80}}],"line":7},"2":{"loc":{"start":{"line":10,"column":0},"end":{"line":10,"column":80}},"type":"if","locations":[{"start":{"line":10,"column":0},"end":{"line":10,"column":80}},{"start":{"line":10,"column":0},"end":{"line":10,"column":80}}],"line":10},"3":{"loc":{"start":{"line":13,"column":0},"end":{"line":13,"column":80}},"type":"if","locations":[{"start":{"line":13,"column":0},"end":{"line":13,"column":80}},{"start":{"line":13,"column":0},"end":{"line":13,"column":80}}],"line":13}},"s":{"0":5,"1":5,"2":5,"3":0,"4":5,"5":0,"6":5,"7":0,"8":5,"9":0,"10":5},"f":{"0":5},"b":{"0":[0,5],"1":[0,5],"2":[0,5],"3":[0,5]}}}
EOF
touch -d '2001-01-01 00:00:00' coverage/coverage-final.json

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
