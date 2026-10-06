#!/usr/bin/env bash
# Builds a cart package whose Cart.total() is a stub with fixed callers.
set -euo pipefail

mkdir -p cart tests

cat > cart/__init__.py <<'EOF'
EOF

cat > cart/cart.py <<'EOF'
class Cart:
    def __init__(self):
        self._items: list[tuple[str, int]] = []

    def add(self, name: str, price_cents: int) -> None:
        self._items.append((name, price_cents))

    def total(self) -> int:
        raise NotImplementedError
EOF

cat > cart/checkout.py <<'EOF'
from cart.cart import Cart


def charge_amount(cart: Cart) -> int:
    """Amount in cents sent to the payment provider."""
    return cart.total()


def receipt_line(cart: Cart) -> str:
    return f"Total: {cart.total() / 100:.2f} EUR"
EOF

cat > tests/__init__.py <<'EOF'
EOF
