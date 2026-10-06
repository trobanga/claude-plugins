#!/usr/bin/env bash
# Builds a repo that already keeps research notes under
# knowledge/investigations/, plus a vendored queue library to research.
set -euo pipefail

mkdir -p knowledge/investigations vendor/tinyqueue src

cat > knowledge/investigations/2026-03-cache-eviction.md <<'EOF'
# Cache eviction in lrukit

Question: when does lrukit evict, and in which order?

- Evicts on insert once `maxsize` is reached, least recently used first
  (source: vendor/lrukit/cache.py, `_evict`).
EOF

cat > knowledge/investigations/README.md <<'EOF'
# Investigations

One Markdown file per question, named `YYYY-MM-<slug>.md`.
EOF

cat > vendor/tinyqueue/queue.py <<'EOF'
import threading
import time


class QueueFull(Exception):
    pass


class TinyQueue:
    def __init__(self, maxsize: int = 100):
        self._items = []
        self._maxsize = maxsize
        self._cond = threading.Condition()

    def put(self, item, timeout: float = 2.0) -> None:
        """Wait up to `timeout` seconds for space, then raise QueueFull."""
        deadline = time.monotonic() + timeout
        with self._cond:
            while len(self._items) >= self._maxsize:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    raise QueueFull(f"queue full after {timeout}s")
                self._cond.wait(remaining)
            self._items.append(item)
            self._cond.notify_all()
EOF

cat > src/worker.py <<'EOF'
from vendor.tinyqueue.queue import TinyQueue

jobs = TinyQueue(maxsize=10)
EOF
