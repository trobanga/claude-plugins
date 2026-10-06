#!/usr/bin/env bash
# Builds a Python repository (pyproject.toml, pytest): main is origin/main,
# the branch "feature" adds reserve() to the stock module. Python is not a
# project type the skill supports.
set -euo pipefail

g() { git -c user.name=eval -c user.email=eval@example.com "$@"; }

git init -q -b main .
printf '__pycache__/\n.coverage\ncoverage.xml\n' > .gitignore

cat > pyproject.toml <<'EOF'
[project]
name = "inventory"
version = "0.1.0"
requires-python = ">=3.10"

[tool.pytest.ini_options]
pythonpath = ["src"]
EOF

mkdir -p src/inventory tests
: > src/inventory/__init__.py

cat > src/inventory/stock.py <<'EOF'
def available(stock: dict[str, int], sku: str) -> int:
    return stock.get(sku, 0)
EOF

cat > tests/test_stock.py <<'EOF'
from inventory.stock import available


def test_available_defaults_to_zero():
    assert available({}, "x") == 0
EOF

g add -A
g commit -q -m "Stock lookup"
git update-ref refs/remotes/origin/main HEAD
git checkout -q -b feature

cat > src/inventory/stock.py <<'EOF'
def available(stock: dict[str, int], sku: str) -> int:
    return stock.get(sku, 0)


def reserve(stock: dict[str, int], sku: str, qty: int) -> bool:
    if qty <= 0:
        raise ValueError("qty must be positive")
    if available(stock, sku) < qty:
        return False
    stock[sku] -= qty
    return True
EOF

cat > tests/test_stock.py <<'EOF'
from inventory.stock import available, reserve


def test_available_defaults_to_zero():
    assert available({}, "x") == 0


def test_reserve_takes_from_stock():
    stock = {"a": 3}
    assert reserve(stock, "a", 2) is True
    assert stock == {"a": 1}
EOF

g add -A
g commit -q -m "Reserve stock"
