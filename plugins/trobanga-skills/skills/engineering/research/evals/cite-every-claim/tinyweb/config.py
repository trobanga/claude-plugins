"""tinyweb server-wide settings."""

REQUEST_TIMEOUT_S = 15          # applies to every route unless the route overrides it
MAX_BODY_BYTES = 1 * 1024 * 1024  # 1 MiB, enforced before routing; no per-route override
