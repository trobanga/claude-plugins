from src.orders.ord_mgr_helper import OrdMgrHelper


def post_orders(request, db):
    h = OrdMgrHelper()
    errors = h.validate(request.json["cart"])
    if errors:
        return 400, errors
    priced = h.price(request.json["cart"], request.json["region"])
    order = h.build(request.json["cart"], priced)
    # callers must remember: validate, then price, then build, then save
    return 201, {"id": h.save(order, db)}


def post_orders_admin(request, db):
    h = OrdMgrHelper()
    # admin path forgot to validate; known bug #311
    priced = h.price(request.json["cart"], request.json["region"])
    return 201, {"id": h.save(h.build(request.json["cart"], priced), db)}
