from src.orders.order_validator import validate_cart
from src.orders.order_builder import build_order
from src.orders.order_saver import save_order
from src.pricing.pricing import price_cart


class OrdMgrHelper:
    """Called by the web handler for POST /orders."""

    def validate(self, cart):
        return validate_cart(cart)

    def price(self, cart, region):
        return price_cart(cart, region)

    def build(self, cart, priced):
        return build_order(cart, priced)

    def save(self, order, db):
        return save_order(order, db)
