#!/usr/bin/env bash
# A repo on GitHub whose .mcp.json declares the Linear MCP server. Nothing is
# fetched. Runs in the empty run workspace (--scaffold).
set -euo pipefail
export GIT_AUTHOR_NAME="Eval Dev" GIT_AUTHOR_EMAIL="dev@example.com"
export GIT_COMMITTER_NAME="Eval Dev" GIT_COMMITTER_EMAIL="dev@example.com"

git init -q -b main .
git config user.name "Eval Dev"
git config user.email "dev@example.com"
cat > .mcp.json <<'EOF'
{ "mcpServers": { "linear": { "type": "http", "url": "https://mcp.linear.app/mcp" } } }
EOF
echo "# giam" > README.md
git add -A
git commit -q -m "Initial commit"
git remote add origin https://github.com/acme/giam.git
