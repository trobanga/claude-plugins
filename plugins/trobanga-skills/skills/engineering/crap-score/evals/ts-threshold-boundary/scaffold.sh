#!/usr/bin/env bash
# Builds a TypeScript repository: main is origin/main, the branch "feature"
# adds a guard to normalize() and an empty-line check to splitFields() in
# src/parse.ts. legacyDecode() in the same file is untouched. The Istanbul
# report describes HEAD and is newer than every source.
set -euo pipefail

g() { git -c user.name=eval -c user.email=eval@example.com "$@"; }

git init -q -b main .
printf 'node_modules/\ncoverage/\n' > .gitignore

cat > package.json <<'EOF'
{
  "name": "csv-tools",
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
cat > src/parse.ts <<'EOF'
export function legacyDecode(raw: string): string {
  if (raw.startsWith("~")) {
    return raw.slice(1);
  }
  if (raw.includes("%")) {
    return decodeURIComponent(raw);
  }
  if (raw.length > 80) {
    return raw.slice(0, 80);
  }
  if (raw === "-") {
    return "";
  }
  return raw;
}

export function normalize(field: string): string {
  let s = field.trim();
  if (s.startsWith('"')) s = s.slice(1);
  if (s.endsWith('"')) s = s.slice(0, -1);
  if (s === "NULL") s = "";
  if (s === "N/A") s = "";
  if (s.includes("\t")) s = s.replace(/\t/g, " ");
  if (s.length > 255) s = s.slice(0, 255);
  return s;
}

export function splitFields(line: string, sep = ","): string[] {
  return line.split(sep).map(normalize);
}
EOF

cat > src/parse.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import { normalize, splitFields } from "./parse";

describe("normalize", () => {
  it("strips quotes", () => expect(normalize('"a"')).toBe("a"));
  it("maps NULL to empty", () => expect(normalize("NULL")).toBe(""));
});

describe("splitFields", () => {
  it("splits on commas", () => expect(splitFields("a,b")).toEqual(["a", "b"]));
});
EOF

g add -A
g commit -q -m "CSV field parsing"
git update-ref refs/remotes/origin/main HEAD
git checkout -q -b feature

# ---- branch version (HEAD) ----
cat > src/parse.ts <<'EOF'
export function legacyDecode(raw: string): string {
  if (raw.startsWith("~")) {
    return raw.slice(1);
  }
  if (raw.includes("%")) {
    return decodeURIComponent(raw);
  }
  if (raw.length > 80) {
    return raw.slice(0, 80);
  }
  if (raw === "-") {
    return "";
  }
  return raw;
}

export function normalize(field: string): string {
  let s = field.trim();
  if (s.startsWith('"')) s = s.slice(1);
  if (s.endsWith('"')) s = s.slice(0, -1);
  if (s === "NULL") s = "";
  if (s === "N/A") s = "";
  if (s.includes("\t")) s = s.replace(/\t/g, " ");
  if (s.length > 255) s = s.slice(0, 255);
  if (s.startsWith("=")) s = "'" + s;
  return s;
}

export function splitFields(line: string, sep = ","): string[] {
  if (line === "") {
    return [];
  }
  return line.split(sep).map(normalize);
}
EOF

cat > src/parse.test.ts <<'EOF'
import { describe, expect, it } from "vitest";
import { normalize, splitFields } from "./parse";

describe("normalize", () => {
  it.each([
    ['"a"', "a"],
    ["NULL", ""],
    ["N/A", ""],
    ["a\tb", "a b"],
    ["x".repeat(300), "x".repeat(255)],
    ["=SUM(A1)", "'=SUM(A1)"],
  ])("normalize(%j) is %j", (input, expected) => {
    expect(normalize(input)).toBe(expected);
  });
});

describe("splitFields", () => {
  it("splits on commas", () => expect(splitFields("a,b")).toEqual(["a", "b"]));
});
EOF

g add -A
g commit -q -m "Guard against formula injection, accept empty lines"

# ---- Istanbul report for HEAD, written after the sources ----
mkdir -p coverage
cat > coverage/coverage-final.json <<'EOF'
{"/builds/acme/csv-tools/src/parse.ts":{"path":"/builds/acme/csv-tools/src/parse.ts","statementMap":{"0":{"start":{"line":2,"column":2},"end":{"line":2,"column":80}},"1":{"start":{"line":3,"column":2},"end":{"line":3,"column":80}},"2":{"start":{"line":5,"column":2},"end":{"line":5,"column":80}},"3":{"start":{"line":6,"column":2},"end":{"line":6,"column":80}},"4":{"start":{"line":8,"column":2},"end":{"line":8,"column":80}},"5":{"start":{"line":9,"column":2},"end":{"line":9,"column":80}},"6":{"start":{"line":11,"column":2},"end":{"line":11,"column":80}},"7":{"start":{"line":12,"column":2},"end":{"line":12,"column":80}},"8":{"start":{"line":14,"column":2},"end":{"line":14,"column":80}},"9":{"start":{"line":18,"column":2},"end":{"line":18,"column":80}},"10":{"start":{"line":19,"column":2},"end":{"line":19,"column":80}},"11":{"start":{"line":20,"column":2},"end":{"line":20,"column":80}},"12":{"start":{"line":21,"column":2},"end":{"line":21,"column":80}},"13":{"start":{"line":22,"column":2},"end":{"line":22,"column":80}},"14":{"start":{"line":23,"column":2},"end":{"line":23,"column":80}},"15":{"start":{"line":24,"column":2},"end":{"line":24,"column":80}},"16":{"start":{"line":25,"column":2},"end":{"line":25,"column":80}},"17":{"start":{"line":26,"column":2},"end":{"line":26,"column":80}},"18":{"start":{"line":30,"column":2},"end":{"line":30,"column":80}},"19":{"start":{"line":31,"column":2},"end":{"line":31,"column":80}},"20":{"start":{"line":33,"column":2},"end":{"line":33,"column":80}}},"fnMap":{"0":{"name":"legacyDecode","decl":{"start":{"line":1,"column":0},"end":{"line":1,"column":80}},"loc":{"start":{"line":1,"column":0},"end":{"line":15,"column":1}},"line":1},"1":{"name":"normalize","decl":{"start":{"line":17,"column":0},"end":{"line":17,"column":80}},"loc":{"start":{"line":17,"column":0},"end":{"line":27,"column":1}},"line":17},"2":{"name":"splitFields","decl":{"start":{"line":29,"column":0},"end":{"line":29,"column":80}},"loc":{"start":{"line":29,"column":0},"end":{"line":34,"column":1}},"line":29}},"branchMap":{"0":{"loc":{"start":{"line":2,"column":0},"end":{"line":2,"column":80}},"type":"if","locations":[{"start":{"line":2,"column":0},"end":{"line":2,"column":80}},{"start":{"line":2,"column":0},"end":{"line":2,"column":80}}],"line":2},"1":{"loc":{"start":{"line":5,"column":0},"end":{"line":5,"column":80}},"type":"if","locations":[{"start":{"line":5,"column":0},"end":{"line":5,"column":80}},{"start":{"line":5,"column":0},"end":{"line":5,"column":80}}],"line":5},"2":{"loc":{"start":{"line":8,"column":0},"end":{"line":8,"column":80}},"type":"if","locations":[{"start":{"line":8,"column":0},"end":{"line":8,"column":80}},{"start":{"line":8,"column":0},"end":{"line":8,"column":80}}],"line":8},"3":{"loc":{"start":{"line":11,"column":0},"end":{"line":11,"column":80}},"type":"if","locations":[{"start":{"line":11,"column":0},"end":{"line":11,"column":80}},{"start":{"line":11,"column":0},"end":{"line":11,"column":80}}],"line":11},"4":{"loc":{"start":{"line":19,"column":0},"end":{"line":19,"column":80}},"type":"if","locations":[{"start":{"line":19,"column":0},"end":{"line":19,"column":80}},{"start":{"line":19,"column":0},"end":{"line":19,"column":80}}],"line":19},"5":{"loc":{"start":{"line":20,"column":0},"end":{"line":20,"column":80}},"type":"if","locations":[{"start":{"line":20,"column":0},"end":{"line":20,"column":80}},{"start":{"line":20,"column":0},"end":{"line":20,"column":80}}],"line":20},"6":{"loc":{"start":{"line":21,"column":0},"end":{"line":21,"column":80}},"type":"if","locations":[{"start":{"line":21,"column":0},"end":{"line":21,"column":80}},{"start":{"line":21,"column":0},"end":{"line":21,"column":80}}],"line":21},"7":{"loc":{"start":{"line":22,"column":0},"end":{"line":22,"column":80}},"type":"if","locations":[{"start":{"line":22,"column":0},"end":{"line":22,"column":80}},{"start":{"line":22,"column":0},"end":{"line":22,"column":80}}],"line":22},"8":{"loc":{"start":{"line":23,"column":0},"end":{"line":23,"column":80}},"type":"if","locations":[{"start":{"line":23,"column":0},"end":{"line":23,"column":80}},{"start":{"line":23,"column":0},"end":{"line":23,"column":80}}],"line":23},"9":{"loc":{"start":{"line":24,"column":0},"end":{"line":24,"column":80}},"type":"if","locations":[{"start":{"line":24,"column":0},"end":{"line":24,"column":80}},{"start":{"line":24,"column":0},"end":{"line":24,"column":80}}],"line":24},"10":{"loc":{"start":{"line":25,"column":0},"end":{"line":25,"column":80}},"type":"if","locations":[{"start":{"line":25,"column":0},"end":{"line":25,"column":80}},{"start":{"line":25,"column":0},"end":{"line":25,"column":80}}],"line":25},"11":{"loc":{"start":{"line":29,"column":0},"end":{"line":29,"column":80}},"type":"default-arg","locations":[{"start":{"line":29,"column":0},"end":{"line":29,"column":80}}],"line":29},"12":{"loc":{"start":{"line":30,"column":0},"end":{"line":30,"column":80}},"type":"if","locations":[{"start":{"line":30,"column":0},"end":{"line":30,"column":80}},{"start":{"line":30,"column":0},"end":{"line":30,"column":80}}],"line":30}},"s":{"0":0,"1":0,"2":0,"3":0,"4":0,"5":0,"6":0,"7":0,"8":0,"9":12,"10":12,"11":12,"12":12,"13":12,"14":12,"15":12,"16":12,"17":12,"18":4,"19":0,"20":4},"f":{"0":0,"1":12,"2":4},"b":{"0":[0,0],"1":[0,0],"2":[0,0],"3":[0,0],"4":[3,9],"5":[3,9],"6":[3,9],"7":[3,9],"8":[3,9],"9":[3,9],"10":[3,9],"11":[4],"12":[0,4]}}}
EOF
