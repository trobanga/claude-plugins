def send_order_email(order, smtp):
    smtp.send(order["customer"], f"Order total {order['total'] / 100:.2f}")
