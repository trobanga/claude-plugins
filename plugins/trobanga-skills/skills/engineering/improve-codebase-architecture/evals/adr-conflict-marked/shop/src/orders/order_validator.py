def validate_cart(cart):
    if not cart["items"]:
        return ["empty cart"]
    return [f"bad qty for {i['sku']}" for i in cart["items"] if i["qty"] <= 0]
