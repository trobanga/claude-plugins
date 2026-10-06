from src.pricing import tax


def price_cart(cart, region):
    lines = []
    for item in cart["items"]:
        net = item["unit_cents"] * item["qty"]
        # reaches into tax internals: the rate table and the rounding helper
        rate = tax._RATES[region].get(item["category"], tax._RATES[region]["default"])
        lines.append({"sku": item["sku"], "net": net, "tax": tax._round_half_even(net * rate)})
    return {"lines": lines, "total": sum(l["net"] + l["tax"] for l in lines)}
