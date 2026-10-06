from tinyweb import config
from tinyweb.router import _routes


class PayloadTooLarge(Exception):
    pass


def handle(path: str, body: bytes):
    if len(body) > config.MAX_BODY_BYTES:   # checked before the route is looked up
        raise PayloadTooLarge(len(body))
    handler, timeout_s = _routes[path]
    return handler(body, timeout=timeout_s)
