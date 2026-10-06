def send_order_sms(order, gateway):
    gateway.post({"to": order["customer"], "text": f"Order total {order['total'] / 100:.2f}"})
