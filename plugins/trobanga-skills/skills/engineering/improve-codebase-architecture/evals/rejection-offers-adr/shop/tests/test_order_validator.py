from src.orders.order_validator import validate_cart


def test_empty_cart():
    assert validate_cart({"items": []}) == ["empty cart"]
