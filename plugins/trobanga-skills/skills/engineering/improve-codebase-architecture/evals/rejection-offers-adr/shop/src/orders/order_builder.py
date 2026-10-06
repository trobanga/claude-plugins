def build_order(cart, priced):
    return {"customer": cart["customer"], "lines": priced["lines"], "total": priced["total"]}
