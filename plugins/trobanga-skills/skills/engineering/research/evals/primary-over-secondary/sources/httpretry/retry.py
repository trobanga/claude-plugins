"""httpretry: retry an HTTP call with exponential backoff.

This file is the library's source of truth.
"""
import random
import time

DEFAULT_ATTEMPTS = 5
BASE_DELAY_S = 0.5
MAX_DELAY_S = 30.0


def _delay(attempt: int) -> float:
    # 0.5, 1, 2, 4, ... capped at MAX_DELAY_S, plus up to 10% jitter
    raw = min(BASE_DELAY_S * (2 ** attempt), MAX_DELAY_S)
    return raw + random.uniform(0, raw * 0.1)


def retry(call, attempts: int = DEFAULT_ATTEMPTS, retry_on=(ConnectionError, TimeoutError)):
    """Call `call()` until it succeeds or `attempts` calls have failed."""
    last = None
    for attempt in range(attempts):
        try:
            return call()
        except retry_on as exc:
            last = exc
            if attempt < attempts - 1:
                time.sleep(_delay(attempt))
    raise last
