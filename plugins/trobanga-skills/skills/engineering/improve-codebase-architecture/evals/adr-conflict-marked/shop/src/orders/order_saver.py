def save_order(order, db):
    db.execute("INSERT INTO orders (customer, total) VALUES (?, ?)", (order["customer"], order["total"]))
    return db.lastrowid
