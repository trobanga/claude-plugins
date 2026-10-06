import time

from transport import fetch_page


class Syncer:
    def __init__(self, cfg, store):
        self.cfg = cfg
        self.store = store

    def sync(self):
        cursor = self.store.cursor()
        while True:
            page = self._fetch_with_retry(cursor)
            self.store.upsert(page["items"])
            cursor = page.get("next")
            if not cursor:
                break
        self.store.set_cursor(None)

    def _fetch_with_retry(self, cursor):
        for attempt in range(3):
            try:
                return fetch_page(self.cfg.base_url, self.cfg.token, cursor)
            except ConnectionError:
                time.sleep(2 ** attempt)
        raise ConnectionError("gave up")
