from tinyweb import config

_routes = {}


def route(path: str, timeout_s: float | None = None):
    """Register a handler. `timeout_s` overrides config.REQUEST_TIMEOUT_S for this route."""
    def wrap(handler):
        _routes[path] = (handler, timeout_s or config.REQUEST_TIMEOUT_S)
        return handler
    return wrap
